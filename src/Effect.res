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
let runWithDisposer = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer =>
  switch RuntimeLifecycle.nearestSuspense() {
  | None => {
      let disposer = Signals.Effect.runWithDisposer(RuntimeContext.bind(fn), ~name?)
      RuntimeOwner.track(RuntimeOwner.addDisposer, disposer.dispose)
      disposer
    }
  /* Under a suspense, a run that reads an async value not ready yet makes the
     suspense wait, and counts as a fetch in flight for its `pending()`, until
     a run gets past it or the effect is disposed. The effect itself is left
     to the scheduler, which runs it again once the value arrives. */
  | Some(suspense) => {
      let wait: ref<option<(unit => unit, RuntimeLifecycle.flight)>> = ref(None)
      let endWait = () =>
        switch wait.contents {
        | Some((resume, flight)) => {
            wait := None
            resume()
            flight.finish()
          }
        | None => ()
        }
      let waiting = () =>
        switch fn() {
        | cleanup => {
            endWait()
            cleanup
          }
        | exception Signals.Async.NotReady => {
            if wait.contents->Option.isNone {
              let flight = RuntimeLifecycle.flightOn(suspense)
              flight.start()
              wait := Some((RuntimeLifecycle.suspendOn(suspense), flight))
            }
            throw(Signals.Async.NotReady)
          }
        | exception exn => {
            /* A real failure goes to its boundary; the suspense has nothing
               left to wait for from this effect. */
            endWait()
            throw(exn)
          }
        }
      let upstream = Signals.Effect.runWithDisposer(RuntimeContext.bind(waiting), ~name?)
      let disposer = {
        dispose: () => {
          upstream.dispose()
          endWait()
        },
      }
      RuntimeOwner.track(RuntimeOwner.addDisposer, disposer.dispose)
      disposer
    }
  }

let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): unit => {
  let _ = runWithDisposer(fn, ~name?)
}
