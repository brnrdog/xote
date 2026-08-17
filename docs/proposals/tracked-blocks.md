# Proposal: Auto-tracked view blocks

| | |
|---|---|
| **Status** | Phases 1 and 2 shipped. This document is kept for the design record — the *why*, the rejected options, and the one phase still unbuilt. Current behaviour is documented in [`ppx/README.md`](../../ppx/README.md) and [`AGENTS.md`](../../AGENTS.md), which are the sources of truth. |
| **Related** | [brnrdog/rescript-signals#34](https://github.com/brnrdog/rescript-signals/pull/34) — auto-tracking for React and the `@tracked` annotation; [RFC #141](https://github.com/brnrdog/xote/issues/141) — adoption and distribution decision |

## Summary

Bring the auto-tracking ergonomics that rescript-signals PR #34 gives React
consumers to Xote's own view layer, in three phases:

1. **`View.tracked`** — a runtime block constructor where every signal read
   inside the body subscribes the block automatically. *Shipped.*
2. **A component annotation** — compile-time expansion that pushes reactivity
   down to individual leaves instead of one coarse block. *Shipped as
   `@xote.component`; see [`ppx/README.md`](../../ppx/README.md).*
3. **Notify-only scheduling** — use the `Signals.Tracking` scope to decouple
   invalidation from DOM writes, enabling batched (microtask/`requestAnimationFrame`)
   update modes. *Exploratory, below.*

Phases 1 and 2 were described here while they were being designed. Now that
they are built, that description has been removed rather than maintained in
parallel: a second account of shipped behaviour goes stale silently, and this
one already had — it predated `MaybeSignal.get` detection, local reactive
helpers, bare `View.child` children, and the `View.probe` hidden-read report.

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
Before this work that took either an intermediate `Computed` to merge the
signals, or nested wrapper components:

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
hand-compiling the dependency graph. That is the tax both shipped phases exist
to remove.

## When to use what

The primitives are complementary, not replacements — this is the decision table
across all of them:

| Situation | Reach for |
|---|---|
| Reactive text/number | `View.Text` / `View.Int` / `signalText` |
| Reactive attribute | `computedAttr` / function props |
| Boolean branch on one signal | `View.Show` |
| Node derived from one signal | `View.Value` / `View.Maybe` |
| Lists | `View.For` with `by` (keyed reconciliation) |
| Block over **several signals + control flow** | `View.tracked` |
| A whole component, without any of the above ceremony | `@xote.component` |

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
  read becomes its own leaf binding, avoiding `View.tracked`'s
  wholesale-replacement tradeoff entirely. This is what Phase 2 became — see
  [`ppx/`](../../ppx/). It turned out to be tractable as a local expansion
  over the pre-JSX-transform AST rather than a full custom JSX transform,
  because Xote's runtime already accepts thunked attribute/child values and
  lowers them to fine-grained bindings.
- **Coarse expansion only** (`@tracked()` → one `View.tracked` around the
  block). The mechanical option, and what PR #34's PPX does for React. It
  inherits the wholesale-replacement semantics, so it is sugar rather than a
  fix; rejected once the fine-grained expansion proved tractable.
- **A `<View.Tracked>` JSX component.** JSX children evaluate eagerly, so the
  component would need a `render: unit => node` thunk prop — no more ergonomic
  than calling `View.tracked` directly, and it would suggest the block is
  cheap to nest. Not worth the surface area.
- **Status quo.** Composing `Computed` + wrapper primitives covers every case
  these phases cover. The work is purely about ergonomics; nothing is removed
  or deprecated.
