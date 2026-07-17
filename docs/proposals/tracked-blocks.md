# Proposal: Auto-tracked view blocks

| | |
|---|---|
| **Status** | Phase 1 implemented (`View.tracked`); Phase 2 proposed; Phase 3 exploratory |
| **Related** | [brnrdog/rescript-signals#34](https://github.com/brnrdog/rescript-signals/pull/34) — auto-tracking for React and the `@tracked` annotation |

## Summary

Bring the auto-tracking ergonomics that rescript-signals PR #34 gives React
consumers to Xote's own view layer, in three phases:

1. **`View.tracked` (implemented)** — a runtime block constructor where every
   signal read inside the body subscribes the block automatically.
2. **A `tracked` annotation (proposed)** — compile-time sugar that expands an
   annotated JSX expression into `View.tracked`, reusing the
   `rescript-tracked-ppx` from PR #34 with a configurable expansion target.
3. **Notify-only scheduling (exploratory)** — use the new `Signals.Tracking`
   scope to decouple invalidation from DOM writes, enabling batched
   (microtask/`requestAnimationFrame`) update modes.

## Motivation: the thunk tax

Xote's reactivity is fine-grained: components run once and reactivity attaches
at the leaves. That model is fast and predictable, but it puts a syntactic tax
on the author — every reactive read must be wrapped in a thunk or routed
through a wrapper component so a `Computed` can capture it:

```rescript
/* one thunk per binding */
View.signalText(() => "Hello, " ++ Signal.get(name))
View.computedAttr("class", () => Signal.get(isActive) ? "active" : "inactive")

/* one wrapper component per reactive branch */
<View.Show when_={Prop.signal(isReady)} fallback={...}> ... </View.Show>
<View.Value value={Prop.signal(count)} render={count => ...} />
```

Each primitive handles exactly one dependency shape. The friction shows up when
one block of UI depends on **several signals with control flow between them**.
Today that takes either an intermediate `Computed` to merge the signals, or
nested wrapper components:

```rescript
/* BEFORE — merge signals into a computed first… */
let greeting = Computed.make(() =>
  Signal.get(loggedIn) ? `Hello, ${Signal.get(name)}` : "Please log in"
)
<p> <View.Text> {greeting} </View.Text> </p>

/* …or nest wrappers */
<View.Show
  when_={Prop.signal(loggedIn)}
  fallback={<p> <View.Text> "Please log in" </View.Text> </p>}>
  <View.Value
    value={Prop.signal(name)}
    render={name => <p> <View.Text> {`Hello, ${name}`} </View.Text> </p>}
  />
</View.Show>
```

Both work, but neither reads like the logic it expresses. The author is
hand-compiling the dependency graph.

## Phase 1 — `View.tracked` (implemented)

```rescript
let tracked: (unit => View.node) => View.node
```

One thunk for the whole block; the reads inside are plain `Signal.get`:

```rescript
/* AFTER */
{View.tracked(() =>
  if Signal.get(loggedIn) {
    <p> <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text> </p>
  } else {
    <p> <View.Text> "Please log in" </View.Text> </p>
  }
)}
```

### Semantics

- **Auto-subscription.** Every signal read while the body runs subscribes the
  block; when any dependency changes, the body re-evaluates and the block's
  children are replaced.
- **Dependency re-discovery.** Dependencies are reconciled on every run, so
  conditional reads work: above, `name` is only tracked while `loggedIn` is
  true. Flipping `loggedIn` off also unsubscribes the block from `name`.
- **Lowering.** `tracked(body)` is `SignalFragment(Computed.make(() => [body()]))`.
  Because it lowers to existing node types, SSR emits the standard fragment
  hydration markers (`<!--#-->` … `<!--/#-->`) and hydration works unchanged.
- **Granularity tradeoff.** The block's children are replaced wholesale on
  update — no diffing, and local DOM state (input focus, scroll) inside the
  block does not survive. This is the same behavior as `SignalFragment` and
  the reactive branches of `Show`/`Maybe`/`Value`. Keep tracked blocks small;
  keyed lists stay on `eachWithKey`/`For` with `by`.

### When to use what

| Situation | Reach for |
|---|---|
| Reactive text/number | `View.Text` / `View.Int` / `signalText` |
| Reactive attribute | `computedAttr` / function props |
| Boolean branch on one signal | `View.Show` |
| Node derived from one signal | `View.Value` / `View.Maybe` |
| Lists | `View.For` with `by` (keyed reconciliation) |
| Block over **several signals + control flow** | `View.tracked` |

## Phase 2 — the `tracked` annotation (proposed)

PR #34 ships `rescript-tracked-ppx`, which expands a `@tracked` attribute at
compile time. It is currently hardcoded to the React hooks
(`SignalsReactAuto.useTracked`), but the expansion is mechanical — the same
PPX with a configurable target (e.g. a `--target` flag in `ppx-flags`) would
let Xote projects write:

```rescript
@tracked()
<div>
  <p> <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text> </p>
</div>
```

expanding to:

```rescript
View.tracked(() =>
  <div>
    <p> <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text> </p>
  </div>
)
```

Notes:

- Only the automatic form (`@tracked()`) is useful in Xote. The explicit-deps
  form (`@tracked([a, b])`) exists in React to avoid re-render subscriptions,
  but inside a `Computed` every read auto-tracks — a dependency list adds
  nothing here.
- This requires a change in rescript-signals (configurable expansion target),
  not in Xote. `View.tracked` is already the stable expansion target.

## Phase 3 — notify-only scheduling (exploratory)

Xote's scheduler is synchronous: effects run inline when a signal is set
(known limitation — no microtask/`requestAnimationFrame` coalescing). The
`Signals.Tracking` scope introduced in PR #34 is a *notify-only* observer:
the scheduler notifies it when a dependency changes but never re-runs it —
the driver re-establishes dependencies itself via `Tracking.track`.

That is exactly the primitive a deferred DOM-update mode needs: on
invalidate, mark the binding dirty and schedule a flush; on flush, re-track
and write to the DOM. This would let Xote offer opt-in rAF-batched rendering
without forking the effect scheduler. Out of scope for this proposal beyond
noting that adopting `Tracking` keeps the door open.

## Alternatives considered

- **Compiler-granular tracking (Solid-style).** Compile JSX so each inline
  read becomes its own leaf binding, avoiding the wholesale-replacement
  tradeoff entirely. Strictly better output, but requires a full JSX
  transform rather than a local attribute expansion — a much larger project
  than reusing the PR #34 PPX. `View.tracked` does not preclude it.
- **A `<View.Tracked>` JSX component.** JSX children evaluate eagerly, so the
  component would need a `render: unit => node` thunk prop — no more ergonomic
  than calling `View.tracked` directly, and it would suggest the block is
  cheap to nest. Not worth the surface area.
- **Status quo.** Composing `Computed` + wrapper primitives covers every case
  `tracked` covers. The proposal is purely about ergonomics; nothing is
  removed or deprecated.
