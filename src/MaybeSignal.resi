/* A value that is either a plain value (`Static`) or a reactive signal
   (`Reactive`).

   The general "static or reactive" wrapper used across Xote. It is not tied to
   component props — use it anywhere an API should accept both a plain value and
   a signal. See `MaybeSignal.res` for when JSX needs the wrapper and when it
   does not. */

type t<'a> = Reactive(Signal.t<'a>) | Static('a)

/* ---------------------------------------------------------------- construct */

let static: 'a => t<'a>
let reactive: Signal.t<'a> => t<'a>

/* Derives a reactive value from a computation, so callers do not have to spell
   out `reactive(Computed.make(fn))`. `fn` runs once immediately. */
let computed: (unit => 'a) => t<'a>

/* --------------------------------------------------------------------- read */

/* Reads the current value, registering a dependency when `Reactive` */
let get: t<'a> => 'a

/* Reads the current value without registering a dependency */
let peek: t<'a> => 'a

let isReactive: t<'a> => bool
let isStatic: t<'a> => bool

/* ---------------------------------------------------------------- transform */

/* Transforms the wrapped value, preserving staticness. A `Reactive` result is
   backed by a `Computed` that stays subscribed until `Computed.dispose`. */
let map: (t<'a>, 'a => 'b) => t<'b>

/* Normalizes to a signal. A `Static` value is lifted into a fresh, detached
   signal — treat the result as read-only. */
let toSignal: t<'a> => Signal.t<'a>

/* Normalizes an untyped value — a raw value, a `Signal.t`, a `unit => 'a`
   thunk, or an already-wrapped `t` — into a `t`. This is the coercion the JSX
   runtimes apply to props. Deliberately unchecked: in typed code prefer
   `static`, `reactive` or `computed`. */
let ofUnknown: 'input => t<'a>
