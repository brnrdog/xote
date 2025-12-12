# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xote (pronounced [ˈʃɔtʃi]) is a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system. It uses [rescript-signals](https://github.com/pedrobslisboa/rescript-signals) for reactive primitives and provides declarative components with JSX support.

## Development Commands

### ReScript Compilation
- `npm run res:build` - Compile ReScript to JavaScript
- `npm run res:clean` - Clean compiled ReScript files
- `npm run res:dev` - Watch mode for ReScript compilation

### Build & Development
- `npm run dev` - Start Vite dev server
- `npm run build` - Build library with Vite (outputs to `dist/`)
- `npm run preview` - Preview production build

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
- **`Signals.Computed`**: Derived signals that automatically recompute when dependencies change. **Push-based** (eager) - they recompute immediately when upstream dependencies notify. **Auto-disposal**: Automatically dispose when they lose all subscribers.
- **`Signals.Effect`**: Side effects that run when dependencies change. **Can return cleanup callbacks** - signature is `unit => option<unit => unit>`. Returns a `disposer` with a `dispose()` method.

**Xote Modules:**
- **`Xote__Component`**: Minimal component/renderer with virtual node types (`Element`, `Text`, `SignalText`, `Fragment`, `SignalFragment`). Provides element constructors (`div`, `button`, `input`, etc.) and reactive nodes that update DOM directly via effects.
- **`Xote__JSX`**: Generic JSX v4 implementation that enables JSX syntax for creating Xote components. Provides `jsx`, `jsxs`, `jsxKeyed`, `jsxsKeyed` functions and an `Elements` module for lowercase HTML tags.
- **`Xote__Router`**: Signal-based client-side router with pattern matching and dynamic routes.
- **`Xote__Route`**: Route matching utilities.
- **`Xote.res`**: Public API surface that re-exports `Signal`, `Computed`, `Effect` from rescript-signals, plus `Component`, `Router`, `Route`, and `JSX` from Xote modules.

### Reactivity Model

All reactive behavior is provided by **rescript-signals**:

**Dependency Tracking**: When an observer (effect or computed) runs, any `Signal.get` calls during execution register the signal as a dependency. Dependencies are re-tracked on every observer run.

**Scheduling**: When `Signal.set` is called, all dependent observers are scheduled and run **synchronously**. The scheduler uses topological ordering to ensure correct execution order.

**Push-based Computeds**: Computeds eagerly recompute when dependencies change and push results to their backing signal. This means computed values are always current but may recompute even if never read.

**Structural Equality**: Signals use structural equality (`==`) to check if values have changed. Only when values differ are dependents notified.

### ReScript Configuration

- **Build system**: ReScript compiler with `esmodule` output format
- **Output**: In-source compilation (`.res.mjs` files alongside `.res` files)
- **Public module**: Only `Xote` is exported (controlled via `rescript.json` `sources.public`)
- **Compiler flags**: `-open RescriptCore` (RescriptCore is auto-opened in all files)
- **Dependencies**: `@rescript/core`, `rescript-signals`
- **JSX**: ReScript JSX v4 configured to use `Xote__JSX` module (generic JSX transform)

### Component System

Components are functions returning `node` types. Xote supports **two syntax styles**:

#### Function-based API (Component module)
1. **Static text nodes**: `text("hello")`
2. **Reactive text nodes**: `textSignal(() => ...)` - accepts a function that computes the text value
3. **Unified attributes**: `attrs` parameter accepts static, signal, or computed values via helper functions:
   - `attr("key", "value")` - static string attribute
   - `signalAttr("key", signal)` - reactive attribute from a signal
   - `computedAttr("key", () => ...)` - reactive attribute from a computed function
4. **Reactive lists**: `list(signal, renderItem)` - creates a computed that maps array to nodes
5. **Event handlers**: `events` parameter for DOM event listeners
6. **Mounting**: `mountById(node, "element-id")` to attach to DOM

#### JSX Syntax (Experimental)
Xote supports ReScript's generic JSX v4 for a more declarative component syntax:

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
- Lowercase tags (`<div>`, `<button>`, etc.) create HTML elements
- Props support: `class`, `id`, `style`, `type_`, `value`, `placeholder`, `disabled`, `checked`, `href`, `target`
- Event handlers: `onClick`, `onInput`, `onChange`, `onSubmit`, `onFocus`, `onBlur`, `onKeyDown`, `onKeyUp`, `onMouseEnter`, `onMouseLeave`
- Children are passed via JSX syntax and rendered as nodes
- Component functions can be called directly with props objects

**Important rendering behavior**:
- `SignalText` nodes create a DOM text node and set up an effect that updates `textContent` when the signal changes
- `SignalFragment` nodes use a container element with `display: contents` and replace all children when the signal changes (no diffing)
- `list` is implemented as a computed signal + `SignalFragment`, so the entire list rerenders on any array change
- Attributes can be static or reactive - reactive attributes set up effects that update the DOM attribute when the signal/computed value changes

## Key Concepts for Development

1. **Unified attributes API**: All attributes use the single `attrs` parameter. Use helper functions `attr()`, `signalAttr()`, or `computedAttr()` to create attribute entries. This replaces the old separate `attrs` and `signalAttrs` parameters.

2. **Signal equality check**: `Signal.set` uses structural equality (`!=`) to check if the value has changed. Only notifies dependents when the value differs from the current value. This prevents accidental infinite loops and reduces unnecessary work.

3. **Effect cleanup callbacks**: Effects can return `Some(cleanupFn)` to register cleanup that runs before re-execution and on disposal. Return `None` when no cleanup is needed. Signature is `unit => option<unit => unit>`.

4. **Computed disposal**: `Computed.make` returns a `Signal.t<'a>` directly. For manual disposal, use `Computed.dispose(signal)` to stop tracking when no longer needed (auto-disposal happens automatically when subscribers drop to zero).

5. **Untracked reads**: Use `Signal.peek(signal)` to read without creating a dependency.

6. **Module naming**: Internal modules use `Xote__ModuleName` convention. The public API is `Xote.ModuleName`.

7. **Batching**: Use `Signal.batch(() => { ... })` to group multiple signal updates and run observers only once after all updates complete. This is provided by rescript-signals.

8. **Observer re-tracking**: Every time an observer runs, its dependencies are cleared and re-tracked. This ensures the dependency graph stays accurate even when control flow changes.

9. **Exception safety**: The scheduler and observer execution is wrapped in try/catch blocks to ensure tracking state is always restored, even when exceptions are thrown.

10. **ReScript compilation required**: Always compile ReScript before building with Vite. The Vite entry point is `src/Xote.res.mjs` (generated by ReScript compiler).

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

// Effect with conditional cleanup
Effect.run(() => {
  switch Signal.get(url) {
  | Some(u) => {
      let controller = AbortController.make()
      fetch(u, {signal: controller.signal})->ignore

      Some(() => controller.abort())
    }
  | None => None
  }
})
```

### Reactive text
```rescript
// Reactive text that updates when signal changes
Component.textSignal(() => Signal.get(count)->Int.toString)

// Reactive text with computed logic
Component.textSignal(() =>
  Signal.get(isActive) ? "Active" : "Inactive"
)
```

### Static attributes
```rescript
Component.button(
  ~attrs=[
    Component.attr("class", "btn btn-primary"),
    Component.attr("type", "button")
  ],
  ()
)
```

### Reactive attributes
```rescript
// Using computed
Component.button(
  ~attrs=[
    Component.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
  ],
  ()
)

// Using signal directly
let className = Signal.make("btn-primary")
Component.button(
  ~attrs=[Component.signalAttr("class", className)],
  ()
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

### Reactive lists
```rescript
let items = Signal.make([1, 2, 3])
Component.list(items, item => Component.text(Int.toString(item)))
```

### JSX Syntax

#### Basic JSX elements
```rescript
// Simple element
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

#### Component functions with JSX
```rescript
// Define a component function
type buttonProps = {
  label: string,
  onClick: Dom.event => unit,
}

let customButton = (props: buttonProps) => {
  <button class="custom-btn" onClick={props.onClick}>
    {Component.text(props.label)}
  </button>
}

// Use the component
let app = () => {
  <div>
    {customButton({label: "Submit", onClick: handleSubmit})}
  </div>
}
```

#### Reactive content in JSX
```rescript
let app = () => {
  let count = Signal.make(0)

  <div>
    <p>
      {Component.textSignal(() =>
        `Count: ${Signal.get(count)->Int.toString}`
      )}
    </p>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Component.text("+")}
    </button>
  </div>
}
```

## Reference Documentation

- **Technical deep-dive**: See `docs/TECHNICAL_OVERVIEW.md` for detailed architecture
- **Example apps**:
  - `demos/TodoApp.res` - Todo list with JSX syntax
  - `demos/ColorMixerApp.res` - Color mixer with reactive sliders
  - `demos/BookstoreApp.res` - Complex app with routing and state management
- **rescript-signals**: https://github.com/pedrobslisboa/rescript-signals - The reactive primitives library
- **TC39 Signals proposal**: https://github.com/tc39/proposal-signals
- **ReScript JSX**: https://rescript-lang.org/docs/manual/latest/jsx

## Known Limitations

1. **Fragment/list updates**: Replace all children without diffing (no reconciliation algorithm)
2. **Push-based computeds**: Computeds are eager (not lazy like TC39 proposal)
3. **Structural equality by default**: Signals use structural equality by default (custom equality functions are available via `Signal.make(value, ~equals=...)`)

## Architecture Changes (v3.0+)

Xote now uses **rescript-signals** for all reactive primitives:

1. **Reactive primitives externalized**: `Signal`, `Computed`, and `Effect` are re-exported from rescript-signals
2. **Xote focuses on UI**: Component system, JSX support, and Router are Xote-specific features
3. **No internal scheduler**: All reactive behavior delegated to rescript-signals
4. **Simplified codebase**: Removed internal signal implementation (~1500 lines of code)
