# rescript-signals

[![Release](https://github.com/brnrdog/rescript-signals/actions/workflows/release.yml/badge.svg)](https://github.com/brnrdog/rescript-signals/actions/workflows/release.yml)
[![npm version](https://badgen.net/npm/v/rescript-signals)](https://www.npmjs.com/package/rescript-signals)
[![bundlephobia](https://badgen.net/bundlephobia/minzip/rescript-signals)](https://bundlephobia.com/package/rescript-signals)

Lightweight, zero-dependency, signals primitives implemented in ReScript for fine-grained reactivity.

## Installation

```bash
npm install rescript-signals
```

Add to your `rescript.json`:

```json
{
  "dependencies": ["rescript-signals"]
}
```

## Usage

### Signal

Signals are reactive containers for values that notify dependents when changed.

```rescript
open Signals

// Create a signal
let count = Signal.make(0)

// Get the value (with tracking)
let value = Signal.get(count)

// Get the value (without tracking)
let value = Signal.peek(count)

// Set a new value
Signal.set(count, 1)

// Update with a function
Signal.update(count, n => n + 1)

// Custom equality function
let signal = Signal.make(0, ~equals=(a, b) => a == b)

// Named signal for debugging
let signal = Signal.make(0, ~name="counter")
```

### Computed

Computed signals automatically update when their dependencies change.

```rescript
open Signals

let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.peek(doubled)) // 10

Signal.set(count, 10)
Console.log(Signal.peek(doubled)) // 20

// Dispose when no longer needed
Computed.dispose(doubled)
```

### Effect

Effects run side effects in response to signal changes.

```rescript
open Signals

let count = Signal.make(0)

// Effect runs immediately and on signal changes
let disposer = Effect.run(() => {
  Console.log(`Count is: ${Int.toString(Signal.get(count))}`)
  None // or Some(cleanupFunction)
})

Signal.set(count, 1) // Logs: "Count is: 1"

// Dispose when done
disposer.dispose()
```

### Effect with Cleanup

```rescript
open Signals

let url = Signal.make("/api/data")

let disposer = Effect.run(() => {
  let currentUrl = Signal.get(url)

  // Start fetch
  fetchData(currentUrl)

  // Return cleanup function
  Some(() => {
    Console.log("Cleaning up previous fetch")
    cancelFetch(currentUrl)
  })
})

// Cleanup runs before re-executing and on disposal
Signal.set(url, "/api/other")
disposer.dispose()
```

## Features

- **Signals**: Reactive state containers
- **Computed**: Derived reactive values
- **Effects**: Side effects with automatic cleanup
- **Dependency Tracking**: Automatic tracking of signal dependencies
- **Fine-grained Reactivity**: Only affected computations re-run
- **Type-safe**: Full ReScript type safety

## API Reference

### Signal

```rescript
type t<'a>

let make: ('a, ~name: option<string>=?, ~equals: option<('a, 'a) => bool>=?) => t<'a>
let get: t<'a> => 'a
let peek: t<'a> => 'a
let set: (t<'a>, 'a) => unit
let update: (t<'a>, 'a => 'a) => unit
```

### Computed

```rescript
let make: (unit => 'a) => Signal.t<'a>
let dispose: Signal.t<'a> => unit
```

### Effect

```rescript
type disposer = {dispose: unit => unit}

let run: (unit => option<unit => unit>) => disposer
```

## Development

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup and guidelines.

### Running Tests

```bash
npm test
```

### Building

```bash
npm run build
```

### Watching for Changes

```bash
npm run watch
```

## License

See [LICENSE](LICENSE) for details.