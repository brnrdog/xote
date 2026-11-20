# Proposal: Pending state for Suspense boundaries

| | |
|---|---|
| **Status** | Step 1 implemented, not yet released. This document keeps the design record — the *why*, the rejected options and the open questions. Current behaviour is documented in `src/View.resi`, `src/Resource.resi` and [`AGENTS.md`](../../AGENTS.md), which are the sources of truth. |
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
  suspense from the frame at that moment. Called anywhere else (an event
  handler, a timer, an effect's later run) it gets whatever frame happens to be
  installed then, so it **warns in development** (see question 3).

**Mechanics**

- `RuntimeContext.suspense` gains a second counter, `inFlight: Signal.t<int>`,
  next to `pending`. `pending` keeps its meaning (resources with no value yet);
  `inFlight` counts fetches in flight.
- `Resource.make` captures the suspense once, at creation, through a new
  `RuntimeLifecycle.flight()` that returns a pair of `start`/`finish` calls bound
  to that suspense (no-ops when there is none). The fetch effect calls `start`
  when it starts a fetch it has not already counted, and `finish` from
  `settle`, from `mutate`, and from the disposer already registered on the
  creating region. A version bump that supersedes a fetch in flight leaves the
  count alone, since one fetch replaces another; only settle, `mutate` and
  disposal end it. The guard is a per-controller `counted: bool`.
- `pending()` returns a library-owned `Computed` of `inFlight > 0`, registered
  with the calling region so it is released with it. It has a `===` equality
  cutoff: a second fetch starting while one is in flight must not wake its
  readers again, and a computed has no cutoff by default.
- The development warning tests `RuntimeContext.inBody`, the flag
  `Context.provide` already uses. The first draft of this proposal said "warn
  when there is no frame", but that does not work: the frame is also empty in
  an ordinary render of an app with no providers and no boundaries, so it
  cannot tell a body from an event handler.
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

- The nearest suspense of the calling component waits until `resource` first
  leaves `Pending`: a value (`Ready`, `Refreshing`, or `mutate`) or a failure
  (`Failed`). `Failed` ends the wait for the same reason the creator-side path
  does: a boundary waiting forever on a failure is worse than rendering it.
- The wait never comes back. A `Pending` again later (a refetch after a
  failure) does not hold, and a resource that already has a value or has
  failed when `hold` is called holds nothing. This is the creator's rule: a
  resource counts once. (The first draft said a hold would wait again on a
  later `Pending`, "the same rule the creating component follows". It is not:
  the creating component suspends once, so the two would have disagreed.)
- It also counts toward that suspense's `pending()` while the resource is
  `Pending` or `Refreshing`.
- Released with the calling component: unmounting ends any wait it holds.
- Outside a `Suspense`, or on the server, it does nothing.
- Holding a resource the component also created is harmless: the creator's
  wait and the hold's wait are counted separately and each ends on its own.

**Mechanics**

- `hold` captures the nearest suspense once, in the body. An `Effect.run` in
  the calling component's region then reads `resource`. On its first `Pending`
  it opens a wait on that suspense with `RuntimeLifecycle.suspendOn(suspense)`;
  on any other state it ends the wait for good. It also starts or finishes the
  hold's own share of `inFlight` (`RuntimeLifecycle.flightOn`) as the state is
  or is not loading. A disposer on the region ends both. Capturing the suspense
  up front, rather than letting each run find it through the frame the effect
  re-installs, keeps the hold tied to one boundary whatever runs it.
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
- `pending()` warns outside a component body and not inside one.
- A fetch superseded by a dependency change does not drop the count to zero
  while its replacement is still in flight.
- An inner suspense's resources do not make an outer `pending()` true.
- `pending()` outside a suspense is constantly `false`.
- `hold` on a module-level resource shows the fallback until it settles and
  holds the children's `onMount` until then; `Failed` ends the wait and a
  retry does not wait again; a resource that already has a value holds
  nothing; unmounting the holder ends the wait; a refetch counts toward
  `pending()` without bringing the fallback back.
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

- **Step 2 — pending through derived values.** Implemented as
  `Resource.map`/`map2`/`map3`/`all` and `Resource.chain`, without a change
  upstream; see [`derived-resources.md`](./derived-resources.md).
- **Step 3 — async computeds in `rescript-signals`.** Implemented as
  rescript-signals 4's `Async` (`make`, `NotReady`, `isPending`) and Xote's
  `Xote.Async`, with read-based suspension: an effect that reads a value not
  ready yet makes its `Suspense` wait. See
  [`async-values.md`](./async-values.md). Batching updates until async work
  settles (transitions) is still not built.

## Open questions

Each carries the recommendation it was built with. They are kept open because
each is a choice that later use could overturn.

### 1. Should an outer `pending()` include fetches under nested boundaries?

With an app-wide `Suspense` around the layout and a nested one around a
sidebar, a sidebar refetch makes the sidebar's `pending()` true. *Local*
(built) leaves the outer one false; *deep* would make both true.

- Local fits a toolbar spinner or a dimmed results panel: the sidebar
  refreshing must not dim the main results. It also matches `pending`, where a
  resource only holds its nearest boundary.
- Deep fits a page-wide progress bar ("something on this page is loading").
  It is cheap to build: bump an extra counter on every enclosing suspense, a
  short walk up `parent`.

**Recommendation: local, and no `~deep` until it is asked for.** A spinner too
wide is a visible bug; one too narrow is a missing feature. A page-wide
progress bar probably wants a global read (say `Resource.anyInFlight()`, every
fetch in the app) more than a flag on whichever boundary happens to be
outermost.

### 2. Should `hold` take several resources at once?

- **One per call** (built): `Resource.hold(a); Resource.hold(b)`. Each opens its
  own wait and the boundary already waits for the count to reach zero, so
  repeated calls mean "all of them".
- **An array**, `Resource.hold([a, b])`, only typechecks when every resource
  holds the same type, since a ReScript array has one element type. That is
  rarely the case, so in practice it needs the next option.
- **A type-erasing wrapper**, `Resource.hold([Resource.any(a), Resource.any(b)])`,
  works for mixed types at the cost of an exported type and a function, to
  save one line per resource.

**Recommendation: one per call.** The wrapper can be added later without
breaking anything if the repetition turns out to matter. `hold` returns `unit`
rather than the resource, so `let user = shared->Resource.hold` is not
possible: it is a statement about the boundary, and returning the resource
would suggest it reads or transforms it.

### 3. A signal, or a render-prop component?

- **A signal** (built): `let refreshing = View.Suspense.pending()`. It composes
  with attribute thunks, `computedAttr`, `Computed`, `Effect` and the PPX's
  `Signal.get` detection. "Dim this element" is an attribute on an element you
  already have, which a component cannot express without wrapping it.
- **A component**, `<View.Suspense.Pending render={refreshing => …} />`,
  covers only child position, but it cannot be misplaced: it always reads the
  frame it renders in. A signal called in an event handler silently reads the
  wrong frame, or none.

**Recommendation: the signal, with a development warning outside a component
body** — built that way. It keeps the composability and removes most of the
risk. The warning keys on `RuntimeContext.inBody`, for the reason given under
*Mechanics*.

### 4. Reading a boundary from outside it

`pending()` reports the boundary *above* its caller, so the component that
renders `<View.Suspense>` cannot ask about that boundary: a header next to the
boundary cannot show a spinner for the content inside it. A handle created
ahead and passed in would cover it:

```rescript
let content = View.Suspense.handle()
/* the header, outside the boundary */
<Spinner visible={View.Suspense.isPending(content)} />
/* the boundary */
<View.Suspense handle=content fallback={...}> ... </View.Suspense>
```

**Recommendation: wait for a real case.** The usual workaround, moving the
header inside the boundary, is usually what the layout wants anyway. The
design fits the signal from question 3: a handle would return the same kind of
signal.
