# xote-tracked-ppx

A native ReScript PPX that expands an `@xote.component` annotation into a
props-deriving component whose returned JSX is decomposed into **fine-grained
reactive leaves** — the compile-time counterpart to the runtime
[`View.tracked`](../src/View.res) helper.

> **Status:** the recommended way to write components today — but the semantics
> are not frozen yet, and a few are still expected to change (see
> [Not settled yet](#not-settled-yet)). The npm package ships the PPX as a
> prebuilt binary per platform, selected at install time (see
> [Distribution](#distribution)), so enabling `@xote.component` is a single
> `ppx-flags` line with no toolchain requirement. The PPX is exercised in CI
> and used by the [docs site](../docs-website) itself. It grew out of the
> [`rescript-signals` #34](https://github.com/brnrdog/rescript-signals/pull/34)
> auto-tracking idea, targeting Xote's view layer *and* compiling away the
> wholesale-replacement tradeoff of `View.tracked`. See
> [`docs/proposals/tracked-blocks.md`](../docs/proposals/tracked-blocks.md) for
> the motivation and the alternatives that were rejected, and
> [RFC #141](https://github.com/brnrdog/xote/issues/141) for the decision to
> distribute prebuilt binaries and make this the primary model.

## What problem it solves

`View.tracked(() => <block>)` is convenient — every signal read inside the
block subscribes it automatically — but it lowers to a `SignalFragment` over a
`Computed`, so **any** dependency change re-evaluates the whole block and
replaces its children wholesale (no diffing; local DOM state like input focus
is lost). Good for small blocks, a footgun on large ones.

This PPX takes the same ergonomic surface — write plain JSX, read signals
inline — but instead of one coarse computed it **decomposes the block at
compile time**, pushing reactivity down to exactly the leaves that read
signals. The element structure is emitted once and never rebuilt.

## Example

Input — one annotation replaces `@jsx.component` and makes the return
fine-grained:

```rescript
@xote.component
let make = (~label: string) => {
  let count = Signal.make(0)
  <div class={Signal.get(count) > 0 ? "on" : "off"} id="card">
    <span class="static-label"> {label} </span>
    {Signal.get(count)}
  </div>
}
```

Compiles to (abbreviated):

```js
function make(props) {
  let label = props.label;                        // props derived (@jsx.component)
  let count = Signal.make(0);
  return Elements.jsxs("div", {
    id: "card",                                   // static — untouched
    class: () => Signal.get(count) > 0 ? "on" : "off", // → View.computedAttr (reactive leaf)
    children: [
      Elements.jsx("span", {                      // static subtree — untouched
        class: "static-label",
        children: View.child(label),              // static text (passthrough/coerce)
      }),
      View.child(() => Signal.get(count)),        // → reactive text node (leaf)
    ],
  });
}
```

Props derive from the labeled args (`label` stays static); no `View.tracked`,
no `SignalFragment`, no `<View.Int>` wrapper, no wholesale rebuild. The bare
`{Signal.get(count)}` child is coerced by `View.child` into a reactive text
leaf; the `<div>` and `<span>` keep their DOM identity across updates, and only
the `class` attribute and the number re-run. (`example/verify.mjs` asserts
exactly this by tagging the elements and checking the tags survive a signal
change.)

`@xote.component` is the single annotation. The PPX rewrites it to
`@jsx.component` (so the JSX transform still derives the props record) and
fine-grains the returned JSX — one attribute, no `@jsx.component` +
tracking-annotation stacking. Because it emits `@jsx.component`, it inherits its
rules: **one component per module** (each in its own file, or a submodule).

## Decomposition rules

Applied recursively to the component's returned JSX:

| Position | Reads a signal? | Result |
|---|---|---|
| Attribute value (`class={…}`) | yes | thunked → `View.computedAttr` (reactive attribute leaf) |
| Attribute value | no | left as-is (static attribute) |
| `attrs={…}` / `onClick={…}` and friends | — | left as-is: neither prop can hold a thunk, and an `attrs` entry carries its own reactivity — see [Hidden reads](#hidden-reads) |
| `<View.Text/Int/Float/Bool>` child | yes | thunked → reactive text node (leaf) |
| `<View.Text/…>` child | no | left as-is (static text) |
| Any value leaf | can't tell — the expression contains a call the PPX cannot resolve | wrapped in `View.probe`, which decides at runtime and reports a read it finds — see [Hidden reads](#hidden-reads) |
| Element / nested JSX | — | recurse into attributes and children |
| Fragment (`<>…</>`) | — | recurse into each child independently (so nested reactive regions stay separate — not collapsed into one thunk) |
| User-component prop (`<Card label={…}>`) | — | left untouched — see [User-component props](#user-component-props) |
| User-component render callback (`render={row => <li>…</li>}`) | — | the callback body is node position: decomposed like any other node, so bare children are coerced and leaves stay fine-grained |
| Bare child, control flow (`if`/`switch` selecting different nodes) | yes | branches decomposed fine-grained, then wrapped in `View.tracked` — see below. Signal reads in `when` guards count: they are evaluated with the scrutinee |
| Bare child, control flow | no | branches decomposed fine-grained, **no** `View.tracked` — a condition that cannot change needs no reactive scope, but its branches are still node position, so their bare children are coerced and their leaves stay fine-grained |
| Bare child, block expression (`{let x = …; <span/>}`) | — | recurse into the tail, threading `let`-bound aliases — the inner JSX keeps fine-grained leaves |
| Bare child, anything containing JSX (`{View.tracked(() => …)}`, `{View.fragment([<p/>])}`, `{xs->Array.map(x => <li/>)}`, `{try {<p/>} catch {…}}`) | — | the whole expression is walked: JSX inside it, and functions returning JSX, are node position and get decomposed; the result is then wrapped in `View.child` |
| Bare child, otherwise (`{Signal.get(x)}`, `{"lit"}`, `{someNode}`) | — | wrapped in `View.child` — see [Bare value children](#bare-value-children) |

The result: reactivity lives at the leaves; `View.tracked` is emitted
**surgically**, only around a child region whose node *structure* actually
varies, and never around the stable elements that enclose it.

### User-component props

Props of a **user component** land in that component's typed props record, so
the PPX never thunks them — `<Card label={Signal.get(name)} />` compiles as
written and is a deliberate **one-shot read** (the component function runs
once; a reactive-looking scalar prop cannot be reactive anyway). For a prop
that should react, pass the signal itself (`<Card count={count} />`) or a
thunk, and have the component read it.

One consequence is worth knowing, because it is the one place the "tracks only
the condition" rule below does not hold. A prop is evaluated where it is
*written*, before the component it belongs to is deferred — so a one-shot read
written inside a tracked branch happens inside that branch's scope and
subscribes it:

```rescript
{if Signal.get(open_) {
  <Card label={Signal.get(name)} />   /* `name` subscribes the branch too */
} else {
  View.null()
}}
```

Changing `name` re-runs the branch and rebuilds the `<Card>` — correct output,
but wholesale rather than fine-grained. Passing the signal (`<Card name={name}
/>`) and reading it inside the component keeps the branch subscribed to
`open_` alone; a read in the component's own body never widens anything,
because the body runs untracked.

The node-shaped exceptions are still decomposed:

- **children**;
- any prop whose value is **itself JSX** (`<Layout header={<span
  class={Signal.get(theme)} />} />` — the header's class stays a fine-grained
  reactive leaf);
- any prop whose value is a **function returning JSX** — a render callback such
  as `View.For`'s `render={row => <li> {row.author} </li>}`. Its body is node
  position once applied, so it is decomposed like any other node: bare children
  are coerced and reactive leaves inside stay fine-grained. Function props whose
  body is *not* JSX (`by={row => row.id}`, `onClick={…}`) are left alone.

Intrinsic elements (`<div>`, …) are different: their attributes accept thunks
at runtime, which is why *their* reactive attributes are thunked into
`computedAttr`s.

### Where the annotation reaches

`@xote.component` marks a *file* as written in the fine-grained style, not just
one binding. In a file containing at least one annotated component, JSX is
decomposed wherever it appears:

- the annotated component's returned markup, and everything nested in it;
- JSX bound to a name (`let row = <p> {"x"} </p>`), including JSX sitting inside
  a container the binding builds — `let rows = [<li/>, <li/>]`,
  `let header = Some(<h1/>)`, `let build = xs => Array.map(xs, x => <li/>)`;
- **plain helper functions that return markup**, at the top level or in a
  sibling module:

```rescript
/* no annotation needed: helpers that return markup are components in all but
   name, and are decomposed like inline JSX */
let filterButton = (label: string, value: filter, current: filter) =>
  <button
    class={value === current ? "active" : "idle"}
    onClick={_ => Signal.set(filter, value)}>
    {label}
  </button>
```

A file with **no** `@xote.component` anywhere is left completely untouched, so a
project that mixes `@jsx.component` code with explicit thunks keeps its current
semantics. That is the opt-in boundary: per file, by annotation.

### Bare value children

You don't need an explicit `<View.Int>`/`<View.Text>` value primitive under the
annotation — a **bare `{…}` child** in element position works directly:

```rescript
@xote.component
let make = () =>
  <div>
    {"Count: "}          // static text
    {Signal.get(count)}  // reactive text leaf
  </div>
```

Every bare non-control-flow child is wrapped in the runtime helper
[`View.child`](../src/View.res), which coerces at runtime:

- an eager signal read is thunked first, so it becomes a **reactive text** leaf;
- a static scalar (`{"lit"}`, `{42}`) becomes a **static text** node — previously
  a *compile error* (a scalar in node position), now it just works;
- a value that is **already a node** (`{View.text(x)}`, a component call)
  passes through untouched (detected by its runtime tag);
- a bare **signal** (`{count}` where `count: Signal.t<_>`) becomes reactive
  text — signals are detected positively by their runtime shape, so an
  arbitrary record is never mistaken for one;
- an **array** is coerced element-wise into a fragment (an array of nodes
  renders each node; an array of scalars renders their text);
- `null`/`undefined` render nothing;
- any **other object** (a record, a dict) cannot be rendered as a node: it is
  stringified with a console warning pointing at the value (development only —
  see [Hidden reads](#hidden-reads) for the flag that gates it).

This also covers control flow whose **branches are scalars** — the `switch` is
still tracked for the structural swap, but each scalar branch is coerced by
`View.child`, so `| Loading => "…"` no longer needs a value primitive either.

The explicit `View.Text/Int/Float/Bool` primitives remain available (they are
what non-PPX code uses, and give stronger `int`/`float` typing on the child);
`View.child` is just the zero-ceremony default under `@xote.component`.

### Control flow tracks only the condition

When a branch body is decomposed *before* the `View.tracked` wrapper is applied,
its leaves become thunks. So when the tracked scope runs the chosen branch to
build its nodes, those thunks are not invoked — the scope ends up subscribed to
only the **condition/scrutinee**, not to signals read by leaves inside the
branches. Given:

```rescript
@xote.component
let make = () =>
  <div>
    {switch Signal.get(status) {
    | Loading => <span> {View.text("Loading...")} </span>
    | Ready(msg) => <strong class={Signal.get(theme)}> {View.text(msg)} </strong>
    }}
  </div>
```

the `class={Signal.get(theme)}` becomes a `computedAttr` **inside** the
`View.tracked`. Changing `theme` updates just that class and leaves the
`<strong>` in place; only a change to `status` (the scrutinee) re-runs the
switch and rebuilds the branch. `example/verify.mjs` asserts both:
the `<strong>` keeps its identity across a `theme` change, and a `status`
change still swaps the branch.

A **component** rendered from a branch is a scope of its own: Xote runs a
component body untracked, so a read the PPX leaves as a one-shot read there —
`let label = Signal.get(count)->Int.toString` — stays one-shot and does not
subscribe the branch. The exception is a *prop* written at the call site, which
is evaluated in the branch itself: see [User-component
props](#user-component-props).

## What counts as "reads a signal"

Detection is more than a literal `Signal.get`. An alias environment threaded
through the traversal (scoped: an alias is visible only *after* its binding, and
shadowing it with a non-alias removes it) recognises all of these:

| Form | Example | Detected via |
|---|---|---|
| Direct | `Signal.get(sig)` / `X.Signal.get(sig)` | literal match |
| Through the wrapper | `MaybeSignal.get(v)`, `Prop.get(v)` | same — reading a `MaybeSignal` subscribes exactly like `Signal.get` |
| Pipe | `sig->Signal.get` | desugars to `Signal.get(sig)` before the PPX |
| Value alias | `let g = Signal.get` … `g(sig)` | binding tracked in scope |
| Module alias | `module S = Signal` … `S.get(sig)` | binding tracked in scope |
| Open | `open Signal` … `get(sig)` | bare `get` under an open |
| Local reactive helper | `let cls = () => Signal.get(x) ? …` … `cls()` | function binding whose body eagerly reads a signal; its *call* counts |
| Same-file module helper | `module Store = { let count = s => Signal.get(s) }` … `Store.count(s)` | the module body is walked, and its reactive names qualified |

`Signal.peek` (and `MaybeSignal.peek`) is intentionally **not** a read — it is an
untracked read, so a value that only peeks stays static (verified by the
example's `PeekShadow` case, where a reactive helper rebound to a `peek`-based
function is dropped from the alias environment and its attribute is left as a
plain, once-evaluated string).

Only *eager* reads trigger a thunk. A read deferred inside a nested lambda — a
`() => …` you wrote yourself, a `Computed`, a `MaybeSignal.reactive(Computed.make(…))`,
or a helper that merely *returns* a thunk — is already reactive and left as-is.
Because of that, when detection can't see a read, the safe fix is always to wrap
the value in `() =>` yourself: it will not be double-wrapped.

### Hidden reads

Everything above is *syntactic*: the PPX follows a read only as far as it can
see the definition. One indirection it cannot follow is a call into **another
module** — `Store.waitingCount(store)`, or a local closure that ends in one:

```rescript
@xote.component
let make = (~store) =>
  <p class={Store.tone(store)}>       /* reads a signal — invisible to the ppx */
    {Store.waitingCount(store)}
  </p>
```

Nothing here says "signal", so nothing is thunked, and the leaf renders its
first value forever. That was the library's one genuinely silent failure — and
it is worse than a frozen leaf when the markup sits inside a `tracked` block or
a tracked branch: the hidden read is captured by *that* scope instead, quietly
widening it, so one unrelated update re-renders the whole region. A screen can
look like it works for exactly that reason while the screen next to it breaks.

The PPX still cannot resolve the call — but it can see that a call it cannot
resolve is *there*. An expression built only from constants, identifiers, field
accesses, lambdas, operators and Xote's own constructors provably calls nothing;
anything else might. Leaves in that second group are emitted wrapped in
[`View.probe`](../src/View.res), which settles the question at runtime: the first
time the leaf is evaluated it runs inside a throwaway computed, and what that
computed subscribed to gives the answer.

- **Nothing subscribed** — the leaf really is static. The computed is disposed
  and the value returned: `probe` was the identity function, and there is no
  warning. An unresolvable call is not evidence of a read, so a false positive
  is impossible.
- **Something subscribed** — the read was hidden. The value is read back
  *through* the computed, so an enclosing tracked block subscribes exactly as it
  did before (behaviour is unchanged), and a one-time warning naming the source
  location is logged:

```
[Xote] Queue.res:42:19: this value reads a signal through a call @xote.component
cannot see (a helper from another module, MaybeSignal.get, a read stored in a
data structure), so it compiled to a one-shot value that will never update — and
inside a tracked block it widens that block and re-renders it wholesale. Wrap it
in a thunk (`{() => ...}`) or inline the Signal.get.
```

The fix at the call site is the same escape hatch as always — make the read
deferred, and the PPX leaves your thunk alone:

```rescript
<p class={() => Store.tone(store)}>
  {() => Store.waitingCount(store)}
</p>
```

Untracked control flow is probed the same way, on its condition/scrutinee and
`when` guards: a read hidden there does not just freeze a value, it freezes the
whole branch.

Each site is probed **once** — the answer belongs to the source expression, not
to a particular render — so a probed leaf costs one throwaway computed the first
time it is evaluated and a plain call every time after, and the report appears
once however often the component renders. Probing is skipped altogether in
production builds: `globalThis.__XOTE_DEV__` decides when set, otherwise
`process.env.NODE_ENV` (which bundlers inline) does. With neither available the
probe stays on — a silently stale UI is worse than an allocation.

What is *not* probed, because it can never be a hidden scalar read: event
handlers and the `attrs` escape-hatch array, values containing JSX, and calls
into `View`/`Html`/`Signal`/`Computed`/`MaybeSignal` themselves.

Event handlers and `attrs` are not thunked either — neither prop can hold a
thunk (`attrs` is an `array<(string, 'a)>`, a handler a `Dom.event => unit`),
so both are left exactly as written. An `attrs` entry carries its own
reactivity, which the runtime reads on every update:

```rescript
attrs=[("data-theme", () => Signal.get(theme))]   /* reactive: a thunk */
attrs=[("data-theme", theme)]                      /* reactive: the signal */
attrs=[("data-theme", Signal.get(theme))]          /* one-shot, like any argument */
```

## How it works

Same mechanism as `rescript-tracked-ppx` in PR #34: ReScript 12 hands an
external PPX an OCaml **4.06** parsetree (marshal magic `Caml1999M022`).
`ast.ml` vendors those exact AST types (so `Marshal` round-trips) and `ppx.ml`
implements the `ppx <infile> <outfile>` protocol, and rewrites bindings carrying the
`xote.component` attribute (swapping in `jsx.component` and decomposing the
returned JSX).

The PPX runs **before** ReScript's JSX transform, so it sees JSX as
`Apply @[JSX]` nodes with attributes as labelled arguments — the ideal layer to
redistribute reactivity across attributes and children before they are lowered
into `XoteJSX` calls. Thunks are emitted as `Function$(fun () -> …)` with a
`res.arity` attribute (the uncurried-function encoding); the same encoding is
unwrapped to reach the component body inside `Function$(fun ~props -> …)`.

## License

The vendored AST modules in [`ast.ml`](./ast.ml) (`Location`, `Longident`,
`Asttypes`, `Parsetree`) are copied verbatim from the OCaml 4.06 compiler,
© 1996–2019 INRIA, distributed under **LGPL-2.1 with the OCaml linking
exception**; they keep their original copyright headers. The
`@xote.component` rewriter below them is the project's own code. The full third-party notice
and license text is in [`LICENSE.OCaml`](./LICENSE.OCaml), which ships in the
npm tarball alongside `ast.ml` and `ppx.ml`.

Keeping them in a separate file is deliberate: `ast.ml` stays a byte-for-byte
copy, so a future AST re-sync is a copy rather than a merge, and `ppx.ml` is
exactly the code this project maintains.

## Distribution

The npm package ships the PPX **prebuilt** for the common platforms, under
`ppx/bin/`:

| Platform | Binary |
|---|---|
| Linux x64 | `ppx-linux-x64.exe` |
| Linux arm64 | `ppx-linux-arm64.exe` |
| macOS x64 (Intel) | `ppx-darwin-x64.exe` |
| macOS arm64 (Apple Silicon) | `ppx-darwin-arm64.exe` |
| Windows x64 | `ppx-win32-x64.exe` |

The binaries are compiled in CI by
[`.github/workflows/ppx-binaries.yml`](../.github/workflows/ppx-binaries.yml)
and injected into the tarball by the release workflow. On install, Xote's
`postinstall` script ([`postinstall.js`](./postinstall.js)) copies the binary
matching `process.platform`-`process.arch` to `ppx/ppx` (`ppx/ppx.exe` on
Windows), which is the path consumers reference:

```json
{ "ppx-flags": ["xote/ppx/ppx"] }
```

That one line in your `rescript.json` is the whole setup — no OCaml toolchain
required. Two edge cases:

- **Install scripts disabled.** Some package managers skip dependency install
  scripts (pnpm does by default). Approve them for `xote`
  (`pnpm approve-builds`) or run `node node_modules/xote/ppx/postinstall.js`
  once. When nothing could be installed, the script leaves an executable stub
  at `ppx/ppx` so the failure reports itself at build time with that fix,
  instead of ReScript's `try_package_path: upward traversal did not find`,
  which names neither xote nor the remedy. (Not on Windows, where the path is
  `ppx.exe` and a shell stub would not execute.)
- **Unsupported platform.** If no prebuilt binary matches — or the matching
  one does not execute on the host (the install script smoke-runs it; the
  Linux prebuilts are glibc-linked, so musl systems like Alpine fall through
  here) — the script falls back to compiling `ppx.ml` from source when
  `ocamlopt` is on the `PATH`, and otherwise prints instructions without
  failing the install.

A `ppx-flags` entry is deliberately **not** in Xote's own published
`rescript.json`: a ReScript consumer recompiles a dependency's sources during
its own build and applies that dependency's `ppx-flags`, and Xote's `src/`
carries no `@xote.component` annotations, so listing the PPX there would make
every build depend on the binary for no benefit. The annotation applies to
*your* components, which is why the flag lives in *your* `rescript.json` —
exactly like the `jsx` configuration you already mirror.

## Build from source

```sh
sh build.sh   # produces ./ppx (needs ocamlopt; any recent OCaml, tested 4.14)
```

`build.sh` also accepts an output path relative to `ppx/`
(`sh build.sh bin/ppx-linux-x64.exe`), which is how the CI matrix produces
the prebuilt binaries.

## In this repo

The PPX is developed and exercised in-repo without touching the published
library config:

- **`npm run ppx:build`** / **`npm run ppx:test`** (repo root) build the binary
  and run both example suites: `verify.mjs` (jsdom, behaviour) and `golden.mjs`
  (assertions on the emitted JavaScript).
- The two suites cover different failure modes, and the second exists because
  the first cannot see the bug that has now shipped three times. `verify.mjs`
  proves leaves are fine-grained by mutating signals and checking elements keep
  their identity — but JSX the traversal never *visits* still compiles and still
  renders correct initial output, so a runtime test passes while the leaf is
  frozen (and gets no `View.probe` either, because probes are only emitted at
  visited sites). `golden.mjs` asserts on the emitted code, where that is
  visible. Every positive assertion there has a matching negative, since
  "reaches the leaf" and "rewrites indiscriminately" both satisfy a positive.
- **`ppx:test` runs `rescript clean` first, and needs to.** ReScript does not
  treat the ppx binary as a build input, so editing `ppx.ml` and re-running the
  suites without a clean silently re-tests the *previously* emitted JavaScript —
  green, and meaningless. Do not drop the clean to speed the loop up.
- **CI** (`.github/workflows/ci.yml`) installs `ocaml-nox`, builds the PPX, and
  runs `ppx:test` on every push/PR, so it can't silently rot.
- The **docs site** (`docs-website/`) is a real consumer: its own
  `rescript.json` carries the `ppx-flags`, its `res:build` builds the PPX first,
  and the Counter demo is authored with `@xote.component`. The published Xote
  library (`src/`, root `rescript.json`) stays PPX-free.

## Run the example

The example is a standalone mini-project. The whole flow is wrapped in a single
script — from the repo root:

```sh
npm run ppx:test        # setup + build ppx + compile Demo.res + jsdom verify
```

Or step by step from `example/`:

```sh
sh setup.sh             # link toolchain + Xote from the repo root (idempotent)
sh ../build.sh          # build the ppx
npx rescript clean      # required after a ppx change — see "In this repo" above
npm run build           # compile Demo.res / Golden.res through the ppx
npm run verify          # jsdom runtime check (every case above, asserted on real DOM)
npm run golden          # assertions on the emitted JavaScript (traversal reach)
```

## Not settled yet

These are decisions rather than defects, and each is one real codebase's worth
of experience away from possibly being made differently. They are listed
separately from the limitations below because they may change in a way that
requires edits to your components — worth knowing before the annotation is
load-bearing for you.

- **The opt-in is per file, but the annotation is per binding.** A file with at
  least one `@xote.component` has *all* its JSX decomposed, including plain
  helper functions (which is the point — see
  [Where the annotation reaches](#where-the-annotation-reaches)). The
  consequence is action at a distance: a byte-identical helper is reactive in
  one file and static in another, moving it between files silently changes its
  behaviour, and deleting the last annotation in a file silently de-reactivates
  every helper in it — or breaks the build, depending on whether those helpers
  happen to use bare children. An explicit file-level marker
  (`@@xote.fineGrained`) would put the opt-in where its effect is; that is the
  most likely change here.
- **`View.child` accepts anything.** Its signature is `'a => node`, so under the
  annotation a value that is neither a node nor a scalar type-checks in child
  position and fails at runtime instead:

  ```rescript
  {user}                 /* a record  -> renders "[object Object]" (+ dev warning) */
  {Signal.get(status)}   /* a variant -> renders "[object Object]" (+ dev warning) */
  ```

  Both are compile errors without the annotation. This is the same trade the
  untyped JSX element props already make, extended from attributes (where a
  wrong value renders a wrong string) to children (where it renders
  `[object Object]`). It buys the zero-ceremony bare child, which is a large
  part of the annotation's value, so the trade is deliberate — but a narrower
  accepted type is the other place this may move.
- **User-component props are never thunked.** A deliberate one-shot read today
  (see [User-component props](#user-component-props)). Defensible, but it is the
  rule people are most likely to trip over — and inside a tracked branch such a
  read subscribes that branch, so the branch rebuilds wholesale on a change the
  annotation otherwise keeps fine-grained. Emitting `Signal.untrack(() => …)`
  around it would make the one-shot read one-shot in every position; it would
  also stop an explicit `View.tracked` block from seeing a read written in its
  own body, which is that helper's documented contract. That trade is the open
  question here.

## Known limitations

- **Signal detection is syntactic** (though alias- and helper-aware — see the
  table above). It follows `let`/`module`/`open` aliases, local reactive helpers
  and same-file module helpers, but not indirection it cannot see the definition
  of: a signal read behind an **imported / cross-module** helper, or reached
  through a data structure, is not detected, and such a value still compiles to a
  **static, once-evaluated attribute/text**. It is no longer *silent*:
  [`View.probe`](#hidden-reads) reports it at runtime, once, with its source
  location. The escape hatch is unchanged — wrap it in `() =>` yourself and it
  becomes reactive (the eager check leaves your thunk alone, so it is never
  double-wrapped). An over-eager match only produces a harmless extra
  `computedAttr`.
- **The probe reports, it does not repair.** It cannot: by the time the value
  exists, the leaf has already been emitted as a static one. It also only fires
  on the *first* evaluation of a site, and only for a *scalar* result — the shape
  that silently renders a stale number or class name. A hidden read behind a
  branch you never render in development is not reported, and neither is one
  that a leaf only performs on a later evaluation.
- **Hoisting a read into a `let` makes it a one-shot read.** Reactivity follows
  the *expression in JSX position*: `<div> {Signal.get(count)} </div>` is a
  reactive leaf, but

  ```rescript
  let label = Signal.get(count)->Int.toString
  <div> {label} </div>
  ```

  reads `count` once, at component setup, and renders a static value — the
  binding is an ordinary eager evaluation, exactly as it would be in any
  signals library without a compiler. When extracting a reactive expression
  into a binding, bind a *thunk* instead: `let label = () =>
  Signal.get(count)->Int.toString` and use `{label()}` (a tracked reactive
  helper) or `{label}` (coerced by `View.child`).
- **Value-component detection is hard-coded** to the qualified
  `View.Text/Int/Float/Bool`. An aliased or opened `View` (`module V = View` →
  `<V.Text>`, `open View` → bare `<Text>`) is not recognized as a value
  component. This is **not silent** — the value child lands in node position and
  is a **compile error** (`string` where `View.node` is expected), so it fails
  loudly at build time. Simplest fix: drop the wrapper and use a **bare `{…}`
  child** (`View.child` coerces it), or use the qualified `View.Text` form.
- **Coupled to ReScript's ppx ABI.** The vendored OCaml 4.06 parsetree, the
  `Caml1999M022` marshal magic, and the uncurried `Function$` construct name are
  compiler internals. A ReScript release that bumps the ppx AST version makes
  the ppx **fail the build immediately** with an error naming the mismatched
  magic (interface ASTs still pass through untouched); a release that renamed
  `Function$` could fail *quietly*. Validated against ReScript 12; CI building
  the docs site through the PPX is the early warning on upgrade.
- **A branch swap still rebuilds that branch's subtree.** Control flow tracks
  only the condition (leaves inside branches stay fine-grained, see above), but
  when the condition *does* change, the selected branch is built fresh — there
  is no keyed diffing between the old and new branch. This matches Xote's own
  `View.Show`/`View.tracked`; use `View.For` with `by` for lists.
- **Separate from the library build.** The PPX is never needed to build or use
  Xote itself (`npm run build`/`npm run test` don't involve it). It is compiled
  per platform in CI, shipped prebuilt in the npm tarball, and exercised
  end-to-end by `npm run ppx:test` on every push.
