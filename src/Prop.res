/* Deprecated: use `MaybeSignal` instead.

 `Prop` was only ever a "static or reactive" wrapper that happened to be named
 after JSX props. `MaybeSignal` is the same thing under a clearer name, usable
 anywhere — not just for component props.

 `Prop.t` is a type alias of `MaybeSignal.t` (same constructors, same runtime
 representation), so migrating is a rename: `Prop.static` -> `MaybeSignal.static`,
 `Prop.signal` -> `MaybeSignal.signal`, `Prop.get` -> `MaybeSignal.get`. Values
 built with one module can be passed to APIs expecting the other. */

@deprecated("Use MaybeSignal.t instead. Prop.t is an alias of MaybeSignal.t.")
type t<'a> = MaybeSignal.t<'a> = Reactive(Signal.t<'a>) | Static('a)

@deprecated("Use MaybeSignal.get instead.")
let get = MaybeSignal.get

@deprecated("Use MaybeSignal.static instead.")
let static = MaybeSignal.static

@deprecated("Use MaybeSignal.reactive instead.")
let reactive = MaybeSignal.reactive

@deprecated("Use MaybeSignal.signal instead.")
let signal = MaybeSignal.signal
