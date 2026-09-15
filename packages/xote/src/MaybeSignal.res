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
 immediately to establish its dependencies.

 The result is the caller's to release: it is not marked as library-owned, so
 no node disposes it on your behalf (see `RuntimeOwner.markOwned`). Call
 `Computed.dispose` on it when you are done. */
let computed = fn => Reactive(Computed.make(fn))

/* The total branch over the two cases, and how `get` and `peek` are implemented.
 The two callbacks are the inverses of the `static` and `reactive` constructors,
 so `~reactive` receives the `Signal.t` rather than its value.

 `switch` on the constructors is equally idiomatic and gives you exhaustiveness
 checking; reach for `fold` when it reads better in a pipe. */
let fold = (value, ~static, ~reactive) =>
  switch value {
  | Reactive(signal) => reactive(signal)
  | Static(value) => static(value)
  }

/* Reads the current value. Inside an observer, a `Reactive` value registers a
 dependency; a `Static` value never does. */
let get = value => fold(value, ~static=v => v, ~reactive=Signal.get)

/* Reads the current value without registering a dependency */
let peek = value => fold(value, ~static=v => v, ~reactive=Signal.peek)

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

/* The underlying signal, when there is one.

 `Reactive` returns its source signal; `Static` returns `None`, because a plain
 value has no signal and fabricating a fresh detached one made writes to the
 result disappear silently. To lift a `Static` value into a signal explicitly,
 write `fold(value, ~static=v => Signal.make(v), ~reactive=s => s)` —
 `~static=Signal.make` does not typecheck, because `Signal.make` carries
 optional `~name`/`~equals` arguments. */
let toSignal = value =>
  switch value {
  | Reactive(signal) => Some(signal)
  | Static(_) => None
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
