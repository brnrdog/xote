# Troubleshooting

## The view renders once and never updates

By far the most common report. Work down this list.

1. **Was the value read eagerly?** Reactivity follows the expression written in
   JSX position. A read hoisted into a `let`, or hidden behind a call into
   another module, is a one-shot read. Wrap it: `{() => …}`.
2. **Is it a user-component prop?** `<Card label={Signal.get(name)} />` is a
   deliberate one-shot read. Pass the signal or a `MaybeSignal` and read it
   inside the component.
3. **Is the file annotated?** `@xote.component` decomposes JSX for the whole
   file it appears in. A file with no annotation anywhere is compiled untouched,
   so inline reads there are one-shot and need explicit thunks.
4. **Is `ppx-flags` in `rescript.json`?** Without `["xote/ppx/ppx"]` the
   annotation is not applied at all — and an unknown attribute is silently
   ignored by the compiler, so nothing tells you.
5. **Did the compiler actually run?** Vite consumes `.res.mjs`. Run
   `npx rescript` and check the timestamp on the generated file.
6. **Check the browser console** for a `View.probe` warning naming a file and
   line — that is xote telling you a leaf reads a signal through a call it
   could not see.

## `[Xote] …: this value reads a signal through a call`

The runtime probe found that a leaf really did subscribe to something while the
PPX had compiled it as a static value. It is always a real defect and there are
no false positives. Wrap the expression at the reported location in `() => …`.

## A child renders as `[object Object]`

`View.child` is typed `'a => node`, so it accepts anything in child position and
coerces at runtime. A record, variant or dict has no text form. Render the
field you meant (`{user.name}`), or build a node.

## Effects

**`This has type: unit / Somewhere wanted: option<unit => unit>`** — an effect
body must return `Some(cleanup)` or `None`. Add `None` as the last expression.

**The effect never stops** — an effect created outside a component render has no
owner. Create it in a component body so unmount disposes it, or use
`Effect.runWithDisposer` and call the disposer yourself.

**The effect runs too often** — every observer re-tracks its dependencies on
every run, so a `Signal.get` you added for a value you only wanted to *read* now
drives the effect. Switch it to `Signal.peek` or wrap the block in
`Signal.untrack`.

## Lists

**Input focus / scroll position is lost on update** — something above the list
is a `View.tracked` block (or a PPX-generated one around an `if`/`switch`), and
tracked blocks replace children wholesale. Shrink the tracked region, or move
the conditional inside the row.

**Rows lose state, or all rows rebuild** — the list has no key. Add
`by={item => item.id}` to `<View.For>` (or use `View.eachWithKey`). An array
index is not a valid key.

**Reordering is slow** — expected. The keyed reconciler preserves identity but
does not compute a minimal move set, so a swap in a long list moves most of the
list. Updates and appends are cheap; if you reorder large lists constantly,
reshape the data instead.

## Attributes

**`data-*` styling never matches** — an attribute rendered as `""` is still
present, so `[data-open]` always matches. Use
`View.optionalComputedAttr(key, () => cond ? Some("") : None)` so the attribute
is removed.

**`aria-expanded` disappears when false** — it should not; ARIA attributes are
enumerated and render their literal `"false"`. If one is vanishing, the value
reaching it is `None`/`undefined` rather than the string `"false"`.

**The attribute renders `undefined`** — an untyped JSX value produced
`undefined`. That now removes the attribute rather than writing the string, so
seeing the literal text means the value was the *string* `"undefined"`.

**Two attributes with the same name** — cannot happen: `attrs` entries are
merged after typed props and override them, so the prop is dropped.

## Compiler errors

**`Unbound module View` / `Unbound module Signal`** — either `"xote"` is missing
from `dependencies` in `rescript.json`, or `-open Xote` is missing from
`compiler-flags`. Without the flag, qualify: `Xote.View`, `Xote.Signal`.

**JSX errors mentioning React** — `"jsx": {"version": 4, "module": "XoteJSX"}`
is missing.

**A scalar in child position fails to compile** — bare children need
`@xote.component`. Without it, use `<View.Text>`/`<View.Int>` or
`View.text(…)`.

**Deprecation warnings about `Prop`** — `Prop` is an alias of `MaybeSignal`.
Rename: `Prop.static` → `MaybeSignal.static`, `Prop.signal`/`Prop.reactive` →
`MaybeSignal.reactive`, `Prop.get` → `MaybeSignal.get`.

**A module exists in the source but will not import** — the public API is what
the `.resi` files declare. `Runtime*` modules are internal and there is no
catch-all `./src/*` export, so `import "xote/src/RuntimeDom.res.mjs"` does not
resolve.

## Router

**Routing functions do nothing** — `Router.init(())` was not called at the entry
point, or it ran after the first render.

**Crash on the server: `window is not defined`** — `Router.init` reads browser
APIs. Use `Router.initSSR(~pathname, ())` on the server.

**Links include the base path twice** — patterns and `to` values are relative to
`basePath`; xote adds and strips it. Never write it yourself.

## SSR and hydration

**State from one request appears in the next** — call `SSRState.clear()` between
renders. The registry is module-level.

**Hydration attaches to the wrong nodes** — server and client produced different
trees. Something non-deterministic (a timestamp, a random value, a `window`
read, a locale format) differs between them. Sync it through `SSRState` or defer
it into a client-only effect.

**Nothing is interactive after hydration** — the client bundle did not run, the
container id does not match the server's `rootId` (default `"root"`), or the two
sides built their state with different `SSRState` ids.
