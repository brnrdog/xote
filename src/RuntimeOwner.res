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

@warning("-27")
let setOwner = (element: Dom.element, owner: owner): unit => {
  %raw(`element["__xote_owner__"] = owner`)
}

@warning("-27")
let getOwner = (element: Dom.element): option<owner> => {
  let owner: Nullable.t<owner> = %raw(`element["__xote_owner__"]`)
  owner->Nullable.toOption
}
