---
name: xote
description: Build user interfaces with xote, the fine-grained reactive UI library for ReScript. Use this whenever you write, edit or debug ReScript that touches Xote modules (View, Html, Signal, Computed, Effect, MaybeSignal, Router, Route, SSR, SSRState, Hydration), whenever a file carries `@xote.component` or uses the XoteJSX transform, and whenever someone asks to add xote to a project, build a component, page, route, list or form with it, wire up SSR and hydration, or work out why a view renders once and never updates again. Xote's update model is not React's, and the difference is invisible to the compiler — load this before writing xote code, including small edits.
---

# Building with xote

Xote renders **once** and then mutates the exact DOM nodes that depend on a
signal. There is no virtual DOM, no diff, and no re-render of a component. A
component function is a *builder*: it runs one time, returns a node tree, and
everything reactive about that tree is a closure captured at build time.

Almost every xote bug is the same bug: a value was read **eagerly** while
building, so a number got baked into the DOM instead of a subscription. It
compiles, it renders the right first frame, and it never changes again. The
rules below exist to keep that from happening.

## Orient before writing code

Three checks, every time — they decide which syntax is even legal in the file.

1. **Is the PPX enabled?** Read `rescript.json`. `"ppx-flags": ["xote/ppx/ppx"]`
   means `@xote.component` is available and is the style to write. Without it,
   use `@jsx.component` plus explicit thunks and `<View.Text>`/`<View.Int>`
   primitives — bare `{…}` children will not compile.
2. **Is JSX pointed at xote?** `"jsx": {"version": 4, "module": "XoteJSX"}`.
   Without it JSX resolves to React's transform and nothing works.
3. **What does the file already do?** Match it. A file that uses
   `Html.div(~children=[…], ())` is in the function-based style; a file with
   `@xote.component` is in the fine-grained style. Mixing inside one file is
   legal but reads badly.

If any of the three is missing and the task is "add xote" or "set this up",
read `references/setup.md` and do the setup first.

## The rule that catches everyone

**Reactivity follows the expression you literally wrote in JSX position.**

`@xote.component` decides what to make reactive by reading your source. It sees
`Signal.get`, `MaybeSignal.get`, aliases of them, and helpers defined in the
same file. It cannot see through a call into another module, and it cannot
follow a read you hoisted into a `let`.

```rescript
@xote.component
let make = () => {
  let label = Signal.get(count)->Int.toString   /* read happens HERE, once */
  <div>
    {label}                       /* ✗ frozen: renders the first value forever */
    {Store.waitingCount(store)}   /* ✗ frozen: read hidden behind another module */
    {Signal.get(count)}           /* ✓ reactive leaf */
    {() => Store.waitingCount(store)}  /* ✓ thunk restores reactivity */
  </div>
}
```

The fix is always the same: **wrap it in `() => …`**. The PPX never
double-wraps a thunk you wrote yourself, so adding one is safe even when you
are not sure it is needed.

You do not have to catch these by eye. A leaf whose expression contains a call
the PPX cannot resolve is compiled inside `View.probe`, which checks at runtime
whether evaluating it actually subscribed to a signal and logs the source
location once, in development only:

```
[Xote] Queue.res:42:19: this value reads a signal through a call
@xote.component cannot see … Wrap it in a thunk (`{() => ...}`).
```

Treat that warning as a defect. There are no false positives — it reports what
the evaluation really read, not what it looks like.

## Where a value may be read

| Position | Reactive? | Notes |
|---|---|---|
| Attribute on a built-in element | yes, automatically | `class={Signal.get(theme)}` becomes a leaf that rewrites only that attribute |
| Bare `{…}` child under `@xote.component` | yes, automatically | scalar → text, node → passes through, array → fragment, `None` → nothing |
| `if`/`switch` in child position | tracks the **condition only** | wrapped in `View.tracked`; leaves inside the branches stay fine-grained |
| Prop of a **user component** | **no** — deliberate one-shot read | pass the signal itself, or a `MaybeSignal.t`, and read it inside the component |
| Component body | runs once, untracked | a read here is a starting value, not a subscription |
| `onClick` and other handlers | untracked, on every call | read with `Signal.peek` unless you want a dependency |

The user-component row is the one that surprises people:

```rescript
<Card label={Signal.get(name)} />        /* ✗ one-shot: Card never sees a change */
<Card name={name} />                     /* ✓ pass the signal, read it inside */
<Badge tone={MaybeSignal.reactive(t)} /> /* ✓ for a typed MaybeSignal prop */
```

## Choosing a construct

Reach for the smallest reactive scope that does the job — a leaf beats a
tracked block, and a tracked block beats rebuilding a list.

| You want | Use | Why not the other thing |
|---|---|---|
| Text that changes | a bare `{Signal.get(x)}` child, or `View.signalText(() => …)` | nothing coarser is needed |
| An attribute that changes | pass the read straight to the attribute, or `View.computedAttr` | — |
| An attribute that must **disappear** | `View.optionalComputedAttr(key, () => cond ? Some("") : None)` | `[data-open]` styling never matches an always-present attribute |
| Show / hide a subtree | `<View.Show when_={MaybeSignal.reactive(flag)} fallback={…}>` | — |
| Branch on a value | `if`/`switch` in child position (PPX), else `View.tracked` | tracks the condition only |
| A list | `<View.For each={…} by={item => item.id} render={…} />` | without `by`, every item is rebuilt on any change |
| Derived value used in several places | `Computed.make(() => …)` | recomputing inline in each leaf is fine too, and cheaper to reason about |
| A side effect tied to the view | `Effect.run(() => {…; None})` inside a component body | it is then owned by the component and stops on unmount |

Details, signatures and worked examples live in the reference files.

## Read the reference for the area you are touching

Load only what the task needs — each file is self-contained.

| File | Read it when |
|---|---|
| `references/setup.md` | adding xote to a project, `rescript.json`, Vite, entry points, or the app will not build |
| `references/components.md` | writing components: `@xote.component`, props, `MaybeSignal`, children, the non-PPX style |
| `references/reactivity.md` | signals, computeds, effects, batching, ownership, disposal, memory leaks |
| `references/control-flow.md` | conditionals, lists, `View.For`/`Show`/`Maybe`/`Value`, `tracked`, keyed reconciliation |
| `references/attributes.md` | attributes, boolean and ARIA handling, `attrs` escape hatch, forms and inputs, SVG |
| `references/routing.md` | `Router.init`, routes, params, `Router.Link`, navigation, base paths |
| `references/ssr.md` | server rendering, hydration, `SSRState` and state transfer |
| `references/api.md` | the exact public surface — every module, value and signature |
| `references/troubleshooting.md` | a compiler error, or a view that renders once and stops |

Their examples assume `@xote.component` is enabled unless they say otherwise.
Without the PPX, every reactive value needs an explicit `() => …` and every
scalar child needs a `<View.Text>`/`<View.Int>` wrapper — `references/components.md`
shows the same component written both ways.

## Finish the job

1. **Compile.** `npx rescript` (or the project's `npm run res:build`). ReScript's
   type system catches a large share of mistakes, and an uncompiled change is an
   unverified change. Never edit a generated `.res.mjs` file — edit the `.res`.
2. **Check the console.** Xote logs `View.probe` warnings and child-coercion
   warnings in development. A clean first render with a warning in the console
   is a frozen leaf waiting to be reported as a bug.
3. **Re-read your own diff for eager reads.** Any `Signal.get` outside JSX
   position, any value passed as a user-component prop, any read behind a helper
   from another module. If the task was larger than a small edit, run the
   `xote-review` skill over the diff.

## Things that are always wrong

- Editing a `.res.mjs` file. It is compiler output.
- Expecting a component to re-run. It does not. Ever.
- `View.each` where item identity matters — it rebuilds every row. Use
  `eachWithKey` / `<View.For by=…>`.
- Reaching for a `Xote__`-prefixed or `Runtime*` module. The public API is what
  the `.resi` files declare, nothing else; `references/api.md` lists it.
- Using `Prop`. It is a deprecated alias of `MaybeSignal` and warns on use.
- Calling `Router.init()` on the server. Use `Router.initSSR(~pathname, ())`.
- Adding a `key` prop to JSX for list reconciliation — it is ignored. Keys come
  from `by` / `eachWithKey`.
