/* Derived signals.

   A deliberate re-export of `rescript-signals` (see `Signal.res` for why).
   `Signals.Computed` returns the upstream signal record; `Signal.t` is the same
   value at runtime but abstract to the type system, hence the casts. */

let make = (
  compute: unit => 'a,
  ~name: option<string>=?,
  ~equals: option<('a, 'a) => bool>=?,
): Signal.t<'a> => Obj.magic(Signals.Computed.make(compute, ~name?, ~equals?))

let dispose = (signal: Signal.t<'a>): unit => Signals.Computed.dispose(Obj.magic(signal))
