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

let schedule = (obsId: int) => {
  pending := pending.contents->IntSet.add(obsId)
  if batching.contents == false {
    /* flush immediately (sync microtask-ish) */
    let toRun = pending.contents
    pending := IntSet.empty
    toRun->IntSet.forEach(id => {
      switch IntMap.get(observers.contents, id) {
      | None => ()
      | Some(o) => {
          /* re-track */
          clearDeps(o)
          let prev = currentObserverId.contents
          currentObserverId := Some(id)
          o.run()
          currentObserverId := prev
        }
      }
    })
  }
}

let notify = (sid: int) => {
  ensureSignalBucket(sid)
  switch IntMap.get(signalObservers.contents, sid) {
  | None => ()
  | Some(sset) => sset->IntSet.forEach(schedule)
  }
}

/* Run a function without tracking dependencies */
let untrack = (f: unit => 'a): 'a => {
  let prev = currentObserverId.contents
  currentObserverId := None
  let r = f()
  currentObserverId := prev
  r
}

/* Batch: defer scheduling until after block ends */
let batch = (f: unit => 'a): 'a => {
  let prev = batching.contents
  batching := true
  let r = f()
  batching := prev

  /* flush anything queued */
  if pending.contents != IntSet.empty {
    let toRun = pending.contents
    pending := IntSet.empty
    toRun->IntSet.forEach(id => schedule(id))
  }
  r
}
