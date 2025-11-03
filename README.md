# xote 
[![npm version](https://img.shields.io/npm/v/xote.svg)](https://www.npmjs.com/package/xote)
[![bundle size](https://badgen.net/bundlephobia/min/xote)](https://bundlephobia.com/package/xote)

Xote (pronounced [ˈʃɔtʃi]) is a lightweight, zero-dependency UI library for ReScript with fine-grained reactivity based on the [TC39 Signals proposal](https://github.com/tc39/proposal-signals). Build reactive web applications with automatic dependency tracking and efficient updates.

## Features

- Zero dependencies: pure ReScript implementation
- Lightweight and efficient runtime
- Declarative components for building reactive UIs (JSX support comming up soon)
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

### Quick Example

```rescript
open Xote

// Create reactive state
let count = Signal.make(0)

// Event handler
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build the UI
let app = Component.div(
  ~children=[
    Component.h1(~children=[Component.text("Counter")], ()),
    Component.p(~children=[
      Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))
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
- **Router**: Signal-based navigation for single-page applications

### Component Features

- **Reactive text**: Use `textSignal(() => ...)` to create text nodes that update when signals change
- **Unified attributes**: Use `attr()`, `signalAttr()`, or `computedAttr()` helper functions to create static or reactive attributes
- **Reactive lists**: Use `list(signal, renderItem)` to render dynamic arrays
- **Event handlers**: Pass event listeners via the `~events` parameter

### Router Features

- **Initialization**: Call `Router.init()` once at app start
- **Imperative navigation**: Use `Router.push()` and `Router.replace()` to navigate programmatically
- **Declarative routing**: Define routes with `Router.routes()` and render components based on URL patterns
- **Dynamic parameters**: Extract URL parameters using `:param` syntax (e.g., `/users/:id`)
- **Navigation links**: Use `Router.link()` for SPA navigation without page reload
- **Reactive location**: Access current route via `Router.location` signal

## Examples

- [Counter](https://github.com/brnrdog/xote/blob/main/src/demo/CounterApp.res) - simple reactive counter with signals and event handlers
- [Todo List](https://github.com/brnrdog/xote/blob/main/src/demo/TodoApp.res) - complete todo app with filters, computed values, and reactive lists
- [Color Mixer](https://github.com/brnrdog/xote/blob/main/src/demo/ColorMixerApp.res) - RGB color mixing with live preview, format conversions, and palette variations
- [Reaction Game](https://github.com/brnrdog/xote/blob/main/src/demo/ReactionGame.res) - reflex testing game with timers, statistics, and computed averages
- [Solitaire](https://github.com/brnrdog/xote/blob/main/src/demo/SolitaireGame.res) - classic Klondike Solitaire with click-to-move gameplay and win detection
- [Router Demo](https://github.com/brnrdog/xote/blob/main/src/demo/RouterApp.res) - multi-page routing with dynamic parameters

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

## License

LGPL v3 
