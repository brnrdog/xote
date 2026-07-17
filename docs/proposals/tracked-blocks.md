# Proposal: Auto-tracked view blocks

| | |
|---|---|
| **Status** | Phase 1 implemented (`View.tracked`); Phase 2 prototyped (fine-grained PPX, see [`ppx/`](../../ppx/)); Phase 3 exploratory |
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

## Phase 2 — the `tracked` annotation (prototyped)

PR #34 ships `rescript-tracked-ppx`, which expands a `@tracked` attribute at
compile time (hardcoded to the React hook `SignalsReactAuto.useTracked`). Two
expansions are possible for Xote, and a prototype of the more ambitious one
lives in [`ppx/`](../../ppx/).

### 2a. Coarse expansion (`@tracked()` → `View.tracked`)

The mechanical option: expand the annotated block to a single
`View.tracked(() => <block>)`. Convenient, but it inherits `View.tracked`'s
wholesale-replacement semantics — any dependency change rebuilds the whole
block. This is what PR #34's PPX does for React, retargeted.

### 2b. Fine-grained expansion (prototyped in [`ppx/`](../../ppx/))

The better option, and the one implemented as a proof of concept: instead of
one coarse computed, **decompose the block** and push reactivity to the leaves
that actually read signals. Given:

```rescript
@tracked
<div class={Signal.get(active) ? "on" : "off"} id="card">
  <span class="static-label"> {View.text("Name:")} </span>
  <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text>
</div>
```

the PPX emits (abbreviated):

```js
Elements.jsxs("div", {
  id: "card",                                     // static — untouched
  class: () => Signal.get(active) ? "on" : "off", // → View.computedAttr (leaf)
  children: [
    Elements.jsx("span", { class: "static-label", children: View.text("Name:") }), // untouched
    jsx(View.Text.make, { children: () => `Hello, ` + Signal.get(name) }),          // reactive text leaf
  ],
})
```

No `View.tracked`, no `SignalFragment`, no rebuild — the `<div>` and `<span>`
keep DOM identity across updates; only the `class` attribute and the greeting
text node re-run. `View.tracked` is emitted **only** where node *structure*
varies (an `if`/`switch` in child position), never around the stable elements
that enclose it. The prototype's `example/verify.mjs` proves this at runtime by
tagging elements and asserting the tags survive signal changes (22 assertions,
all passing).

Signal detection is alias-aware: beyond a literal `Signal.get`, the PPX threads
a scoped alias environment that follows value aliases (`let g = Signal.get`),
module aliases (`module S = Signal`), `open Signal`, and the pipe form
(`sig->Signal.get`), while treating the untracked `Signal.peek` as a non-read.
Decomposition rules and limitations are documented in
[`ppx/README.md`](../../ppx/README.md). The PPX runs before ReScript's JSX
transform, so it sees JSX as `Apply @[JSX]` nodes with attributes as labelled
arguments — the ideal layer to redistribute reactivity before lowering.

Notes:

- Only the automatic form (`@tracked()` / bare `@tracked`) is useful in Xote.
  The explicit-deps form (`@tracked([a, b])`) exists in React to avoid
  re-render subscriptions, but inside fine-grained leaves every read
  auto-tracks — a dependency list adds nothing here.
- 2b is self-contained in Xote (its own vendored-AST PPX). 2a would instead
  reuse rescript-signals' PPX with a configurable expansion target;
  `View.tracked` is already the stable target for that path.

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
  tradeoff entirely. This is precisely what Phase 2b prototypes — see
  [`ppx/`](../../ppx/). It turned out to be tractable as a local expansion
  over the pre-JSX-transform AST rather than a full custom JSX transform,
  because Xote's runtime already accepts thunked attribute/child values and
  lowers them to fine-grained bindings.
- **A `<View.Tracked>` JSX component.** JSX children evaluate eagerly, so the
  component would need a `render: unit => node` thunk prop — no more ergonomic
  than calling `View.tracked` directly, and it would suggest the block is
  cheap to nest. Not worth the surface area.
- **Status quo.** Composing `Computed` + wrapper primitives covers every case
  `tracked` covers. The proposal is purely about ergonomics; nothing is
  removed or deprecated.
