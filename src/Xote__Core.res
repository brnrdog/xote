module IntSet = Belt.Set.Int
module IntMap = Belt.Map.Int
module Observer = Xote__Observer
module Id = Xote__Id

type t<'a> = {id: int, value: ref<'a>, version: ref<int>}

/* Global tables */
let observers: ref<IntMap.t<Observer.t>> = ref(IntMap.empty)
let signalObservers: ref<IntMap.t<IntSet.t>> = ref(IntMap.empty) /* signal id -> observer ids */
let signalPeeks: ref<IntSet.t> = ref(IntSet.empty) /* optional; for debugging */

/* Currently running observer for tracking */
let currentObserverId: ref<option<int>> = ref(None)

/* Simple scheduler */
let pending: ref<IntSet.t> = ref(IntSet.empty)
let batching = ref(false)
let flushing = ref(false) /* Prevent nested flushes */

let ensureSignalBucket = (sid: int) => {
  switch IntMap.get(signalObservers.contents, sid) {
  | Some(_) => ()
  | None => signalObservers := IntMap.set(signalObservers.contents, sid, IntSet.empty)
  }
}

let addDep = (obsId: int, sid: int) => {
  ensureSignalBucket(sid)
  /* add obs -> dep */
  let obs = Belt.Option.getExn(IntMap.get(observers.contents, obsId))
  if currentObserverId.contents == Some(obsId) {
    if obs.deps->IntSet.has(sid) == false {
      obs.deps = obs.deps->IntSet.add(sid)
      /* add dep -> obs */
      let sset = Belt.Option.getExn(IntMap.get(signalObservers.contents, sid))
      signalObservers := IntMap.set(signalObservers.contents, sid, sset->IntSet.add(obsId))
    }
  }
}

let clearDeps = (obs: Observer.t) => {
  /* remove obs from all signal buckets it was in */
  obs.deps->IntSet.forEach(sid => {
    switch IntMap.get(signalObservers.contents, sid) {
    | None => ()
    | Some(sset) =>
      signalObservers := IntMap.set(signalObservers.contents, sid, sset->IntSet.remove(obs.id))
    }
  })
  obs.deps = IntSet.empty
}

/* Compute observer level based on dependency depth (topological ordering) */
let computeLevel = (obs: Observer.t): int => {
  /* Effects are always at a higher level than computeds they depend on */
  switch obs.kind {
  | #Effect => {
      /* Find the maximum level among all dependent signals' observers + 1 */
      let maxDepLevel = ref(0)
      obs.deps->IntSet.forEach(sid => {
        switch IntMap.get(signalObservers.contents, sid) {
        | None => ()
        | Some(obsSet) =>
          obsSet->IntSet.forEach(depObsId => {
            switch IntMap.get(observers.contents, depObsId) {
            | None => ()
            | Some(depObs) =>
              if depObs.level > maxDepLevel.contents {
                maxDepLevel := depObs.level
              }
            }
          })
        }
      })
      maxDepLevel.contents + 1000 /* Effects always after computeds */
    }
  | #Computed(_) => {
      /* Find the maximum level among all signals we depend on */
      let maxDepLevel = ref(0)
      obs.deps->IntSet.forEach(sid => {
        switch IntMap.get(signalObservers.contents, sid) {
        | None => ()
        | Some(obsSet) =>
          obsSet->IntSet.forEach(depObsId => {
            if depObsId != obs.id {
              /* Don't include self */
              switch IntMap.get(observers.contents, depObsId) {
              | None => ()
              | Some(depObs) =>
                /* Only look at other computeds (not effects) */
                switch depObs.kind {
                | #Computed(_) =>
                  if depObs.level > maxDepLevel.contents {
                    maxDepLevel := depObs.level
                  }
                | #Effect => () /* Ignore effects */
                }
              }
            }
          })
        }
      })
      maxDepLevel.contents + 1
    }
  }
}

let flush = () => {
  /* Iterative loop instead of recursion to avoid stack overflow */
  while pending.contents != IntSet.empty {
    let toRun = pending.contents
    pending := IntSet.empty

    /* Convert to array and sort by level (lower levels first) */
    let arr = toRun->IntSet.toArray
    let sorted = Belt.SortArray.stableSortBy(arr, (a, b) => {
      switch (IntMap.get(observers.contents, a), IntMap.get(observers.contents, b)) {
      | (Some(obsA), Some(obsB)) => obsA.level - obsB.level
      | (Some(_), None) => -1
      | (None, Some(_)) => 1
      | (None, None) => 0
      }
    })

    sorted->Array.forEach(id => {
      switch IntMap.get(observers.contents, id) {
      | None => ()
      | Some(o) => {
          /* re-track */
          clearDeps(o)
          let prev = currentObserverId.contents
          currentObserverId := Some(id)
          /* Use try/catch to ensure tracking state is restored even on exceptions */
          try {
            o.run()
          } catch {
          | exn => {
              currentObserverId := prev
              raise(exn)
            }
          }
          currentObserverId := prev
          /* Recompute level after re-tracking (dependencies may have changed) */
          o.level = computeLevel(o)
        }
      }
    })

    /* Loop continues if new pending observers were scheduled during execution */
  }
}

let schedule = (obsId: int) => {
  pending := pending.contents->IntSet.add(obsId)
  if batching.contents == false && flushing.contents == false {
    /* flush with topological ordering, preventing nested flushes */
    flushing := true
    flush()
    flushing := false
  }
}

let notify = (sid: int) => {
  ensureSignalBucket(sid)
  switch IntMap.get(signalObservers.contents, sid) {
  | None => ()
  | Some(sset) => {
      // Add all dependent observers to pending before flushing
      sset->IntSet.forEach(obsId => {
        pending := pending.contents->IntSet.add(obsId)
      })
      // Only flush if we're not already batching or flushing
      if batching.contents == false && flushing.contents == false {
        flushing := true
        flush()
        flushing := false
      }
    }
  }
}

/* Run a function without tracking dependencies */
let untrack = (f: unit => 'a): 'a => {
  let prev = currentObserverId.contents
  currentObserverId := None
  /* Use try/catch to ensure tracking state is restored even on exceptions */
  try {
    let result = f()
    currentObserverId := prev
    result
  } catch {
  | exn => {
      currentObserverId := prev
      raise(exn)
    }
  }
}

/* Batch: defer scheduling until after block ends */
let batch = (f: unit => 'a): 'a => {
  let prev = batching.contents
  batching := true
  /* Use try/finally to ensure batching state is restored even on exceptions */
  let result = try {
    f()
  } catch {
  | exn => {
      batching := prev
      raise(exn)
    }
  }
  batching := prev

  /* flush anything queued */
  if pending.contents != IntSet.empty {
    let toRun = pending.contents
    pending := IntSet.empty
    toRun->IntSet.forEach(id => schedule(id))
  }
  result
}
