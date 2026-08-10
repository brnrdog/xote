type owner = {
  disposers: array<Effect.disposer>,
  mutable computeds: array<Obj.t>,
}

let currentOwner: ref<option<owner>> = ref(None)

let createOwner = (): owner => {
  disposers: [],
  computeds: [],
}

let runWithOwner = (owner: owner, fn: unit => 'a): 'a => {
  let previousOwner = currentOwner.contents
  currentOwner := Some(owner)
  let result = fn()
  currentOwner := previousOwner
  result
}

let addDisposer = (owner: owner, disposer: Effect.disposer): unit => {
  owner.disposers->Array.push(disposer)->ignore
}

let disposeOwner = (owner: owner): unit => {
  owner.disposers->Array.forEach(disposer => disposer.dispose())

  owner.computeds->Array.forEach(computed => {
    let c: Signal.t<Obj.t> = Obj.magic(computed)
    Computed.dispose(c)
  })
}

let setOwner: (Dom.element, owner) => unit = %raw(`function (element, owner) {
  element["__xote_owner__"] = owner
}`)

let readOwner: Dom.element => Nullable.t<owner> = %raw(`function (element) {
  return element["__xote_owner__"]
}`)

let getOwner = (element: Dom.element): option<owner> => readOwner(element)->Nullable.toOption
