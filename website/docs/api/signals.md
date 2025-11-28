---
sidebar_position: 1
---

# Signal API Reference

Complete API documentation for Xote signals.

## Type

```rescript
type t<'a>
```

A signal is an opaque type representing a reactive state container. The type parameter `'a` is the type of value the signal holds.

## Functions

### `make`

```rescript
let make: 'a => t<'a>
```

Creates a new signal with an initial value.

**Parameters:**
- `initialValue: 'a` - The initial value for the signal

**Returns:**
- `t<'a>` - A new signal

**Example:**
```rescript
let count = Signal.make(0)
let name = Signal.make("Alice")
let items = Signal.make([1, 2, 3])
```

---

### `get`

```rescript
let get: t<'a> => 'a
```

Reads the current value from a signal. When called inside a tracking context (effect or computed), automatically registers the signal as a dependency.

**Parameters:**
- `signal: t<'a>` - The signal to read from

**Returns:**
- `'a` - The current value

**Example:**
```rescript
let count = Signal.make(5)
let value = Signal.get(count) // Returns 5

Effect.run(() => {
  // Creates a dependency on count
  Console.log(Signal.get(count))
})
```

**Note:** Always creates a dependency when called in a tracking context. Use `peek()` to read without tracking.

---

### `peek`

```rescript
let peek: t<'a> => 'a
```

Reads the current value from a signal **without** creating a dependency, even in tracking contexts.

**Parameters:**
- `signal: t<'a>` - The signal to read from

**Returns:**
- `'a` - The current value

**Example:**
```rescript
let count = Signal.make(5)

Effect.run(() => {
  // Does NOT create a dependency
  let value = Signal.peek(count)
  Console.log(value)
})

Signal.set(count, 10) // Effect will NOT re-run
```

**Use cases:**
- Reading signals in effects without creating dependencies
- Debugging (logging signal values without tracking)
- Reading configuration values that don't need to trigger updates

---

### `set`

```rescript
let set: (t<'a>, 'a) => unit
```

Sets a new value for the signal and notifies all dependent observers if the value has changed.

**Parameters:**
- `signal: t<'a>` - The signal to update
- `value: 'a` - The new value

**Returns:**
- `unit`

**Example:**
```rescript
let count = Signal.make(0)
Signal.set(count, 10) // count is now 10, observers notified

Signal.set(count, 10) // Same value - no notification
```

**Equality Check:** Uses structural equality (`!=`) to check if the value has changed. Only notifies dependent observers if the new value differs from the current value. This prevents unnecessary recomputations and helps avoid infinite loops when effects write back to their dependencies.

**Note:** The equality check uses ReScript's structural comparison, which works correctly for primitives, records, and arrays. For complex objects or when you need custom equality, consider using a different pattern.

---

### `update`

```rescript
let update: (t<'a>, 'a => 'a) => unit
```

Updates a signal's value based on its current value.

**Parameters:**
- `signal: t<'a>` - The signal to update
- `fn: 'a => 'a` - Function that receives the current value and returns the new value

**Returns:**
- `unit`

**Example:**
```rescript
let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2

let items = Signal.make([1, 2, 3])
Signal.update(items, arr => Array.concat(arr, [4, 5])) // [1, 2, 3, 4, 5]
```

**Note:** Equivalent to `Signal.set(signal, fn(Signal.get(signal)))` but more concise.

---

## Examples

### Basic Usage

```rescript
open Xote

let count = Signal.make(0)

// Read
Console.log(Signal.get(count)) // 0

// Update
Signal.set(count, 5)
Console.log(Signal.get(count)) // 5

// Update based on current value
Signal.update(count, n => n + 1)
Console.log(Signal.get(count)) // 6
```

### With Effects

```rescript
let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
})

Signal.set(count, 1) // Logs: "Count changed: 1"
Signal.set(count, 2) // Logs: "Count changed: 2"
```

### With Computed

```rescript
let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // 20
```

### Complex State

```rescript
type user = {
  id: int,
  name: string,
  email: string,
}

let user = Signal.make({
  id: 1,
  name: "Alice",
  email: "alice@example.com",
})

// Update specific fields
Signal.update(user, u => {...u, name: "Alice Smith"})
Signal.update(user, u => {...u, email: "alice.smith@example.com"})
```

### Array Operations

```rescript
let todos = Signal.make([])

// Add item
Signal.update(todos, arr => Array.concat(arr, ["Buy milk"]))

// Remove item
Signal.update(todos, arr => Array.filter(arr, item => item != "Buy milk"))

// Update item
Signal.update(todos, arr =>
  Array.map(arr, item =>
    item == "Buy milk" ? "Buy oat milk" : item
  )
)
```

## Notes

- Signals use structural equality checks - only notify dependents when the value actually changes
- Use `peek()` to avoid creating dependencies in effects
- Signals work with any type: primitives, records, arrays, etc.
- Signal updates are synchronous by default (use `Core.batch()` for grouping)
- The equality check prevents accidental infinite loops and unnecessary recomputations

## See Also

- [Signals Guide](/docs/core-concepts/signals) - Conceptual overview
- [Computed Guide](/docs/core-concepts/computed) - Derived values
- [Effects Guide](/docs/core-concepts/effects) - Side effects
- [Batching Guide](/docs/core-concepts/batching) - Batching and utilities
