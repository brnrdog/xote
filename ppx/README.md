# xote-tracked-ppx

A native ReScript PPX that expands an `@xote.component` annotation into a
props-deriving component whose returned JSX is decomposed into **fine-grained
reactive leaves** — the compile-time counterpart to the runtime
[`View.tracked`](../src/View.res) helper.

> **Status:** the standard authoring model. The npm package ships the PPX as a
> prebuilt binary per platform, selected at install time (see
> [Distribution](#distribution)), so enabling `@xote.component` is a single
> `ppx-flags` line with no toolchain requirement. The PPX is exercised in CI
> and used by the [docs site](../docs-website) itself. It grew out of the
> [`rescript-signals` #34](https://github.com/brnrdog/rescript-signals/pull/34)
> auto-tracking idea, targeting Xote's view layer *and* compiling away the
> wholesale-replacement tradeoff of `View.tracked`. See
> [`docs/proposals/tracked-blocks.md`](../docs/proposals/tracked-blocks.md) for
> the full design context, and
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
| `<View.Text/Int/Float/Bool>` child | yes | thunked → reactive text node (leaf) |
| `<View.Text/…>` child | no | left as-is (static text) |
| Element / nested JSX | — | recurse into attributes and children |
| Fragment (`<>…</>`) | — | recurse into each child independently (so nested reactive regions stay separate — not collapsed into one thunk) |
| Bare child, control flow (`if`/`switch` selecting different nodes) | yes | branches decomposed fine-grained, then wrapped in `View.tracked` — see below |
| Bare child, otherwise (`{Signal.get(x)}`, `{"lit"}`, `{someNode}`) | — | wrapped in `View.child` — see [Bare value children](#bare-value-children) |

The result: reactivity lives at the leaves; `View.tracked` is emitted
**surgically**, only around a child region whose node *structure* actually
varies, and never around the stable elements that enclose it.

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
- a value that is **already a node** (`{View.text(x)}`, a component call, a list)
  passes through untouched (detected by its runtime tag);
- `null`/`undefined` render nothing.

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

## What counts as "reads a signal"

Detection is more than a literal `Signal.get`. An alias environment threaded
through the traversal (scoped: an alias is visible only *after* its binding, and
shadowing it with a non-alias removes it) recognises all of these:

| Form | Example | Detected via |
|---|---|---|
| Direct | `Signal.get(sig)` / `X.Signal.get(sig)` | literal match |
| Pipe | `sig->Signal.get` | desugars to `Signal.get(sig)` before the PPX |
| Value alias | `let g = Signal.get` … `g(sig)` | binding tracked in scope |
| Module alias | `module S = Signal` … `S.get(sig)` | binding tracked in scope |
| Open | `open Signal` … `get(sig)` | bare `get` under an open |
| Local reactive helper | `let cls = () => Signal.get(x) ? …` … `cls()` | function binding whose body eagerly reads a signal; its *call* counts |

`Signal.peek` is intentionally **not** a read — it is an untracked read, so a
value that only peeks stays static (verified by the shadowing case, where an
alias rebound to a `peek`-based function is dropped and its attribute is left
as a plain string).

Only *eager* reads trigger a thunk. A read deferred inside a nested lambda — a
`() => …` you wrote yourself, a `Computed`, a `Prop.reactive(Computed.make(…))`,
or a helper that merely *returns* a thunk — is already reactive and left as-is.
Because of that, when detection can't see a read (below), the safe fix is always
to wrap the value in `() =>` yourself: it will not be double-wrapped.

## How it works

Same mechanism as `rescript-tracked-ppx` in PR #34: ReScript 12 hands an
external PPX an OCaml **4.06** parsetree (marshal magic `Caml1999M022`).
`ppx.ml` vendors those exact AST types (so `Marshal` round-trips), implements
the `ppx <infile> <outfile>` protocol, and rewrites bindings carrying the
`xote.component` attribute (swapping in `jsx.component` and decomposing the
returned JSX).

The PPX runs **before** ReScript's JSX transform, so it sees JSX as
`Apply @[JSX]` nodes with attributes as labelled arguments — the ideal layer to
redistribute reactivity across attributes and children before they are lowered
into `XoteJSX` calls. Thunks are emitted as `Function$(fun () -> …)` with a
`res.arity` attribute (the uncurried-function encoding); the same encoding is
unwrapped to reach the component body inside `Function$(fun ~props -> …)`.

## License

The vendored AST modules at the top of `ppx.ml` (`Location`, `Longident`,
`Asttypes`, `Parsetree`) are copied verbatim from the OCaml 4.06 compiler,
© 1996–2019 INRIA, distributed under **LGPL-2.1 with the OCaml linking
exception**; they keep their original copyright headers. The
`@xote.component` rewriter below them is the project's own code. The full third-party notice
and license text is in [`LICENSE.OCaml`](./LICENSE.OCaml), which ships in the
npm tarball alongside `ppx.ml`.

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
  once.
- **Unsupported platform.** If no prebuilt binary matches, the install script
  falls back to compiling `ppx.ml` from source when `ocamlopt` is on the
  `PATH`, and otherwise prints instructions without failing the install.

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
  and run the end-to-end example verification.
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
npm run build           # compile Demo.res through the ppx
npm run verify          # jsdom runtime check (71 assertions)
```

## Known limitations (it's a prototype)

- **Signal detection is syntactic** (though alias- and helper-aware — see the
  table above). It follows `let`/`module`/`open` aliases and *local* reactive
  helpers, but not indirection it cannot see the definition of: a signal read
  behind an **imported / cross-module** helper, or reached through a data
  structure, is not detected. Such a value compiles to a **static, once-evaluated
  attribute/text with no error** — the one genuinely silent failure. The escape
  hatch is reliable: wrap it in `() =>` yourself and it becomes reactive (the
  eager check leaves your thunk alone, so it is never double-wrapped). An
  over-eager match only produces a harmless extra `computedAttr`.
- **Value-component detection is hard-coded** to the qualified
  `View.Text/Int/Float/Bool`. An aliased or opened `View` (`module V = View` →
  `<V.Text>`, `open View` → bare `<Text>`) is not recognized as a value
  component. This is **not silent** — the value child lands in node position and
  is a **compile error** (`string` where `View.node` is expected), so it fails
  loudly at build time. Simplest fix: drop the wrapper and use a **bare `{…}`
  child** (`View.child` coerces it), or use the qualified `View.Text` form.
- **Coupled to ReScript's ppx ABI.** The vendored OCaml 4.06 parsetree, the
  `Caml1999M022` marshal magic, and the uncurried `Function$` construct name are
  compiler internals. A ReScript release that bumps the ppx AST version fails
  loudly (magic mismatch); one that renamed `Function$` could fail *quietly*.
  Validated against ReScript 12; CI building the docs site through the PPX is the
  canary on upgrade.
- **A branch swap still rebuilds that branch's subtree.** Control flow tracks
  only the condition (leaves inside branches stay fine-grained, see above), but
  when the condition *does* change, the selected branch is built fresh — there
  is no keyed diffing between the old and new branch. This matches Xote's own
  `View.Show`/`View.tracked`; use `View.For` with `by` for lists.
- **Not wired into the main build.** This lives outside `src/` and is not part
  of `npm run build`/`test`; it is a standalone proof of concept.
