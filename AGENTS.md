# AGENTS.md

This is the primary reference for both AI coding agents and human contributors working on this repository. It covers the project architecture, module APIs, reactivity model, common patterns, and agent-specific workflow guidance.

> **Note:** `CLAUDE.md` exists only to point Claude Code here. This file (`AGENTS.md`) is the single source of truth — keep it up to date and avoid duplicating its content elsewhere.

## Project Overview

Xote is a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system. It uses [rescript-signals](https://brnrdog.github.io/rescript-signals) for reactive primitives and provides declarative components with JSX support, server-side rendering, and client-side hydration.

## Development Commands

### ReScript Compilation
- `npm run res:build` - Compile ReScript to JavaScript
- `npm run res:clean` - Clean compiled ReScript files
- `npm run res:dev` - Watch mode for ReScript compilation

### Build & Development
- `npm run dev` - Start Vite dev server
- `npm run build` - Build library with Vite (outputs to `dist/`)
- `npm run preview` - Preview production build

### Testing
- `npm run test` - Compile ReScript, run the zekr suites, then the two public API guardrails. Tests are built on the [zekr](https://www.npmjs.com/package/zekr) framework (see `tests/Tests.res`) and include snapshot fixtures under `tests/__snapshots__/`.
- `npm run test:exports` - Assert the JS export surface of each public module matches its snapshot.
- `npm run test:boundary` - Compile `tests/consumer` against a staged copy of the publishable package to check the public API boundary from outside.

### PPX (`@xote.component`)
- `npm run ppx:build` - Compile the native PPX binary from `ppx/ppx.ml` (needs `ocamlopt`)
- `npm run ppx:test` - Build the PPX and run the end-to-end example verification (`ppx/example/`, jsdom)

### Documentation
- `npm run docs:start` - Start documentation site
- `npm run docs:build` - Build documentation site
- `npm run docs:serve` - Serve built documentation site

Note: the docs site is a real PPX consumer — its `res:build` compiles the PPX first, so building `docs-website/` locally requires `ocamlopt` on the `PATH` (any recent OCaml; CI uses 4.14 via apt `ocaml-nox`).

### Build Artifacts
The build process generates:
- `dist/xote.mjs` - ES module
- `dist/xote.cjs` - CommonJS module
- `dist/xote.umd.js` - UMD bundle
- `dist/client.{mjs,cjs}` - client rendering entry
- `dist/router.{mjs,cjs}` - router and route utilities entry
- `dist/ssr.{mjs,cjs}` - SSR, SSR state, and SSR context entry
- `dist/hydration.{mjs,cjs}` - hydration entry
- `dist/mdx.{mjs,cjs}` - optional MDX integration entry

## Architecture

### Module Structure

The codebase uses ReScript's `namespace: true` setting in `rescript.json`, so every source file in `src/` is automatically scoped under the `Xote` namespace by the compiler. There is no manual `Xote__` prefix and no central `Xote.res` barrel — each module is an independent entry point, which lets bundlers tree-shake at module granularity.

JavaScript package entries are intentionally split by feature:
- `xote` and `xote/client` expose the client rendering core (`View`, `Html`, `XoteJSX`, `MaybeSignal`, the deprecated `Prop` alias, and signal shims).
- `xote/router` exposes the browser router plus `Route`.
- `xote/ssr` exposes `SSR`, `SSRState`, and `SSRContext`.
- `xote/hydration` exposes hydration only.
- `xote/mdx` exposes the optional MDX integration.

The root `xote` entry is client-focused and does not export router, SSR, hydration, or MDX. Direct source/module subpaths remain available where listed in `package.json`. There is no catch-all `./src/*` export: `package.json` names one `./src/<Module>.res.mjs` entry per public module, so `import "xote/src/RuntimeDom.res.mjs"` fails to resolve even though the ReScript module is reachable.

### Public API Boundary

**The public API is what the `.resi` interface files in `src/` declare. Nothing else.**

Fifteen modules are public: `View`, `Html`, `XoteJSX`, `MaybeSignal`, `Prop`, `Route`, `Router`, `SSR`, `SSRContext`, `SSRState`, `Hydration`, `Mdx`, `Signal`, `Computed`, `Effect`. All of them except `XoteJSX` ship a `.resi` that lists exactly the values, types and nested modules they export. A `.resi` narrows both the ReScript surface and the emitted JavaScript, so `dist/` stays clean too.

Everything else in `src/` is an internal `Runtime*` module. Public modules use them but never re-export them — no `module DOM = RuntimeDom` style aliases, because an alias inside a public module republishes the internal.

Three things are worth knowing:

- **`rescript.json`'s `sources.public` field has no effect in ReScript 12.** It is kept because it documents intent (and would start enforcing if upstream fixes it), but it is not the boundary. As a consequence the `Runtime*` modules stay reachable as `Xote.RuntimeDom`, `Xote.RuntimeOwner`, and so on. They are internal regardless, and the `Runtime` prefix is the signal.
- **`XoteJSX` has no `.resi`.** `Elements.props` carries around a hundred type parameters; restating it in an interface would cost far more than it buys. Its prop-conversion helpers are therefore still reachable.
- **`Obj.magic` defeats all of this**, as it defeats any ReScript abstraction. The boundary is a contract against accident, not against determination.

Two guardrails check the boundary instead of asserting it in prose:

| Command | What it checks |
|---|---|
| `npm run test:boundary` | Compiles `tests/consumer` against a staged copy of the publishable package. `allowed/` must compile, `deprecated/` must compile *with a warning*, every file in `forbidden/` must fail. `forbidden/` samples one probe per sealing mechanism rather than listing every internal. |
| `npm run test:exports` | Snapshots the `export { ... }` list of each public `src/*.res.mjs` against `tests/__snapshots__/public-exports.json`. |

Both run as part of `npm test` and in CI. Widening a `.resi` is an API change: expect `test:exports` to fail, and update the snapshot deliberately with `UPDATE_SNAPSHOTS=1 node tests/PublicExports_test.mjs`.

**Removing something reachable needs a deprecation cycle.** Mark it `@deprecated("... Removed in the next major release.")` in the `.resi`, add a probe under `tests/consumer/deprecated/`, and delete it in the next major. Values that were only ever reachable by accident — never named in `AGENTS.md`, `docs/`, or the docs site — can be sealed outright.

**Reactive Primitives (re-exported from rescript-signals):**
- **`Xote.Signal`**: Reactive state cells with `make`, `get`, `peek`, `set`, `update`, plus `batch` and `untrack` from the scheduler. `Signal.make` accepts optional `~name` (for debugging) and `~equals` (a custom `('a, 'a) => bool` comparator) parameters. The default equality is JavaScript `===` (reference/strict), not structural — pass `~equals` when you need deep comparison. `set` only notifies dependents when the new value differs from the current one, preventing unnecessary updates and accidental infinite loops.
- **`Xote.Computed`**: Derived signals that automatically recompute when dependencies change. `Computed.make` accepts optional `~name` (for debugging) and `~equals` (a custom `('a, 'a) => bool` comparator) parameters. As with `Signal.make`, the default equality is JavaScript `===` — pass `~equals` when downstream observers should ignore structurally-equal recomputations. **Lazy with push-based dirty flagging** — when upstream dependencies change, computeds are marked dirty immediately, but only recompute when read (via `Signal.get` or `Signal.peek`). **Disposal is manual**: `rescript-signals` 3.x does not drop a computed when its subscribers reach zero — a computed stays linked to its source signals until `Computed.dispose(signal)` unlinks it.
- **`Xote.Effect`**: Side effects that run when dependencies change. **Can return cleanup callbacks** — signature is `unit => option<unit => unit>`. Two entry points: `Effect.run` is fire-and-forget and returns `unit`; `Effect.runWithDisposer` returns a `disposer` with a `dispose()` method for manual teardown. Both accept an optional `~name` for debugging. An effect created while a component is rendering belongs to that component and is disposed when it unmounts; one created outside a render lives until its disposer is called.

These three are explicit re-export shims (`src/Signal.res`, `src/Computed.res`, `src/Effect.res`) over `rescript-signals` — deliberately not `include`, so a new helper upstream does not silently become Xote public API. `Signal.t<'a>` is **abstract**: it is the upstream signal record at runtime, but the type system hides the fields, so `signal.value = x` cannot bypass the scheduler.

**Xote Modules:**
- **`Xote.View`**: Core rendering primitives. Defines the virtual node types (`Element`, `Text`, `SignalText`, `Fragment`, `SignalFragment`, `Keyed`, `LazyComponent`, `KeyedList`) and exposes node constructors (`text`, `signalText`, `signalInt`, `signalFloat`, `int`, `float`, `bool`, `fragment`, `signalFragment`, `tracked`, `each`, `eachWithKey`, `element`), the JSX rendering components (`For`, `Show`, `Maybe`, `Value`, `Text`, `Int`, `Float`, `Bool`), attribute helpers (`attr`, `signalAttr`, `computedAttr`, `optionalAttr`, `optionalSignalAttr`, `optionalComputedAttr`, `Attr`), the `null`/`empty` placeholders, and `mount`/`mountById`. It also exposes the two helpers `@xote.component` emits: `child` (runtime coercion of a bare JSX child) and `probe` (hidden-read detection — see the PPX section below). Note that `child` is typed `'a => node`, so it **erases type checking in child position**: under the annotation a record or variant in `{…}` compiles and renders `"[object Object]"` with a development-only console warning (gated on the same `__XOTE_DEV__` / `NODE_ENV` flag as `probe`), where unannotated code would have failed to compile. That is the deliberate price of the zero-ceremony bare child. The renderer itself lives in the internal `RuntimeRender` module, the node types in `RuntimeNode`, and the owner-based cleanup system in `RuntimeOwner`.
- **`Xote.Html`**: Convenience constructors for common HTML tags (`div`, `span`, `button`, `input`, `h1`-`h3`, `p`, `ul`, `li`, `a`). Thin wrappers over `View.element`. For tags not listed, call `View.element(tag, ...)` directly or use JSX.
- **`Xote.XoteJSX`**: Generic JSX v4 implementation that enables JSX syntax for creating Xote components. Provides `jsx`, `jsxs`, `jsxKeyed`, `jsxsKeyed` functions and an `Elements` module for lowercase HTML tags with a broad set of supported attributes (standard, form/input, link, media, accessibility, drag-and-drop, and data attributes) plus an `attrs` escape hatch for anything else. Named `XoteJSX` (not `JSX`) to avoid colliding with unrelated modules when consumers use `open Xote`. Note: to defer side-effecting component evaluation out of any surrounding `Computed` context, `XoteJSX.jsx` wraps user-defined components in `View.LazyComponent`.
- **`Xote.MaybeSignal`**: Static-or-reactive value wrapper exposing the type `t<'a> = Reactive(Signal.t<'a>) | Static('a)` plus `static`, `reactive`, `computed` (derives a `Reactive` from a `unit => 'a`), `get` (tracked read), `peek` (untracked read), `isStatic`/`isReactive`, `map`, `toSignal`, and `ofUnknown`. Use it anywhere an API should accept either a plain value or a signal — JSX props are the most common case, not the only one. Notes on the trickier members:
  - `map` runs its function once immediately in both cases. For a `Reactive` value the result is backed by a `Computed`, which stays subscribed to the source until `Computed.dispose` is called on it, so prefer holding a mapped value over rebuilding it per update.
  - `toSignal` returns the source signal for `Reactive`, but lifts `Static` into a **fresh, detached** signal — each call allocates a new one and writing to the result does not reach the original. Treat that result as read-only.
  - `ofUnknown` normalizes an untyped value (raw / `Signal.t` / `unit => 'a` thunk / already-wrapped `t`) into a `t`. It is the single coercion behind every JSX surface that accepts untyped props, in both the ReScript and the hand-written JS runtime. It is unchecked by design — use `static`/`reactive`/`computed` in typed code.
  - The JS export for `static` is `$$static` (ReScript escapes the reserved word), which matters for consumers importing `xote/maybe-signal` from JavaScript.
- **`Xote.Prop`**: **Deprecated** alias of `Xote.MaybeSignal`, kept for backwards compatibility. `Prop.t` is a type alias of `MaybeSignal.t` (same constructors, same runtime representation), so values are interchangeable and migrating is a rename: `Prop.static` → `MaybeSignal.static`, `Prop.signal` and `Prop.reactive` → `MaybeSignal.reactive`, `Prop.get` → `MaybeSignal.get`. The deprecations live in `src/Prop.resi`: ReScript only reports warning 3 for values declared in an interface file, so `@deprecated` on the implementation's `let` bindings alone is silently ignored at call sites. `XoteJSX.Prop` and `Router.Link.Prop` re-export this module (not `MaybeSignal`), so those paths warn too.
- **`Xote.Router`**: Signal-based client-side router with pattern matching, dynamic routes, base path support, scroll position restoration, and a global singleton state (via `Symbol.for()`) that works across multiple bundles.
- **`Xote.Route`**: Route matching. `Route.match(pattern, pathname)` returns `Match(params)` or `NoMatch`. `parsePattern`, `matchPath`, `compile`, `matchCompiled` and `matchPathname` are `@deprecated` and go away in the next major.
- **`Xote.SSR`**: Server-side rendering to HTML strings with hydration markers (`<!--$-->`, `<!--#-->`, `<!--kl-->`, `<!--k:KEY-->`, `<!--lc-->`).
- **`Xote.SSRContext`**: Runtime environment detection (`isServer`, `isClient`) and helpers (`onServer`, `onClient`, `match`).
- **`Xote.SSRState`**: State serialization/restoration between server and client. Includes a `Codec` system for type-safe encoding/decoding and a `sync`/`signal` API for seamless server-client state transfer.
- **`Xote.Hydration`**: Client-side hydration that walks server-rendered DOM, attaches reactive effects, event listeners, and sets up keyed list reconciliation without re-rendering.

**Internal modules** (prefixed `Runtime`, no compatibility guarantee): `RuntimeNode` (the `node`/`attrValue` types and `resolveAttr`/`peekAttr`), `RuntimeRender` (DOM rendering and keyed reconciliation), `RuntimeDom`, `RuntimeOwner`, `RuntimeHtml`, `RuntimeAttr`, `RuntimeValue`, `RuntimeJsxProp`, `RuntimeHydrationMarkers`.

### Reactivity Model

All reactive behavior is provided by **rescript-signals**:

**Dependency Tracking**: When an observer (effect or computed) runs, any `Signal.get` calls during execution register the signal as a dependency. Dependencies are re-tracked on every observer run.

**Scheduling**: When `Signal.set` is called, all dependent observers are scheduled and run **synchronously**. The scheduler uses level-based ordering (each observer's level is derived from its computed dependency chain) so computeds flush before effects and downstream observers never see inconsistent intermediate state.

**Lazy Computeds with Push-based Dirty Flagging**: When dependencies change, computeds are marked dirty immediately (the dirty flag is pushed through the graph), but actual recomputation is deferred until the computed is read via `Signal.get` or `Signal.peek` (which calls `ensureComputedFresh`). A computed with no active readers will stay dirty and never recompute.

**Equality**: By default `Signal.set` uses JavaScript strict equality (`===`) to decide whether to notify subscribers, so reassigning a primitive to the same value is a no-op but a new object/array reference will always propagate. Pass `~equals=(a, b) => ...` to `Signal.make` for deep/structural comparison when you want identity-invariant updates.

**Batching**: `Signal.batch(fn)` defers scheduler flushing until `fn` returns, so a burst of `Signal.set` calls triggers each effect at most once. Batches can be nested and return a value. `Signal.untrack(fn)` disables dependency capture inside `fn`, which is the idiomatic way to read a signal without subscribing the current observer to it (there is also `Signal.peek(signal)` for a single untracked read).

**Owner System**: Components use an owner-based tracking system (the internal `RuntimeOwner` module) that stores effect disposers and computed references on DOM elements via the `__xote_owner__` property. Owners are disposed recursively when DOM elements are removed, preventing memory leaks. Three things register with the scope that is rendering: the effects the renderer creates for reactive text and attributes, the computeds the library allocates to back a node (`View.child`, `tracked`, `each`, `Show`/`Maybe`/`Value`, `signalText`), and any `Effect.run` a component body sets up. A signal or computed the consumer built is never disposed on their behalf.

**Component bodies are their own scope**: rendering happens inside the enclosing region's effect — every `SignalFragment` (a `tracked` block, `Show`, `For`, a ppx-emitted tracked branch) renders its children from one — so a component function is invoked untracked. An eager read in a body is the one-shot read it reads as, and does not subscribe the region that is rendering it; without that, one unrelated update would rebuild the whole region wholesale and take input focus and scroll position with it. Reads deferred into a thunk, a `Computed` or an `Effect` open their own scope and are unaffected, so a `tracked` block still subscribes to everything its own body reads.

### ReScript Configuration

- **Build system**: ReScript compiler v12+ with `esmodule` output format
- **Output**: In-source compilation (`.res.mjs` files alongside `.res` files)
- **Namespacing**: `namespace: true` in `rescript.json` automatically scopes every module under `Xote`. The public API is defined by the `.resi` interface files in `src/` — see [Public API Boundary](#public-api-boundary).
- **Dependencies**: `rescript-signals` ^3.1.0 (the only runtime dependency)
- **JSX**: ReScript JSX v4 configured with `module: "XoteJSX"` (generic JSX transform). Consumers must mirror this in their own `rescript.json`.

### Component System

Components are functions returning `node` types. The virtual node types are:
- `Text(string)` - Static text
- `SignalText(Signal.t<string>)` - Reactive text
- `Element({tag, attrs, events, children})` - HTML elements
- `Fragment(array<node>)` - Static grouping
- `SignalFragment(Signal.t<array<node>>)` - Reactive grouping (replaces children on change)
- `LazyComponent(unit => node)` - Deferred evaluation
- `KeyedList({signal, keyFn, renderItem})` - Efficient list reconciliation with key-based identity

Xote supports **two syntax styles**:

#### Function-based API (Component module)
1. **Static text nodes**: `text("hello")`
2. **Reactive text nodes**: `signalText(() => ...)` - accepts a function that computes the text value
3. **Type-specific helpers**: `signalText`, `signalInt`, `signalFloat` for reactive values; `int`, `float` for static values
4. **Unified attributes**: `attrs` parameter accepts static, signal, or computed values via helper functions:
   - `attr("key", "value")` - static string attribute
   - `signalAttr("key", signal)` - reactive attribute from a signal
   - `computedAttr("key", () => ...)` - reactive attribute from a computed function
   - `optionalAttr("key", option)`, `optionalSignalAttr("key", signal)`, `optionalComputedAttr("key", () => ...)` - the same three over `option<string>`, where `None` **removes** the attribute (see "Attribute & Property Handling")
5. **Lists**:
   - `each(signal, renderItem)` - simple reactive list (re-renders all items on change)
   - `eachWithKey(signal, keyFn, renderItem)` - efficient keyed list with DOM reconciliation (preserves element identity, only updates changed items)
6. **Event handlers**: `events` parameter for DOM event listeners
7. **Null node**: `View.null()` - renders an empty text node
8. **HTML element helpers**: `Html.div`, `Html.button`, `Html.p`, etc. live in the `Xote.Html` module — use them when writing the function-based API. For tags not covered, fall back to `View.element("tag", ...)`.
9. **Mounting**: `mount(node, container)` or `mountById(node, "element-id")` to attach to DOM

#### The `@xote.component` PPX (recommended; semantics not yet frozen)

`@xote.component` (implemented by the native PPX in `ppx/ppx.ml`, enabled by consumers via `"ppx-flags": ["xote/ppx/ppx"]`) is the recommended way to write components. Its semantics are **not frozen** — the per-file opt-in, `View.child`'s untyped child position, and never-thunking user-component props are all still open (see "Not settled yet" in `ppx/README.md`). It derives the props record exactly like `@jsx.component` (which it emits under the hood, so its one-component-per-module rule applies) **and** decomposes the returned JSX into fine-grained reactive leaves:

- an attribute or `<View.Text/Int/Float/Bool>` child that *eagerly* reads a signal is thunked, so only that leaf re-runs;
- a **bare `{…}` child** (scalar, signal read, array, node) is wrapped in `View.child`, which coerces it at runtime — no value-primitive ceremony;
- an `if`/`switch` in child position is wrapped in `View.tracked`, tracking only the condition/scrutinee (including reads in `when` guards); leaves inside branches stay fine-grained;
- values that are already reactive (a `() => …` thunk, a `Computed`, `Prop.reactive(…)`) are left alone — the annotation is a safe drop-in;
- **user-component props are never thunked**: `<Card label={Signal.get(x)} />` is a deliberate one-shot read; pass the signal itself for a reactive prop. Children and JSX-valued props of user components are still decomposed.

Detection covers `Signal.get` **and** `MaybeSignal.get`/`Prop.get`, and follows aliases (`let g = Signal.get`, `module S = Signal`, `open Signal`), local reactive helpers, and helpers in a module declared in the same file. It is still syntactic, so reads hidden behind an **imported** helper, or hoisted into a plain `let` binding (`let label = Signal.get(count)->Int.toString`), compile to static one-shot values; the escape hatch is to wrap the value in `() => …` yourself.

Those remaining cases are no longer silent. A value leaf whose expression contains a call the PPX cannot resolve is emitted wrapped in `View.probe`: on its **first** evaluation it runs inside a throwaway computed and, if that computed subscribed to anything, a warning naming the source location is logged (and the value is read back through the computed, so an enclosing `tracked` block's dependencies are unchanged). No dependencies means no warning and no behaviour change, so there are no false positives. Each site is probed once — later evaluations are a plain call — and probing is skipped entirely when `globalThis.__XOTE_DEV__` or `process.env.NODE_ENV` says production. Full rules and limitations: `ppx/README.md`. The npm package ships the PPX as prebuilt per-platform binaries selected by `ppx/postinstall.js`; Xote's own `src/` never uses the annotation.

#### JSX Syntax
Xote supports ReScript's generic JSX v4 for a declarative component syntax:

```rescript
let app = () => {
  <div class="container">
    <h1> {View.text("Hello JSX")} </h1>
    <button onClick={handleClick}>
      {View.text("Click me")}
    </button>
  </div>
}
```

**JSX features**:
- Lowercase tags (`<div>`, `<button>`, etc.) create HTML elements via the `XoteJSX.Elements` module
- Supported HTML attributes include:
  - Standard: `id`, `class`, `style`, `title`
  - Form/input: `type_`, `name`, `value`, `placeholder`, `disabled`, `checked`, `required`, `readOnly`, `maxLength`, `minLength`, `min`, `max`, `step`, `pattern`, `autoComplete`, `multiple`, `accept`, `rows`, `cols`, `autofocus`, `action`, `method`
  - Label: `for_`
  - Link/media: `href`, `target`, `src`, `alt`, `width`, `height`
  - Global: `draggable`, `hidden`, `contentEditable`, `spellcheck`
  - Accessibility: `role`, `tabIndex`, `ariaLabel`, `ariaHidden`, `ariaExpanded`, `ariaSelected`
  - Data: `data` (an `Obj.t`/`Dict.t` expanded into `data-*` attributes)
  - Escape hatch: `attrs` (see below) for anything without a typed prop
  - SVG root: `xmlns`, `xmlnsXlink`, `version`, `viewBox`, `preserveAspectRatio`
  - SVG geometry: `d`, `pathLength`, `cx`, `cy`, `r`, `rx`, `ry`, `x`, `y`, `x1`, `y1`, `x2`, `y2`, `fx`, `fy`, `dx`, `dy`, `points`, `transform`, `transformOrigin`
  - SVG presentation: `fill`, `fillOpacity`, `fillRule`, `stroke`, `strokeWidth`, `strokeLinecap`, `strokeLinejoin`, `strokeDasharray`, `strokeDashoffset`, `strokeOpacity`, `strokeMiterlimit`, `opacity`, `color`, `visibility`, `vectorEffect`, `pointerEvents`
  - SVG clipping/filter: `clipPath`, `clipRule`, `mask`, `filter`
  - SVG text: `textAnchor`, `dominantBaseline`, `fontFamily`, `fontSize`, `fontWeight`, `letterSpacing`, `wordSpacing`, `textDecoration`
  - SVG gradient/stop: `offset`, `stopColor`, `stopOpacity`, `gradientUnits`, `gradientTransform`, `spreadMethod`
  - SVG markers: `markerStart`, `markerMid`, `markerEnd`
  - SVG xlink (legacy): `xlinkHref`
- Props support raw values, `MaybeSignal.t<'a>` (`Static` / `Reactive`), raw `Signal.t<'a>`, or a computed `unit => 'a` function for flexible static/reactive handling. These element props are untyped by design (each is its own type variable, resolved at runtime by `MaybeSignal.ofUnknown`), so `class={42}` compiles and renders `class="42"` — the trade for not requiring a wrapper. Props with a declared type (`View.Show`, `View.For`, `View.Maybe`, `View.Value`, and user components) take a `MaybeSignal.t` and are checked normally
- Event handlers: `onClick`, `onInput`, `onChange`, `onSubmit`, `onFocus`, `onBlur`, `onKeyDown`, `onKeyUp`, `onMouseEnter`, `onMouseLeave`, `onMouseDown`, `onMouseMove`, `onMouseUp`, `onContextMenu`, plus drag-and-drop: `onDrag`, `onDragStart`, `onDragEnd`, `onDragOver`, `onDragEnter`, `onDragLeave`, `onDrop`
- Children are passed via JSX syntax and rendered as nodes
- Boolean attributes (`disabled`, `checked`, `required`, `readOnly`, `multiple`, `autofocus`, `draggable`, `hidden`, `contentEditable`, `spellcheck`) are added/removed based on the value rather than stringified. `ariaHidden`/`ariaExpanded`/`ariaSelected` are not: ARIA is enumerated, so they render `aria-expanded="false"` rather than dropping the attribute
- `attrs` is the escape hatch for attributes the typed props do not cover — `aria-controls`, `aria-labelledby`, `aria-valuenow`, presence-toggled state attributes, and anything else. Entries are `(key, value)` pairs merged **after** the typed props, so an entry overrides a prop with the same key (the prop is dropped, not rendered twice). A value accepts everything a typed attribute prop accepts (raw value, `Signal.t`, `unit => 'a` thunk, `MaybeSignal.t`, `None`) as well as a `View.attrValue` built with `View.attr`/`View.optionalComputedAttr`/… — which is also how one array mixes static and reactive entries, since the array's values share a single type. `Router.Link` takes the same `attrs` prop

### Router

Signal-based client-side router with:
- **Initialization**: `Router.init(~basePath="/optional-base", ())` - must be called at app entry
- **SSR initialization**: `Router.initSSR(~basePath?, ~pathname, ~search?, ~hash?, ())` - sets location without accessing browser APIs
- **Navigation**: `Router.push(pathname)`, `Router.replace(pathname)` with optional `~search` and `~hash`
- **Route matching**: `Router.route(pattern, params => node)` for single routes, `Router.routes(configs)` for first-match routing
- **Base path**: All routes are relative to the configured base path; browser URLs are automatically prefixed/stripped
- **Scroll restoration**: Saves/restores scroll position on back/forward navigation via `history.state`
- **Global singleton**: Uses `Symbol.for("xote.router.state")` on `globalThis` so all Xote bundles share router state
- **Link component**: `Router.link(~to, ~attrs, ~children, ())` for navigation without page reload
- **JSX Link**: `<Router.Link to="/path" class="nav-link">` for declarative navigation in JSX; takes the same `attrs` escape hatch as HTML elements (`attrs=[("aria-current", "page")]`)

### SSR & Hydration

Full server-side rendering with client-side hydration:

**Server-side (`SSR` module)**:
- `SSR.renderToString(component, ~options?)` - render component to HTML string
- `SSR.renderToStringWithRoot(component, ~rootId?, ~options?)` - with hydration root markers (`~rootId` defaults to `"root"`)
- `SSR.generateHydrationScript(~nonce?)` - generate `<script>` tag that sets `window.__XOTE_HYDRATED__`
- `SSR.renderDocument(~head?, ~bodyAttrs?, ~scripts?, ~styles?, ~stateScript?, ~nonce?, component)` - full HTML document
- Uses comment-based hydration markers to identify reactive boundaries
- `renderOptions` type: `{nonce?: string, renderId?: string}`

**State transfer (`SSRState` module)**:
- `SSRState.Codec` - type-safe serialization with built-in codecs for `int`, `float`, `string`, `bool`, `array`, `option`, `tuple2`, `tuple3`, `dict`; and `Codec.make(~encode, ~decode)` for custom codecs
- `SSRState.sync(id, signal, codec)` - register on server, restore on client
- `SSRState.signal(id, initial, codec)` - create and sync a signal in one call
- `SSRState.generateScript(~nonce?)` - generate `<script>` tag with serialized state
- Lower-level API: `SSRState.register(id, signal, codec)` (server), `SSRState.restore(id, signal, codec)` (client), `SSRState.clear()` (reset registry), `SSRState.getClientState()` (read `window.__XOTE_STATE__`)

**Environment detection (`SSRContext` module)**:
- `SSRContext.isServer` / `SSRContext.isClient` - runtime detection
- `SSRContext.onServer(fn)` / `SSRContext.onClient(fn)` - conditional execution
- `SSRContext.match(~server, ~client)` - environment branching

**Client-side (`Hydration` module)**:
- `Hydration.hydrate(component, container, ~options?)` - hydrate server-rendered DOM
- `Hydration.hydrateById(component, containerId, ~options?)` - hydrate by element ID
- `hydrateOptions` type: `{renderId?: string, onHydrated?: unit => unit}`
- Walks existing DOM, attaches effects/events without re-rendering
- Handles all node types including keyed lists and lazy components

### Attribute & Property Handling

The internal `RuntimeDom.setAttrOrProp` helper handles the distinction between HTML attributes and DOM properties:
- `value`, `checked`, `disabled` are set as DOM properties (not attributes)
- Boolean attributes (`checked`, `disabled`, `required`, `readonly`, `multiple`, `draggable`, `hidden`, `contenteditable`, `spellcheck`, `autofocus`) are added or removed based on whether the serialized value is `"true"`. ARIA attributes are deliberately **not** on that list — they are enumerated, so `aria-expanded`, `aria-selected`, and `aria-hidden` render their literal `"true"`/`"false"` value
- A **missing value removes the attribute**: `None` from an optional attribute, or a `null`/`undefined` coming out of an untyped JSX value, calls `removeAttribute` (or resets the property for `value`/`checked`/`disabled`) instead of writing the string `"undefined"`. This is what presence-based styling needs — `data-checked:bg-primary` compiles to `[data-checked]`, so an attribute that is always present, even as `""`, always matches
- All other attributes use `setAttribute`

`View.attrValue` therefore has six variants: `Static`/`SignalValue`/`Compute` over `string`, and `OptionalStatic`/`OptionalSignalValue`/`OptionalCompute` over `option<string>`. Consumers may match on them, but renderers do not — the internal `RuntimeNode.resolveAttr` reduces any of them to `ReadStatic(Nullable.t<string>)` (a value known up front) or `ReadReactive(unit => Nullable.t<string>)` (a read that must run inside an effect), and `RuntimeNode.peekAttr` returns the current value untracked for SSR. `RuntimeRender`, `Hydration` and `SSR` all go through those two, so a new variant only has to be handled once.

## Key Concepts for Development

1. **Unified attributes API**: All attributes use the single `attrs` parameter. Use helper functions `attr()`, `signalAttr()`, or `computedAttr()` to create attribute entries.

2. **Signal equality check**: `Signal.set` uses JavaScript strict equality (`===`) by default and only notifies dependents when the new value differs from the current one. This prevents accidental infinite loops and reduces unnecessary work. Pass `~equals` to `Signal.make` or `Computed.make` when you need a custom comparator (e.g. deep equality for records/arrays) — on a computed, `~equals` controls whether recomputed values propagate to downstream observers.

3. **Effect cleanup callbacks**: Effects can return `Some(cleanupFn)` to register cleanup that runs before re-execution and on disposal. Return `None` when no cleanup is needed. Signature is `unit => option<unit => unit>`.

4. **Computed disposal**: `Computed.make` returns a `Signal.t<'a>` directly, already subscribed to whatever it read during its initial computation. There is no automatic disposal for a computed *you* create — call `Computed.dispose(signal)` to unlink one you no longer need, including one created in a component body. The computeds the library allocates to back a node are a different matter: they are marked as its own and released when that node is removed, so a block that rebuilds does not leave a leaf computed linked to its sources on every pass.

5. **Untracked reads**: Use `Signal.peek(signal)` for a single untracked read, or `Signal.untrack(fn)` to disable dependency capture inside a larger block.

6. **Batching**: Use `Signal.batch(fn)` to coalesce multiple writes so each dependent effect runs at most once per batch. Batches return the value produced by `fn` and can be nested safely.

7. **Module naming**: Source files in `src/` use bare names (`View.res`, `Router.res`, ...). ReScript's `namespace: true` scopes them under `Xote`, so consumers access them as `Xote.View`, `Xote.Router`, etc. There is no `Xote__` prefix and no central `Xote.res` barrel.

8. **Debug names**: `Signal.make`, `Computed.make`, `Effect.run`, and `Effect.runWithDisposer` all accept an optional `~name` argument surfaced for debugging/tooling. Prefer naming long-lived or cross-module reactive primitives when diagnosing graph issues.

9. **Observer re-tracking**: Every time an observer runs, its dependencies are cleared and re-tracked. This ensures the dependency graph stays accurate even when control flow changes.

10. **Exception safety**: The scheduler and observer execution is wrapped in try/catch blocks to ensure tracking state is always restored, even when exceptions are thrown.

11. **ReScript compilation required**: Always compile ReScript before building with Vite. Vite entry points consume the per-module compiled `.res.mjs` files in `src/` (e.g. `src/View.res.mjs`). Hand-written package-entry glue lives in `entries/` so maintained source modules in `src/` stay ReScript-first.

12. **Owner-based cleanup**: Reactive state (effects, computeds) is tracked per-DOM-element via the owner system. When elements are removed, their owners are disposed recursively, preventing memory leaks. `Effect.run`/`Effect.runWithDisposer` called while a component renders registers with that component, so unmounting stops the effect; called outside a render (module level, an event handler) there is no scope to belong to and the effect lives until its disposer runs. A node can be the root of two scopes — a component and the element it returns — so they merge rather than overwrite.

13. **Keyed list reconciliation**: `eachWithKey` uses comment-based anchors and a 3-phase algorithm (remove, build new order, reconcile DOM) for efficient updates. Preserves element identity across re-renders. A key whose item identity changed is rebuilt in the build phase, where its own previous element is retired — the ordering pass only moves elements, so an update that reorders *and* replaces cannot dispose a bystander row or leave the replaced one behind.

14. **SSR hydration markers**: Comment nodes mark reactive boundaries in server-rendered HTML. The hydration walker uses these to attach reactivity without re-rendering the DOM.

15. **Router global state**: The router uses `Symbol.for("xote.router.state")` to store state on `globalThis`, ensuring all Xote instances (even from different bundles) share the same router state.

16. **SVG element support**: SVG elements are created with `createElementNS` using the SVG namespace. The component renderer detects SVG tags via `isSvgTag` and uses the appropriate DOM creation method automatically.

17. **JSX component laziness**: `XoteJSX.jsx` wraps user component functions in `View.LazyComponent`, deferring evaluation until render time so effects/computeds created inside a component aren't incorrectly tracked by a surrounding `Computed` context. Render time is inside the enclosing region's *effect*, so the body also runs untracked — see "Component bodies are their own scope" above.

18. **Tracked blocks**: `View.tracked(body)` lowers to `SignalFragment(Computed.make(() => [body()]))`. Every signal read while `body` runs subscribes the block, and dependencies are re-discovered on each run — a read reached only on one branch is unsubscribed when that branch stops being taken. On change the block's children are replaced **wholesale**: no diffing, and local DOM state inside (input focus, scroll) does not survive. Because it lowers to existing node types, SSR emits the standard fragment markers (`<!--#-->` … `<!--/#-->`) and hydration is unchanged. Keep tracked blocks small, use `For`/`eachWithKey` for lists, and prefer `@xote.component` where you want the same inline-read ergonomics without the wholesale rebuild.

## Common Patterns

### Creating reactive state
```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Access computed value
Console.log(Signal.get(doubled)) // 0

// Named primitives for debugging
let userCount = Signal.make(0, ~name="userCount")
let total = Computed.make(() => Signal.get(price) * Signal.get(qty), ~name="orderTotal")

// Custom equality (e.g. deep compare for records)
type point = {x: int, y: int}
let position = Signal.make({x: 0, y: 0}, ~equals=(a, b) => a.x === b.x && a.y === b.y)
let translated = Computed.make(
  () => {x: Signal.get(position).x + 1, y: Signal.get(position).y},
  ~equals=(a, b) => a.x === b.x && a.y === b.y,
)

// Manual disposal - unlinks the computed from the signals it depends on
Computed.dispose(doubled)
```

### Batching and untracked reads
```rescript
// Coalesce multiple updates so effects only run once
Signal.batch(() => {
  Signal.set(firstName, "Ada")
  Signal.set(lastName, "Lovelace")
})

// Nested batch that returns a value
let count = Signal.batch(() => {
  Signal.update(items, arr => Array.concat(arr, [newItem]))
  Signal.peek(items)->Array.length
})

// Untracked reads inside an observer
Effect.run(() => {
  let current = Signal.get(source)                    // tracked
  let config = Signal.untrack(() => Signal.get(cfg))  // not tracked
  render(current, config)
  None
})
```

### Event handlers
```rescript
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
```

### Effects with cleanup
```rescript
// Effect without cleanup
Effect.run(() => {
  Console.log(Signal.get(count))
  None
})

// Effect with cleanup (e.g., timer)
Effect.run(() => {
  let timerId = setInterval(() => Console.log("Tick"), 1000)

  Some(() => {
    clearInterval(timerId)
  })
})
```

### Text nodes
```rescript
// Static text
View.text("Hello")

// Reactive text (auto-updates)
View.signalText(() => Signal.get(count)->Int.toString)

// Type-specific helpers
View.signalInt(() => Signal.get(count))
View.signalFloat(() => Signal.get(price))
View.int(42)
View.float(3.14)
```

### Attributes
```rescript
// Static
View.attr("class", "btn btn-primary")

// Reactive from signal
let className = Signal.make("btn-primary")
View.signalAttr("class", className)

// Reactive from computation
View.computedAttr("class", () =>
  Signal.get(isActive) ? "active" : "inactive"
)

// Mixing static and reactive
Html.button(
  ~attrs=[
    View.attr("type", "button"),
    View.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
  ],
  ()
)

// Optional: None removes the attribute instead of writing a value.
// Presence-based styling ([data-checked], [data-open]) needs the removal.
Html.button(
  ~attrs=[
    View.optionalComputedAttr("data-checked", () =>
      Signal.get(isChecked) ? Some("") : None
    ),
    View.optionalAttr("aria-describedby", descriptionId),  // option<string>
  ],
  ()
)
```

### Auto-tracked blocks
```rescript
/* Every signal read inside the body subscribes the block automatically —
   no thunk-per-binding. The block re-evaluates and replaces its children
   wholesale (no diffing) when any dependency changes, so keep tracked
   blocks small and use eachWithKey/For for lists. */
View.tracked(() =>
  if Signal.get(loggedIn) {
    Html.p(~children=[View.text("Hello, " ++ Signal.get(name))], ())
  } else {
    View.text("Please log in")
  }
)
```
Dependencies are re-discovered on every run, so conditional reads work: above, `name` is only tracked while `loggedIn` is true. `tracked` lowers to `SignalFragment` + `Computed`, so SSR markers and hydration work unchanged.

### Lists
```rescript
// Simple list (re-renders all items on change)
let items = Signal.make([1, 2, 3])
View.each(items, item => View.text(Int.toString(item)))

// Keyed list (efficient reconciliation)
type todo = { id: string, text: string }
let todos = Signal.make([{ id: "1", text: "Buy milk" }])
View.eachWithKey(
  todos,
  todo => todo.id,
  todo => Html.li(~children=[View.text(todo.text)], ())
)
```

### JSX Syntax

#### Basic JSX elements
```rescript
<div class="container">
  {View.text("Hello")}
</div>

// With events
<button onClick={handleClick}>
  {View.text("Click me")}
</button>

// Input with reactive value
<input
  type_="text"
  value={Signal.peek(inputValue)}
  onInput={handleInput}
/>
```

#### Attributes without a typed prop (`attrs`)

```rescript
// Untyped entries — same values as any other JSX attribute
<div role="tablist" attrs=[("aria-controls", "panel-1"), ("aria-orientation", "horizontal")]>
  ...
</div>

// View.attrValue entries — typed, and the way to mix static and reactive
<button
  role="switch"
  attrs=[
    View.attr("aria-controls", panelId),
    View.computedAttr("aria-checked", () => Signal.get(checked) ? "true" : "false"),
    // present as `data-checked` only while checked, so [data-checked] matches
    View.optionalComputedAttr("data-checked", () => Signal.get(checked) ? Some("") : None),
  ]>
  {View.text("Toggle")}
</button>
```

`attrs` is merged after the typed props, so `<div class="a" attrs=[("class", "b")] />`
renders `class="b"` once.

#### Static-or-reactive values with MaybeSignal
Built-in element attributes and `View.Text`/`Int`/`Float`/`Bool` are untyped and
accept anything, so no wrapper is needed there:

```rescript
<div class="container"> {View.text("Static class")} </div>
<div class={classSignal}> {View.text("Reactive class")} </div>
<div class={() => Signal.get(isActive) ? "on" : "off"}> {View.text("Derived")} </div>
```

Props with a declared type take a `MaybeSignal.t`, and that is where the wrapper
earns its keep — `View.Show`, `View.For`, `View.Maybe`, `View.Value`, and any
component you write:

```rescript
<View.Show when_={MaybeSignal.reactive(isReady)}> ... </View.Show>
<View.For each={MaybeSignal.static(["Draft", "Ship"])} render={...} />

@jsx.component
let make = (~className: MaybeSignal.t<string>=MaybeSignal.static("badge"), ~children) =>
  <span class={className}> {children} </span>
```

`MaybeSignal` is not prop-specific — use it for any static-or-reactive input:

```rescript
let label: MaybeSignal.t<string> = MaybeSignal.reactive(nameSignal)
let title = MaybeSignal.computed(() => Signal.get(first) ++ " " ++ Signal.get(last))

MaybeSignal.get(label)          // tracked read
MaybeSignal.peek(label)         // untracked read
MaybeSignal.map(label, String.toUpperCase) // stays static if the input was static
MaybeSignal.toSignal(label)     // Signal.t<string>; a Static input yields a detached signal
MaybeSignal.ofUnknown(anything) // coercion for untyped input (raw / signal / thunk / t)
```

> `Prop` is the deprecated predecessor of `MaybeSignal`. It still works (`Prop.t`
> is a type alias of `MaybeSignal.t`) but emits deprecation warnings.

#### Router with JSX
```rescript
// Initialize router
Router.init(~basePath="/my-app", ())

// JSX Link component
<Router.Link to="/about" class="nav-link">
  {View.text("About")}
</Router.Link>

// Route matching
Router.routes([
  { pattern: "/", render: _ => <HomePage /> },
  { pattern: "/about", render: _ => <AboutPage /> },
  { pattern: "/users/:id", render: params =>
    <UserPage id={params->Dict.get("id")->Option.getOr("")} />
  },
])
```

### SSR Example
```rescript
// Shared component (runs on both server and client)
let app = () => {
  let count = SSRState.signal("count", 0, SSRState.Codec.int)

  <div>
    <p> {View.signalInt(() => Signal.get(count))} </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {View.text("+")}
    </button>
  </div>
}

// Server
let html = SSR.renderDocument(
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app
)

// Client
Hydration.hydrateById(app, "root")
```

## Reference Documentation

- **Technical deep-dive**: See `docs/TECHNICAL_OVERVIEW.md` for detailed architecture
- **Changelog**: See `docs/CHANGELOG.md` for version history
- **SSR example**: `examples/ssr/` - Full SSR + hydration setup
- **rescript-signals**: https://brnrdog.github.io/rescript-signals - The reactive primitives library
- **TC39 Signals proposal**: https://github.com/tc39/proposal-signals
- **ReScript JSX**: https://rescript-lang.org/docs/manual/latest/jsx

## Known Limitations

1. **SignalFragment updates**: `SignalFragment` replaces all children without diffing (no reconciliation algorithm). Use `eachWithKey` for efficient list updates.
2. **Hydration is one-way**: After hydration, subsequent updates use full client-side rendering (no incremental/streaming hydration).
3. **Synchronous scheduler**: All scheduling is synchronous; there is no microtask/animation-frame integration. Use `Signal.batch` to coalesce updates, but understand that effects still run inline when the batch ends.
4. **Manual JSX key plumbing**: `jsxKeyed`/`jsxsKeyed` currently ignore the `~key` argument — use `View.eachWithKey` (or `<View.For by=...>`) for reconciled lists rather than relying on JSX-level keys.
5. **`each` re-renders fully**: `View.each` recreates every item on change (it is implemented on top of `SignalFragment`). Prefer `View.eachWithKey` when item identity matters.

## Agent Workflow

Guidance for AI coding agents (and humans) making changes to this repository.

### Before Making Changes

1. **Compile first**: Always run `npm run res:build` before testing or building
2. **Understand the module boundary**: The public surface is what the `.resi` files in `src/` declare — see [Public API Boundary](#public-api-boundary). Widening one is an API change; run `npm run test:exports` and `npm run test:boundary` after touching any of them.

### Making Changes

1. Edit `.res` source files in `src/`
2. Run `npm run res:build` to compile
3. Check for compiler errors - ReScript has a strict type system
4. Run `npm run dev` to test in browser if needed

### Key Files

| File | Purpose |
|------|---------|
| `src/View.res` | Public node API: constructors, attributes, JSX components, mount |
| `src/Html.res` | Common HTML element constructors (`div`, `button`, ...) |
| `src/XoteJSX.res` | JSX v4 transform and `Elements` module |
| `src/Router.res` | Client-side routing |
| `src/Route.res` | Route pattern matching utilities |
| `src/SSR.res` | Server-side rendering |
| `src/Hydration.res` | Client-side hydration |
| `src/SSRState.res` | Server-client state transfer |
| `src/SSRContext.res` | Server/client environment detection |
| `src/MaybeSignal.res` | Static/Reactive value wrapper |
| `src/Prop.res`, `src/Prop.resi` | Deprecated alias of `MaybeSignal` (the interface file is what makes the deprecations warn) |
| `src/Signal.res`, `src/Computed.res`, `src/Effect.res` | Explicit re-export shims for `rescript-signals` |
| `src/*.resi` | Interface files - the public API boundary |
| `src/RuntimeNode.res` | Internal `node`/`attrValue` type definitions and attribute resolution |
| `src/RuntimeRender.res` | Internal renderer, shared by `View.mount` and `Hydration` |
| `tests/consumer/` | Fixture package that compiles against the published surface |
| `ppx/ppx.ml` | The `@xote.component` fine-grained PPX (vendored OCaml 4.06 AST + rewriter) |
| `ppx/example/` | Standalone PPX consumer project; `verify.mjs` is its jsdom regression suite (`npm run ppx:test`). `src/Store.res` is deliberately a *second* file, so its helpers model the cross-module reads detection cannot follow |
| `ppx/postinstall.js` | Selects/installs the prebuilt PPX binary at npm install time |
| `rescript.json` | ReScript compiler configuration (`namespace: true`) |
| `vite.config.js` | Library build configuration |

### Common Pitfalls

- **Forgetting to compile**: `.res.mjs` files are generated - edit `.res` files, not `.res.mjs`
- **Adding a value to a public module**: it is invisible until the module's `.resi` declares it. That is the point - decide whether it is API before exporting it.
- **`%raw` capturing a ReScript binding**: write raw JavaScript as a self-contained function literal (`let f: string => unit = %raw(\`function (x) { ... }\`)`). Referring to a surrounding binding by name works until the compiler inlines or renames it, and then breaks at runtime with a `ReferenceError`.
- **Effect return type**: Effects must return `option<unit => unit>`, not `unit`. Return `None` when no cleanup is needed.
- **Signal reads in effects**: Use `Signal.get` (creates dependency) vs `Signal.peek` (no dependency). Using `get` inside an effect will re-run the effect when the signal changes.
- **Owner disposal**: When removing DOM elements with reactive state, ensure the owner system cleans up (handled automatically by `RuntimeRender.disposeElement`)
- **Router init**: `Router.init()` must be called before any routing functions on the client. For SSR, use `Router.initSSR(~pathname, ())` instead to avoid accessing browser APIs.
- **Boolean attributes**: Use string `"true"`/`"false"` - the `setAttrOrProp` function handles the conversion to proper DOM behavior. To *remove* an attribute reactively, use the optional helpers (`View.optionalComputedAttr(key, () => ... ? Some("") : None)`) rather than adding the key to `RuntimeAttr.booleanAttributes`
- **SSR state cleanup**: Call `SSRState.clear()` between multiple renders on the server to reset the state registry

### Code Style

- Follow existing patterns in the codebase
- Use `/* */` comments (ReScript style), not `//` for documentation comments
- Source files in `src/` use bare module names; ReScript namespacing handles the `Xote.` prefix at the consumer
- Keep the public API minimal — a value is public only if a `.resi` declares it
- Prefer structural types over nominal when possible in ReScript

### Testing Changes

The project has a test suite using the [zekr](https://github.com/nicholasgasior/zekr) framework. Verify changes by:

1. Successful ReScript compilation (`npm run res:build`)
2. Run tests (`npm run test`) - this includes the public API guardrails
3. Successful Vite build (`npm run build`)
4. Manual testing with demo apps (`npm run dev`)
5. For SSR changes, check the `examples/ssr/` setup
6. For PPX or `View.child`/`View.tracked` changes, run the end-to-end suite: `npm run ppx:test` (needs `ocamlopt`)

#### Test Files

| File | Purpose |
|------|---------|
| `tests/Component_test.res` | Component rendering |
| `tests/Hydration_test.res` | Hydration logic |
| `tests/JSX_test.res` | JSX transform |
| `tests/MaybeSignal_test.res` | `MaybeSignal` helpers and the deprecated `Prop` alias |
| `tests/KeyedList_test.res` | Keyed list reconciliation |
| `tests/Probe_test.res` | `View.probe` hidden-read detection (reports, false positives, dedupe) |
| `tests/Route_test.res` | Route matching |
| `tests/SSR_test.res` | Server-side rendering |
| `tests/SSRState_test.res` | State serialization |
| `tests/PublicApi_test.res` | Documented API stays usable from inside the package |
| `tests/PublicExports_test.mjs` | JS export surface of each public module (snapshot) |
| `tests/consumer/` | Public API boundary as a downstream package sees it (`allowed/`, `deprecated/`, `forbidden/`) |
