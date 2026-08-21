/* Side effects that re-run when their dependencies change.

   A deliberate re-export of `rescript-signals` (see `Signal.res` for why), with
   one addition: an effect created while a component is rendering is registered
   with that component's scope, so unmounting the component stops it. An effect
   created outside a render — at module level, from an event handler — has no
   scope to belong to and lives until its disposer is called, exactly as before. */

type disposer = Signals.Effect.disposer = {dispose: unit => unit}

let runWithDisposer = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer => {
  let disposer = Signals.Effect.runWithDisposer(fn, ~name?)
  RuntimeOwner.track(RuntimeOwner.addDisposer, disposer.dispose)
  disposer
}

let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): unit => {
  let _ = runWithDisposer(fn, ~name?)
}
