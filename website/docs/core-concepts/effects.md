---
sidebar_position: 3
---

# Effects

Effects are functions that **run side effects** in response to reactive state changes. They automatically re-execute when any signal they depend on changes.

## Creating Effects

Use `Effect.run()` to create an effect. The effect function can optionally return a cleanup function:

```rescript
open Xote

let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count is now:", Signal.get(count))
  None // No cleanup needed
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
5. If a cleanup function was returned, it runs before re-execution

## Cleanup Callbacks

Effects can return an optional cleanup function that runs before the effect re-executes or when the effect is disposed:

```rescript
open Xote

let url = Signal.make("https://api.example.com/data")

Effect.run(() => {
  let currentUrl = Signal.get(url)
  Console.log2("Fetching:", currentUrl)

  // Simulate an API call with AbortController
  let controller = AbortController.make()

  fetch(currentUrl, {signal: controller.signal})
    ->Promise.then(response => {
      Console.log("Data received")
      Promise.resolve()
    })
    ->ignore

  // Return cleanup function
  Some(() => {
    Console.log("Aborting previous request")
    controller.abort()
  })
})

// When url changes, the cleanup function runs first,
// then the effect re-executes with the new URL
Signal.set(url, "https://api.example.com/other-data")
```

**Key points about cleanup:**
- Return `None` when no cleanup is needed
- Return `Some(cleanupFn)` to register cleanup
- Cleanup runs **before** the effect re-executes
- Cleanup runs when the effect is disposed via `dispose()`
- Cleanup is useful for canceling requests, clearing timers, removing event listeners, etc.

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
  None // No cleanup needed
})
```

### Logging and Debugging

Track state changes for debugging:

```rescript
let user = Signal.make({id: 1, name: "Alice"})

Effect.run(() => {
  let currentUser = Signal.get(user)
  Console.log2("User changed:", currentUser)
  None // No cleanup needed
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
  None // No cleanup needed
})
```

### Event Listeners with Cleanup

Use cleanup to properly remove event listeners:

```rescript
let activeElement = Signal.make("button1")

Effect.run(() => {
  let elementId = Signal.get(activeElement)

  switch Document.getElementById(elementId) {
  | Some(element) => {
      let handler = _evt => Console.log("Clicked!")
      element->Element.addEventListener("click", handler)

      // Clean up listener when effect re-runs or disposes
      Some(() => {
        element->Element.removeEventListener("click", handler)
      })
    }
  | None => None
  }
})
```

### Timers with Cleanup

Properly clean up timers:

```rescript
let interval = Signal.make(1000)

Effect.run(() => {
  let ms = Signal.get(interval)

  let timerId = setInterval(() => {
    Console.log("Tick")
  }, ms)

  // Clear timer when interval changes or effect disposes
  Some(() => {
    clearInterval(timerId)
  })
})
```

## Disposing Effects

`Effect.run()` returns a disposer object with a `dispose()` method to stop the effect. When disposed, any registered cleanup function is called:

```rescript
let count = Signal.make(0)

let disposer = Effect.run(() => {
  Console.log(Signal.get(count))
  None // No cleanup needed
})

Signal.set(count, 1) // Effect runs
Signal.set(count, 2) // Effect runs

disposer.dispose() // Stop the effect

Signal.set(count, 3) // Effect does NOT run
```

**With cleanup:**

```rescript
let disposer = Effect.run(() => {
  let timerId = setInterval(() => Console.log("Tick"), 1000)

  // Cleanup function
  Some(() => {
    clearInterval(timerId)
    Console.log("Timer cleared")
  })
})

// Later...
disposer.dispose() // Runs cleanup, prints "Timer cleared"
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

  None // No cleanup needed
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

  None // No cleanup needed
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

  None // No cleanup needed
})
```

## Example: Auto-save

Here's a practical example of an auto-save effect with proper cleanup:

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

// Auto-save effect with debouncing and cleanup
Effect.run(() => {
  let current = Signal.get(draft)

  Signal.set(saveStatus, "Unsaved changes...")

  // Save after 1 second of no changes
  let timeoutId = setTimeout(() => {
    // Save to server
    saveToServer(current)
    Signal.set(saveStatus, "Saved")
  }, 1000)

  // Clean up timeout when draft changes again
  Some(() => {
    clearTimeout(timeoutId)
  })
})
```

**Benefits of this approach:**
- No need for external mutable refs
- Timeout is automatically canceled when draft changes
- Cleanup runs when effect is disposed
- More declarative and easier to understand

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
    None
  })

  None
})
```

**Better approach with cleanup:**

```rescript
Effect.run(() => {
  Console.log2("Outer:", Signal.get(outer))

  // Create nested effect and clean it up
  let innerDisposer = Effect.run(() => {
    Console.log2("Inner:", Signal.get(inner))
    None
  })

  // Clean up nested effect when outer changes
  Some(() => {
    innerDisposer.dispose()
  })
})
```

**Tip**: Avoid creating effects inside effects unless you're cleaning them up properly. Usually, a single effect with multiple dependencies is clearer.

## Best Practices

1. **Keep effects focused**: Each effect should do one thing
2. **Clean up resources**: Return cleanup functions for timers, listeners, subscriptions, etc.
3. **Dispose effects**: Use the disposer when effects are no longer needed (e.g., component unmount)
4. **Avoid infinite loops**: Don't set signals that the effect depends on (unless using equality checks)
5. **Use for side effects only**: Effects should not compute values (use Computed instead)
6. **Handle errors**: Wrap effect code in try-catch if it might throw
7. **Return None when no cleanup needed**: Be explicit about cleanup needs

## Common Pitfalls

### Infinite Loop (Mitigated)

```rescript
// ⚠️ CAUTION: This would infinite loop without equality checks
let count = Signal.make(0)

Effect.run(() => {
  Signal.set(count, Signal.get(count) + 1) // Triggers itself!
  None
})

// However, setting to the same value is now safe:
Effect.run(() => {
  Signal.set(count, Signal.get(count)) // Does NOT trigger - equality check prevents this
  None
})
```

**Note**: Xote now includes an equality check in `Signal.set`, so setting a signal to its current value won't trigger notifications. This prevents many accidental infinite loops.

### Not Disposing

```rescript
// ❌ DON'T: Creates memory leak in components
let createComponent = () => {
  Effect.run(() => {
    // ...
    None
  })
  // Effect never cleaned up!
}
```

```rescript
// ✅ DO: Store and clean up disposers
let createComponent = () => {
  let disposer = Effect.run(() => {
    // ...
    None
  })

  let cleanup = () => {
    disposer.dispose()
  }

  (component, cleanup)
}
```

### Not Cleaning Up Resources

```rescript
// ❌ DON'T: Forget cleanup
Effect.run(() => {
  let timerId = setInterval(() => Console.log("Tick"), 1000)
  None // Timer never cleared!
})
```

```rescript
// ✅ DO: Return cleanup function
Effect.run(() => {
  let timerId = setInterval(() => Console.log("Tick"), 1000)
  Some(() => clearInterval(timerId))
})
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
- Try the [Reaction Game Demo](/demos/reaction-game) to see effects with timers
