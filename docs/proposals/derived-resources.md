# Proposal: Derived resources

| | |
|---|---|
| **Status** | Implemented, not yet released. This document keeps the design record — the *why*, the rejected options and the open questions. Current behaviour is documented in `src/Resource.resi` and [`AGENTS.md`](../../AGENTS.md), which are the sources of truth. |
| **Scope** | Step 2 of 3 toward async values in the reactive graph. Step 1 is [`suspense-pending.md`](./suspense-pending.md). Everything here is built in Xote on top of `Resource`; nothing changes in `rescript-signals`. |

## Summary

Five functions that return resources from resources, so loading and failure
travel through derived values instead of being matched on at every step:

| Function | Result |
|---|---|
| `Resource.map(r, f)` | `f` of `r`'s value |
| `Resource.map2(a, b, f)`, `map3(a, b, c, f)` | `f` of every value, once each has one |
| `Resource.all(rs)` | the array of every value, in order |
| `Resource.chain(r, fetch)` | a fetch that runs with `r`'s value once it has one |

Each returns a `Resource.t`, so everything that takes a resource takes them:
`Signal.get`, `Resource.value`, `Resource.isLoading`, `Resource.hold`,
`refetch` and `mutate`.

## Motivation

Before this, a page that needed a user, their settings and their posts did one
of two things:

- **Matched on three states**, everywhere a value from more than one of them
  was needed. Each match handles `Pending`, `Ready`, `Refreshing` and `Failed`,
  and combining them by hand is where "is it still loading?" bugs come from.
- **Fetched everything in one resource**, `Resource.make(() => Promise.all3(…))`.
  One state, but one `refetch` and one `mutate` for everything, and a dependent
  request (posts need the user's id) has to be sequenced inside the promise,
  so changing the user refetches the settings too.

And a dependent request had no good form at all. `Resource.make(() =>
switch Signal.get(user) { | Ready(u) => fetchPosts(u.id) | _ => ??? })` has no
way to say "not yet": there is no promise to return for a user that has not
loaded.

## Design

### Derived resources: `map`, `map2`, `map3`, `all`

All four are one internal function, `derived(sources, f)`, which returns a
`Computed` over the sources' states:

1. `Failed(e)` as soon as a source is `Failed` — the first, in argument order.
2. Otherwise `Pending` while a source is `Pending`.
3. Otherwise `f` of every value: `Refreshing` while a source is `Refreshing`,
   `Ready` once none is.

**Failure before pending.** One failed source decides the result whatever the
others are doing, as `Promise.all` rejects at the first rejection. Waiting for
the others to load only to show the failure anyway would hold a spinner for
nothing.

**`f` re-runs only on a new value.** The derived resource keeps its last inputs
and output, and reuses the output when every source value is the same (`===`).
A source going from `Ready(v)` to `Refreshing(v)` therefore keeps the derived
value the same object, which matters to a keyed list rendered from it and to
any `~equals` downstream.

**An equality cutoff.** A derived resource builds a new state on every
recompute, and a computed has no cutoff by default. It is created with
`~equals=sameState`: the same case carrying the same value (`===`). Its readers
wake only when the case or the value changes.

**A throwing `f` is a failure.** `f` *is* the derivation, so a throw in it makes
the derived resource `Failed(exn)` rather than making every read throw. This
differs on purpose from `Resource.make`, which keeps a failure in what
*settling* sets off (a view rendering the value) apart from the fetch failing.

**No suspension by creation.** A derived resource fetches nothing, so creating
one does not make a `View.Suspense` wait; its sources do that, where they were
created. `Resource.hold(derived)` makes a suspense wait for it, which waits for
every source.

**Lifetime.** Like any `Computed`, a derived resource is attached to its sources
only while something reads it.

**`refetch` and `mutate`.** A `WeakMap` (`links`) records what a derived
resource derives from. `refetch` walks it down to the resources with a fetch
and bumps all their triggers in one `Signal.batch`, visiting each resource once,
so a source reached two ways (`map2(a, map(a, f))`) fetches once. `mutate` on
a derived resource does nothing: there is no inverse of `f` to write through.

### `chain`

`chain(source, fetch)` is two resources and a hold:

- **Its own resource**, built by `makeWith(~suspends=false, run)`, the machinery
  `make` now shares. `run` is called inside the fetch effect and returns
  `Some(fetch(value))` when the source is `Ready(value)`, and `None` otherwise.
  `None` means nothing to fetch yet: no new version, no loading state, and a
  fetch already in flight goes on. That last part matters: when the source
  starts refreshing, the chain's fetch for the current value is still valid,
  and dropping it would leave the chain waiting on a fetch nobody restarts if
  the source then settles with the same value.
- **What it shows**, a computed over the source and its own resource:
  `Pending`/`Failed` while the source is, otherwise the own state, with
  `Ready(v)` shown as `Refreshing(v)` while the source refreshes. Cut off by
  `sameState` like a derived resource.
- **A `hold` on what it shows**, which makes the suspense it was created under
  wait until it first leaves `Pending` and counts it toward
  `View.Suspense.pending()` while it is loading. Its own resource neither
  suspends nor counts (`~suspends=false`), so nothing is counted twice.

**When it fetches.** On every `Ready(value)` of the source, and never on
`Refreshing`. A source settles to `Ready` only after a fetch or a `mutate`, both
of which are reasons to fetch again; "only refreshing" means the value is the
one already fetched with. One exception: a chain created while its source is
already `Refreshing(value)` fetches once with that value, since it may be a
while before the source settles and that value is the best there is.

**`refetch` and `mutate`.** `links` maps the chain to its own resource.
`refetch(chain)` runs the chain's own fetch again with the source's current
value and leaves the source alone; `mutate(chain, v)` sets its own value.

### Changes to `Resource.make`

`make` became `makeWith(~suspends=true, () => Some(fetch()))`. To let `run`
return `None` without side effects, the fetch effect now calls `run` *before*
it starts a new version and sets the loading state, where it used to call the
fetch after. Nothing observable depends on the old order: the loading state is
set before the promise can settle either way, and a synchronous throw still
settles as `Failed` through the same version.

## Considered and rejected

- **A distinct type for derived resources**, so that `mutate` on one does not
  typecheck. It would split every function that takes a resource in two, or
  need a phantom parameter on `Resource.t`, which is an API break. `mutate` on a
  derived resource is a silent no-op instead (see question 1).
- **`flatMap(r, value => Resource.t)`**, returning a resource per value. It
  would create a resource inside a computation each time the source changes,
  with nothing to own or dispose it. `chain` takes the fetch function instead,
  and keeps one resource.
- **Making derived resources suspend their creator's boundary**, as a resource
  created there does. It would make a component that derives from a background
  resource, deliberately created elsewhere, suspend on it by surprise. `hold`
  says it explicitly.
- **`map4` and up.** `map3` covers the common case; beyond it, `all` over
  resources of one type, or nested `map2`s, or a record built in `map3` and
  combined again.
- **Re-deriving on structurally equal values.** A refetch usually returns a new
  object with the same content, and a derived resource treats it as new. Deep
  comparison would cost a walk of every value on every recompute; see
  question 2.

## Open questions

1. **Should `mutate` on a derived resource warn in development?** It is a
   silent no-op that the type allows. **Recommendation: yes**, once the
   development-mode check moves from `View` to an internal module both `View`
   and `Resource` can use. It was left out here to keep the change to `Resource`.
2. **Should `map`/`chain` take `~equals` for the source value?** A source that
   refetches to equal content currently re-runs `f` and refetches a chain.
   **Recommendation: wait for a case.** `Signal.make`'s `~equals` already exists
   for anyone who needs it upstream.
3. **Should `refetch(chain)` also refetch the source?** "Reload the posts" and
   "reload the user and then the posts" are both reasonable readings.
   **Recommendation: keep it shallow.** `refetch(source)` already reloads both,
   since the chain fetches again when the source settles.

## Later steps

Step 3 — async computeds in `rescript-signals`, read-based suspension and a
read-based `isPending` — is built: see [`async-values.md`](./async-values.md).
`Resource` and its derived forms stay: they keep loading and failure as values
a view matches on, where `Async` makes them reads that wait or throw.
