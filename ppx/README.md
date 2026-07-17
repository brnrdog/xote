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
| Bare child in node position (an `if`/`switch` selecting different nodes) | yes | wrapped in `View.tracked` — the one place a structural swap is unavoidable |

The result: reactivity lives at the leaves; `View.tracked` is emitted
**surgically**, only around a child region whose node *structure* actually
varies, and never around the stable elements that enclose it.

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
npm run verify          # jsdom runtime check (11 assertions)
```

## Known limitations (it's a prototype)

- **Signal detection is syntactic.** A read is recognised as
  `Signal.get(…)` / `X.Signal.get(…)`. An aliased or indirect read
  (`let g = Signal.get; g(sig)`) is not detected. `Signal.peek` is
  intentionally ignored (it is an untracked read).
- **Value-component set is hard-coded** to `View.Text/Int/Float/Bool`. Other
  components are treated as elements (children recursed as nodes).
- **`if`/`switch` in node position always falls back to `View.tracked`.** A
  smarter version could track only the condition and keep leaves inside each
  branch fine-grained; here the whole selected branch is re-rendered on change.
- **Not wired into the main build.** This lives outside `src/` and is not part
  of `npm run build`/`test`; it is a standalone proof of concept.
