---
sidebar_position: 4
---

# Batching Updates

By default, Xote runs effects and recomputes values **synchronously** when signals change. Batching allows you to group multiple updates and defer observer execution until the batch completes.

## Why Batch?

Without batching, each signal update triggers observers immediately:

```rescript
let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

Effect.run(() => {
  Console.log(Signal.get(fullName))
})

// Without batching
Signal.set(firstName, "Jane")  // Logs: "Jane Doe"
Signal.set(lastName, "Smith")  // Logs: "Jane Smith"
// Effect runs twice, computed recalculates twice
```

With batching, observers run once after all updates:

```rescript
Core.batch(() => {
  Signal.set(firstName, "Jane")  // Queued
  Signal.set(lastName, "Smith")  // Queued
})
// Logs: "Jane Smith" (only once)
// Effect runs once, computed recalculates once
```

## Using `Core.batch()`

Wrap multiple signal updates in a batch:

```rescript
open Xote

let x = Signal.make(0)
let y = Signal.make(0)

Effect.run(() => {
  Console.log2("Position:", (Signal.get(x), Signal.get(y)))
})

// Update both coordinates together
Core.batch(() => {
  Signal.set(x, 10)
  Signal.set(y, 20)
})
// Logs only once: "Position: (10, 20)"
```

## How Batching Works

1. When `Core.batch()` is called, Xote sets a batching flag
2. Signal updates queue their observers instead of running them immediately
3. When the batch function completes, all queued observers run
4. Each observer runs only once, even if multiple dependencies changed

## Example: Form Updates

Batching is especially useful when updating related state:

```rescript
type formData = {
  name: string,
  email: string,
  age: int,
}

let form = Signal.make({
  name: "",
  email: "",
  age: 0,
})

let errors = Computed.make(() => {
  let data = Signal.get(form)
  let errors = []

  if String.length(data.name) == 0 {
    errors->Array.push("Name is required")
  }
  if String.length(data.email) == 0 {
    errors->Array.push("Email is required")
  }
  if data.age < 18 {
    errors->Array.push("Must be 18 or older")
  }

  errors
})

// Update form fields together
let handleSubmit = () => {
  Core.batch(() => {
    Signal.update(form, f => {...f, name: "Alice"})
    Signal.update(form, f => {...f, email: "alice@example.com"})
    Signal.update(form, f => {...f, age: 25})
  })
  // Validation runs once after all updates
}
```

## Nested Batches

Batches can be nested. The observers run when the **outermost** batch completes:

```rescript
let count = Signal.make(0)

Effect.run(() => {
  Console.log(Signal.get(count))
})

Core.batch(() => {
  Signal.set(count, 1)

  Core.batch(() => {
    Signal.set(count, 2)
  })
  // No effect runs yet

  Signal.set(count, 3)
})
// Effect runs once: logs "3"
```

## Returning Values from Batches

`Core.batch()` returns the result of the batch function:

```rescript
let result = Core.batch(() => {
  Signal.set(count, 10)
  Signal.set(name, "Alice")
  "Success"
})

Console.log(result) // "Success"
```

## When to Use Batching

Use batching when:

- **Updating multiple related signals**: Form state, coordinates, settings
- **Performing complex state transitions**: Multi-step updates that should appear atomic
- **Optimizing performance**: Reducing unnecessary recomputations
- **Maintaining consistency**: Ensuring observers see a consistent state

Don't batch when:

- **Single signal updates**: No benefit from batching
- **Updates need to be visible immediately**: Rare, but sometimes intermediate states matter
- **Debugging**: Batching can make it harder to trace state changes

## Example: Animation

Batching is useful for coordinated updates in animations:

```rescript
let x = Signal.make(0)
let y = Signal.make(0)
let rotation = Signal.make(0)
let scale = Signal.make(1)

let animationFrame = () => {
  Core.batch(() => {
    Signal.update(x, v => v + 1)
    Signal.update(y, v => v + 2)
    Signal.update(rotation, v => v + 5)
    Signal.update(scale, v => v * 1.01)
  })
  // All transform properties update together
}

let intervalId = setInterval(animationFrame, 16) // ~60fps
```

## Performance Considerations

Batching provides benefits when:

1. Multiple signals feed into the same computed/effect
2. Computed values have expensive calculations
3. Effects perform costly side effects (DOM updates, network requests)

In simple cases, batching overhead might not be worth it:

```rescript
// Simple case: batching adds minimal benefit
let count = Signal.make(0)

Core.batch(() => {
  Signal.set(count, 1)
}) // Overhead not worth it for single update
```

## Best Practices

1. **Batch related updates**: Group changes that logically belong together
2. **Keep batches small**: Don't batch unrelated updates
3. **Batch at the right level**: Batch where updates originate, not deep in the stack
4. **Document batching**: Comment why batching is needed if it's not obvious

## Example: Shopping Cart

Here's a complete example showing effective batching:

```rescript
type item = {id: int, quantity: int}
type cart = {
  items: array<item>,
  discountCode: option<string>,
  shippingMethod: string,
}

let cart = Signal.make({
  items: [],
  discountCode: None,
  shippingMethod: "standard",
})

let addItem = (id: int, quantity: int) => {
  Core.batch(() => {
    Signal.update(cart, c => {
      ...c,
      items: Array.concat(c.items, [{id, quantity}])
    })

    // Clear discount if cart changes
    Signal.update(cart, c => {...c, discountCode: None})
  })
}

let applyDiscount = (code: string) => {
  Core.batch(() => {
    Signal.update(cart, c => {...c, discountCode: Some(code)})
    Signal.update(cart, c => {...c, shippingMethod: "express"})
  })
}
```

## Next Steps

- See how batching works with [Effects](/docs/core-concepts/effects)
- Learn about [Components](/docs/components/overview) which use batching internally
- Try the [Todo List Demo](/demos/todo) to see batching in a real application
