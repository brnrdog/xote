/***
Reactive state cells.

`t<'a>` is abstract: values are only ever read through `get`/`peek` and written
through `set`/`update`, so every mutation goes through the scheduler and
notifies dependents.

## Examples

```rescript
let count = Signal.make(0)

Effect.run(() => {
  Console.log2("count is", Signal.get(count))
  None
})

Signal.set(count, 1) // the effect re-runs
```
*/

/**
A reactive cell holding a value of type `'a`.

Abstract by design: construct one with `make`, read it with `get` or `peek`,
write it with `set` or `update`. `Computed.make` returns the same type, so a
derived value is accepted anywhere a signal is.
*/
type t<'a>

/**
Creates a signal holding `initialValue`.

`~name` is a debugging label, surfaced in development warnings. `~equals`
replaces the default JavaScript strict equality used to decide whether `set`
notifies dependents — pass it when the value is a structure that strict
equality would always consider changed.

## Examples

```rescript
let count = Signal.make(0)
Signal.get(count) == 0

let named = Signal.make(0, ~name="counter")
Signal.get(named) == 0

// Structural comparison, so writing an equal array does not notify dependents.
let items = Signal.make([1, 2], ~equals=(a, b) => a == b)
Signal.set(items, [1, 2]) // no dependents re-run
```
*/
let make: ('a, ~name: string=?, ~equals: ('a, 'a) => bool=?) => t<'a>

/**
Reads the value and subscribes the current observer to it.

Called inside an effect, a computed or a tracked view block, this registers a
dependency, so that observer re-runs whenever the signal changes. Outside any
observer it is simply a read.

## Examples

```rescript
let count = Signal.make(41)
Signal.get(count) == 41

let doubled = Computed.make(() => Signal.get(count) * 2) // subscribes to count
Signal.get(doubled) == 82
```
*/
let get: t<'a> => 'a

/**
Reads the value *without* subscribing the current observer.

Use it when an observer needs a signal's current value but should not re-run
when that signal changes.

## Examples

```rescript
let count = Signal.make(10)
let step = Signal.make(2)

Effect.run(() => {
  // Re-runs when `count` changes, but not when `step` does.
  Console.log(Signal.get(count) + Signal.peek(step))
  None
})
```
*/
let peek: t<'a> => 'a

/**
Writes the value, notifying dependents when it differs from the current one.

"Differs" is decided by the `~equals` passed to `make`, defaulting to
JavaScript strict equality. Writing an equal value is a no-op.

## Examples

```rescript
let count = Signal.make(0)
Signal.set(count, 5)
Signal.get(count) == 5

Signal.set(count, 5) // equal to the current value: no dependents re-run
```
*/
let set: (t<'a>, 'a) => unit

/**
Writes a value derived from the current one.

Equivalent to `set(signal, fn(peek(signal)))`, and the idiomatic way to write
an increment or a push, since it does not subscribe the caller.

## Examples

```rescript
let count = Signal.make(0)
Signal.update(count, n => n + 1)
Signal.get(count) == 1

let items = Signal.make(["a"])
Signal.update(items, xs => Array.concat(xs, ["b"]))
Signal.get(items) == ["a", "b"]
```
*/
let update: (t<'a>, 'a => 'a) => unit

/**
Defers scheduler flushing until `fn` returns, so a burst of writes runs each
dependent effect at most once.

Returns whatever `fn` returns. Batches nest: only the outermost one flushes.

## Examples

```rescript
let first = Signal.make("Ada")
let last = Signal.make("Lovelace")

Effect.run(() => {
  Console.log(Signal.get(first) ++ " " ++ Signal.get(last))
  None
})

// One re-run, not two.
Signal.batch(() => {
  Signal.set(first, "Grace")
  Signal.set(last, "Hopper")
})
```
*/
let batch: (unit => 'a) => 'a

/**
Disables dependency capture inside `fn`, returning its result.

The block form of `peek`: every signal read while `fn` runs is untracked, so
the surrounding observer does not subscribe to any of them.

## Examples

```rescript
let count = Signal.make(1)
let multiplier = Signal.make(10)

Effect.run(() => {
  let factor = Signal.untrack(() => Signal.get(multiplier))
  // Re-runs when `count` changes, but not when `multiplier` does.
  Console.log(Signal.get(count) * factor)
  None
})
```
*/
let untrack: (unit => 'a) => 'a
