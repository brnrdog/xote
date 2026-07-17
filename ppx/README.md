# xote-tracked-ppx (prototype)

A native ReScript PPX that expands a `@tracked` annotation on a JSX block into
**fine-grained reactive leaves** — the compile-time counterpart to the runtime
[`View.tracked`](../src/View.res) helper.

> **Status:** prototype / proof of concept. It demonstrates that the
> [`rescript-signals` #34](https://github.com/brnrdog/rescript-signals/pull/34)
> `@tracked` annotation can target Xote's view layer *and* compile away the
> wholesale-replacement tradeoff of `View.tracked`. See
> [`docs/proposals/tracked-blocks.md`](../docs/proposals/tracked-blocks.md) for
> the full design context (this is "Phase 2, fine-grained variant").

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

Input:

```rescript
@tracked
<div class={Signal.get(active) ? "on" : "off"} id="card">
  <span class="static-label"> {View.text("Name:")} </span>
  <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text>
</div>
```

Compiles to (abbreviated):

```js
Elements.jsxs("div", {
  id: "card",                                   // static — untouched
  class: () => Signal.get(active) ? "on" : "off", // → View.computedAttr (reactive leaf)
  children: [
    Elements.jsx("span", {                      // static subtree — untouched
      class: "static-label",
      children: View.text("Name:"),
    }),
    jsx(View.Text.make, {
      children: () => `Hello, ` + Signal.get(name), // → reactive text node (leaf)
    }),
  ],
})
```

No `View.tracked`, no `SignalFragment`, no wholesale rebuild. The `<div>` and
`<span>` keep their DOM identity across updates; only the `class` attribute and
the greeting text node re-run. (`example/verify.mjs` asserts exactly this by
tagging the elements and checking the tags survive a signal change.)

## Decomposition rules

Applied recursively to the annotated JSX expression:

| Position | Reads a signal? | Result |
|---|---|---|
| Attribute value (`class={…}`) | yes | thunked → `View.computedAttr` (reactive attribute leaf) |
| Attribute value | no | left as-is (static attribute) |
| `<View.Text/Int/Float/Bool>` child | yes | thunked → reactive text node (leaf) |
| `<View.Text/…>` child | no | left as-is (static text) |
| Element / nested JSX | — | recurse into attributes and children |
| Bare child in node position (an `if`/`switch` selecting different nodes) | yes | branches decomposed fine-grained, then wrapped in `View.tracked` — see below |

The result: reactivity lives at the leaves; `View.tracked` is emitted
**surgically**, only around a child region whose node *structure* actually
varies, and never around the stable elements that enclose it.

### Control flow tracks only the condition

When a branch body is decomposed *before* the `View.tracked` wrapper is applied,
its leaves become thunks. So when the tracked scope runs the chosen branch to
build its nodes, those thunks are not invoked — the scope ends up subscribed to
only the **condition/scrutinee**, not to signals read by leaves inside the
branches. Given:

```rescript
@tracked
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

`Signal.peek` is intentionally **not** a read — it is an untracked read, so a
value that only peeks stays static (verified by the shadowing case, where an
alias rebound to a `peek`-based function is dropped and its attribute is left
as a plain string).

## How it works

Same mechanism as `rescript-tracked-ppx` in PR #34: ReScript 12 hands an
external PPX an OCaml **4.06** parsetree (marshal magic `Caml1999M022`).
`ppx.ml` vendors those exact AST types (so `Marshal` round-trips), implements
the `ppx <infile> <outfile>` protocol, and rewrites expressions carrying the
`tracked` attribute.

The PPX runs **before** ReScript's JSX transform, so it sees JSX as
`Apply @[JSX]` nodes with attributes as labelled arguments — the ideal layer to
redistribute reactivity across attributes and children before they are lowered
into `XoteJSX` calls. Thunks are emitted as `Function$(fun () -> …)` with a
`res.arity` attribute (the uncurried-function encoding), matching PR #34.

## Build

```sh
sh build.sh   # produces ./ppx (needs ocamlopt; any recent OCaml, tested 4.14)
```

Wire it into a project's `rescript.json`:

```json
{ "ppx-flags": ["xote-tracked-ppx/ppx"] }
```

## Run the example

The example is a standalone mini-project. From `example/`, link the toolchain
and Xote from the repo root, then build and verify:

```sh
cd example
mkdir -p node_modules
ln -sfn ../../.. node_modules/xote
ln -sfn ../.. node_modules/xote-tracked-ppx
ln -sfn ../../../node_modules/rescript node_modules/rescript
ln -sfn ../../../node_modules/@rescript node_modules/@rescript
ln -sfn ../../../node_modules/rescript-signals node_modules/rescript-signals
ln -sfn ../../../node_modules/jsdom node_modules/jsdom

sh ../build.sh          # build the ppx
npm run build           # compile Demo.res through the ppx
npm run verify          # jsdom runtime check (27 assertions)
```

## Known limitations (it's a prototype)

- **Signal detection is syntactic** (though alias-aware — see the table above).
  It follows `let`/`module`/`open` aliases of `Signal`/`Signal.get`, but not
  arbitrarily deep indirection: a signal read behind a helper function
  (`let read = () => Signal.get(x)` called elsewhere) or reached through a
  data structure is not seen. Scoping is approximate — aliases are tracked
  down the traversal but a few exotic shadowing patterns may be imprecise.
  A missed read is a silent bug (the leaf never updates); an over-eager match
  only produces a harmless extra `computedAttr`.
- **Value-component set is hard-coded** to `View.Text/Int/Float/Bool`. Other
  components are treated as elements (children recursed as nodes).
- **A branch swap still rebuilds that branch's subtree.** Control flow tracks
  only the condition (leaves inside branches stay fine-grained, see above), but
  when the condition *does* change, the selected branch is built fresh — there
  is no keyed diffing between the old and new branch. This matches Xote's own
  `View.Show`/`View.tracked`; use `View.For` with `by` for lists.
- **Not wired into the main build.** This lives outside `src/` and is not part
  of `npm run build`/`test`; it is a standalone proof of concept.
