/* A value that is either a plain value (`Static`) or a reactive signal
 (`Reactive`).

 This is the general "static or reactive" wrapper used across Xote. It is not
 tied to component props — use it anywhere an API should accept both a plain
 value and a signal (function arguments, record fields, configuration, JSX
 props, ...).

 Where you do and do not need it in JSX:

 - built-in HTML/SVG attributes and `View.Text`/`Int`/`Float`/`Bool` accept a
   raw value, a `Signal.t`, a `unit => 'a` thunk, or a `t` — wrapping is
   optional there and usually just noise
 - props with a declared type — `View.Show`, `View.For`, `View.Maybe`,
   `View.Value`, and the components you write — take a `t`, so the wrapper is
   how the caller says which one they are passing */
type t<'a> = Reactive(Signal.t<'a>) | Static('a)

/* Constructors */
let static = value => Static(value)

let reactive = signal => Reactive(signal)

/* Derives a reactive value from a computation, so callers do not have to spell
 out `reactive(Computed.make(fn))`. Like `Computed.make`, `fn` runs once
 immediately to establish its dependencies. */
let computed = fn => Reactive(Computed.make(fn))

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

/* Transforms the wrapped value, preserving staticness.

 `fn` runs once immediately in both cases — for `Reactive` values the result is
 backed by a `Computed`, which performs an initial computation to establish its
 dependencies and recomputes lazily from then on. That `Computed` stays
 subscribed to the source signal until `Computed.dispose` is called on it, so
 hold on to long-lived mapped values rather than rebuilding them per update. */
let map = (value, fn) =>
  switch value {
  | Reactive(signal) => Reactive(Computed.make(() => fn(Signal.get(signal))))
  | Static(value) => Static(fn(value))
  }

/* Normalizes to a signal, so the result is always readable with `Signal.get`.

 A `Reactive` value returns its own signal. A `Static` value is lifted into a
 *fresh, detached* signal: each call allocates a new one, and writing to the
 result does not change the original — treat it as read-only. */
let toSignal = value =>
  switch value {
  | Reactive(signal) => signal
  | Static(value) => Signal.make(value)
  }

/* Normalizes an untyped value into a `t`. This is the coercion the JSX runtimes
 apply to props, which may arrive as a raw value, a `Signal.t`, a `unit => 'a`
 thunk, or an already-wrapped `t`:

 - a `t` is returned as-is
 - a `Signal.t` becomes `Reactive`
 - a `unit => 'a` thunk becomes `Reactive` over a `Computed`
 - anything else — including null and undefined — becomes `Static`

 It is deliberately unchecked: nothing verifies that the value really holds an
 `'a`. Reach for it when adapting untyped JSX-shaped input; in typed code use
 `static`, `reactive`, or `computed` instead. */
let ofUnknown = (value: 'input): t<'a> =>
  if RuntimeValue.isMaybeSignal(value) {
    Obj.magic(value)
  } else if RuntimeValue.isSignalLike(value) {
    Reactive(Obj.magic(value))
  } else if RuntimeValue.isFunction(value) {
    computed(Obj.magic(value))
  } else {
    Static(Obj.magic(value))
  }
