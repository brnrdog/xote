# xote
![NPM Version](https://img.shields.io/npm/v/xote)
![npm bundle size](https://img.shields.io/bundlephobia/min/xote)
![npm bundle size](https://img.shields.io/bundlephobia/minzip/xote)

Xote is a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system. Built on [rescript-signals](https://github.com/brnrdog/rescript-signals), it provides declarative components, JSX support, and signal-based routing for building reactive web applications.

## Features

- **Reactive Components**: Declarative UI building with JSX support and direct DOM updates
- **Signal-based Reactivity**: Powered by [rescript-signals](https://github.com/brnrdog/rescript-signals) for automatic dependency tracking
- **Fine-grained Updates**: Direct DOM manipulation without virtual DOM diffing
- **Signal-based Router**: SPA navigation with pattern matching and dynamic parameters
- **Lightweight**: Minimal runtime footprint
- **Type-safe**: Full ReScript type safety throughout

## Getting Started

### Installation

```bash
npm install xote
# or
yarn add xote
# or
pnpm add xote
```

Then, add it to your ReScript project’s dependencies in `rescript.json`:

```json
{
  "bs-dependencies": ["xote"]
}
```

## Why Xote?

Xote uses **rescript-signals** for reactive primitives (Signal, Computed, Effect), and it adds:

- **Component System**: A minimal but powerful component model with JSX support for declarative UI
- **Direct DOM Updates**: Fine-grained reactivity that updates DOM elements directly, no virtual DOM
- **Signal-based Router**: Client-side routing with pattern matching and reactive location state
- **Reactive Attributes**: Support for static, signal-based, and computed attributes on elements
- **Automatic Cleanup**: Effect disposal and memory management built into the component lifecycle

Xote focuses on clarity, control, and performance. The goal is to offer precise, fine-grained updates and predictable behavior with minimal abstractions, while leveraging the robust type system from ReScript.

### Quick Example

#### Using JSX

```rescript
open Xote

module App = {
  let make = () => {
    // Create reactive state
    let count = Signal.make(0)

    // Event handler
    let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

    // Build the UI with JSX
    <div>
      <h1> {Component.text("Counter")} </h1>
      <p>
        {Component.textSignal(() => `Count: ${Signal.get(count)->Int.toString}`)}
      </p>
      <button onClick={increment}>
        {Component.text("Increment")}
      </button>
    </div>
  }
}

// Mount to the DOM
Component.mountById(<App />, "app")
```

## Core Concepts

### Reactive Primitives (from rescript-signals)

- **Signal**: Reactive state container - `Signal.make(value)`
- **Computed**: Derived reactive value that updates automatically - `Computed.make(() => ...)`
- **Effect**: Side-effect functions that re-run when dependencies change - `Effect.run(() => ...)`

All reactive primitives feature automatic dependency tracking - no manual subscriptions needed.

### Xote Features

- **Component**: Declarative UI builder with JSX syntax and function-based APIs
- **Router**: Signal-based navigation for SPAs with pattern matching and dynamic routes

### Component Features

- **JSX syntax**: Use HTML tags like `<div>`, `<button>`, `<input>`
- **Props**: Standard HTML attributes like `class`, `id`, `style`, `value`, `placeholder`
- **Event handlers**: `onClick`, `onInput`, `onChange`, `onSubmit`, etc.
- **Reactive content**: Wrap reactive text with `Component.textSignal(() => ...)`
- **Component functions**: Define reusable components as functions that return JSX

### Xote.Router Features

- **Initialization**: Call `Router.init()` once at app start
- **Imperative navigation**: Use `Router.push()` and `Router.replace()` to navigate programmatically
- **Declarative routing**: Define routes with `Router.routes()` and render components based on URL patterns
- **Dynamic parameters**: Extract URL parameters using `:param` syntax (e.g., `/users/:id`)
- **Navigation links**: Use `Router.link()` for SPA navigation without page reload
- **Reactive location**: Access current route via `Router.location` signal

## Examples

Check some examples of applications built with Xote at https://brnrdog.github.io/xote/demos/.

### Running Examples Locally

To run the example demos locally:

1. Clone the repository:
```bash
git clone https://github.com/brnrdog/xote.git
cd xote
```

2. Install dependencies:
```bash
npm install
```

3. Compile ReScript and start the dev server:
```bash
npm run res:dev  # In one terminal (watches ReScript files)
npm run dev      # In another terminal (starts Vite dev server)
```

4. Open your browser and navigate to `http://localhost:5173`

The demo app includes a navigation menu to explore all examples interactively.

## Documentation

Comprehensive documentation with live embedded demos is available at:

**https://brnrdog.github.io/xote/**


### Building Documentation Locally

To build and preview the documentation site:

```bash
npm run docs:start
```

This will build the demos and start the documentation server at `http://localhost:3000`.

## License

LGPL v3 
