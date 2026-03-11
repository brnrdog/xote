module Id = Signals__Id
module Observer = Signals__Observer
module Scheduler = Signals__Scheduler

type disposer = {dispose: unit => unit}

let run = (fn: unit => option<unit => unit>, ~name: option<string>=?): disposer => {
  let observerId = Id.make()
  let cleanup: ref<option<unit => unit>> = ref(None)

  // Wrapper that handles cleanup
  let runWithCleanup = () => {
    // Run previous cleanup
    switch cleanup.contents {
    | Some(cleanupFn) => cleanupFn()
    | None => ()
    }

    // Run effect and store new cleanup
    cleanup := fn()
  }

  // Create observer
  let observer = Observer.make(observerId, #Effect, runWithCleanup, ~name?)

  Scheduler.observers->Map.set(observerId, observer)

  // Initial run under tracking
  Scheduler.retracking := true
  Scheduler.clearDeps(observer)

  let prev = Scheduler.currentObserverId.contents
  Scheduler.currentObserverId := Some(observerId)

  try {
    observer.run()
    Scheduler.retracking := false
  } catch {
  | exn => {
      Scheduler.currentObserverId := prev
      Scheduler.retracking := false
      throw(exn)
    }
  }

  Scheduler.currentObserverId := prev

  // Compute level
  observer.level = Scheduler.computeLevel(observer)

  // Return disposer
  let dispose = () => {
    switch Scheduler.observers->Map.get(observerId) {
    | Some(obs) => {
        // Run final cleanup
        switch cleanup.contents {
        | Some(cleanupFn) => cleanupFn()
        | None => ()
        }

        Scheduler.clearDeps(obs)
        Scheduler.observers->Map.delete(observerId)->ignore
      }
    | None => ()
    }
  }

  {dispose: dispose}
}
