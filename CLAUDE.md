# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

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
- `npm run test` - Compile ReScript and run `node tests/Tests.res.mjs`. Tests are built on the [zekr](https://www.npmjs.com/package/zekr) framework (see `tests/Tests.res`) and include snapshot fixtures under `tests/__snapshots__/`.

### Documentation
- `npm run docs:start` - Start documentation site
- `npm run docs:build` - Build documentation site
- `npm run docs:serve` - Serve built documentation site

### Build Artifacts
The build process generates:
- `dist/xote.mjs` - ES module
- `dist/xote.cjs` - CommonJS module
- `dist/xote.umd.js` - UMD bundle

## Architecture

### Module Structure

The codebase uses ReScript's `namespace: true` setting in `rescript.json`, so every source file in `src/` is automatically scoped under the `Xote` namespace by the compiler. There is no manual `Xote__` prefix and no central `Xote.res` barrel — each module is an independent entry point, which lets bundlers tree-shake at module granularity.

**Reactive Primitives (re-exported from rescript-signals):**
- **`Xote.Signal`**: Reactive state cells with `make`, `get`, `peek`, `set`, `update`, plus `batch` and `untrack` from the scheduler. `Signal.make` accepts optional `~name` (for debugging) and `~equals` (a custom `('a, 'a) => bool` comparator) parameters. The default equality is JavaScript `===` (reference/strict), not structural — pass `~equals` when you need deep comparison. `set` only notifies dependents when the new value differs from the current one, preventing unnecessary updates and accidental infinite loops.
- **`Xote.Computed`**: Derived signals that automatically recompute when dependencies change. `Computed.make` accepts optional `~name` (for debugging) and `~equals` (a custom `('a, 'a) => bool` comparator) parameters. As with `Signal.make`, the default equality is JavaScript `===` — pass `~equals` when downstream observers should ignore structurally-equal recomputations. **Lazy with push-based dirty flagging** — when upstream dependencies change, computeds are marked dirty immediately, but only recompute when read (via `Signal.get` or `Signal.peek`). **Auto-disposal**: automatically dispose when they lose all subscribers; use `Computed.dispose(signal)` for manual cleanup.
- **`Xote.Effect`**: Side effects that run when dependencies change. **Can return cleanup callbacks** — signature is `unit => option<unit => unit>`. Two entry points: `Effect.run` is fire-and-forget and returns `unit`; `Effect.runWithDisposer` returns a `disposer` with a `dispose()` method for manual teardown. Both accept an optional `~name` for debugging.

These three are thin shims (`src/Signal.res`, `src/Computed.res`, `src/Effect.res`) that `include` the corresponding modules from `rescript-signals`.

**Xote Modules:**
- **`Xote.Node`**: Core rendering primitives. Defines the virtual node types (`Element`, `Text`, `SignalText`, `Fragment`, `SignalFragment`, `LazyComponent`, `KeyedList`) and exposes node constructors (`text`, `signalText`, `signalInt`, `signalFloat`, `computedText`, `computedInt`, `computedFloat`, `fragment`, `signalFragment`, `list`, `keyedList`, `each`, `keyedEach`, `element`), attribute helpers (`attr`, `signalAttr`, `computedAttr`, `Attr`), the `null`/`empty` placeholders, and `mount`/`mountById`. The owner-based reactivity system for resource cleanup also lives here.
- **`Xote.View`**: Alias module for `Node`, useful when the term "view" reads more clearly than "node" in application code.
- **`Xote.Html`**: Convenience constructors for common HTML tags (`div`, `span`, `button`, `input`, `h1`-`h3`, `p`, `ul`, `li`, `a`). Thin wrappers over `Node.element`. For tags not listed, call `Node.element(tag, ...)` directly or use JSX.
- **`Xote.XoteJSX`**: Generic JSX v4 implementation that enables JSX syntax for creating Xote components. Provides `jsx`, `jsxs`, `jsxKeyed`, `jsxsKeyed` functions and an `Elements` module for lowercase HTML tags with a broad set of supported attributes (standard, form/input, link, media, accessibility, drag-and-drop, and data attributes). Named `XoteJSX` (not `JSX`) to avoid colliding with unrelated modules when consumers use `open Xote`. Note: to defer side-effecting component evaluation out of any surrounding `Computed` context, `XoteJSX.jsx` wraps user-defined components in `Node.LazyComponent`.
- **`Xote.ReactiveProp`**: A helper type `t<'a> = Reactive(Signal.t<'a>) | Static('a)` for flexible prop handling in JSX - allows props to accept either static values or reactive signals.
- **`Xote.Prop`**: Alias module for `ReactiveProp`, including `Prop.signal(signal)` as a shorter alias for `ReactiveProp.reactive(signal)`.
- **`Xote.Router`**: Signal-based client-side router with pattern matching, dynamic routes, base path support, scroll position restoration, and a global singleton state (via `Symbol.for()`) that works across multiple bundles.
- **`Xote.Route`**: Route matching utilities.
- **`Xote.SSR`**: Server-side rendering to HTML strings with hydration markers (`<!--$-->`, `<!--#-->`, `<!--kl-->`, `<!--k:KEY-->`, `<!--lc-->`).
- **`Xote.SSRContext`**: Runtime environment detection (`isServer`, `isClient`) and helpers (`onServer`, `onClient`, `match`).
- **`Xote.SSRState`**: State serialization/restoration between server and client. Includes a `Codec` system for type-safe encoding/decoding and a `sync`/`make` API for seamless server-client state transfer.
- **`Xote.Hydration`**: Client-side hydration that walks server-rendered DOM, attaches reactive effects, event listeners, and sets up keyed list reconciliation without re-rendering.

### Reactivity Model

All reactive behavior is provided by **rescript-signals**:

**Dependency Tracking**: When an observer (effect or computed) runs, any `Signal.get` calls during execution register the signal as a dependency. Dependencies are re-tracked on every observer run.

**Scheduling**: When `Signal.set` is called, all dependent observers are scheduled and run **synchronously**. The scheduler uses level-based ordering (each observer's level is derived from its computed dependency chain) so computeds flush before effects and downstream observers never see inconsistent intermediate state.

**Lazy Computeds with Push-based Dirty Flagging**: When dependencies change, computeds are marked dirty immediately (the dirty flag is pushed through the graph), but actual recomputation is deferred until the computed is read via `Signal.get` or `Signal.peek` (which calls `ensureComputedFresh`). A computed with no active readers will stay dirty and never recompute.

**Equality**: By default `Signal.set` uses JavaScript strict equality (`===`) to decide whether to notify subscribers, so reassigning a primitive to the same value is a no-op but a new object/array reference will always propagate. Pass `~equals=(a, b) => ...` to `Signal.make` for deep/structural comparison when you want identity-invariant updates.

**Batching**: `Signal.batch(fn)` defers scheduler flushing until `fn` returns, so a burst of `Signal.set` calls triggers each effect at most once. Batches can be nested and return a value. `Signal.untrack(fn)` disables dependency capture inside `fn`, which is the idiomatic way to read a signal without subscribing the current observer to it (there is also `Signal.peek(signal)` for a single untracked read).

**Owner System**: Components use an owner-based tracking system (`Reactivity` module in `Node.res`) that stores effect disposers and computed references on DOM elements via the `__xote_owner__` property. Owners are disposed recursively when DOM elements are removed, preventing memory leaks.

### ReScript Configuration

- **Build system**: ReScript compiler v12+ with `esmodule` output format
- **Output**: In-source compilation (`.res.mjs` files alongside `.res` files)
- **Namespacing**: `namespace: true` in `rescript.json` automatically scopes every module under `Xote`. Public modules are listed explicitly in `sources.public` (`Node`, `View`, `Html`, `XoteJSX`, `ReactiveProp`, `Prop`, `Route`, `Router`, `SSR`, `SSRContext`, `SSRState`, `Hydration`, `Signal`, `Computed`, `Effect`); everything else (e.g. `DOM`, `Reactivity`, which live inside `Node.res`) stays internal.
- **Dependencies**: `rescript-signals` ^2.1.0 (the only runtime dependency)
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
5. **Lists**:
   - `list(signal, renderItem)` - simple reactive list (re-renders all items on change)
   - `keyedList(signal, keyFn, renderItem)` - efficient keyed list with DOM reconciliation (preserves element identity, only updates changed items)
6. **Event handlers**: `events` parameter for DOM event listeners
7. **Null node**: `Node.null()` - renders an empty text node
8. **HTML element helpers**: `Html.div`, `Html.button`, `Html.p`, etc. live in the `Xote.Html` module — use them when writing the function-based API. For tags not covered, fall back to `Node.element("tag", ...)`.
9. **Mounting**: `mount(node, container)` or `mountById(node, "element-id")` to attach to DOM

#### JSX Syntax
Xote supports ReScript's generic JSX v4 for a declarative component syntax:

```rescript
let app = () => {
  <div class="container">
    <h1> {Node.text("Hello JSX")} </h1>
    <button onClick={handleClick}>
      {Node.text("Click me")}
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
  - SVG root: `xmlns`, `xmlnsXlink`, `version`, `viewBox`, `preserveAspectRatio`
  - SVG geometry: `d`, `pathLength`, `cx`, `cy`, `r`, `rx`, `ry`, `x`, `y`, `x1`, `y1`, `x2`, `y2`, `fx`, `fy`, `dx`, `dy`, `points`, `transform`, `transformOrigin`
  - SVG presentation: `fill`, `fillOpacity`, `fillRule`, `stroke`, `strokeWidth`, `strokeLinecap`, `strokeLinejoin`, `strokeDasharray`, `strokeDashoffset`, `strokeOpacity`, `strokeMiterlimit`, `opacity`, `color`, `visibility`, `vectorEffect`, `pointerEvents`
  - SVG clipping/filter: `clipPath`, `clipRule`, `mask`, `filter`
  - SVG text: `textAnchor`, `dominantBaseline`, `fontFamily`, `fontSize`, `fontWeight`, `letterSpacing`, `wordSpacing`, `textDecoration`
  - SVG gradient/stop: `offset`, `stopColor`, `stopOpacity`, `gradientUnits`, `gradientTransform`, `spreadMethod`
  - SVG markers: `markerStart`, `markerMid`, `markerEnd`
  - SVG xlink (legacy): `xlinkHref`
- Props support raw values, `ReactiveProp.t<'a>` (`Static` / `Reactive`), raw `Signal.t<'a>`, or a computed `unit => 'a` function for flexible static/reactive handling
- Event handlers: `onClick`, `onInput`, `onChange`, `onSubmit`, `onFocus`, `onBlur`, `onKeyDown`, `onKeyUp`, `onMouseEnter`, `onMouseLeave`, `onMouseDown`, `onMouseMove`, `onMouseUp`, `onContextMenu`, plus drag-and-drop: `onDrag`, `onDragStart`, `onDragEnd`, `onDragOver`, `onDragEnter`, `onDragLeave`, `onDrop`
- Children are passed via JSX syntax and rendered as nodes
- Boolean attributes (`disabled`, `checked`, `required`, `readOnly`, `multiple`, `autofocus`, `ariaHidden`, `ariaExpanded`, `ariaSelected`, `draggable`, `hidden`, `contentEditable`, `spellcheck`) are added/removed based on the value rather than stringified

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
- **JSX Link**: `<Router.Link to="/path" class="nav-link">` for declarative navigation in JSX

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
- `SSRState.make(id, initial, codec)` - create and sync a signal in one call
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

The `DOM.setAttrOrProp` helper (in `Node.res`) handles the distinction between HTML attributes and DOM properties:
- `value`, `checked`, `disabled` are set as DOM properties (not attributes)
- Boolean attributes (`required`, `readonly`, `multiple`, `aria-hidden`, `aria-expanded`, `aria-selected`, `draggable`, `hidden`, `contenteditable`, `spellcheck`, `autofocus`) are added or removed based on whether the serialized value is `"true"`
- All other attributes use `setAttribute`

## Key Concepts for Development

1. **Unified attributes API**: All attributes use the single `attrs` parameter. Use helper functions `attr()`, `signalAttr()`, or `computedAttr()` to create attribute entries.

2. **Signal equality check**: `Signal.set` uses JavaScript strict equality (`===`) by default and only notifies dependents when the new value differs from the current one. This prevents accidental infinite loops and reduces unnecessary work. Pass `~equals` to `Signal.make` or `Computed.make` when you need a custom comparator (e.g. deep equality for records/arrays) — on a computed, `~equals` controls whether recomputed values propagate to downstream observers.

3. **Effect cleanup callbacks**: Effects can return `Some(cleanupFn)` to register cleanup that runs before re-execution and on disposal. Return `None` when no cleanup is needed. Signature is `unit => option<unit => unit>`.

4. **Computed disposal**: `Computed.make` returns a `Signal.t<'a>` directly. For manual disposal, use `Computed.dispose(signal)`. Auto-disposal happens automatically when subscribers drop to zero.

5. **Untracked reads**: Use `Signal.peek(signal)` for a single untracked read, or `Signal.untrack(fn)` to disable dependency capture inside a larger block.

6. **Batching**: Use `Signal.batch(fn)` to coalesce multiple writes so each dependent effect runs at most once per batch. Batches return the value produced by `fn` and can be nested safely.

7. **Module naming**: Source files in `src/` use bare names (`Node.res`, `Router.res`, ...). ReScript's `namespace: true` scopes them under `Xote`, so consumers access them as `Xote.Node`, `Xote.Router`, etc. There is no `Xote__` prefix and no central `Xote.res` barrel.

8. **Debug names**: `Signal.make`, `Computed.make`, `Effect.run`, and `Effect.runWithDisposer` all accept an optional `~name` argument surfaced for debugging/tooling. Prefer naming long-lived or cross-module reactive primitives when diagnosing graph issues.

9. **Observer re-tracking**: Every time an observer runs, its dependencies are cleared and re-tracked. This ensures the dependency graph stays accurate even when control flow changes.

10. **Exception safety**: The scheduler and observer execution is wrapped in try/catch blocks to ensure tracking state is always restored, even when exceptions are thrown.

11. **ReScript compilation required**: Always compile ReScript before building with Vite. Vite entry points consume the per-module compiled `.res.mjs` files in `src/` (e.g. `src/View.res.mjs`). Hand-written package-entry glue lives in `entries/` so maintained source modules in `src/` stay ReScript-first.

12. **Owner-based cleanup**: Reactive state (effects, computeds) is tracked per-DOM-element via the owner system. When elements are removed, their owners are disposed recursively, preventing memory leaks.

13. **Keyed list reconciliation**: `keyedList` uses comment-based anchors and a 3-phase algorithm (remove, build new order, reconcile DOM) for efficient updates. Preserves element identity across re-renders.

14. **SSR hydration markers**: Comment nodes mark reactive boundaries in server-rendered HTML. The hydration walker uses these to attach reactivity without re-rendering the DOM.

15. **Router global state**: The router uses `Symbol.for("xote.router.state")` to store state on `globalThis`, ensuring all Xote instances (even from different bundles) share the same router state.

16. **SVG element support**: SVG elements are created with `createElementNS` using the SVG namespace. The component renderer detects SVG tags via `isSvgTag` and uses the appropriate DOM creation method automatically.

17. **JSX component laziness**: `XoteJSX.jsx` wraps user component functions in `Node.LazyComponent`, deferring evaluation until render time so effects/computeds created inside a component aren't incorrectly tracked by a surrounding `Computed` context.

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

// Manual disposal (usually not needed - auto-disposes when subscribers drop to zero)
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
Node.text("Hello")

// Reactive text (auto-updates)
Node.signalText(() => Signal.get(count)->Int.toString)

// Type-specific helpers
Node.signalInt(() => Signal.get(count))
Node.signalFloat(() => Signal.get(price))
Node.int(42)
Node.float(3.14)
```

### Attributes
```rescript
// Static
Node.attr("class", "btn btn-primary")

// Reactive from signal
let className = Signal.make("btn-primary")
Node.signalAttr("class", className)

// Reactive from computation
Node.computedAttr("class", () =>
  Signal.get(isActive) ? "active" : "inactive"
)

// Mixing static and reactive
Html.button(
  ~attrs=[
    Node.attr("type", "button"),
    Node.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
  ],
  ()
)
```

### Lists
```rescript
// Simple list (re-renders all items on change)
let items = Signal.make([1, 2, 3])
Node.list(items, item => Node.text(Int.toString(item)))

// Keyed list (efficient reconciliation)
type todo = { id: string, text: string }
let todos = Signal.make([{ id: "1", text: "Buy milk" }])
Node.keyedList(
  todos,
  todo => todo.id,
  todo => Html.li(~children=[Node.text(todo.text)], ())
)
```

### JSX Syntax

#### Basic JSX elements
```rescript
<div class="container">
  {Node.text("Hello")}
</div>

// With events
<button onClick={handleClick}>
  {Node.text("Click me")}
</button>

// Input with reactive value
<input
  type_="text"
  value={Signal.peek(inputValue)}
  onInput={handleInput}
/>
```

#### Reactive props with ReactiveProp
```rescript
// Props can accept either static or reactive values
<div class={ReactiveProp.static("container")}>
  {Node.text("Static class")}
</div>

<div class={ReactiveProp.reactive(classSignal)}>
  {Node.text("Reactive class")}
</div>
```

#### Router with JSX
```rescript
// Initialize router
Router.init(~basePath="/my-app", ())

// JSX Link component
<Router.Link to="/about" class="nav-link">
  {Node.text("About")}
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
  let count = SSRState.make("count", 0, SSRState.Codec.int)

  <div>
    <p> {Node.signalInt(() => Signal.get(count))} </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Node.text("+")}
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
- **Example apps**:
  - `docs-website/src/demos/TodoDemo.res` - Todo list with keyed lists and filtering
  - `docs-website/src/demos/ColorMixerDemo.res` - Color mixer with reactive sliders
  - `docs-website/src/demos/CounterDemo.res` - Basic counter
  - `docs-website/src/demos/SnakeGameDemo.res` - Snake game
  - `docs-website/src/demos/SolitaireDemo.res` - Solitaire card game
  - `docs-website/src/demos/MatchGameDemo.res` - Memory match game
  - `docs-website/src/demos/ReactionGameDemo.res` - Reaction time game
- **SSR example**: `examples/ssr/` - Full SSR + hydration setup
- **rescript-signals**: https://brnrdog.github.io/rescript-signals - The reactive primitives library
- **TC39 Signals proposal**: https://github.com/tc39/proposal-signals
- **ReScript JSX**: https://rescript-lang.org/docs/manual/latest/jsx

## Known Limitations

1. **SignalFragment updates**: `SignalFragment` replaces all children without diffing (no reconciliation algorithm). Use `keyedList` for efficient list updates.
2. **Hydration is one-way**: After hydration, subsequent updates use full client-side rendering (no incremental/streaming hydration).
3. **Synchronous scheduler**: All scheduling is synchronous; there is no microtask/animation-frame integration. Use `Signal.batch` to coalesce updates, but understand that effects still run inline when the batch ends.
4. **Manual JSX key plumbing**: `jsxKeyed`/`jsxsKeyed` currently ignore the `~key` argument — use `Node.keyedList` for reconciled lists rather than relying on JSX-level keys.
5. **`list` re-renders fully**: `Node.list` recreates every item on change (it is implemented on top of `SignalFragment`). Prefer `Node.keyedList` when item identity matters.
