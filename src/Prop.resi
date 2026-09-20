/***
Deprecated alias of `MaybeSignal`, kept for one release.

Every binding here forwards to its `MaybeSignal` counterpart; see
`MaybeSignal.res` for the migration notes. New code should use `MaybeSignal`
directly.

This interface exists so the deprecations actually fire: ReScript only reports
warning 3 for values when they are declared in an interface file. Without it,
`@deprecated` on the implementation's `let` bindings is silently ignored at
call sites.
*/

/** Deprecated alias of `MaybeSignal.t`. The two are the same type. */
@deprecated("Use MaybeSignal.t instead. Prop.t is an alias of MaybeSignal.t.")
type t<'a> = MaybeSignal.t<'a> = Reactive(Signal.t<'a>) | Static('a)

/** Deprecated alias of `MaybeSignal.get`. */
@deprecated("Use MaybeSignal.get instead.")
let get: MaybeSignal.t<'a> => 'a

/** Deprecated alias of `MaybeSignal.static`. */
@deprecated("Use MaybeSignal.static instead.")
let static: 'a => MaybeSignal.t<'a>

/** Deprecated alias of `MaybeSignal.reactive`. */
@deprecated("Use MaybeSignal.reactive instead.")
let reactive: Signal.t<'a> => MaybeSignal.t<'a>

/** Deprecated alias of `MaybeSignal.reactive`. */
@deprecated("Use MaybeSignal.reactive instead.")
let signal: Signal.t<'a> => MaybeSignal.t<'a>
