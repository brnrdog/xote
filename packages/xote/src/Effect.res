/* Side effects that re-run when their dependencies change.

   A deliberate re-export of `rescript-signals` (see `Signal.res` for why), with
   one addition: an effect created while a component is rendering is registered
   with that component's scope, so unmounting the component stops it. An effect
   created outside a render — at module level, from an event handler — has no
   scope to belong to and lives until its disposer is called, exactly as before. */

type disposer = Signals.Effect.disposer = {dispose: unit => unit}

/* The scheduler's pending queue holds a plain reference to the observer, so an
   effect disposed while it is queued — a region effect replacing its children
   disposes the leaf effects inside, and a leaf scheduled by the same write is
   still waiting its turn — gets one more run after disposal. Upstream, that run
   re-tracks the effect's dependencies, which relinks the disposed effect to its
   sources: it comes back from the dead and re-runs on every later write,
   accumulating one resurrected effect per replacement.

   The body is therefore guarded here: after disposal it reads nothing, so the
   scheduler's stale-dependency sweep unlinks whatever that last run would have
   re-tracked, and the effect stays dead. Cleanup is managed on this side of the
   guard for the same reason — upstream re-runs the previous cleanup before the
   post-disposal run, which would run a cleanup the disposer already ran. */
let runWithDisposer = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer => {
  let disposed = ref(false)
  /* Upstream keeps storing the cleanup; taking that bookkeeping over here
     would cost a ref and a closure on *every* effect, and the renderer builds
     two per row. Instead each cleanup is handed over pre-disarmed, so the
     leftover run cannot fire one twice — an effect that returns `None`, which
     is every attribute and text effect, then pays nothing for the guarantee. */
  let guarded = () =>
    if disposed.contents {
      None
    } else {
      switch fn() {
      | None => None
      | Some(cleanup) => {
          let pending = ref(true)
          Some(
            () =>
              if pending.contents {
                pending := false
                cleanup()
              },
          )
        }
      }
    }
  let inner = Signals.Effect.runWithDisposer(guarded, ~name?)
  let dispose = () =>
    if !disposed.contents {
      disposed := true
      inner.dispose()
    }
  RuntimeOwner.track(RuntimeOwner.addDisposer, dispose)
  {dispose: dispose}
}

let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): unit => {
  let _ = runWithDisposer(fn, ~name?)
}
