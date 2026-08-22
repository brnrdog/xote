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

let createOwner = (): owner => {
  disposers: [],
  computeds: [],
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

/* ---- scopes ---------------------------------------------------------------

   Most DOM elements own nothing. A static `<td class="col-md-1">` registers no
   effect and no computed, yet allocating its scope up front cost an owner
   record, two arrays and an expando property on the element — and then a walk
   over all of it at disposal. Measured on the keyed-list benchmark, 78% of the
   owners the renderer allocated carried nothing at all: 9 per row, 7 of them
   empty.

   So a scope starts as a promise of an owner rather than an owner. Nothing is
   allocated until something actually registers, at which point the owner is
   created and attached to the node the scope belongs to. Elements that own
   nothing now cost nothing. */

type scope = {
  mutable owner: option<owner>,
  /* Where to attach on materialisation. Null for a scope whose node does not
     exist yet — a component's, whose element only exists once its body has
     run; the caller attaches that one itself afterwards. */
  host: Nullable.t<Dom.element>,
}

let currentScope: ref<option<scope>> = ref(None)

let scopeFor = (~host: Nullable.t<Dom.element>): scope => {owner: None, host}

/* The owner this scope stands for, created on first use. */
let materialize = (scope: scope): owner =>
  switch scope.owner {
  | Some(owner) => owner
  | None => {
      let owner = createOwner()
      scope.owner = Some(owner)
      switch scope.host->Nullable.toOption {
      | Some(element) => attachOwner(element, owner)
      | None => ()
      }
      owner
    }
  }

let runInScope = (scope: scope, fn: unit => 'a): 'a => {
  let previous = currentScope.contents
  currentScope := Some(scope)
  let result = fn()
  currentScope := previous
  result
}

/* Run `fn` against an owner that already exists — the reactive-node scopes
   (`SignalText`, `SignalFragment`, `KeyedList`, hydration) always register
   something, so there is nothing to defer. */
let runWithOwner = (owner: owner, fn: unit => 'a): 'a =>
  runInScope({owner: Some(owner), host: Nullable.null}, fn)

/* Register with the scope that is currently rendering, if there is one. */
let track = (register: (owner, 'a) => unit, value: 'a): unit =>
  switch currentScope.contents {
  | Some(scope) => register(materialize(scope), value)
  | None => ()
  }
