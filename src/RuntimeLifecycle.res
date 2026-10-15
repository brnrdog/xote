/* Internal: work that has to wait until rendered DOM is in place — element refs
   and `onMount` callbacks.

   Rendering builds DOM detached and inserts it at the end: `View.mount` appends
   the finished tree, a fragment pass appends its children to a container that
   is already in the page, a keyed reconcile places its rows once they are all
   built. Every one of those operations runs through `rendering`, and whatever
   the render scheduled is held until the outermost one returns, so a callback
   always sees its DOM inserted, along with every ref in it. Refs are handed
   over before any `onMount` runs, so a component's `onMount` can read the refs
   of everything it rendered.

   Each scheduled entry belongs to the region rendering when it was scheduled.
   A region released before the flush — a failed subtree an error boundary
   replaced, a pass that a later pass already superseded — takes its entries
   with it, so nothing runs for DOM that never made it into the page. */

type entry = {
  mutable live: bool,
  run: unit => unit,
}

/* How many render operations are in progress; entries flush when it drops back
   to zero. */
let depth = ref(0)

/* Server rendering produces markup, not DOM: nothing is ever inserted, so
   nothing scheduled there runs. */
let onServer = ref(0)

/* Read at call time: a module can load before a test or a bundler's shim has
   defined `document`. */
let noDocument: unit => bool = %raw(`function () { return typeof document === "undefined" }`)

let refs: array<entry> = []
let mounts: array<entry> = []

/* Entries scheduled outside any render operation — by a component function
   called eagerly, as in `View.mount(app(), container)`. They belong to
   whichever mount or hydration comes next, not to an unrelated update that
   happens to finish first, so only those (or a microtask, if none comes) take
   them. */
let eagerRefs: array<entry> = []
let eagerMounts: array<entry> = []

let takeAll = (queue: array<'a>): array<'a> => {
  let taken = Array.copy(queue)
  queue->Array.splice(~start=0, ~remove=Array.length(queue), ~insert=[])
  taken
}

/* Drop what a failed render operation scheduled: everything past `mark`. */
let discardFrom = (queue: array<entry>, mark: int): unit =>
  if Array.length(queue) > mark {
    queue
    ->Array.splice(~start=mark, ~remove=Array.length(queue) - mark, ~insert=[])
    ->ignore
  }

let discardAll = (queue: array<entry>): unit =>
  takeAll(queue)->Array.forEach(entry => entry.live = false)

/* Run every live entry, even when one throws: the rest of the batch still
   belongs to DOM that is in the page. The first failure is kept for the end. */
let runAll = (entries: array<entry>, ~failure: ref<option<exn>>): unit =>
  entries->Array.forEach(entry =>
    if entry.live {
      entry.live = false
      try {
        entry.run()
      } catch {
      | exn =>
        if failure.contents == None {
          failure := Some(exn)
        }
      }
    }
  )

/* Refs first, then mounts, until nothing is left: a callback that renders
   something schedules more, which its own render operation flushes, so each
   round only runs what was queued before it started. A failure is thrown once
   both queues are empty. */
let flush = (): unit => {
  let failure = ref(None)
  while Array.length(refs) > 0 || Array.length(mounts) > 0 {
    runAll(takeAll(refs), ~failure)
    runAll(takeAll(mounts), ~failure)
  }
  switch failure.contents {
  | Some(exn) => throw(exn)
  | None => ()
  }
}

/* Put the eager entries ahead of the ones the mount itself scheduled: the
   component that scheduled them is the one being mounted. */
let adoptEager = (): unit => {
  refs->Array.splice(~start=0, ~remove=0, ~insert=takeAll(eagerRefs))
  mounts->Array.splice(~start=0, ~remove=0, ~insert=takeAll(eagerMounts))
}

/* Run `fn` as a render operation. `~root` marks the operations that insert a
   tree a component function may have been called eagerly for — `View.mount`,
   `Hydration.hydrate` — and so take the eager entries. An operation that
   throws drops what it scheduled, at any depth: a boundary may catch the
   failure further out, and what the failed render queued must not outlive it. */
let rendering = (~root: bool=false, fn: unit => 'a): 'a => {
  let refMark = Array.length(refs)
  let mountMark = Array.length(mounts)
  depth := depth.contents + 1
  let result = try {
    fn()
  } catch {
  | exn => {
      depth := depth.contents - 1
      discardFrom(refs, refMark)
      discardFrom(mounts, mountMark)
      if depth.contents == 0 && root {
        discardAll(eagerRefs)
        discardAll(eagerMounts)
      }
      throw(exn)
    }
  }
  depth := depth.contents - 1
  if depth.contents == 0 {
    if root {
      adoptEager()
    }
    flush()
  }
  result
}

let server = (fn: unit => 'a): 'a => {
  onServer := onServer.contents + 1
  try {
    let result = fn()
    onServer := onServer.contents - 1
    result
  } catch {
  | exn => {
      onServer := onServer.contents - 1
      throw(exn)
    }
  }
}

@val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"

let microtaskPending = ref(false)

/* Queue `run` for after the current render operation, owned by the region
   rendering now. Scheduled outside one, it waits for the next mount or
   hydration, or for a microtask if none comes. Nothing is scheduled where
   there is no document to insert into. */
let schedule = (queue: array<entry>, ~eager: array<entry>, run: unit => unit): unit =>
  if onServer.contents == 0 && !noDocument() {
    let entry = {live: true, run}
    RuntimeOwner.track(RuntimeOwner.addDisposer, () => entry.live = false)
    if depth.contents > 0 {
      queue->Array.push(entry)->ignore
    } else {
      eager->Array.push(entry)->ignore
      if !microtaskPending.contents {
        microtaskPending := true
        queueMicrotask(() => {
          microtaskPending := false
          if depth.contents == 0 {
            adoptEager()
            flush()
          }
        })
      }
    }
  }

/* Hand `element` to `ref` once it is inserted, and take it back when the
   region that rendered it is released — unless the ref has since moved on to
   another element. */
let attachRef = (ref: RuntimeNode.elementRef, element: Dom.element): unit => {
  schedule(refs, ~eager=eagerRefs, () => {
    Signal.set(ref.element, Some(element))
    switch ref.callback->Nullable.toOption {
    | Some(callback) => Signal.untrack(() => callback(element))
    | None => ()
    }
  })
  RuntimeOwner.track(RuntimeOwner.addDisposer, () =>
    switch Signal.peek(ref.element) {
    | Some(current) if current === element => Signal.set(ref.element, None)
    | _ => ()
    }
  )
}

/* Run `fn` once the component calling it is in the document. It runs under the
   component's region, so `onCleanup` and `Effect.run` inside it belong to the
   component, and under the component's context and error boundary. */
let onMount = (fn: unit => unit): unit => {
  let owner = RuntimeOwner.currentOwner.contents
  let run = RuntimeContext.bind(() => {
    switch owner {
    | Some(owner) => RuntimeOwner.runWithOwner(owner, () => Signal.untrack(fn))
    | None => Signal.untrack(fn)
    }
    None
  })
  schedule(mounts, ~eager=eagerMounts, () => ignore(run()))
}

/* Run `fn` when the region rendering now is released. Release happens inside
   whichever update removed the region, so `fn` runs untracked. */
let onCleanup = (fn: unit => unit): unit =>
  RuntimeOwner.track(RuntimeOwner.addDisposer, () => Signal.untrack(fn))
