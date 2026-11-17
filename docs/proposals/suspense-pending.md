# Proposal: Pending state for Suspense boundaries

| | |
|---|---|
| **Status** | Proposed. Nothing here is built. |
| **Scope** | Step 1 of 3 toward async values in the reactive graph. This step changes only Xote; steps 2 and 3 are sketched under [Later steps](#later-steps) so this one does not close doors on them. |
| **Prior art** | SolidJS 2.0 (release candidate at the time of writing): `isPending`, the reworked Suspense boundary, async computeds. Its exact API names were not checked against final docs and are cited only for the idea. |

## Summary

Two additive APIs that close the gaps between Xote's `Resource` + `View.Suspense`
and what an app needs around *refreshing* data:

1. **`View.Suspense.pending()`** — called in a component body, returns a
   `Signal.t<bool>` that is `true` while any fetch of a resource the nearest
   `Suspense` owns is in flight: the first fetch *and every later one*. It lets
   a page dim itself or show a spinner during a refresh without matching on
   each resource's state.
2. **`Resource.hold(resource)`** — called in a component body, makes the nearest
   `Suspense` wait for a resource that was created somewhere else (at module
   level, in a parent, in a shared store) while that resource has no value.
   Today only the component that *creates* a resource can suspend.

Neither changes existing behaviour. Neither needs a change in `rescript-signals`.

## Where things stand

From `src/Resource.res` and `View.Suspense` in `src/View.res`:

- A resource is a `Signal.t<state<'a>>` (`Pending | Ready | Refreshing | Failed`)
  kept up to date by a fetch that runs in an effect.
- `Resource.make` calls `RuntimeLifecycle.suspend()`, which bumps the `pending`
  count of the nearest suspense **in the frame of the creating component**, and
  ends that wait when the first fetch settles, on `mutate`, or when the creating
  component is released.
- A suspense renders its children hidden while `pending > 0`, holds back their
  refs and `onMount`s, and shows the fallback.
- **A later fetch never suspends again.** It sets `Refreshing(previous)` and
  the content stays visible. This already matches what Solid and React settled
  on — bringing a fallback back on every refresh is jarring — so this proposal
  keeps it.

What is missing:

| Need | Today |
|---|---|
| "Is anything on this page refreshing?" | Match every resource's state yourself and combine them in a `Computed`. A page with five resources in three components has to thread all five to wherever the spinner lives. |
| Suspend on a resource created outside the boundary | Not possible. A resource created at module level, or by a parent above the `Suspense`, never holds that `Suspense`. Its readers inside the boundary render `Pending` while the boundary is shown. |

## Design

### 1. `View.Suspense.pending()`

```rescript
module Page = {
  @xote.component
  let make = () =>
    <View.Suspense fallback={<Spinner />}>
      <Toolbar />
      <Results />
    </View.Suspense>
}

module Toolbar = {
  @xote.component
  let make = () => {
    let refreshing = View.Suspense.pending()
    <div class={() => Signal.get(refreshing) ? "toolbar dimmed" : "toolbar"}>
      ...
    </div>
  }
}
```

**Semantics**

- `true` while at least one fetch of a resource that counts toward the nearest
  suspense is in flight. "Counts toward" means the same set that holds the
  suspense today (resources created below it) plus any `Resource.hold` below
  it. The first fetch counts too, so `pending()` is `true` throughout the
  initial wait as well.
- It reports the nearest suspense only. An inner suspense's resources do not
  make an outer one's `pending()` true. That matches how the `pending` count
  already works, and it keeps a spinner local to the boundary that drew it.
  (See [open questions](#open-questions).)
- Called outside any `Suspense`, or during a server render, it returns a signal
  that is always `false`. It does not raise: a component should not have to
  know whether it was placed under a boundary.
- Like `Context.use`, it is read **in the component body**. It captures the
  suspense from the frame at that moment. A call from an event handler or a
  timer sees no frame and gets the constant `false`.

**Mechanics**

- `RuntimeContext.suspense` gains a second counter, `inFlight: Signal.t<int>`,
  next to `pending`. `pending` keeps its meaning (resources with no value yet);
  `inFlight` counts fetches in flight.
- `Resource.make` captures the suspense once, at creation, through a new
  `RuntimeLifecycle.track()` that returns a pair of `start`/`finish` calls bound
  to that suspense (no-ops when there is none). The fetch effect calls `start`
  when it starts a fetch it has not already counted, and `finish` from
  `settle`, from `mutate`, and from the disposer already registered on the
  creating region. A version bump that supersedes a fetch in flight leaves the
  count alone, since one fetch replaces another; only settle, `mutate` and
  disposal end it. The guard is a per-controller `counted: bool`.
- `pending()` returns `RuntimeOwner.ownedComputed(() => Signal.get(suspense.inFlight) > 0)`,
  registered with the calling region so it is released with it.
- Writes to `inFlight` happen where writes to the resource state already
  happen: inside the fetch effect and in `settle`. No new place writes during a
  render.

### 2. `Resource.hold(resource)`

```rescript
/* Shared at module level: fetched once, read by several pages. */
let currentUser = Resource.make(() => fetchCurrentUser())

module Dashboard = {
  @xote.component
  let make = () => {
    Resource.hold(currentUser)
    <h1> {Signal.get(currentUser)->Resource.value->Option.mapOr("", u => u.name)} </h1>
  }
}

<View.Suspense fallback={<Spinner />}> <Dashboard /> </View.Suspense>
```

**Semantics**

- While `resource` has no value (`Pending`), the nearest suspense of the calling
  component waits. When it has one (`Ready`, `Refreshing`) or has failed
  (`Failed`), the wait ends. `Failed` ends the wait for the same reason the
  creator-side path does: a boundary waiting forever on a failure is worse than
  rendering it. A `Pending` again later (a refetch after a failure) holds again,
  which is the same rule `Pending` already follows for the creating component.
- It also counts toward that suspense's `pending()` while the resource is
  `Pending` or `Refreshing`.
- Released with the calling component: unmounting ends any wait it holds.
- Outside a `Suspense`, or on the server, it does nothing.
- Holding a resource the component also created is harmless: the creator's
  wait and the hold's wait are counted separately and each ends on its own.

**Mechanics**

- An `Effect.run` in the calling component's region reads `resource`. On
  `Pending` with no wait open, it opens one with `RuntimeLifecycle.suspend()`;
  on any other state it ends the open wait. Its disposer ends the wait too.
  `Effect.runWithDisposer` already re-installs the creation frame on every run,
  so `suspend()` finds the right suspense on later runs.
- The first run happens synchronously in the component body, so the wait opens
  before the render that would mount the children finishes, and their refs and
  `onMount`s are held exactly as they are for a resource created there.

### Naming

`pending` matches the counter name already used inside `RuntimeContext` and
reads well next to `Resource.isLoading`. `hold` says what it does to the
boundary without suggesting that it reads or returns the value. A name with
`use` was rejected because `Context.use` returns a value and this does not.

## Compatibility

- Purely additive. Existing programs behave the same: the extra counter is only
  read by `pending()`, and no resource holds a suspense it does not hold today
  unless `Resource.hold` is called.
- Widens two `.resi` files (`View.resi`, `Resource.resi`), so
  `tests/__snapshots__/public-exports.json` changes deliberately.
- SSR is unchanged: on the server a `Suspense` renders only its fallback and
  never evaluates its children, so neither API runs there.
- Hydration is unchanged: a `Suspense` is a `SignalFragment`, which hydration
  re-renders; both APIs run in that render like they do in a client render.

## Testing

In `tests/Resource_test.res`, under jsdom:

- `pending()` is `true` during the first fetch and during a refetch, `false`
  after each settles; it follows `mutate` and disposal.
- A fetch superseded by a dependency change does not drop the count to zero
  while its replacement is still in flight.
- An inner suspense's resources do not make an outer `pending()` true.
- `pending()` outside a suspense is constantly `false`.
- `hold` on a module-level resource shows the fallback until it settles and
  holds the children's `onMount` until then; `Failed` ends the wait; unmounting
  the holder ends the wait.
- `hold` plus creation in the same component: both waits end, the suspense
  shows once.

## Considered and rejected

- **Bring the fallback back on refetch** (an opt-in `~suspendOnRefetch`). Easy
  to build on the same counter, but the behaviour both Solid and React moved
  away from: a refresh should not throw away what the user is looking at.
  `pending()` gives the "something is loading" signal without hiding anything.
- **A read-based `isPending(() => expr)`** like Solid's, true when any async
  value *read* in `expr` is in flight. That needs the runtime to know which of
  the signals a computation read are resources. `Signal.get` has no hook for
  that, and enumerating a computed's dependencies is not public API in
  `rescript-signals`. It belongs in step 3, where an async value is a graph
  node and pending state flows through it.
- **Suspend on read instead of on creation, for every resource.** That is the
  model Solid uses and probably the right long-term one, but it is a silent
  behaviour change for existing apps (a module-level resource would start
  holding every boundary that reads it) and it also needs read detection.
  `hold` gets the same effect explicitly, now.

## Later steps

These are not proposed here; they are listed so step 1 is judged against them.

- **Step 2 — pending through derived values.** A computed that reads a resource
  is pending while the resource is, so a page that derives from three resources
  does not match on three states. Can likely be done in Xote with a
  `Resource.map`/`Resource.all` family that returns resources, before any
  change upstream.
- **Step 3 — async computeds in `rescript-signals`.** Something like
  `Computed.async: (unit => promise<'a>) => Signal.t<'a>`, where reading a
  value that is not there yet throws a dedicated exception that `Suspense`
  catches, and pending state propagates through ordinary computeds. A separate
  constructor because ReScript, unlike TypeScript, will not let a computed that
  returns `promise<'a>` read as `'a`. This is where read-based suspension and a
  read-based `isPending` become possible, and where batching updates until
  async work settles (transitions) would start to pay for itself.

## Open questions

1. Should an outer `pending()` include inner boundaries' fetches? Local is
   proposed because it matches `pending` and keeps spinners local, but a
   page-level progress bar wants the union. A `~deep=true` argument is cheap
   to add later; adding it now is speculative.
2. Should `hold` take several resources (`Resource.hold([a, b])`)? Repeated
   calls already work, and an array of resources of different types does not
   typecheck without a wrapper, so one at a time is proposed.
3. Should `pending()` be a component instead (`<View.Suspense.Pending>{bool => …}</…>`)?
   A signal composes with `computedAttr`, class thunks and the PPX; a render-prop
   component would only cover the child-position case.
