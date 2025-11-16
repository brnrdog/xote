---
sidebar_position: 1
---

# Components Overview

Xote provides a lightweight component system for building reactive UIs. Components are **functions that return virtual nodes**, which are then rendered to the DOM.

Xote supports **two syntax styles** for building components:
- **JSX Syntax**: Modern, declarative JSX syntax (recommended)
- **Function API**: Explicit function calls with labeled parameters

## What are Components?

In Xote, a component is simply a function that returns a `Component.node`:

### JSX Syntax

```rescript
open Xote

let greeting = () => {
  <div>
    <h1> {Component.text("Hello, Xote!")} </h1>
  </div>
}
```

### Function API

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

## JSX Configuration

To use JSX syntax, configure your `rescript.json`:

```json
{
  "jsx": {
    "version": 4,
    "module": "Xote__JSX"
  }
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

**JSX:**
```rescript
<div>
  {Component.text("This text never changes")}
</div>
```

**Function API:**
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

**JSX:**
```rescript
let count = Signal.make(0)

<div>
  {Component.textSignal(() =>
    "Count: " ++ Int.toString(Signal.get(count))
  )}
</div>
```

**Function API:**
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

Xote provides a unified attributes API with helper functions.

### JSX Props

JSX elements support common HTML attributes:
- `class` - CSS classes (note: `class`, not `className`)
- `id` - Element ID
- `style` - Inline styles
- `type_` - Input type (with underscore to avoid keyword conflict)
- `value` - Input value
- `placeholder` - Input placeholder
- `disabled` - Boolean disabled state
- `checked` - Boolean checked state
- `href` - Link URL
- `target` - Link target

**JSX Example:**
```rescript
<button
  class="btn btn-primary"
  type_="button"
  disabled={true}>
  {Component.text("Submit")}
</button>
```

### Static Attributes (Function API)

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

**JSX:**
```rescript
let isActive = Signal.make(false)
let activeClass = Computed.make(() =>
  Signal.get(isActive) ? "active" : "inactive"
)

<div class={Signal.peek(activeClass)}>
  {Component.text("Content")}
</div>
```

**Function API:**
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

**Function API:**
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

**Function API:**
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

### JSX Event Props

JSX elements support common event handlers:
- `onClick` - Click events
- `onInput` - Input events
- `onChange` - Change events
- `onSubmit` - Form submit events
- `onFocus` - Focus events
- `onBlur` - Blur events
- `onKeyDown` / `onKeyUp` - Keyboard events
- `onMouseEnter` / `onMouseLeave` - Mouse hover events

**JSX Example:**
```rescript
let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

<button onClick={increment}>
  {Component.text("+1")}
</button>
```

**Multiple events in JSX:**
```rescript
let handleClick = (_evt: Dom.event) => Console.log("Clicked")
let handleMouseEnter = (_evt: Dom.event) => Console.log("Hover")

<button
  onClick={handleClick}
  onMouseEnter={handleMouseEnter}>
  {Component.text("Hover me")}
</button>
```

### Function API

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

Xote provides two approaches for rendering lists:

### Simple Lists (Non-Keyed)

Use `Component.list()` for simple lists where the entire list re-renders on any change:

**JSX:**
```rescript
let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {Component.list(items, item =>
    <li> {Component.text(item)} </li>
  )}
</ul>
```

**Function API:**
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

**Note**: Simple lists re-render completely when the array changes (no diffing). For better performance, use keyed lists.

### Keyed Lists (Efficient Reconciliation)

Use `Component.listKeyed()` for efficient list rendering with DOM element reuse:

**JSX:**
```rescript
type todo = {id: int, text: string, completed: bool}
let todos = Signal.make([
  {id: 1, text: "Buy milk", completed: false},
  {id: 2, text: "Walk dog", completed: true},
])

<ul>
  {Component.listKeyed(
    todos,
    todo => todo.id->Int.toString,  // Key extractor
    todo => <li> {Component.text(todo.text)} </li>  // Renderer
  )}
</ul>
```

**Function API:**
```rescript
type todo = {id: int, text: string, completed: bool}
let todos = Signal.make([...])

Component.ul(
  ~children=[
    Component.listKeyed(
      todos,
      todo => todo.id->Int.toString,  // Key extractor
      todo => Component.li(
        ~children=[Component.text(todo.text)],
        ()
      )
    )
  ],
  ()
)
```

**Benefits of keyed lists:**
- **Reuses DOM elements** - Only updates what changed
- **Preserves component state** - When list items move position
- **Better performance** - Fewer DOM operations for large lists
- **Correct animations** - Essential for transitions and animations
- **Efficient reconciliation** - Adds/removes/moves only necessary elements

**Best practices:**
- Always use unique, stable keys (like database IDs)
- Don't use array indices as keys
- Keys should be strings
- Use `listKeyed` for any list that can be reordered, filtered, or modified

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

Here's a complete counter component using both syntaxes:

### JSX Version

```rescript
open Xote

type counterProps = {initialValue: int}

let counter = (props: counterProps) => {
  let count = Signal.make(props.initialValue)

  let increment = (_evt: Dom.event) => {
    Signal.update(count, n => n + 1)
  }

  let decrement = (_evt: Dom.event) => {
    Signal.update(count, n => n - 1)
  }

  <div class="counter">
    <h2>
      {Component.textSignal(() =>
        "Count: " ++ Int.toString(Signal.get(count))
      )}
    </h2>
    <div class="controls">
      <button onClick={decrement}>
        {Component.text("-")}
      </button>
      <button onClick={increment}>
        {Component.text("+")}
      </button>
    </div>
  </div>
}

// Use the component
let app = counter({initialValue: 10})
Component.mountById(app, "app")
```

### Function API Version

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

### JSX Version

```rescript
type buttonProps = {
  label: string,
  onClick: Dom.event => unit,
}

let button = (props: buttonProps) => {
  <button class="btn" onClick={props.onClick}>
    {Component.text(props.label)}
  </button>
}

let toolbar = () => {
  <div class="toolbar">
    {button({label: "Save", onClick: handleSave})}
    {button({label: "Cancel", onClick: handleCancel})}
  </div>
}
```

### Function API Version

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
3. **Pass data via parameters**:
   - JSX: Use record types for props
   - Function API: Use labeled parameters
4. **Compose components**: Build complex UIs from simple, reusable components
5. **Name components clearly**:
   - JSX: Use camelCase names (e.g., `todoItem`, `userProfile`)
   - Function API: Use camelCase or lowercase names
6. **Choose the right list type**:
   - Use `listKeyed` for dynamic lists that can change
   - Use `list` only for simple, static lists
7. **Use `class` not `className`**: In JSX, use the `class` prop for CSS classes
8. **Prefer JSX for new code**: JSX syntax is more concise and familiar to most developers

## Next Steps

- Try the [Counter Demo](/demos/counter) to see basic components in action
- Explore the [Todo List Demo](/demos/todo) for reactive lists and event handling
- Check out the [Color Mixer Demo](/demos/color-mixer) for complex reactive patterns
- View all [Examples](/demos) to see complete applications
