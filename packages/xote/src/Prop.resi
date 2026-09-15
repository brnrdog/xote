/* Deprecated: use `MaybeSignal` instead. See `Prop.res` for the migration notes.

 This interface exists so the deprecations actually fire: ReScript only reports
 warning 3 for values when they are declared in an interface file. Without it,
 `@deprecated` on the implementation's `let` bindings is silently ignored at
 call sites. */

@deprecated("Use MaybeSignal.t instead. Prop.t is an alias of MaybeSignal.t.")
type t<'a> = MaybeSignal.t<'a> = Reactive(Signal.t<'a>) | Static('a)

@deprecated("Use MaybeSignal.get instead.")
let get: MaybeSignal.t<'a> => 'a

@deprecated("Use MaybeSignal.static instead.")
let static: 'a => MaybeSignal.t<'a>

@deprecated("Use MaybeSignal.reactive instead.")
let reactive: Signal.t<'a> => MaybeSignal.t<'a>

@deprecated("Use MaybeSignal.reactive instead.")
let signal: Signal.t<'a> => MaybeSignal.t<'a>
