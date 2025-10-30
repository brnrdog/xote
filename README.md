# xote (pronounced [ˈʃɔtʃi])
[![npm version](https://img.shields.io/npm/v/xote.svg)](https://www.npmjs.com/package/xote)

A lightweight, zero-dependency UI library for ReScript with fine-grained reactivity based on the [TC39 Signals proposal](https://github.com/tc39/proposal-signals). Build reactive web applications with automatic dependency tracking and efficient updates.

## Features

- Zero dependencies: pure ReScript implementation
- Lightweight (~1kb) and efficient runtime
- Declarative components for building reactive UIs (JSX support comming up soon)
- Reactive primitives: signals, computed values, and effects
- Automatic dependency tracking: no manual subscription management
- Fine-grained updates: direct DOM updates without a virtual DOM

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

### Quick Example

```rescript
open Xote

// Create reactive state
let count = Signal.make(0)

// Derived value
let doubled = Computed.make(() => Signal.get(count) * 2)

// Event handler
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build the UI
let app = Component.div(
  ~children=[
    Component.h1(~children=[Component.text("Counter")], ()),
    Component.p(~children=[
      Component.textSignal(
        Computed.make(() => "Count: " ++ Int.toString(Signal.get(count)))
      )
    ], ()),
    Component.button(
      ~events=[("click", increment)],
      ~children=[Component.text("Increment")],
      ()
    )
  ],
  ()
)

// Mount to the DOM
Component.mountById(app, "app")
```

Classic counter: when you click the button, the counter updates reactively.

## Philosophy

Xote focuses on clarity, control, and performance. It brings reactive programming to ReScript with minimal abstractions and no runtime dependencies. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM.

## Core Concepts

- **Signal**: Reactive state container  
- **Computed**: Derived reactive value that updates automatically  
- **Effect**: Function that re-runs when dependencies change  
- **Component**: Declarative UI builder using ReScript functions  

For a more complete example, see the full [Todo App example](https://github.com/brnrdog/xote/blob/main/src/demo/TodoApp.res).



## License

MIT © 2025
