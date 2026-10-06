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

let refs: array<entry> = []
let mounts: array<entry> = []

let takeAll = (queue: array<entry>): array<entry> => {
  let taken = Array.copy(queue)
  queue->Array.splice(~start=0, ~remove=Array.length(queue), ~insert=[])
  taken
}

let runAll = (entries: array<entry>): unit =>
  entries->Array.forEach(entry =>
    if entry.live {
      entry.live = false
      entry.run()
    }
  )

/* Refs first, then mounts, until nothing is left: a callback that renders
   something schedules more, which its own render operation flushes, so each
   round only runs what was queued before it started. */
let rec flush = (): unit =>
  if Array.length(refs) > 0 || Array.length(mounts) > 0 {
    runAll(takeAll(refs))
    runAll(takeAll(mounts))
    flush()
  }

/* A render that throws past every boundary inserted nothing reliable, so what
   it scheduled is dropped rather than run against detached DOM. */
let discard = (): unit => {
  takeAll(refs)->Array.forEach(entry => entry.live = false)
  takeAll(mounts)->Array.forEach(entry => entry.live = false)
}

let rendering = (fn: unit => 'a): 'a => {
  depth := depth.contents + 1
  let result = try {
    fn()
  } catch {
  | exn => {
      depth := depth.contents - 1
      if depth.contents == 0 {
        discard()
      }
      throw(exn)
    }
  }
  depth := depth.contents - 1
  if depth.contents == 0 {
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
   rendering now. Scheduled outside one — a component function called eagerly,
   as in `View.mount(app(), container)`, runs before the mount starts — it waits
   for the next render operation to finish, or for a microtask if none comes. */
let schedule = (queue: array<entry>, run: unit => unit): unit =>
  if onServer.contents == 0 {
    let entry = {live: true, run}
    RuntimeOwner.track(RuntimeOwner.addDisposer, () => entry.live = false)
    queue->Array.push(entry)->ignore
    if depth.contents == 0 && !microtaskPending.contents {
      microtaskPending := true
      queueMicrotask(() => {
        microtaskPending := false
        if depth.contents == 0 {
          flush()
        }
      })
    }
  }

/* Hand `element` to `ref` once it is inserted, and take it back when the
   region that rendered it is released — unless the ref has since moved on to
   another element. */
let attachRef = (ref: RuntimeNode.elementRef, element: Dom.element): unit => {
  schedule(refs, () => {
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
  schedule(mounts, () => ignore(run()))
}

/* Run `fn` when the region rendering now is released. Release happens inside
   whichever update removed the region, so `fn` runs untracked. */
let onCleanup = (fn: unit => unit): unit =>
  RuntimeOwner.track(RuntimeOwner.addDisposer, () => Signal.untrack(fn))
