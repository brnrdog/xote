/* Side effects that re-run when their dependencies change.

   A deliberate re-export of `rescript-signals` (see `Signal.res` for why), with
   one addition: an effect created while a component is rendering is registered
   with that component's scope, so unmounting the component stops it. An effect
   created outside a render — at module level, from an event handler — has no
   scope to belong to and lives until its disposer is called, exactly as before.

   Every run also happens under the context the effect was created under, and a
   failure in it goes to the nearest error boundary above, if there is one: a
   later update renders with the same context and boundary its first run had. */

type disposer = Signals.Effect.disposer = {dispose: unit => unit}

/* Registers with the region that is rendering, so unmounting the region
   disposes the effect. `rescript-signals` 3.1.3 and later make disposal final
   on their side — a disposed effect still sitting in the scheduler's queue is
   dequeued without running, and its cleanup runs exactly once — so nothing has
   to be guarded here and the upstream disposer is registered as is. */
let runWithDisposer = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer => {
  let disposer = Signals.Effect.runWithDisposer(RuntimeContext.bind(fn), ~name?)
  RuntimeOwner.track(RuntimeOwner.addDisposer, disposer.dispose)
  disposer
}

let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): unit => {
  let _ = runWithDisposer(fn, ~name?)
}
