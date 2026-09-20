/***
Side effects that re-run when their dependencies change.

An effect runs once immediately, subscribing to every signal it reads, then
re-runs whenever any of them changes. The body returns `Some(cleanup)` to
register teardown that runs before the next execution and on disposal, or
`None` when there is nothing to clean up.

## Examples

```rescript
let query = Signal.make("xote")

Effect.run(() => {
  let id = setTimeout(() => Console.log("searching " ++ Signal.get(query)), 300)
  Some(() => clearTimeout(id))
})

Signal.set(query, "rescript") // cleanup runs, then the body re-runs
```
*/

/**
Handle returned by `runWithDisposer`, used to tear an effect down by hand.

Calling `dispose` runs the effect's pending cleanup and unsubscribes it from
its dependencies. Calling it more than once is safe.
*/
type disposer = {dispose: unit => unit}

/**
Runs `effect` immediately and again whenever a signal it read changes.

Fire-and-forget: the effect lives until its owner is disposed, which for an
effect created inside a component means when that component is removed. Use
`runWithDisposer` when there is no owner to tie it to. `~name` is a debugging
label surfaced in development warnings.

## Examples

```rescript
let count = Signal.make(0)

// No cleanup needed.
Effect.run(() => {
  Console.log2("count:", Signal.get(count))
  None
})

// With cleanup, run before every re-execution and on disposal.
let enabled = Signal.make(true)
Effect.run(() => {
  if Signal.get(enabled) {
    Console.log("listening")
    Some(() => Console.log("stopped listening"))
  } else {
    None
  }
}, ~name="listener")
```
*/
let run: (unit => option<unit => unit>, ~name: string=?) => unit

/**
Like `run`, but returns a `disposer` for manual teardown.

Use it for effects that outlive any component, or that must be stopped on a
condition rather than when an owner goes away.

## Examples

```rescript
let ticks = Signal.make(0)

let subscription = Effect.runWithDisposer(() => {
  Console.log2("tick", Signal.get(ticks))
  None
})

Signal.set(ticks, 1) // logs
subscription.dispose()
Signal.set(ticks, 2) // does not log
```
*/
let runWithDisposer: (unit => option<unit => unit>, ~name: string=?) => disposer
