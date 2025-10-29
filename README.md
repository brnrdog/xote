# xote (pronounced [ˈʃɔtʃi])

A small, zero-dependency implementation of the TC39 Signals proposal written in ReScript. It provides a minimal reactive system similar to Solid.js or Preact Signals, but with ReScript types and a simple synchronous scheduler.

## Features

- Reactive primitives: signals, computed values, and effects
- Automatic dependency tracking
- Computed values are regular signals
- Support for untracked reads (`untrack`) and batching (`batch`)
- Implemented entirely in ReScript (no JS interop)

## Getting Started

Comming soon.

## API Overview

### Signal
```rescript
let count = Signal.make(0)
Signal.get(count) // => 0
Signal.set(count, 1)
Signal.update(count, n => n + 1)
```

### Computed
```rescript
let double = Computed.make(() => Signal.get(count) * 2)
```

### Effect
```rescript
let eff = Effect.run(() => {
  Js.log2("count:", Signal.get(count))
  Js.log2("double:", Signal.get(double))
})
```

### Utility functions
```rescript
untrack(() => Js.log2("peek double (no track)", Signal.peek(double)))

batch(() => {
  Signal.set(count, 10)
  Signal.set(count, 11)
})
```

## Example

```rescript
open Signals

let count = Signal.make(0)
let double = Computed.make(() => Signal.get(count) * 2)

let eff = Effect.run(() => {
  Js.log2("count:", Signal.get(count))
  Js.log2("double:", Signal.get(double))
})

Signal.set(count, 1)
Signal.update(count, n => n + 1)

batch(() => {
  Signal.set(count, 10)
  Signal.set(count, 11)
})
```

Output:
```
count: 0
double: 0
count: 1
double: 2
count: 2
double: 4
count: 11
double: 22
```

## Implementation Notes

- Dependencies are tracked automatically during reads.
- Computed signals are regular signals that update automatically.
- Effects and Computeds are observers stored in an internal dependency graph.
- Simple synchronous microtask-like scheduler.

## License

MIT © 2025
