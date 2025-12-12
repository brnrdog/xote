# Components Overview

Xote provides a lightweight component system for building reactive UIs. Components are functions that return virtual nodes, which are then rendered to the DOM.

Xote supports two syntax styles for building components:

- **JSX Syntax:** Modern, declarative JSX syntax (recommended)
- **Function API:** Explicit function calls with labeled parameters

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

## Text Nodes

### Static Text

Use `Component.text()` for static text:

```rescript
<div>
  {Component.text("This text never changes")}
</div>
```

### Reactive Text

Use `Component.textSignal()` for text that updates with signals:

```rescript
let count = Signal.make(0)

<div>
  {Component.textSignal(() =>
    "Count: " ++ Int.toString(Signal.get(count))
  )}
</div>
```

The function is tracked, so the text automatically updates when `count` changes.

## Attributes

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

### Reactive Attributes

Function API supports reactive attributes:

```rescript
let isActive = Signal.make(false)

Component.div(
  ~attrs=[
    Component.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
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
- `onFocus`, `onBlur` - Focus events
- `onKeyDown`, `onKeyUp` - Keyboard events

```rescript
let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

<button onClick={increment}>
  {Component.text("+1")}
</button>
```

## Lists

### Simple Lists (Non-Keyed)

Use `Component.list()` for simple lists where the entire list re-renders on any change:

```rescript
let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {Component.list(items, item =>
    <li> {Component.text(item)} </li>
  )}
</ul>
```

**Note:** Simple lists re-render completely when the array changes (no diffing). For better performance, use keyed lists.

### Keyed Lists (Efficient Reconciliation)

Use `Component.listKeyed()` for efficient list rendering with DOM element reuse:

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

**Benefits of keyed lists:**

- **Reuses DOM elements** - Only updates what changed
- **Preserves component state** - When list items move position
- **Better performance** - Fewer DOM operations for large lists
- **Efficient reconciliation** - Adds/removes/moves only necessary elements

**Best practices:**

- Always use unique, stable keys (like database IDs)
- Don't use array indices as keys
- Keys should be strings
- Use listKeyed for any list that can be reordered, filtered, or modified

## Mounting to the DOM

Use `mountById` to attach your component to an existing DOM element:

```rescript
let app = () => {
  <div> {Component.text("Hello, World!")} </div>
}

Component.mountById(app(), "app")
```

## Example: Counter Component

Here's a complete counter component using JSX:

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

## Best Practices

- **Keep components small:** Each component should do one thing well
- **Use signals for local state:** Create signals inside components for component-specific state
- **Pass data via props:** Use record types for component parameters
- **Compose components:** Build complex UIs from simple, reusable components
- **Choose the right list type:** Use `listKeyed` for dynamic lists, `list` for simple static lists
- **Use class not className:** In JSX, use the `class` prop for CSS classes

## Next Steps

- Try the [Demos](/demos) to see components in action
- Learn about [Routing](/docs/router/overview) for building SPAs
- Explore the [API Reference](/docs/api/signals) for detailed documentation
