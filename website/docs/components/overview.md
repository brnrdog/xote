---
sidebar_position: 1
---

# Components Overview

Xote provides a lightweight component system for building reactive UIs. Components are **functions that return virtual nodes**, which are then rendered to the DOM.

## What are Components?

In Xote, a component is simply a function that returns a `Component.node`:

```rescript
open Xote

let greeting = () => {
  Component.div(
    ~children=[
      Component.h1(~children=[Component.text("Hello, Xote!")], ())
    ],
    ()
  )
}
```

## Virtual Node Types

Xote uses several node types to represent UI elements:

- **Element**: Standard DOM elements (`div`, `button`, `input`, etc.)
- **Text**: Static text nodes
- **SignalText**: Reactive text that updates when signals change
- **Fragment**: Groups multiple nodes without a wrapper element
- **SignalFragment**: Reactive fragment that re-renders when a signal changes

## Creating Elements

Use helper functions for common HTML elements:

```rescript
Component.div(~attrs=?, ~events=?, ~children=?, ())
Component.button(~attrs=?, ~events=?, ~children=?, ())
Component.input(~attrs=?, ~events=?, ())
Component.h1(~attrs=?, ~children=?, ())
Component.p(~attrs=?, ~children=?, ())
// ... and many more
```

All elements accept optional parameters:
- `~attrs`: Array of attributes (static or reactive)
- `~events`: Array of event listeners
- `~children`: Array of child nodes

## Text Nodes

### Static Text

Use `Component.text()` for static text:

```rescript
Component.div(
  ~children=[
    Component.text("This text never changes")
  ],
  ()
)
```

### Reactive Text

Use `Component.textSignal()` for text that updates with signals:

```rescript
let count = Signal.make(0)

Component.div(
  ~children=[
    Component.textSignal(() =>
      "Count: " ++ Int.toString(Signal.get(count))
    )
  ],
  ()
)
```

The function is tracked, so the text automatically updates when `count` changes.

## Attributes

Xote provides a unified attributes API with helper functions:

### Static Attributes

```rescript
Component.button(
  ~attrs=[
    Component.attr("class", "btn btn-primary"),
    Component.attr("type", "button"),
    Component.attr("disabled", "true"),
  ],
  ()
)
```

### Reactive Attributes with Signals

```rescript
let isActive = Signal.make(false)

Component.div(
  ~attrs=[
    Component.signalAttr("class", isActive->Signal.map(active =>
      active ? "active" : "inactive"
    ))
  ],
  ()
)
```

### Reactive Attributes with Computed Functions

```rescript
let count = Signal.make(0)

Component.button(
  ~attrs=[
    Component.computedAttr("disabled", () =>
      Signal.get(count) >= 10 ? "true" : ""
    )
  ],
  ()
)
```

### Mixing Static and Reactive

```rescript
Component.button(
  ~attrs=[
    Component.attr("type", "button"),  // Static
    Component.computedAttr("class", () =>  // Reactive
      Signal.get(isActive) ? "active" : "inactive"
    ),
    Component.attr("aria-label", "Toggle"),  // Static
  ],
  ()
)
```

## Event Handlers

Attach DOM event listeners using the `~events` parameter:

```rescript
let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

Component.button(
  ~events=[("click", increment)],
  ~children=[Component.text("+1")],
  ()
)
```

Multiple events:

```rescript
let handleClick = (_evt: Dom.event) => Console.log("Clicked")
let handleMouseOver = (_evt: Dom.event) => Console.log("Hover")

Component.button(
  ~events=[
    ("click", handleClick),
    ("mouseover", handleMouseOver),
  ],
  ()
)
```

## Lists

Render arrays of data using `Component.list()`:

```rescript
let items = Signal.make(["Apple", "Banana", "Cherry"])

Component.ul(
  ~children=[
    Component.list(items, item =>
      Component.li(
        ~children=[Component.text(item)],
        ()
      )
    )
  ],
  ()
)
```

**Important**: Lists re-render completely when the array changes (no diffing). For better performance with large lists, consider keeping list items as separate signals.

## Fragments

Group nodes without adding a wrapper element:

```rescript
let header = () => {
  Component.fragment([
    Component.h1(~children=[Component.text("Title")], ()),
    Component.p(~children=[Component.text("Subtitle")], ()),
  ])
}
```

## Mounting to the DOM

Use `mountById` to attach your component to an existing DOM element:

```rescript
let app = Component.div(
  ~children=[Component.text("Hello, World!")],
  ()
)

Component.mountById(app, "app")
```

Or use `mount` with a DOM element:

```rescript
switch Document.getElementById("root") {
| Some(element) => Component.mount(app, element)
| None => Console.error("Root element not found")
}
```

## Example: Counter Component

Here's a complete counter component:

```rescript
open Xote

let counter = (~initialValue=0, ()) => {
  let count = Signal.make(initialValue)

  let increment = (_evt: Dom.event) => {
    Signal.update(count, n => n + 1)
  }

  let decrement = (_evt: Dom.event) => {
    Signal.update(count, n => n - 1)
  }

  Component.div(
    ~attrs=[Component.attr("class", "counter")],
    ~children=[
      Component.h2(~children=[
        Component.textSignal(() =>
          "Count: " ++ Int.toString(Signal.get(count))
        )
      ], ()),
      Component.div(
        ~attrs=[Component.attr("class", "controls")],
        ~children=[
          Component.button(
            ~events=[("click", decrement)],
            ~children=[Component.text("-")],
            ()
          ),
          Component.button(
            ~events=[("click", increment)],
            ~children=[Component.text("+")],
            ()
          ),
        ],
        ()
      ),
    ],
    ()
  )
}

// Use the component
let app = counter(~initialValue=10, ())
Component.mountById(app, "app")
```

## Component Composition

Build complex UIs by composing smaller components:

```rescript
let button = (~label, ~onClick, ()) => {
  Component.button(
    ~attrs=[Component.attr("class", "btn")],
    ~events=[("click", onClick)],
    ~children=[Component.text(label)],
    ()
  )
}

let toolbar = () => {
  Component.div(
    ~attrs=[Component.attr("class", "toolbar")],
    ~children=[
      button(~label="Save", ~onClick=handleSave, ()),
      button(~label="Cancel", ~onClick=handleCancel, ()),
    ],
    ()
  )
}
```

## Best Practices

1. **Keep components small**: Each component should do one thing well
2. **Use signals for local state**: Create signals inside components for component-specific state
3. **Pass data via parameters**: Use labeled parameters for component props
4. **Compose components**: Build complex UIs from simple, reusable components
5. **Name components clearly**: Use descriptive names that indicate what the component does

## Next Steps

- Try the [Counter Demo](/demos/counter) to see basic components in action
- Explore the [Todo List Demo](/demos/todo) for reactive lists and event handling
- Check out the [Color Mixer Demo](/demos/color-mixer) for complex reactive patterns
- View all [Examples](/demos) to see complete applications
