module IntSet = Belt.Set.Int
module IntMap = Belt.Map.Int

module Id = Xote__Id
module Observer = Xote__Observer
module Signal = Xote__Signal
module Core = Xote__Core

type disposer = {dispose: unit => unit}

let run = (fn: unit => unit): disposer => {
  let id = Id.make()
  let observer: Observer.t = {
    id,
    kind: #Effect,
    run: () => fn(),
    deps: IntSet.empty,
  }
  Core.observers := IntMap.set(Core.observers.contents, id, observer)
  /* initial run */
  Core.clearDeps(observer)
  Core.currentObserverId := Some(id)
  observer.run()
  Core.currentObserverId := None

  let dispose = () => {
    switch IntMap.get(Core.observers.contents, id) {
    | None => ()
    | Some(o) => {
        Core.clearDeps(o)
        Core.observers := IntMap.remove(Core.observers.contents, id)
      }
    }
  }
  {dispose: dispose}
}
