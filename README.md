# xote 
![NPM Version](https://img.shields.io/npm/v/xote)
![npm bundle size](https://img.shields.io/bundlephobia/min/xote)
![npm bundle size](https://img.shields.io/bundlephobia/minzip/xote)

Xote is a lightweight, zero-dependency library for ReScript with fine-grained reactivity based on the [TC39 Signals proposal](https://github.com/tc39/proposal-signals). With Xote, you can build reactive web applications with automatic dependency tracking and efficient updates.

## Features

- Zero dependencies: pure ReScript implementation
- Lightweight and efficient runtime (~12kb minified)
- Declarative components for building reactive UIs with JSX support
- Reactive primitives: signals, computed values, and effects
- Automatic dependency tracking: no manual subscription management
- Fine-grained updates: direct DOM updates without a virtual DOM
- Signal-based router: SPA navigation with pattern matching and dynamic parameters

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

## Philosophy

Xote focuses on clarity, control, and performance. It brings reactive programming to ReScript with minimal abstractions and no runtime dependencies. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM.

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

- **Signal**: Reactive state container
- **Computed**: Derived reactive value that updates automatically
- **Effect**: Side-effect functions that re-runs when dependencies change. Dependencies are automatically tracked, unlike React.
- **Component**: Declarative UI builder using ReScript functions
- **Router**: Signal-based navigation for single-page applications

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
