---
sidebar_position: 3
---

# Effects

Effects are functions that **run side effects** in response to reactive state changes. They automatically re-execute when any signal they depend on changes.

## Creating Effects

Use `Effect.run()` to create an effect:

```rescript
open Xote

let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count is now:", Signal.get(count))
})
// Prints: "Count is now: 0"

Signal.set(count, 1)
// Prints: "Count is now: 1"
```

## How Effects Work

1. The effect function runs immediately when created
2. Any `Signal.get()` calls during execution are tracked as dependencies
3. When a dependency changes, the effect re-runs
4. Dependencies are **re-tracked** on every execution

## Common Use Cases

### DOM Updates

Effects are great for manual DOM manipulation:

```rescript
let color = Signal.make("red")

Effect.run(() => {
  let element = Document.getElementById("box")
  switch element {
  | Some(el) => el->Element.setStyle("backgroundColor", Signal.get(color))
  | None => ()
  }
})
```

### Logging and Debugging

Track state changes for debugging:

```rescript
let user = Signal.make({id: 1, name: "Alice"})

Effect.run(() => {
  let currentUser = Signal.get(user)
  Console.log2("User changed:", currentUser)
})
```

### Synchronization

Sync reactive state with external systems:

```rescript
let settings = Signal.make({theme: "dark", language: "en"})

Effect.run(() => {
  let current = Signal.get(settings)
  // Save to localStorage
  LocalStorage.setItem("settings", JSON.stringify(current))
})
```

## Disposing Effects

`Effect.run()` returns a disposer object with a `dispose()` method to stop the effect:

```rescript
let count = Signal.make(0)

let disposer = Effect.run(() => {
  Console.log(Signal.get(count))
})

Signal.set(count, 1) // Effect runs
Signal.set(count, 2) // Effect runs

disposer.dispose() // Stop the effect

Signal.set(count, 3) // Effect does NOT run
```

## Dynamic Dependencies

Effects re-track dependencies on each execution, adapting to conditional logic:

```rescript
let showDetails = Signal.make(false)
let name = Signal.make("Alice")
let age = Signal.make(30)

Effect.run(() => {
  Console.log(Signal.get(name))

  if Signal.get(showDetails) {
    Console.log2("Age:", Signal.get(age))
  }
})

// Initially depends on: name, showDetails
// After setting showDetails to true, depends on: name, showDetails, age
```

## Avoiding Dependencies

Use `Signal.peek()` or `Core.untrack()` to read signals without creating dependencies:

### Using `peek()`

```rescript
let count = Signal.make(0)
let debug = Signal.make(true)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))

  // Read debug flag without depending on it
  if Signal.peek(debug) {
    Console.log("Debug mode is on")
  }
})
```

### Using `untrack()`

```rescript
let count = Signal.make(0)
let logger = Signal.make(Console.log)

Effect.run(() => {
  let value = Signal.get(count)

  // Run code without tracking dependencies
  Core.untrack(() => {
    let logFn = Signal.get(logger)
    logFn(value)
  })
})
```

## Example: Auto-save

Here's a practical example of an auto-save effect:

```rescript
open Xote

type draft = {
  title: string,
  content: string,
}

let draft = Signal.make({
  title: "",
  content: "",
})

let saveStatus = Signal.make("Saved")

// Auto-save effect with debouncing
let timeoutId = ref(None)

Effect.run(() => {
  let current = Signal.get(draft)

  // Cancel previous timeout
  switch timeoutId.contents {
  | Some(id) => clearTimeout(id)
  | None => ()
  }

  Signal.set(saveStatus, "Unsaved changes...")

  // Save after 1 second of no changes
  timeoutId := Some(setTimeout(() => {
    // Save to server
    saveToServer(current)
    Signal.set(saveStatus, "Saved")
  }, 1000))
})
```

## Nested Effects

You can create effects inside other effects, but be careful:

```rescript
let outer = Signal.make(0)
let inner = Signal.make(0)

Effect.run(() => {
  Console.log2("Outer:", Signal.get(outer))

  // This creates a new effect each time outer changes!
  Effect.run(() => {
    Console.log2("Inner:", Signal.get(inner))
  })
})
```

**Tip**: Avoid creating effects inside effects unless you're cleaning them up properly. Usually, a single effect with multiple dependencies is clearer.

## Best Practices

1. **Keep effects focused**: Each effect should do one thing
2. **Clean up resources**: Use the disposer when effects are no longer needed
3. **Avoid infinite loops**: Don't set signals that the effect depends on
4. **Use for side effects only**: Effects should not compute values (use Computed instead)
5. **Handle errors**: Wrap effect code in try-catch if it might throw

## Common Pitfalls

### Infinite Loop

```rescript
// ❌ DON'T: Creates infinite loop
let count = Signal.make(0)

Effect.run(() => {
  Signal.update(count, n => n + 1) // Triggers itself!
})
```

### Not Disposing

```rescript
// ❌ DON'T: Creates memory leak in components
let createComponent = () => {
  Effect.run(() => {
    // ...
  })
  // Effect never cleaned up!
}
```

```rescript
// ✅ DO: Store and clean up disposers
let createComponent = () => {
  let disposer = Effect.run(() => {
    // ...
  })

  let cleanup = () => {
    disposer.dispose()
  }

  (component, cleanup)
}
```

## Effects vs Computed

| Feature | Effect | Computed |
|---------|--------|----------|
| Purpose | Side effects | Derive values |
| Returns | Disposer | Signal |
| When runs | Immediately and on changes | Immediately and on changes |
| Result | None (performs actions) | New reactive value |

Use **Computed** for pure calculations, **Effects** for side effects.

## Next Steps

- Learn about [Batching](/docs/core-concepts/batching) to optimize multiple updates
- See how effects work in [Components](/docs/components/overview)
- Check the [API Reference](/docs/api/effects) for complete details
