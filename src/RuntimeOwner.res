/* Internal: the per-DOM-node scope that owns the reactive state created while a
   node is being built and rendered, so removing the node stops it.

   Disposers are stored as plain functions rather than `Effect.disposer` values
   on purpose: `Effect` registers its own disposers here (an effect created
   while a component renders belongs to that component), so a dependency in the
   other direction would be a cycle. */

type owner = {
  disposers: array<unit => unit>,
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

let addDisposer = (owner: owner, dispose: unit => unit): unit => {
  owner.disposers->Array.push(dispose)->ignore
}

let addComputed = (owner: owner, computed: Obj.t): unit => {
  owner.computeds->Array.push(computed)->ignore
}

/* Computeds the library builds to back a node — a reactive text leaf, a tracked
   fragment, a mapped list — are owned by the node they back: rendering hands
   them to that node's scope, so removing the node unlinks them from the signals
   they read. A signal that came from the consumer is never marked, and never
   disposed on their behalf. */
let markOwned: Signal.t<'a> => Signal.t<'a> = %raw(`function (signal) {
  signal["__xote_owned__"] = true
  return signal
}`)

let isOwned: Signal.t<'a> => bool = %raw(`function (signal) {
  return signal != null && signal["__xote_owned__"] === true
}`)

let ownedComputed = (compute: unit => 'a): Signal.t<'a> => markOwned(Computed.make(compute))

/* Register with the scope that is currently rendering, if there is one. */
let track = (register: (owner, 'a) => unit, value: 'a): unit =>
  switch currentOwner.contents {
  | Some(owner) => register(owner, value)
  | None => ()
  }

/* Fold `source` into `target`. One DOM node can be the root of more than one
   scope — a component's own scope and the element it returns — and the second
   `setOwner` would otherwise overwrite the first, dropping its disposers on the
   floor instead of running them when the node goes away. */
let absorb = (target: owner, source: owner): unit => {
  source.disposers->Array.forEach(dispose => target.disposers->Array.push(dispose)->ignore)
  source.computeds->Array.forEach(computed => target.computeds->Array.push(computed)->ignore)
}

let disposeOwner = (owner: owner): unit => {
  owner.disposers->Array.forEach(dispose => dispose())

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

/* Attach without clobbering: merge into whatever scope the node already carries. */
let attachOwner = (element: Dom.element, owner: owner): unit =>
  switch getOwner(element) {
  | Some(existing) => absorb(existing, owner)
  | None => setOwner(element, owner)
  }
