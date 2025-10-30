# xote (pronounced [ˈʃɔtʃi])

A lightweight, zero-dependency UI library for ReScript with fine-grained reactivity powered by signals. Build reactive web applications with automatic dependency tracking and efficient updates.

## Features

- **Zero dependencies** - No runtime dependencies, pure ReScript implementation
- **Reactive primitives** - Signals, computed values, and effects
- **Component system** - Declarative UI components with automatic reactive updates
- **Automatic dependency tracking** - No manual subscription management
- **Batching and control** - Support for untracked reads and batched updates
- **Lightweight** - Small bundle size, minimal overhead

## Getting Started

Comming soon.

### Installation

Comming soon.

### Quick Example

```rescript
open Xote

// Create reactive state
let count = Signal.make(0)

// Create computed values
let doubled = Computed.make(() => Signal.get(count) * 2)

// Define event handlers
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build your UI
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

// Mount to DOM
Component.mountById(app, "app")
```

## API Reference

### Signals - Reactive State

Signals are the foundation of reactive state management in Xote.

```rescript
// Create a signal with initial value
let count = Signal.make(0)

// Read signal value (tracks dependencies)
let value = Signal.get(count) // => 0

// Read without tracking
let value = Signal.peek(count) // => 0

// Update signal value
Signal.set(count, 1)

// Update with a function
Signal.update(count, n => n + 1)
```

### Computed - Derived State

Computed values automatically update when their dependencies change.

```rescript
let count = Signal.make(5)

// Computed values are signals that derive from other signals
let doubled = Computed.make(() => Signal.get(count) * 2)

Signal.get(doubled) // => 10

Signal.set(count, 10)
Signal.get(doubled) // => 20
```

### Effects - Side Effects

Effects run automatically when their dependencies change.

```rescript
let count = Signal.make(0)

// Effect runs immediately and re-runs when count changes
let disposer = Effect.run(() => {
  Console.log("Count is now: " ++ Int.toString(Signal.get(count)))
})

Signal.set(count, 1) // Logs: "Count is now: 1"

// Clean up effect
disposer.dispose()
```

### Components - Building UI

#### Basic Elements

```rescript
// Text nodes
Component.text("Hello, world!")

// Reactive text from signals
let name = Signal.make("Alice")
Component.textSignal(
  Computed.make(() => "Hello, " ++ Signal.get(name))
)

// HTML elements
Component.div(
  ~attrs=[("class", "container"), ("id", "main")],
  ~events=[("click", handleClick)],
  ~children=[
    Component.h1(~children=[Component.text("Title")], ()),
    Component.p(~children=[Component.text("Content")], ())
  ],
  ()
)
```

#### Reactive Lists

Render lists that automatically update when data changes:

```rescript
let todos = Signal.make([
  {id: 1, text: "Learn Xote"},
  {id: 2, text: "Build an app"}
])

let todoItem = (todo) => {
  Component.li(~children=[Component.text(todo.text)], ())
}

Component.ul(
  ~children=[Component.list(todos, todoItem)],
  ()
)
// List updates automatically when todos signal changes!
```

#### Event Handling

```rescript
let handleClick = (evt: Dom.event) => {
  Console.log("Clicked!")
}

Component.button(
  ~events=[("click", handleClick), ("mouseenter", handleHover)],
  ~children=[Component.text("Click me")],
  ()
)
```

### Utilities

#### Untracked Reads

Read signals without creating dependencies.

```rescript
Core.untrack(() => {
  let value = Signal.get(count) // Won't track this read
  Console.log(value)
})
```

#### Batching Updates

Group multiple updates to run effects only once.

```rescript
Core.batch(() => {
  Signal.set(count1, 10)
  Signal.set(count2, 20)
  Signal.set(count3, 30)
})
// Effects run once after all updates
```

## Complete Example

### Counter Application

```rescript
open Xote

// State management
let counterValue = Signal.make(0)

// Derived state
let counterDisplay = Computed.make(() =>
  "Count: " ++ Int.toString(Signal.get(counterValue))
)

let isEven = Computed.make(() =>
  mod(Signal.get(counterValue), 2) == 0
)

// Event handlers
let increment = (_evt: Dom.event) => {
  Signal.update(counterValue, n => n + 1)
}

let decrement = (_evt: Dom.event) => {
  Signal.update(counterValue, n => n - 1)
}

let reset = (_evt: Dom.event) => {
  Signal.set(counterValue, 0)
}

// Side effects
let _ = Effect.run(() => {
  Console.log("Counter changed: " ++ Int.toString(Signal.get(counterValue)))
})

// UI Component
let app = Component.div(
  ~attrs=[("class", "app")],
  ~children=[
    Component.h1(~children=[Component.text("Xote Counter")], ()),

    Component.div(
      ~attrs=[("class", "counter-display")],
      ~children=[
        Component.h2(~children=[Component.textSignal(counterDisplay)], ()),
        Component.p(~children=[
          Component.textSignal(
            Computed.make(() =>
              Signal.get(isEven) ? "Even" : "Odd"
            )
          )
        ], ())
      ],
      ()
    ),

    Component.div(
      ~attrs=[("class", "controls")],
      ~children=[
        Component.button(
          ~events=[("click", decrement)],
          ~children=[Component.text("-")],
          ()
        ),
        Component.button(
          ~events=[("click", reset)],
          ~children=[Component.text("Reset")],
          ()
        ),
        Component.button(
          ~events=[("click", increment)],
          ~children=[Component.text("+")],
          ()
        )
      ],
      ()
    )
  ],
  ()
)

// Mount to DOM
Component.mountById(app, "app")
```

## How It Works

### Reactive System

- **Automatic dependency tracking** - When you read a signal with `Signal.get()` inside a computed or effect, it automatically tracks that dependency
- **Fine-grained updates** - Only the specific computeds and effects that depend on changed signals are re-executed
- **Synchronous by default** - Updates happen immediately and synchronously for predictable behavior
- **Batching support** - Group multiple updates to minimize re-computation

### Component Rendering

- **Initial render** - Components are rendered to real DOM elements on mount
- **Reactive text** - `textSignal()` creates text nodes that automatically update when their signal changes
- **Reactive lists** - `Component.list()` creates lists that automatically update when data changes
- **Direct DOM manipulation** - No virtual DOM diffing, updates are precise and efficient
- **Effect-based** - Signal changes trigger effects that update specific DOM nodes automatically

## Best Practices

1. **Keep signals at the top level** - Define signals outside component definitions for proper reactivity
2. **Use computed for derived state** - Don't repeat calculations, use `Computed.make()`
3. **Use `Component.list()` for reactive arrays** - Let the framework handle list updates automatically
4. **Batch related updates** - Use `Core.batch()` when updating multiple signals together
5. **Dispose effects when done** - Call `disposer.dispose()` for effects you no longer need
6. **Use `peek()` when you don't want tracking** - Read signal values without creating dependencies

## License

MIT © 2025
