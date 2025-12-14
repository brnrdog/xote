# Computed Values

Computed values are derived signals that automatically recalculate when their dependencies change. They're perfect for deriving state from other reactive sources.

> **Info:** Xote re-exports `Computed` from [rescript-signals](https://github.com/pedrobslisboa/rescript-signals). The API and behavior are provided by that library.

Test

## Creating Computed Values

Use `Computed.make()` with a function that computes the derived value. It returns the computed signal:

```rescript
open Xote

let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// Automatically updates when firstName or lastName changes
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

// Read the computed value directly from the signal
Console.log(Signal.get(fullName)) // "John Doe"
```

## How Computed Values Work

Computed values are push-based (eager), not pull-based (lazy):

1. When created, the computation runs immediately to establish dependencies
2. When any dependency changes, the computed automatically recalculates
3. The new value is pushed to a backing signal
4. Any observers of the computed are notified

This means computed values are always up-to-date, but they may recalculate even if their value is never read.

## Reading Computed Values

Computed values return a signal that can be read with `Signal.get()`:

```rescript
let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // Prints: 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // Prints: 20
```

## Automatic Disposal

**Computed values automatically dispose when they lose all subscribers - you don't need to manually call Computed.dispose() in most cases!**

```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Create an effect that subscribes to doubled
let disposer = Effect.run(() => {
  Console.log(Signal.get(doubled))  // doubled has 1 subscriber
  None
})

Signal.set(count, 5)  // doubled recomputes and logs

// Dispose the effect
disposer.dispose()
// ↑ doubled now has 0 subscribers - automatically disposed! ✨

Signal.set(count, 10)
// doubled doesn't recompute anymore (it was auto-disposed)
```

This works seamlessly with Components:

```rescript
let app = () => {
  let count = Signal.make(0)
  let doubled = Computed.make(() => Signal.get(count) * 2)

  <div>
    {Component.textSignal(() => Signal.get(doubled)->Int.toString)}
  </div>
}

// When the component unmounts:
// 1. The textSignal effect is disposed
// 2. doubled loses its last subscriber
// 3. doubled is automatically disposed ✨
```

### Manual Disposal (Optional)

You can still manually dispose computeds when needed:

```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Use it...
Console.log(Signal.get(doubled))

// Manually dispose when done
Computed.dispose(doubled)
```

**Manual disposal is useful when:**

- You want explicit control over lifecycle
- The computed has no subscribers but you want to stop it anyway
- You're managing complex dependency graphs manually

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

Computed values re-track dependencies on every execution, so they adapt to control flow:

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

Console.log(Signal.get(temperature)) // 20

// Initially depends on: useMetric, celsius
Signal.set(useMetric, false)
// Now depends on: useMetric, fahrenheit
Console.log(Signal.get(temperature)) // 68
```

## Best Practices

- **Keep computations pure:** Computed functions should not have side effects
- **Use for derived state:** Any value that can be calculated from other signals should be a computed
- **Avoid expensive operations:** Computed values recalculate eagerly, so keep them fast
- **Don't nest effects:** Computed values should not call Effect.run() internally
- **Trust auto-disposal:** In most cases, computeds will automatically clean up when their subscribers are disposed. Manual disposal is rarely needed

## Important Notes

### Cascading Auto-Disposal

Auto-disposal can cascade through chains of computeds:

```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)
let quadrupled = Computed.make(() => Signal.get(doubled) * 2)

let disposer = Effect.run(() => {
  Console.log(Signal.get(quadrupled))
  None
})

// Dependency chain: count → doubled → quadrupled → effect

disposer.dispose()
// Effect disposed → quadrupled has 0 subscribers → auto-dispose quadrupled
// → doubled has 0 subscribers → auto-dispose doubled ✨
```

This ensures the entire chain is cleaned up automatically when the leaf subscriber is removed!

### Push-based, Not Lazy

Unlike some reactive systems, Xote's computed values are eager:

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

## Next Steps

- Learn about [Effects](/docs/core-concepts/effects) for side effects
- Understand [Batching](/docs/core-concepts/batching) for grouping updates
- See [Components](/docs/components/overview) to use computed values in UIs
