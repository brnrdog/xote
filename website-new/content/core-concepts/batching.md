# Batching Updates

Batching allows you to group multiple signal updates together, ensuring that observers (effects and computed values) run only once after all updates complete, rather than after each individual update.

> **Info:** Batching is available through `Signal.batch` which is re-exported from [rescript-signals](https://github.com/pedrobslisboa/rescript-signals).

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
  None
})

// Without batching
Signal.set(firstName, "Jane")  // Logs: "Jane Doe"
Signal.set(lastName, "Smith")  // Logs: "Jane Smith"
// Effect runs twice, computed recalculates twice
```

With batching, observers run once after all updates:

```rescript
Signal.batch(() => {
  Signal.set(firstName, "Jane")  // Queued
  Signal.set(lastName, "Smith")  // Queued
})
// Logs: "Jane Smith" (only once)
// Effect runs once, computed recalculates once
```

## Using Signal.batch()

Wrap multiple signal updates in a batch:

```rescript
open Xote

let x = Signal.make(0)
let y = Signal.make(0)

Effect.run(() => {
  Console.log2("Position:", (Signal.get(x), Signal.get(y)))
  None
})

// Update both coordinates together
Signal.batch(() => {
  Signal.set(x, 10)
  Signal.set(y, 20)
})
// Logs only once: "Position: (10, 20)"
```

## How Batching Works

1. When Signal.batch() is called, a batching flag is set
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
  Signal.batch(() => {
    Signal.update(form, f => {...f, name: "Alice"})
    Signal.update(form, f => {...f, email: "alice@example.com"})
    Signal.update(form, f => {...f, age: 25})
  })
  // Validation runs once after all updates
}
```

## Nested Batches

Batches can be nested. The observers run when the outermost batch completes:

```rescript
let count = Signal.make(0)

Effect.run(() => {
  Console.log(Signal.get(count))
  None
})

Signal.batch(() => {
  Signal.set(count, 1)

  Signal.batch(() => {
    Signal.set(count, 2)
  })
  // No effect runs yet

  Signal.set(count, 3)
})
// Effect runs once: logs "3"
```

## Returning Values from Batches

`Signal.batch()` returns the result of the batch function:

```rescript
let result = Signal.batch(() => {
  Signal.set(count, 10)
  Signal.set(name, "Alice")
  "Success"
})

Console.log(result) // "Success"
```

## When to Use Batching

Use batching when:

- **Updating multiple related signals:** Form state, coordinates, settings
- **Performing complex state transitions:** Multi-step updates that should appear atomic
- **Optimizing performance:** Reducing unnecessary recomputations
- **Maintaining consistency:** Ensuring observers see a consistent state

Don't batch when:

- **Single signal updates:** No benefit from batching
- **Updates need to be visible immediately:** Rare, but sometimes intermediate states matter
- **Debugging:** Batching can make it harder to trace state changes

## Example: Animation

Batching is useful for coordinated updates in animations:

```rescript
let x = Signal.make(0)
let y = Signal.make(0)
let rotation = Signal.make(0)
let scale = Signal.make(1.0)

let animationFrame = () => {
  Signal.batch(() => {
    Signal.update(x, v => v + 1)
    Signal.update(y, v => v + 2)
    Signal.update(rotation, v => v + 5)
    Signal.update(scale, v => v *. 1.01)
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

Signal.batch(() => {
  Signal.set(count, 1)
}) // Overhead not worth it for single update
```

## Best Practices

- **Batch related updates:** Group changes that logically belong together
- **Keep batches small:** Don't batch unrelated updates
- **Batch at the right level:** Batch where updates originate, not deep in the stack
- **Document batching:** Comment why batching is needed if it's not obvious

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
  Signal.batch(() => {
    Signal.update(cart, c => {
      ...c,
      items: Array.concat(c.items, [{id, quantity}])
    })

    // Clear discount if cart changes
    Signal.update(cart, c => {...c, discountCode: None})
  })
}

let applyDiscount = (code: string) => {
  Signal.batch(() => {
    Signal.update(cart, c => {...c, discountCode: Some(code)})
    Signal.update(cart, c => {...c, shippingMethod: "express"})
  })
}
```

## Next Steps

- See how batching works with [Effects](/docs/core-concepts/effects)
- Learn about [Components](/docs/components/overview) which benefit from batching
- Try the [Demos](/demos) to see batching in action
