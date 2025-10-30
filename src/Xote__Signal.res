module IntSet = Belt.Set.Int
module IntMap = Belt.Map.Int
module Observer = Xote__Observer
module Id = Xote__Id
module Core = Xote__Core

let make = (v: 'a): Core.t<'a> => {
  let id = Id.make()
  Core.ensureSignalBucket(id)
  {id, value: ref(v), version: ref(0)}
}

let get = (s: Core.t<'a>): 'a => {
  switch Core.currentObserverId.contents {
  | None => ()
  | Some(obsId) => Core.addDep(obsId, s.id)
  }
  s.value.contents
}

/* read without tracking */
let peek = (s: Core.t<'a>): 'a => s.value.contents

let set = (s: Core.t<'a>, v: 'a) => {
  // Always update - skip equality check to avoid issues with complex types
  s.value := v
  s.version := s.version.contents + 1
  Core.notify(s.id)
}

let update = (s: Core.t<'a>, f: 'a => 'a) => set(s, f(s.value.contents))
