module Id = Signals__Id
module Signal = Signals__Signal
module Observer = Signals__Observer
module Scheduler = Signals__Scheduler

let make = (compute: unit => 'a, ~name: option<string>=?): Signal.t<'a> => {
  // Create backing signal with magic initial value
  let backingSignal = Signal.make((Obj.magic(): 'a), ~name?)

  // Create observer ID
  let observerId = Id.make()

  // Recompute function
  let recompute = () => {
    let newValue = compute()

    backingSignal.value := newValue
  }

  // Create observer
  let observer = Observer.make(observerId, #Computed(backingSignal.id), recompute)

  Scheduler.observers->Map.set(observerId, observer)

  // Initial computation under tracking
  Scheduler.retracking := true
  Scheduler.clearDeps(observer)

  let prev = Scheduler.currentObserverId.contents
  Scheduler.currentObserverId := Some(observerId)

  try {
    observer.run()
    observer.dirty = false
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

  // Register for auto-disposal
  Scheduler.computedToObserver->Map.set(backingSignal.id, observerId)

  backingSignal
}

let dispose = (signal: Signal.t<'a>): unit => {
  Scheduler.autoDisposeComputed(signal.id)
}
