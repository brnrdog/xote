# Proposal: Async values in the renderer

| | |
|---|---|
| **Status** | Implemented, not yet released. Needs rescript-signals 4.0, which is not published yet. Current behaviour is documented in `src/Async.resi` and [`AGENTS.md`](../../AGENTS.md), which are the sources of truth. |
| **Scope** | Step 3 of 3 toward async values in the reactive graph, Xote's side. Steps 1 and 2 are [`suspense-pending.md`](./suspense-pending.md) and [`derived-resources.md`](./derived-resources.md). The library side is `docs/superpowers/specs/2026-11-20-async-values-design.md` in brnrdog/rescript-signals. |

## Summary

rescript-signals 4 adds `Async.make(fetch)`, a computed over a promise whose
reads throw `Async.NotReady` until the first value, and makes computeds hold
failures as results. This step teaches the renderer what `NotReady` means:
**not yet**, never a failure.

| Where the value is read | What happens until it arrives |
|---|---|
| JSX child or attribute, `View.tracked`, `Show`, lists | Renders nothing there; renders the value once it arrives |
| `Computed` | Holds `NotReady`, recomputes when the value arrives |
| Under `View.Suspense` | The fallback shows, refs and `onMount` are held, `pending()` is `true` |
| `View.ErrorBoundary` | Lets it pass; a rejected fetch is a failure and goes to the boundary |
| A component body (`let x = Signal.get(value)`) | An error that says to read it elsewhere |
| A server render | No fetch; empty text, no attribute, no rows. Hydration fills them in |

## Design

### Effects wait, and a Suspense waits with them

Every reactive leaf and block in Xote is an `Effect.run`. rescript-signals 4
already keeps an effect whose run ends in `NotReady` waiting: it has
subscribed to the async value, and runs again when that settles. Xote only has
to stop treating the throw as a failure, and to make the nearest `Suspense`
wait meanwhile.

- `RuntimeContext.within` rethrows `NotReady` to the scheduler instead of
  calling `fail`, so no error boundary claims it. `renderBoundary` lets it pass
  too.
- `Effect.runWithDisposer` captures the nearest suspense at creation. A run
  that ends in `NotReady` opens a wait on it (`suspendOn`) and an `inFlight`
  share (`flightOn`), so the fallback shows and `pending()` is `true`. The next
  run that gets past it — succeeding, or failing for real — ends both, and so
  does disposal.

This is read-based suspension: the suspense waits for what is *read* below
it, wherever the value was created, where a `Resource` suspends the boundary
of the component that *created* it.

### Component bodies

A body runs once and untracked, so an eager read of a value not ready yet
would leave the component waiting on something it never subscribed to. That
read is turned into a descriptive error. The alternatives were worse:

- **Re-run the body when the value arrives.** Needs the body to run tracked to
  learn what it read, which is exactly what Xote's untracked bodies exist to
  avoid; and everything the failed attempt created (effects, resources) would
  have to be torn down and made again.
- **Leave it.** The component would render nothing, forever, with no message.

With `@xote.component`, `{Signal.get(user).name}` in JSX is already a reactive
leaf, so the common case needs no change. Only a value hoisted into a `let`
hits the error, the same reads that are one-shot for any signal.

### Reading once before the effect

A few renderers read a leaf once, untracked, before its effect takes over:
`RuntimeRender` and `RuntimeTemplate` text leaves, a keyed list's initial
items, `Hydration`, and every `SSR` read. They go through `RuntimeNode.peekOr`,
`peekText` and `peekAttr`, which treat `NotReady` as "nothing yet".

### Server rendering and hydration

`Xote.Async.make` returns a computed that is never ready during a server
render and starts no fetch, as `Resource.make` does. The server renders empty
text between the hydration markers, which surfaced an older bug: the browser
makes no text node for empty text, so hydration took the end marker for the
text node and lost every later write. Hydration now makes a text node there.
The fix applies to any reactive text that was empty on the server.

## Considered and rejected

- **Holding the suspense once per value, like `Resource`.** An effect waits
  each time the value is missing — first load, or a fetch again after a
  failure — because it cannot tell the two apart, and an empty view behind a
  visible boundary is the worse failure.
- **Making `NotReady` count as `Resource.Pending` everywhere.** The two models
  stay separate: `Resource` for loading and failure as values a view matches
  on, `Async` for reads that wait.

## Open questions

1. **Transitions.** A dependency change refetches an async value and keeps the
   old value readable, so the rest of the page updates at once while that part
   lags behind. Holding the whole update until the fetch settles needs the
   scheduler to batch on async work. **Recommendation: wait for a case**; the
   synchronous scheduler is a property worth keeping.
2. **A body read that waits.** If eager body reads of async values turn out to
   be common, the retry design above becomes worth its cost.
   **Recommendation: wait**, and watch for the error in practice.
