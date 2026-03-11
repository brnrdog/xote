module Id = Signals__Id
module Scheduler = Signals__Scheduler

type t<'a> = {
  id: int,
  value: ref<'a>,
  version: ref<int>,
  equals: ('a, 'a) => bool,
  name: option<string>,
}

let make = (initialValue: 'a, ~name: option<string>=?, ~equals: option<('a, 'a) => bool>=?): t<
  'a,
> => {
  let id = Id.make()
  Scheduler.ensureSignal(id)

  {
    id,
    value: ref(initialValue),
    version: ref(0),
    equals: equals->Option.getOr((a, b) => a === b),
    name,
  }
}

let get = (signal: t<'a>): 'a => {
  Scheduler.ensureComputedFresh(signal.id)

  switch Scheduler.currentObserverId.contents {
  | Some(observerId) => Scheduler.addDep(observerId, signal.id)
  | None => ()
  }

  signal.value.contents
}

let peek = (signal: t<'a>): 'a => {
  Scheduler.ensureComputedFresh(signal.id)
  signal.value.contents
}

let set = (signal: t<'a>, newValue: 'a): unit => {
  let shouldUpdate = try {
    !signal.equals(signal.value.contents, newValue)
  } catch {
  | _ => true
  }

  if shouldUpdate {
    signal.value := newValue
    signal.version := signal.version.contents + 1
    Scheduler.notify(signal.id)
  }
}

let update = (signal: t<'a>, fn: 'a => 'a): unit => signal->set(fn(signal.value.contents))

let batch = Scheduler.batch

let untrack = Scheduler.untrack
