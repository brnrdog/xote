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
downstream observers. There is no default cutoff: without `~equals`, every
recompute wakes the computed's dependents, even when it produced an identical
(`===`) value.

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

Rarely needed: a computed detaches from its sources by itself when it loses its
last subscriber, so one read only by a component's own leaves and effects goes
cold when the component unmounts. It is not tied to an owner, though: while
anything still subscribes to it, it stays attached. Reach for this to cut off a
computed that still has subscribers. The computed stays readable, and the next
read recomputes it and re-collects its dependencies.

## Examples

```rescript
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Signal.get(doubled) == 0
Computed.dispose(doubled)
```
*/
let dispose: Signal.t<'a> => unit
