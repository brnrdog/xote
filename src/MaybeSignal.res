/* A value that is either a plain value (`Static`) or a reactive signal
 (`Reactive`).

 This is the general "static or reactive" wrapper used across Xote. It is not
 tied to component props — use it anywhere an API should accept both a plain
 value and a signal (function arguments, record fields, configuration, JSX
 props, ...). */
type t<'a> = Reactive(Signal.t<'a>) | Static('a)

/* Constructors */
let static = value => Static(value)

let reactive = signal => Reactive(signal)

/* Alias of `reactive`, reads better when the argument is already a signal */
let signal = reactive

/* Reads the current value. Inside an observer, a `Reactive` value registers a
 dependency; a `Static` value never does. */
let get = value =>
  switch value {
  | Reactive(signal) => Signal.get(signal)
  | Static(value) => value
  }

/* Reads the current value without registering a dependency */
let peek = value =>
  switch value {
  | Reactive(signal) => Signal.peek(signal)
  | Static(value) => value
  }

/* Predicates */
let isReactive = value =>
  switch value {
  | Reactive(_) => true
  | Static(_) => false
  }

let isStatic = value => !isReactive(value)

/* Transforms the wrapped value, preserving staticness. `Reactive` values are
 mapped through a lazy `Computed`, so `fn` only runs when the result is read. */
let map = (value, fn) =>
  switch value {
  | Reactive(signal) => Reactive(Computed.make(() => fn(Signal.get(signal))))
  | Static(value) => Static(fn(value))
  }

/* Normalizes to a signal. `Static` values are lifted into a constant signal, so
 the result is always readable with `Signal.get`. */
let toSignal = value =>
  switch value {
  | Reactive(signal) => signal
  | Static(value) => Signal.make(value)
  }
