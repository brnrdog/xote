/* Internal: ownership of the reactive state a rendered region creates, so that
   removing the region stops it.

   A region is a unit the renderer removes as a whole: a keyed row, one pass of
   a `SignalFragment`, a hydrated row. Every effect and every library-built
   computed created while a region renders is registered with that region's
   owner, and disposing the owner releases all of it at once.

   Ownership used to hang off DOM nodes instead — an expando per element that
   registered anything, and a walk over the removed subtree at disposal to find
   them. That put a property on the DOM wrapper of one node in three and
   visited ten nodes per row to clear a list, and it cost the region's owner
   nothing it needed: the renderer only ever removes whole regions, so the
   region is the right granularity.

   Disposers are plain functions rather than `Effect.disposer` values on
   purpose: `Effect` registers its own disposers here (an effect created while a
   component renders belongs to that component's region), so a dependency in
   the other direction would be a cycle. */

/* Disposers (`unit => unit`) and library-owned computeds (`Signal.t`) share one
   array: a function is called, anything else is a computed to release. One
   array per owner instead of two, and most regions hold a handful of entries. */
type owner = {mutable owned: array<Obj.t>}

let createOwner = (): owner => {owned: []}

let isFunction: Obj.t => bool = %raw(`function (value) { return typeof value === "function" }`)

let addDisposer = (owner: owner, dispose: unit => unit): unit =>
  owner.owned->Array.push(Obj.magic(dispose))->ignore

let addComputed = (owner: owner, computed: Signal.t<'a>): unit =>
  owner.owned->Array.push(Obj.magic(computed))->ignore

/* Computeds the library builds to back a node — a reactive text leaf, a tracked
   fragment, a mapped list — are owned by the region that renders the node, so
   removing the region unlinks them from the signals they read. A signal that
   came from the consumer is never marked, and never disposed on their behalf. */
let markOwned: Signal.t<'a> => Signal.t<'a> = %raw(`function (signal) {
  signal["__xote_owned__"] = true
  return signal
}`)

let isOwned: Signal.t<'a> => bool = %raw(`function (signal) {
  return signal != null && signal["__xote_owned__"] === true
}`)

let ownedComputed = (compute: unit => 'a): Signal.t<'a> => markOwned(Computed.make(compute))

/* Entries are visited by index against the live length, so a cleanup that
   registers something with the owner it is being released from is released in
   the same pass rather than left behind. Disposal is idempotent on both kinds
   of entry, so an owner released twice does no harm. */
let disposeOwner = (owner: owner): unit => {
  let owned = owner.owned
  let index = ref(0)
  while index.contents < Array.length(owned) {
    let entry = owned->Array.getUnsafe(index.contents)
    if isFunction(entry) {
      let dispose: unit => unit = Obj.magic(entry)
      dispose()
    } else {
      let computed: Signal.t<Obj.t> = Obj.magic(entry)
      Computed.dispose(computed)
    }
    index := index.contents + 1
  }
}

/* The region currently rendering, if any. Outside a render — module level, an
   event handler — there is none, and reactive state created there lives until
   its own disposer runs. */
let currentOwner: ref<option<owner>> = ref(None)

/* The owner pointer is restored even when `fn` throws. Without that, a
   component body that raises leaves this module-global aimed at the abandoned
   region, and every effect created afterwards — anywhere, including outside any
   render — registers with an owner nothing will ever dispose. The scheduler
   upstream restores its own tracking state the same way, for the same reason. */
let runWithOwner = (owner: owner, fn: unit => 'a): 'a => {
  let previous = currentOwner.contents
  currentOwner := Some(owner)
  try {
    let result = fn()
    currentOwner := previous
    result
  } catch {
  | exn => {
      currentOwner := previous
      throw(exn)
    }
  }
}

/* Register with the region that is currently rendering, if there is one. */
let track = (register: (owner, 'a) => unit, value: 'a): unit =>
  switch currentOwner.contents {
  | Some(owner) => register(owner, value)
  | None => ()
  }

/* A node backed by a computed the library created carries its release with it:
   the region rendering the node owns the computed. A signal the consumer built
   and handed us is left alone. */
let ownComputed = (signal: Signal.t<'a>): unit =>
  if isOwned(signal) {
    track(addComputed, signal)
  }
