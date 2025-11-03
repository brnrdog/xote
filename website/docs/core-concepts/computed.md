---
sidebar_position: 2
---

# Computed Values

Computed values are **derived signals** that automatically recalculate when their dependencies change. They're perfect for deriving state from other reactive sources.

## Creating Computed Values

Use `Computed.make()` with a function that computes the derived value:

```rescript
open Xote

let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// Automatically updates when firstName or lastName changes
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)
```

## How Computed Values Work

Computed values are **push-based** (eager), not pull-based (lazy):

1. When created, the computation runs immediately to establish dependencies
2. When any dependency changes, the computed **automatically recalculates**
3. The new value is pushed to a backing signal
4. Any observers of the computed are notified

This means computed values are **always up-to-date**, but they may recalculate even if their value is never read.

## Reading Computed Values

Computed values return a signal, so you read them using `Signal.get()`:

```rescript
let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // Prints: 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // Prints: 20
```

## Chaining Computed Values

You can create computed values that depend on other computed values:

```rescript
let price = Signal.make(100)
let quantity = Signal.make(3)

let subtotal = Computed.make(() =>
  Signal.get(price) * Signal.get(quantity)
)

let tax = Computed.make(() =>
  Signal.get(subtotal) * 0.1
)

let total = Computed.make(() =>
  Signal.get(subtotal) + Signal.get(tax)
)

Console.log(Signal.get(total)) // 330

Signal.set(quantity, 5)
Console.log(Signal.get(total)) // 550
```

## Example: Shopping Cart

Here's a practical example using computed values:

```rescript
open Xote

type item = {
  name: string,
  price: float,
  quantity: int,
}

let items = Signal.make([
  {name: "Apple", price: 1.50, quantity: 3},
  {name: "Banana", price: 0.75, quantity: 5},
])

let subtotal = Computed.make(() => {
  Signal.get(items)
  ->Array.reduce(0.0, (acc, item) => {
    acc +. item.price *. Int.toFloat(item.quantity)
  })
})

let tax = Computed.make(() => Signal.get(subtotal) *. 0.08)

let total = Computed.make(() => Signal.get(subtotal) +. Signal.get(tax))

let app = Component.div(
  ~children=[
    Component.h1(~children=[Component.text("Shopping Cart")], ()),
    Component.list(items, item =>
      Component.div(
        ~children=[
          Component.text(
            item.name ++ " - $" ++
            Float.toString(item.price) ++ " x " ++
            Int.toString(item.quantity)
          )
        ],
        ()
      )
    ),
    Component.div(~children=[
      Component.textSignal(() =>
        "Subtotal: $" ++ Float.toString(Signal.get(subtotal))
      )
    ], ()),
    Component.div(~children=[
      Component.textSignal(() =>
        "Tax: $" ++ Float.toString(Signal.get(tax))
      )
    ], ()),
    Component.div(~children=[
      Component.textSignal(() =>
        "Total: $" ++ Float.toString(Signal.get(total))
      )
    ], ()),
  ],
  ()
)

Component.mountById(app, "app")
```

## Computed vs Manual Updates

Instead of manually updating derived state:

```rescript
// ❌ Manual (error-prone)
let count = Signal.make(0)
let doubled = Signal.make(0)

let increment = () => {
  Signal.update(count, n => n + 1)
  Signal.set(doubled, Signal.get(count) * 2) // Easy to forget!
}
```

Use computed values for automatic updates:

```rescript
// ✅ Automatic (safe)
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

let increment = () => {
  Signal.update(count, n => n + 1)
  // doubled automatically updates!
}
```

## Dynamic Dependencies

Computed values **re-track** dependencies on every execution, so they adapt to control flow:

```rescript
let useMetric = Signal.make(true)
let celsius = Signal.make(20)
let fahrenheit = Signal.make(68)

let temperature = Computed.make(() => {
  if Signal.get(useMetric) {
    Signal.get(celsius)
  } else {
    Signal.get(fahrenheit)
  }
})

// Initially depends on: useMetric, celsius
Signal.set(useMetric, false)
// Now depends on: useMetric, fahrenheit
```

## Best Practices

1. **Keep computations pure**: Computed functions should not have side effects
2. **Use for derived state**: Any value that can be calculated from other signals should be a computed
3. **Avoid expensive operations**: Computed values recalculate eagerly, so keep them fast
4. **Don't nest effects**: Computed values should not call `Effect.run()` internally

## Important Notes

### Push-based, Not Lazy

Unlike some reactive systems, Xote's computed values are **eager**:

```rescript
let count = Signal.make(0)
let expensive = Computed.make(() => {
  Console.log("Computing...")
  Signal.get(count) * 2
})

// "Computing..." is logged immediately

Signal.set(count, 5)
// "Computing..." is logged again, even if we never read 'expensive'
```

This ensures computed values are always current but may do unnecessary work if the computed is never observed.

## Next Steps

- Learn about [Effects](/docs/core-concepts/effects) for side effects
- Understand [Batching](/docs/core-concepts/batching) for grouping updates
- Try the [Color Mixer Demo](/demos/color-mixer) to see computed values in action
