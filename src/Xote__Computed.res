module IntSet = Belt.Set.Int
module IntMap = Belt.Map.Int
module Signal = Xote__Signal
module Core = Xote__Core
module Observer = Xote__Observer
module Id = Xote__Id

let make = (calc: unit => 'a): Core.t<'a> => {
  /* create backing signal */
  let s = Signal.make((Obj.magic(): 'a))
  /* mark it as absent; force first compute */
  let initialized = ref(false)

  let id = Id.make()
  let rec recompute = () => {
    let next = calc()
    if initialized.contents == false {
      initialized := true
      Signal.set(s, next)
    } else {
      Signal.set(s, next)
    }
  }

  let rec o: Observer.t = {
    id,
    kind: #Computed(s.id),
    run: recompute,
    deps: IntSet.empty,
  }

  Core.observers := IntMap.set(Core.observers.contents, id, o)

  /* initial compute under tracking */
  Core.clearDeps(o)
  let prev = Core.currentObserverId.contents
  Core.currentObserverId := Some(id)
  o.run()
  Core.currentObserverId := prev

  /* When dependencies change, scheduler will run `recompute` which writes to s,
   and that write will notify s's own dependents. */
  s
}
