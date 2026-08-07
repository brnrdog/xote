/* Shim over `Signals.Computed`.

   The signatures are written out rather than `include`d. An `include` rewrites
   paths that point at the included module itself, but not paths that point at
   *other* modules: `Signals.Computed.make` returns `Signals.Signal.t`, and that
   path would survive into Xote's public API. Consumers who do not declare
   rescript-signals in their own `rescript.json` cannot resolve it, so every
   computed became unusable — `Signal.get(computed)` failed with
   `Signals.Signal.t` versus `Xote.Signal.t`. Naming Xote's own `Signal.t` here
   keeps rescript-signals an implementation detail. */

let make = (
  compute: unit => 'a,
  ~name: option<string>=?,
  ~equals: option<('a, 'a) => bool>=?,
): Signal.t<'a> => Signals.Computed.make(compute, ~name?, ~equals?)

let makeWithoutEquals = (compute: unit => 'a, ~name: option<string>=?): Signal.t<'a> =>
  Signals.Computed.makeWithoutEquals(compute, ~name?)

let makeWithEquals = (
  compute: unit => 'a,
  equalsFn: ('a, 'a) => bool,
  ~name: option<string>=?,
): Signal.t<'a> => Signals.Computed.makeWithEquals(compute, equalsFn, ~name?)

let dispose = (signal: Signal.t<'a>): unit => Signals.Computed.dispose(signal)
