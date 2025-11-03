---
sidebar_position: 1
---

# Signals

Signals are the foundation of Xote's reactive system. A signal is a **reactive state container** that automatically notifies its dependents when its value changes.

## Creating Signals

Use `Signal.make()` to create a new signal with an initial value:

```rescript
open Xote

let count = Signal.make(0)
let name = Signal.make("Alice")
let isActive = Signal.make(true)
```

## Reading Signal Values

### `Signal.get()`

Use `Signal.get()` to read a signal's value. When called inside a tracking context (like an effect or computed value), it automatically registers the signal as a dependency:

```rescript
let count = Signal.make(5)
let value = Signal.get(count) // Returns 5
```

### `Signal.peek()`

Use `Signal.peek()` to read a signal's value **without** creating a dependency:

```rescript
let count = Signal.make(5)

Effect.run(() => {
  // This creates a dependency
  let current = Signal.get(count)

  // This does NOT create a dependency
  let peeked = Signal.peek(count)

  Console.log2("Current:", current)
  Console.log2("Peeked:", peeked)
})
```

## Updating Signals

### `Signal.set()`

Replace a signal's value entirely:

```rescript
let count = Signal.make(0)
Signal.set(count, 10) // count is now 10
```

### `Signal.update()`

Update a signal based on its current value:

```rescript
let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2
```

## Important Behaviors

### Always Notifies

Signals **always notify** their dependents when `set` is called, even if the new value is the same as the old value. There's no built-in equality check:

```rescript
let count = Signal.make(5)

Effect.run(() => {
  Console.log(Signal.get(count))
})

Signal.set(count, 5) // Effect runs even though value didn't change
```

### Automatic Dependency Tracking

When you call `Signal.get()` inside a tracking context, the dependency is automatically registered:

```rescript
let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// This computed automatically depends on both firstName and lastName
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)
```

## Example: Counter

Here's a complete example showing signals in action:

```rescript
open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

let decrement = (_evt: Dom.event) => {
  Signal.update(count, n => n - 1)
}

let reset = (_evt: Dom.event) => {
  Signal.set(count, 0)
}

let app = Component.div(
  ~children=[
    Component.h1(~children=[
      Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))
    ], ()),
    Component.button(
      ~events=[("click", increment)],
      ~children=[Component.text("+")],
      ()
    ),
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
  ],
  ()
)

Component.mountById(app, "app")
```

## Best Practices

1. **Keep signals focused**: Each signal should represent a single piece of state
2. **Use `peek()` to avoid dependencies**: When you need to read a value without tracking, use `peek()`
3. **Prefer `update()` over `get() + set()`**: It's more concise and clearer in intent
4. **Group related updates**: Use `Core.batch()` when updating multiple signals at once (covered in [Batching](/docs/core-concepts/batching))

## Next Steps

- Learn about [Computed Values](/docs/core-concepts/computed) for derived state
- Understand [Effects](/docs/core-concepts/effects) for side effects
- See the [API Reference](/docs/api/signals) for complete signal API
