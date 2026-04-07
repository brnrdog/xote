open Signals

/* Defines a property that can either be a signal (Reactive) or a static value
 (Static) */
type t<'a> = Reactive(Signal.t<'a>) | Static('a)

let get = value =>
  switch value {
  | Reactive(signal) => Signal.get(signal)
  | Static(value) => value
  }

/* Helper functions for creating reactive props */
let static = value => Static(value)

let reactive = signal => Reactive(signal)
