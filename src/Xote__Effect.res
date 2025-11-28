module IntSet = Belt.Set.Int
module IntMap = Belt.Map.Int

module Id = Xote__Id
module Observer = Xote__Observer
module Signal = Xote__Signal
module Core = Xote__Core

type disposer = {dispose: unit => unit}

let run = (fn: unit => option<unit => unit>): disposer => {
  let id = Id.make()
  let cleanup: ref<option<unit => unit>> = ref(None)

  let runWithCleanup = () => {
    /* Run previous cleanup if it exists */
    switch cleanup.contents {
    | Some(cleanupFn) => cleanupFn()
    | None => ()
    }
    /* Run the effect and store the new cleanup */
    cleanup := fn()
  }

  let observer: Observer.t = {
    id,
    kind: #Effect,
    run: runWithCleanup,
    deps: IntSet.empty,
    level: 1000, /* Effects start at high level, will be recomputed after tracking */
  }
  Core.observers := IntMap.set(Core.observers.contents, id, observer)
  /* initial run */
  Core.retracking := true
  Core.clearDeps(observer)
  let prev = Core.currentObserverId.contents
  Core.currentObserverId := Some(id)
  /* Use try/catch to ensure tracking state is restored even on exceptions */
  try {
    observer.run()
    Core.retracking := false
  } catch {
  | exn => {
      Core.currentObserverId := prev
      Core.retracking := false
      raise(exn)
    }
  }
  Core.currentObserverId := prev
  /* Compute proper level after tracking dependencies */
  observer.level = Core.computeLevel(observer)

  let dispose = () => {
    switch IntMap.get(Core.observers.contents, id) {
    | None => ()
    | Some(o) => {
        /* Run cleanup before disposing */
        switch cleanup.contents {
        | Some(cleanupFn) => cleanupFn()
        | None => ()
        }
        Core.clearDeps(o)
        Core.observers := IntMap.remove(Core.observers.contents, id)
      }
    }
  }
  {dispose: dispose}
}
