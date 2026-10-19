/***
Derived signals that recompute when their dependencies change.

Computeds are lazy with push-based dirty flagging: an upstream change marks
them dirty immediately, but the value is only recomputed when read. A computed
*is* a `Signal.t`, so it is accepted anywhere a signal is — including as a
dependency of another computed.

## Examples

```rescript
let first = Signal.make("Ada")
let last = Signal.make("Lovelace")

let fullName = Computed.make(() => Signal.get(first) ++ " " ++ Signal.get(last))
Signal.get(fullName) == "Ada Lovelace"

Signal.set(first, "Grace")
Signal.get(fullName) == "Grace Lovelace"
```
*/

/**
Creates a computed whose value is the result of `compute`.

Every signal read while `compute` runs becomes a dependency. `~name` is a
debugging label; `~equals` decides whether a recomputed value propagates to
downstream observers, defaulting to JavaScript strict equality — so a computed
that recomputes to an equal value does not wake its own dependents.

The result is a `Signal.t`, read with `Signal.get` and `Signal.peek`. There is
no `set`: a computed is written only by its `compute` function.

## Examples

```rescript
let count = Signal.make(2)

let doubled = Computed.make(() => Signal.get(count) * 2)
Signal.get(doubled) == 4

// Chained: a computed may depend on another computed.
let label = Computed.make(() => "n = " ++ Int.toString(Signal.get(doubled)))
Signal.get(label) == "n = 4"

// `~equals` keeps dependents asleep when the recomputed value is equivalent.
let isEven = Computed.make(() => mod(Signal.get(count), 2) == 0, ~name="isEven")
Signal.get(isEven) == true
```
*/
let make: (unit => 'a, ~name: string=?, ~equals: ('a, 'a) => bool=?) => Signal.t<'a>

/**
Disposes a computed, unsubscribing it from its dependencies.

Rarely needed: computeds auto-dispose when they lose all subscribers, and one
created inside a component or effect is disposed with its owner. Reach for this
only for a long-lived computed created outside any owner.

## Examples

```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Signal.get(doubled) == 0
Computed.dispose(doubled)
```
*/
let dispose: Signal.t<'a> => unit
