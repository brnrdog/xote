# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Xote (pronounced [ˈʃɔtʃi]) is a lightweight, zero-dependency UI library for ReScript with fine-grained reactivity based on the TC39 Signals proposal. It provides reactive primitives (signals, computed values, effects) and a minimal component system.

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

The codebase follows a flat module hierarchy with the `Xote__` prefix for internal modules:

- **`Xote__Core`**: Low-level runtime managing dependency tracking and observer scheduling. Contains global state (`observers`, `signalObservers`, `currentObserverId`, `pending`, `batching`) and implements the reactivity graph. This is the scheduler and dependency tracking engine.

- **`Xote__Signal`**: User-facing reactive state cells. Implements `make`, `get`, `peek`, `set`, `update`. The `get` function automatically captures dependencies when called within a tracking context.

- **`Xote__Computed`**: Derived signals that automatically recompute when dependencies change. Creates an internal observer that writes to a backing signal. **Important**: Computeds are **push-based** (eager) - they recompute immediately when upstream dependencies notify, not lazily on read.

- **`Xote__Effect`**: Side effects that run when dependencies change. Returns a `disposer` with a `dispose()` method to stop tracking.

- **`Xote__Observer`**: Observer type definitions and structures used by the scheduler. Defines observer kinds: `#Effect` and `#Computed(int)`.

- **`Xote__Id`**: Monotonic integer ID generator for signals and observers.

- **`Xote__Component`**: Minimal component/renderer with virtual node types (`Element`, `Text`, `SignalText`, `Fragment`, `SignalFragment`). Provides element constructors (`div`, `button`, `input`, etc.) and reactive nodes that update DOM directly via effects.

- **`Xote__JSX`**: Generic JSX v4 implementation that enables JSX syntax for creating Xote components. Provides `jsx`, `jsxs`, `jsxKeyed`, `jsxsKeyed` functions and an `Elements` module for lowercase HTML tags.

- **`Xote.res`**: Public API surface that re-exports the above modules as `Signal`, `Computed`, `Effect`, `Core`, `Component`, and `JSX`.

### Reactivity Model

**Dependency Tracking**: When an observer (effect or computed) runs, `Core.currentObserverId` is set. Any `Signal.get` calls during execution register the signal as a dependency via `Core.addDep`. Dependencies are re-tracked on every observer run.

**Scheduling**: When `Signal.set` is called, `Core.notify` is invoked, which schedules all dependent observers. By default, scheduling is **synchronous** - observers run immediately unless wrapped in `Core.batch()`. Batching defers observer execution until the batch completes.

**Push-based Computeds**: Unlike pull-based systems, computeds eagerly recompute and push results to their backing signal when dependencies change. This means computed values are always current but may recompute even if never read.

### ReScript Configuration

- **Build system**: ReScript compiler with `esmodule` output format
- **Output**: In-source compilation (`.res.mjs` files alongside `.res` files)
- **Public module**: Only `Xote` is exported (controlled via `rescript.json` `sources.public`)
- **Compiler flags**: `-open RescriptCore` (RescriptCore is auto-opened in all files)
- **Dependencies**: `@rescript/core` only
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
- `listKeyed` implements efficient reconciliation using keys - it reuses DOM elements, only updating what changed
- Attributes can be static or reactive - reactive attributes set up effects that update the DOM attribute when the signal/computed value changes

## Key Concepts for Development

1. **Unified attributes API**: All attributes use the single `attrs` parameter. Use helper functions `attr()`, `signalAttr()`, or `computedAttr()` to create attribute entries. This replaces the old separate `attrs` and `signalAttrs` parameters.

2. **Signals are always notified**: `Signal.set` always calls `notify`, even if the value didn't change. There's no built-in equality check.

3. **Untracked reads**: Use `Signal.peek(signal)` to read without creating a dependency, or wrap code in `Core.untrack(() => ...)`.

4. **Batching updates**: Wrap multiple signal updates in `Core.batch(() => ...)` to defer observer execution until the batch completes.

5. **Module naming**: Internal modules use `Xote__ModuleName` convention. The public API is `Xote.ModuleName`.

6. **Observer re-tracking**: Every time an observer runs, its dependencies are cleared and re-tracked. This ensures the dependency graph stays accurate even when control flow changes.

7. **No cleanup in effects**: Effects don't have a cleanup callback API. Call the returned `dispose()` method to stop tracking.

8. **ReScript compilation required**: Always compile ReScript before building with Vite. The Vite entry point is `src/Xote.res.mjs` (generated by ReScript compiler).

## Common Patterns

### Creating reactive state
```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)
```

### Event handlers
```rescript
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
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
// Simple list (re-renders entire list on change)
let items = Signal.make([1, 2, 3])
Component.list(items, item => Component.text(Int.toString(item)))

// Keyed list (efficient reconciliation)
type todo = {id: int, text: string}
let todos = Signal.make([{id: 1, text: "Buy milk"}])
Component.listKeyed(
  todos,
  todo => todo.id->Int.toString,  // key extractor
  todo => Component.text(todo.text)  // renderer
)
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
  - `demos/TodoApp.res` - Todo list using function-based API
  - `demos/CounterJSX.res` - Counter demo with JSX syntax
  - `demos/TodoJSX.res` - Todo list with JSX syntax and custom components
- **TC39 Signals proposal**: https://github.com/tc39/proposal-signals
- **ReScript JSX**: https://rescript-lang.org/docs/manual/latest/jsx

## Known Limitations

1. Computeds are push-based (eager), not pull-based (lazy) like the TC39 proposal
2. No microtask-based scheduling (synchronous by default)
3. No effect cleanup hooks
4. No equality checks in `Signal.set`
5. Non-keyed lists (`list`) replace all children on update - use `listKeyed` for efficient reconciliation
