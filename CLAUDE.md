# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xote is a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system. It uses [rescript-signals](https://github.com/brnrdog/rescript-signals) for reactive primitives and provides declarative components with JSX support, server-side rendering, and client-side hydration.

## Development Commands

### ReScript Compilation
- `npm run res:build` - Compile ReScript to JavaScript
- `npm run res:clean` - Clean compiled ReScript files
- `npm run res:dev` - Watch mode for ReScript compilation

### Build & Development
- `npm run dev` - Start Vite dev server
- `npm run build` - Build library with Vite (outputs to `dist/`)
- `npm run preview` - Preview production build

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

The codebase uses the `Xote__` prefix for internal modules:

**Reactive Primitives (from rescript-signals):**
- **`Signals.Signal`**: Reactive state cells with `make`, `get`, `peek`, `set`, `update`. **Includes structural equality check** - only notifies dependents if the value has changed, preventing unnecessary updates and accidental infinite loops.
- **`Signals.Computed`**: Derived signals that automatically recompute when dependencies change. **Lazy with push-based dirty flagging** - when upstream dependencies change, computeds are marked dirty immediately, but only recompute when read (via `Signal.get` or `Signal.peek`). **Auto-disposal**: Automatically dispose when they lose all subscribers.
- **`Signals.Effect`**: Side effects that run when dependencies change. **Can return cleanup callbacks** - signature is `unit => option<unit => unit>`. Returns a `disposer` with a `dispose()` method.

**Xote Modules:**
- **`Xote__Component`**: Component/renderer with virtual node types (`Element`, `Text`, `SignalText`, `Fragment`, `SignalFragment`, `LazyComponent`, `KeyedList`). Provides element constructors, reactive nodes, keyed list reconciliation, and an owner-based reactivity system for resource cleanup.
- **`Xote__JSX`**: Generic JSX v4 implementation that enables JSX syntax for creating Xote components. Provides `jsx`, `jsxs`, `jsxKeyed`, `jsxsKeyed` functions and an `Elements` module for lowercase HTML tags with ~30 supported attributes.
- **`Xote__ReactiveProp`**: A helper type `t<'a> = Reactive(Signal.t<'a>) | Static('a)` for flexible prop handling in JSX - allows props to accept either static values or reactive signals.
- **`Xote__Router`**: Signal-based client-side router with pattern matching, dynamic routes, base path support, scroll position restoration, and a global singleton state (via `Symbol.for()`) that works across multiple bundles.
- **`Xote__Route`**: Route matching utilities.
- **`Xote__SSR`**: Server-side rendering to HTML strings with hydration markers (`<!--$-->`, `<!--#-->`, `<!--kl-->`, `<!--k:KEY-->`, `<!--lc-->`).
- **`Xote__SSRContext`**: Runtime environment detection (`isServer`, `isClient`) and helpers (`onServer`, `onClient`, `match`).
- **`Xote__SSRState`**: State serialization/restoration between server and client. Includes a `Codec` system for type-safe encoding/decoding and a `sync`/`make` API for seamless server-client state transfer.
- **`Xote__Hydration`**: Client-side hydration that walks server-rendered DOM, attaches reactive effects, event listeners, and sets up keyed list reconciliation without re-rendering.
- **`Xote.res`**: Public API surface that re-exports all modules: `Signal`, `Computed`, `Effect`, `Component`, `Router`, `Route`, `ReactiveProp`, `SSR`, `SSRContext`, `SSRState`, `Hydration`.

### Reactivity Model

All reactive behavior is provided by **rescript-signals**:

**Dependency Tracking**: When an observer (effect or computed) runs, any `Signal.get` calls during execution register the signal as a dependency. Dependencies are re-tracked on every observer run.

**Scheduling**: When `Signal.set` is called, all dependent observers are scheduled and run **synchronously**. The scheduler uses topological ordering to ensure correct execution order.

**Lazy Computeds with Push-based Dirty Flagging**: When dependencies change, computeds are marked dirty immediately (the dirty flag is pushed through the graph), but actual recomputation is deferred until the computed is read via `Signal.get` or `Signal.peek` (which calls `ensureComputedFresh`). A computed with no active readers will stay dirty and never recompute.

**Structural Equality**: Signals use structural equality (`==`) to check if values have changed. Only when values differ are dependents notified.

**Owner System**: Components use an owner-based tracking system (`Reactivity` module) that stores effect disposers and computed references on DOM elements via `__xote_owner__`. Owners are disposed recursively when DOM elements are removed, preventing memory leaks.

### ReScript Configuration

- **Build system**: ReScript compiler v12+ with `esmodule` output format
- **Output**: In-source compilation (`.res.mjs` files alongside `.res` files)
- **Public module**: Only `Xote` is exported (controlled via `rescript.json` `sources.public`)
- **Dependencies**: `rescript-signals` ^1.3.3
- **JSX**: ReScript JSX v4 configured to use `Xote__JSX` module (generic JSX transform)

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
2. **Reactive text nodes**: `textSignal(() => ...)` - accepts a function that computes the text value
3. **Type-specific helpers**: `reactiveString`, `reactiveInt`, `reactiveFloat` for reactive values; `int`, `float` for static values
4. **Unified attributes**: `attrs` parameter accepts static, signal, or computed values via helper functions:
   - `attr("key", "value")` - static string attribute
   - `signalAttr("key", signal)` - reactive attribute from a signal
   - `computedAttr("key", () => ...)` - reactive attribute from a computed function
5. **Lists**:
   - `list(signal, renderItem)` - simple reactive list (re-renders all items on change)
   - `keyedList(signal, keyFn, renderItem)` - efficient keyed list with DOM reconciliation (preserves element identity, only updates changed items)
6. **Event handlers**: `events` parameter for DOM event listeners
7. **Null node**: `Component.null()` - renders an empty text node
8. **Mounting**: `mount(node, container)` or `mountById(node, "element-id")` to attach to DOM

#### JSX Syntax
Xote supports ReScript's generic JSX v4 for a declarative component syntax:

```rescript
let app = () => {
  <div class="container">
    <h1> {Component.text("Hello JSX")} </h1>
    <button onClick={handleClick}>
      {Component.text("Click me")}
    </button>
  </div>
}
```

**JSX features**:
- Lowercase tags (`<div>`, `<button>`, etc.) create HTML elements via `Elements` module
- ~30 supported HTML attributes: `class`, `id`, `style`, `type_`, `value`, `placeholder`, `disabled`, `checked`, `href`, `target`, `src`, `alt`, `width`, `height`, `name`, `action`, `method`, `role`, `tabIndex`, `title`, `for_`, `required`, `readonly`, `multiple`, `min`, `max`, `step`, `pattern`, `rows`, `cols`, `data` (dict), and more
- Props support both raw values and `ReactiveProp.t` for flexible static/reactive handling
- Event handlers: `onClick`, `onInput`, `onChange`, `onSubmit`, `onFocus`, `onBlur`, `onKeyDown`, `onKeyUp`, `onMouseEnter`, `onMouseLeave`, `onMouseDown`, `onMouseMove`, `onMouseUp`, `onContextMenu`
- Children are passed via JSX syntax and rendered as nodes
- Data attributes via `data` prop (Dict.t)
- Boolean attributes (`disabled`, `checked`, `required`, etc.) are properly handled

### Router

Signal-based client-side router with:
- **Initialization**: `Router.init(~basePath="/optional-base", ())` - must be called at app entry
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
- `SSR.renderToString(component)` - render component to HTML string
- `SSR.renderToStringWithRoot(component, ~rootId)` - with hydration root markers
- `SSR.renderDocument(~head, ~scripts, ~styles, ~stateScript, component)` - full HTML document
- Uses comment-based hydration markers to identify reactive boundaries

**State transfer (`SSRState` module)**:
- `SSRState.Codec` - type-safe serialization with built-in codecs for `int`, `float`, `string`, `bool`, `array`, `option`, `tuple2`, `tuple3`, `dict`
- `SSRState.sync(id, signal, codec)` - register on server, restore on client
- `SSRState.make(id, initial, codec)` - create and sync a signal in one call
- `SSRState.generateScript()` - generate `<script>` tag with serialized state

**Environment detection (`SSRContext` module)**:
- `SSRContext.isServer` / `SSRContext.isClient` - runtime detection
- `SSRContext.onServer(fn)` / `SSRContext.onClient(fn)` - conditional execution
- `SSRContext.match(~server, ~client)` - environment branching

**Client-side (`Hydration` module)**:
- `Hydration.hydrate(component, container)` - hydrate server-rendered DOM
- `Hydration.hydrateById(component, containerId)` - hydrate by element ID
- Walks existing DOM, attaches effects/events without re-rendering
- Handles all node types including keyed lists and lazy components

### Attribute & Property Handling

The `DOM.setAttrOrProp` function handles the distinction between HTML attributes and DOM properties:
- `value`, `checked`, `disabled` are set as DOM properties (not attributes)
- Boolean attributes (`required`, `readonly`, `multiple`, `aria-hidden`, `aria-expanded`, `aria-selected`) are added/removed based on value
- All other attributes use `setAttribute`

## Key Concepts for Development

1. **Unified attributes API**: All attributes use the single `attrs` parameter. Use helper functions `attr()`, `signalAttr()`, or `computedAttr()` to create attribute entries.

2. **Signal equality check**: `Signal.set` uses structural equality (`!=`) to check if the value has changed. Only notifies dependents when the value differs from the current value. This prevents accidental infinite loops and reduces unnecessary work.

3. **Effect cleanup callbacks**: Effects can return `Some(cleanupFn)` to register cleanup that runs before re-execution and on disposal. Return `None` when no cleanup is needed. Signature is `unit => option<unit => unit>`.

4. **Computed disposal**: `Computed.make` returns a `Signal.t<'a>` directly. For manual disposal, use `Computed.dispose(signal)`. Auto-disposal happens automatically when subscribers drop to zero.

5. **Untracked reads**: Use `Signal.peek(signal)` to read without creating a dependency.

6. **Module naming**: Internal modules use `Xote__ModuleName` convention. The public API is `Xote.ModuleName`.

7. **Batching not available**: The underlying rescript-signals library does not currently expose batching functionality. Updates run synchronously.

8. **Observer re-tracking**: Every time an observer runs, its dependencies are cleared and re-tracked. This ensures the dependency graph stays accurate even when control flow changes.

9. **Exception safety**: The scheduler and observer execution is wrapped in try/catch blocks to ensure tracking state is always restored, even when exceptions are thrown.

10. **ReScript compilation required**: Always compile ReScript before building with Vite. The Vite entry point is `src/Xote.res.mjs` (generated by ReScript compiler).

11. **Owner-based cleanup**: Reactive state (effects, computeds) is tracked per-DOM-element via the owner system. When elements are removed, their owners are disposed recursively, preventing memory leaks.

12. **Keyed list reconciliation**: `keyedList` uses comment-based anchors and a 3-phase algorithm (remove, build new order, reconcile DOM) for efficient updates. Preserves element identity across re-renders.

13. **SSR hydration markers**: Comment nodes mark reactive boundaries in server-rendered HTML. The hydration walker uses these to attach reactivity without re-rendering the DOM.

14. **Router global state**: The router uses `Symbol.for()` to store state on `globalThis`, ensuring all Xote instances (even from different bundles) share the same router state.

## Common Patterns

### Creating reactive state
```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Access computed value
Console.log(Signal.get(doubled)) // 0

// Manual disposal (usually not needed - auto-disposes when subscribers drop to zero)
Computed.dispose(doubled)
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
Component.text("Hello")

// Reactive text (auto-updates)
Component.textSignal(() => Signal.get(count)->Int.toString)

// Type-specific helpers
Component.reactiveInt(() => Signal.get(count))
Component.reactiveFloat(() => Signal.get(price))
Component.int(42)
Component.float(3.14)
```

### Attributes
```rescript
// Static
Component.attr("class", "btn btn-primary")

// Reactive from signal
let className = Signal.make("btn-primary")
Component.signalAttr("class", className)

// Reactive from computation
Component.computedAttr("class", () =>
  Signal.get(isActive) ? "active" : "inactive"
)

// Mixing static and reactive
Component.button(
  ~attrs=[
    Component.attr("type", "button"),
    Component.computedAttr("class", () =>
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
Component.list(items, item => Component.text(Int.toString(item)))

// Keyed list (efficient reconciliation)
type todo = { id: string, text: string }
let todos = Signal.make([{ id: "1", text: "Buy milk" }])
Component.keyedList(
  todos,
  todo => todo.id,
  todo => Component.li(~children=[Component.text(todo.text)], ())
)
```

### JSX Syntax

#### Basic JSX elements
```rescript
<div class="container">
  {Component.text("Hello")}
</div>

// With events
<button onClick={handleClick}>
  {Component.text("Click me")}
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
  {Component.text("Static class")}
</div>

<div class={ReactiveProp.reactive(classSignal)}>
  {Component.text("Reactive class")}
</div>
```

#### Router with JSX
```rescript
// Initialize router
Router.init(~basePath="/my-app", ())

// JSX Link component
<Router.Link to="/about" class="nav-link">
  {Component.text("About")}
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
    <p> {Component.reactiveInt(() => Signal.get(count))} </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Component.text("+")}
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
  - `docs-website/src/demos/BookstoreDemo.res` - Complex app with routing and state management
  - `docs-website/src/demos/CounterDemo.res` - Basic counter
  - `docs-website/src/demos/SnakeGameDemo.res` - Snake game
  - `docs-website/src/demos/SolitaireDemo.res` - Solitaire card game
  - `docs-website/src/demos/MatchGameDemo.res` - Memory match game
  - `docs-website/src/demos/ReactionGameDemo.res` - Reaction time game
- **SSR example**: `examples/ssr/` - Full SSR + hydration setup
- **rescript-signals**: https://github.com/brnrdog/rescript-signals - The reactive primitives library
- **TC39 Signals proposal**: https://github.com/tc39/proposal-signals
- **ReScript JSX**: https://rescript-lang.org/docs/manual/latest/jsx

## Known Limitations

1. **No batching**: The underlying rescript-signals library doesn't expose batching functionality
2. **SignalFragment updates**: Replace all children without diffing (no reconciliation algorithm). Use `keyedList` for efficient list updates.
3. **Lazy computeds**: Computeds use lazy evaluation with push-based dirty flagging, similar to the TC39 proposal
4. **Structural equality only**: No custom equality functions for signals
5. **Hydration is one-way**: After hydration, subsequent updates use full client-side rendering (no incremental hydration)
