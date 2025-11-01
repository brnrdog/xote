## Xote Technical Overview

This document describes the architecture and APIs of the Xote reactive core and minimal component renderer, inspired by the TC39 Signals proposal. It summarizes the data model, dependency tracking, scheduling, and module boundaries.

Reference: TC39 Signals proposal `https://github.com/tc39/proposal-signals`.

### Modules and Responsibilities

- **`Xote__Core`**: Low-level runtime for dependency tracking and scheduling of observers (effects and computeds). Defines the signal cell shape (`t<'a>`) and maintains global maps of dependencies and observers. Potentially some of these modules could be moved into other modules (e.g observers scheduling to `Xote__Observer`, signal observers to `Xote__Signal`, and so on).
- **`Xote__Signal`**: User-facing state cells. `make`, `get`, `peek`, `set`, `update` with automatic dependency capture on `get`.
- **`Xote__Computed`**: Derived signals. Creates an internal observer that recomputes and writes into a backing signal.
- **`Xote__Effect`**: Effects that run a function tracked against any signals it reads. Returns a disposer fn.
- **`Xote__Observer`**: Observer types and structure used by the scheduler.
- **`Xote__Id`**: Monotonic integer ID generator.
- **`Xote__Component`**: Minimal virtual DOM with reactive text and fragment nodes, render and mount to DOM. Convenience element constructors.
- **`Xote`**: Public module surface that re-exports the above.

### Core Data Structures (`Xote__Core`)

- **Signal cell**: `t<'a> = { id: int, value: ref<'a>, version: ref<int> }`.
- **Global state**:
  - `observers: Map<int, Observer.t>` — all observers by id.
  - `signalObservers: Map<int, Set<int>>` — signal id -> set of observer ids.
  - `currentObserverId: option<int>` — the observer currently tracking reads.
  - `pending: Set<int>` and `batching: bool` — simple synchronous scheduler queue and batching flag.

### Dependency Tracking

- Reads under tracking are captured: when `currentObserverId` is `Some(id)`, `Signal.get` calls `Core.addDep(id, signalId)`.
- `addDep` both records the dependency in the observer and adds the observer to the signal’s reverse index. `clearDeps` removes an observer from all its dependency buckets before re-tracking.

### Scheduling Model

- `notify(signalId)` looks up dependent observers and enqueues them via `schedule`.
- `schedule(observerId)` queues the observer; if not batching, it immediately flushes: clears previous deps, sets `currentObserverId`, runs the observer’s `run`, then unsets tracking.
- `batch(f)` sets `batching = true` for the duration of `f` and flushes the queued observers afterward.
- `untrack(f)` temporarily disables dependency capture during `f`.

Semantics:

- Synchronous, immediate scheduling by default (microtask-like but runs inline when not batching).
- Re-execution always re-tracks dependencies to reflect the latest graph.

### Signals (`Xote__Signal`)

- `make(v)` creates a new cell.
- `get(s)` returns the value and, if tracking, captures a dependency.
- `peek(s)` returns the value without dependency capture.
- `set(s, v)` writes the value, increments a version counter, and `notify`s dependents.
- `update(s, f)` convenience helper that sets `f(get(s))`.

Notes:

- No equality check on `set`; every write notifies.

### Computed (`Xote__Computed`)

- `make(calc)` creates a backing signal `s` and registers an observer whose `run` recomputes `calc()` and writes into `s`.
- Initial compute runs under tracking to establish dependencies.
- On dependency writes, the core re-runs the computed’s observer which pushes the new value into `s` and notifies any downstream dependents of `s`.

Implication:

- Computeds are realized via push into a backing signal rather than being lazily re-evaluated only on read. They are re-evaluated when upstream dependencies notify and the scheduler flushes.

### Effects (`Xote__Effect`)

- `run(fn)` registers an observer of kind `#Effect` and runs `fn` under tracking. Returns `{ dispose }` to stop observing.
- On dependency writes, the effect re-runs synchronously (or after batching) and re-tracks.

Notes:

- No explicit cleanup callback API (e.g., returning a disposer from `fn`); explicit `dispose()` removes the observer and clears deps.

### Observers (`Xote__Observer`)

- `type kind = [ #Effect | #Computed(int) ]` — computed carries the id of its backing signal.
- `type t = { id, kind, run, mutable deps }` — internal unit of scheduling.

### Component/Rendering (`Xote__Component`)

- Virtual node types: `Element`, `Text`, `SignalText(Core.t<string>)`, `Fragment`, `SignalFragment(Core.t<array<node>>)\`.
- Builders: `text`, `textSignal`, `fragment`, `signalFragment`, `list(signal, renderItem)`, `element` and tag helpers (`div`, `span`, `button`, `input`, `h1`, etc.).
- Rendering:
  - `SignalText` creates a text node seeded with `peek`, and an effect that reads via `get` and writes `textContent` on change.
  - `SignalFragment` uses an effect to replace its container’s children when the array signal changes.
  - `list` is built with a computed that maps the array signal through the item renderer and is rendered as a `SignalFragment`.
- Mounting: `mount(node, container)` and `mountById(node, containerId)`.

### Execution Characteristics

- **Push vs Pull**: Signals push notifications to observers; computeds eagerly push into their backing signal upon upstream changes. Effects run synchronously (unless wrapped in `batch`).
- **Reactivity Graph**: Auto-tracked; observers re-track on every run to maintain an accurate dependency set.
- **Batching**: Groups multiple writes; flush runs after the batch completes.

### Relation to TC39 Signals Proposal

- Aligned concepts:
  - Cells/signals with automatic dependency tracking on read, invalidation on write.
  - Observer-based recomputation and re-tracking; batching and untracked execution helpers.
- Notable differences from the current proposal draft:
  - Computeds are realized via a backing state signal and are re-evaluated on upstream notification (eager push), whereas the proposal emphasizes pull-evaluation on demand.
  - Effects here are regular observers that run user code and may read signals during execution; the proposal’s low-level `Watcher.notify` is synchronous and not permitted to read or write signals.
  - No subtle namespace or formalized `versioned`/`dirty` semantics; a simple `version` counter is maintained per signal but is not exposed.
  - Scheduler flush is synchronous and inline (microtask-like semantics are not modeled explicitly).
  - No built-in cleanup/teardown API for effects beyond `dispose()`; no error handling or cancellation API.

See the TC39 draft for the intended semantics and motivations: `https://github.com/tc39/proposal-signals`.

### API Summary

- `Signal.make : 'a -> Core.t<'a>`
- `Signal.get : Core.t<'a> -> 'a`
- `Signal.peek : Core.t<'a> -> 'a`
- `Signal.set : (Core.t<'a>, 'a) -> unit`
- `Signal.update : (Core.t<'a>, 'a -> 'a) -> unit`
- `Computed.make : (unit -> 'a) -> Core.t<'a>`
- `Effect.run : (unit -> unit) -> { dispose: unit -> unit }`
- `Core.batch : (unit -> 'a) -> 'a`
- `Core.untrack : (unit -> 'a) -> 'a`

Rendering helpers (selected):

- `Component.text : string -> node`
- `Component.textSignal : Core.t<string> -> node`
- `Component.signalFragment : Core.t<array<node>> -> node`
- `Component.list : (Core.t<array<'a>>, 'a -> node) -> node`
- `Component.element : (~attrs=?, ~events=?, ~children=?, unit) -> node` and tag helpers.
- `Component.mount : (node, Dom.element) -> unit`
- `Component.mountById : (node, string) -> unit`

### Known Limitations and Future Work

- Computed laziness differs from the proposal; to be considered pull-style recomputation.
- Microtask-based scheduling and consolidation of redundant recomputations.
- Effect cleanup hooks and error handling.
- Optional equality/comparator for `set` to avoid unnecessary notifications.
- More granular DOM updates for fragments and lists (diffing instead of replace-all).
- Remove redundancy from signal consumption when using computed within components.
