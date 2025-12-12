# Effects

Effects are functions that run side effects in response to reactive state changes. They automatically re-execute when any signal they depend on changes.

> **Info:** Xote re-exports `Effect` from [rescript-signals](https://github.com/pedrobslisboa/rescript-signals). The API and behavior are provided by that library.

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
2. Any Signal.get() calls during execution are tracked as dependencies
3. When a dependency changes, the effect re-runs
4. Dependencies are re-tracked on every execution
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

- Return None when no cleanup is needed
- Return Some(cleanupFn) to register cleanup
- Cleanup runs before the effect re-executes
- Cleanup runs when the effect is disposed via dispose()
- Cleanup is useful for canceling requests, clearing timers, removing event listeners, etc.

## Common Use Cases

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

## Disposing Effects

Effect.run() returns a disposer object with a dispose() method to stop the effect. When disposed, any registered cleanup function is called:

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

Use `Signal.peek()` to read signals without creating dependencies:

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

## Best Practices

- **Keep effects focused:** Each effect should do one thing
- **Clean up resources:** Return cleanup functions for timers, listeners, subscriptions, etc.
- **Dispose effects:** Use the disposer when effects are no longer needed (e.g., component unmount)
- **Avoid infinite loops:** Don't set signals that the effect depends on (unless using equality checks)
- **Use for side effects only:** Effects should not compute values (use Computed instead)
- **Return None when no cleanup needed:** Be explicit about cleanup needs

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
- Try the [Demos](/demos) to see effects in action
