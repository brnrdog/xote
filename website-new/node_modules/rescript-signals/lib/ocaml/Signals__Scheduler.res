module Observer = Signals__Observer

// Observer registry: observer ID → Observer.t (mutable)
let observers: Map.t<int, Observer.t> = Map.make()

// Bidirectional index: signal ID → set of observer IDs (mutable)
let signalObservers: Map.t<int, Set.t<int>> = Map.make()

// Computed tracking: signal ID → observer ID (mutable)
let computedToObserver: Map.t<int, int> = Map.make()

// Current execution context (which observer is running)
let currentObserverId: ref<option<int>> = ref(None)

let pending: Set.t<int> = Set.make()
let flushing: ref<bool> = ref(false)
let retracking: ref<bool> = ref(false)

module SignalObservers = {
  let ensure = (signalId: int): unit => {
    switch signalObservers->Map.get(signalId) {
    | Some(_) => ()
    | None => signalObservers->Map.set(signalId, Set.make())
    }
  }

  let forEach = (signalId: int, fn: int => unit): unit => {
    switch signalObservers->Map.get(signalId) {
    | Some(obsSet) => obsSet->Set.forEach(fn)
    | None => ()
    }
  }

  let add = (signalId: int, observerId: int): unit => {
    switch signalObservers->Map.get(signalId) {
    | Some(obsSet) => obsSet->Set.add(observerId)
    | None => ()
    }
  }

  let remove = (signalId: int, observerId: int): unit => {
    switch signalObservers->Map.get(signalId) {
    | Some(obsSet) => obsSet->Set.delete(observerId)->ignore
    | None => ()
    }
  }

  let toArray = (signalId: int): array<int> => {
    signalObservers
    ->Map.get(signalId)
    ->Option.getOr(Set.make())
    ->Set.values
    ->Core__Iterator.toArray
  }
}

module ExecutionContext = {
  let withContext = (observerId: int, fn: unit => 'a): 'a => {
    let prev = currentObserverId.contents
    currentObserverId := Some(observerId)
    try {
      let result = fn()
      currentObserverId := prev
      result
    } catch {
    | exn => {
        currentObserverId := prev
        throw(exn)
      }
    }
  }

  let withoutTracking = (fn: unit => 'a): 'a => {
    let prev = currentObserverId.contents
    currentObserverId := None
    try {
      let result = fn()
      currentObserverId := prev
      result
    } catch {
    | exn => {
        currentObserverId := prev
        throw(exn)
      }
    }
  }

  let isCurrentObserver = (observerId: int): bool => {
    switch currentObserverId.contents {
    | Some(currentId) => currentId == observerId
    | None => false
    }
  }
}

module FlushGuard = {
  let withFlushing = (fn: unit => unit): unit => {
    if !flushing.contents {
      flushing := true
      try {
        fn()
        flushing := false
      } catch {
      | exn => {
          flushing := false
          throw(exn)
        }
      }
    }
  }
}

let addDep = (observerId: int, signalId: int): unit => {
  SignalObservers.ensure(signalId)

  switch (ExecutionContext.isCurrentObserver(observerId), observers->Map.get(observerId)) {
  | (true, Some(observer)) =>
    if !(observer.deps->Set.has(signalId)) {
      observer.deps->Set.add(signalId)
      SignalObservers.add(signalId, observerId)
    }
  | _ => ()
  }
}

let rec clearDeps = (observer: Observer.t): unit => {
  observer.deps->Set.forEach(signalId => SignalObservers.remove(signalId, observer.id))
  Set.clear(observer.deps)
}

and autoDisposeComputed = (signalId: int): unit => {
  switch computedToObserver->Map.get(signalId) {
  | Some(observerId) => {
      computedToObserver->Map.delete(signalId)->ignore
      switch observers->Map.get(observerId) {
      | Some(obs) => {
          clearDeps(obs)
          observers->Map.delete(observerId)->ignore
        }
      | None => ()
      }
    }
  | None => ()
  }
}

module LevelCalculation = {
  let maxLevel = (levels: array<int>): int => {
    levels->Array.reduce(0, (max, level) => level > max ? level : max)
  }

  let forEffect = (observer: Observer.t): int => {
    // Effects run after all computeds
    // Only look at computed observers, not other effects, to prevent level inflation
    let computedLevels = []

    observer.deps->Set.forEach(signalId => {
      SignalObservers.forEach(signalId, depObsId => {
        if depObsId != observer.id {
          switch observers->Map.get(depObsId) {
          | Some(depObs) =>
            switch depObs.kind {
            | #Computed(_) => computedLevels->Array.push(depObs.level)->ignore
            | #Effect => () // Ignore effects to prevent level inflation
            }
          | None => ()
          }
        }
      })
    })

    maxLevel(computedLevels) + 1
  }

  let forComputed = (observer: Observer.t): int => {
    // Computeds run based on dependency depth
    // Track producer→consumer edges directly by checking if dependencies are computed signals
    let producerLevels = []

    observer.deps->Set.forEach(signalId => {
      switch computedToObserver->Map.get(signalId) {
      | Some(producerObsId) if producerObsId != observer.id =>
        switch observers->Map.get(producerObsId) {
        | Some(producerObs) => producerLevels->Array.push(producerObs.level)->ignore
        | None => ()
        }
      | _ => ()
      }
    })

    maxLevel(producerLevels) + 1
  }
}

let computeLevel = (observer: Observer.t): int => {
  switch observer.kind {
  | #Effect => LevelCalculation.forEffect(observer)
  | #Computed(_) => LevelCalculation.forComputed(observer)
  }
}

module ObserverExecution = {
  let compareLevel = (a: int, b: int): float => {
    switch (observers->Map.get(a), observers->Map.get(b)) {
    | (Some(obsA), Some(obsB)) => {
        // Get kind priority: Computed = 0, Effect = 1
        let priorityA = switch obsA.kind {
        | #Computed(_) => 0
        | #Effect => 1
        }
        let priorityB = switch obsB.kind {
        | #Computed(_) => 0
        | #Effect => 1
        }

        // First sort by kind priority, then by level
        let priorityDiff = priorityA - priorityB
        if priorityDiff != 0 {
          Int.toFloat(priorityDiff)
        } else {
          Int.toFloat(obsA.level - obsB.level)
        }
      }
    | (Some(_), None) => -1.0
    | (None, Some(_)) => 1.0
    | (None, None) => 0.0
    }
  }

  let retrack = (observer: Observer.t): unit => {
    retracking := true
    clearDeps(observer)

    ExecutionContext.withContext(observer.id, () => {
      observer.run()
      retracking := false
    })

    observer.level = computeLevel(observer)
  }
}

let anyPending = () => pending->Set.size > 0

let flush = (): unit => {
  while anyPending() {
    let arr = pending->Set.values->Core__Iterator.toArray
    Set.clear(pending)

    arr->Array.sort(ObserverExecution.compareLevel)->ignore

    arr->Array.forEach(observerId => {
      switch observers->Map.get(observerId) {
      | Some(observer) => ObserverExecution.retrack(observer)
      | None => ()
      }
    })
  }
}

let schedule = (observerId: int): unit => {
  pending->Set.add(observerId)
  FlushGuard.withFlushing(flush)
}

let rec notify = (signalId: int): unit => {
  SignalObservers.ensure(signalId)

  SignalObservers.toArray(signalId)->Array.forEach(observerId => {
    switch observers->Map.get(observerId) {
    | None => ()
    | Some(observer) =>
      switch observer.kind {
      | #Effect => pending->Set.add(observerId)
      | #Computed(backingSignalId) =>
        if !observer.dirty {
          observer.dirty = true
          notify(backingSignalId)
        }
      }
    }
  })

  if anyPending() {
    FlushGuard.withFlushing(flush)
  }
}

let ensureComputedFresh = (signalId: int): unit => {
  switch computedToObserver->Map.get(signalId) {
  | Some(observerId) =>
    switch observers->Map.get(observerId) {
    | Some(observer) =>
      if observer.dirty {
        retracking := true
        clearDeps(observer)

        ExecutionContext.withContext(observerId, () => {
          observer.run()
          observer.dirty = false
          retracking := false
        })

        observer.level = computeLevel(observer)
      }
    | None => ()
    }
  | None => ()
  }
}

let batch = fn => {
  let wasFlushing = flushing.contents
  flushing := true

  try {
    let result = fn()
    if !wasFlushing {
      flushing := false
      if anyPending() {
        flush()
      }
    }
    result
  } catch {
  | exn => {
      if !wasFlushing {
        flushing := false
      }
      throw(exn)
    }
  }
}

let untrack = ExecutionContext.withoutTracking
let ensureSignal = SignalObservers.ensure
