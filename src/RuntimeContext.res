/* Internal: what a component renders under — the context values provided above
   it, the nearest error boundary and the nearest suspense boundary — and how
   that follows the subtree into the effects that update it later.

   All of it lives in a *frame*: an immutable list of what the components above
   provided, each entry also carrying the nearest boundaries so finding one is a
   single read. A component body that provides something pushes an entry; the
   renderer puts the frame back once that component's result has rendered, so
   siblings never see it. Rendering is synchronous, but updates are not: a
   `tracked` pass, a keyed reconcile or a component's own effect runs long after
   the component above it returned. Every effect therefore captures the frame it
   was created under and runs under it again, so a later pass renders with the
   context and the boundary its first pass had — including an effect created
   under no frame at all, which must not pick up whichever frame happens to be
   installed when a write during a render flushes it. */

type boundary = {
  /* What renders in place of the subtree when its synchronous render fails. */
  fallback: exn => RuntimeNode.node,
  /* Takes a failure from a later update, after the subtree has rendered. */
  report: exn => unit,
  /* Hears every further failure of one synchronous render; the first is the
     one the fallback renders, and is heard through `fallback`. */
  notify: exn => unit,
  /* True while the subtree renders synchronously: a failure inside an effect's
     first run is recorded rather than reported, and the render that started it
     falls back once it returns. */
  mutable rendering: bool,
  mutable caught: option<exn>,
}

/* A `View.Suspense`: how many resources below it have yet to load for the
   first time, and the refs and `onMount` callbacks of its subtree, held back
   while that count is above zero so they run once the subtree is shown. */
type rec suspense = {
  pending: Signal.t<int>,
  /* The suspense this one renders inside, whose wait also holds back what
     this one renders. */
  parent: Nullable.t<suspense>,
  heldRefs: array<scheduled>,
  heldMounts: array<scheduled>,
}
/* An entry of `RuntimeLifecycle`'s post-render queue. Defined here so that a
   suspense can hold the entries themselves: released, each is checked again —
   for the region that scheduled it, and for its own suspense. */
and scheduled = {
  mutable live: bool,
  run: unit => unit,
  /* The suspense the entry was scheduled under, if any. */
  suspense: Nullable.t<suspense>,
}

type rec frame = {
  context: Obj.t,
  value: Obj.t,
  parent: Nullable.t<frame>,
  boundary: Nullable.t<boundary>,
  suspense: Nullable.t<suspense>,
}

/* The context of an entry that only installs a boundary: no context is ever
   this object, so a lookup walks past it. */
let noContext: Obj.t = %raw(`{}`)

/* The frame the current render or effect runs under; null when nothing above
   provided anything, which keeps effects in an app without providers free of
   any wrapping. */
let current: ref<Nullable.t<frame>> = ref(Nullable.null)

/* Whether a component body is running, the only place `provide` may be called:
   anywhere else there is no render to scope the entry to, and it would stay in
   place for everything rendered afterwards. */
let inBody = ref(false)

let boundaryOf = (frame: Nullable.t<frame>): Nullable.t<boundary> =>
  switch frame->Nullable.toOption {
  | Some(frame) => frame.boundary
  | None => Nullable.null
  }

let suspenseOf = (frame: Nullable.t<frame>): Nullable.t<suspense> =>
  switch frame->Nullable.toOption {
  | Some(frame) => frame.suspense
  | None => Nullable.null
  }

let push = (
  ~context: Obj.t,
  ~value: Obj.t,
  ~boundary: Nullable.t<boundary>=boundaryOf(current.contents),
  ~suspense: Nullable.t<suspense>=suspenseOf(current.contents),
): unit => current := Nullable.make({context, value, parent: current.contents, boundary, suspense})

let lookup = (context: Obj.t): option<Obj.t> => {
  let rec walk = (frame: Nullable.t<frame>) =>
    switch frame->Nullable.toOption {
    | Some(frame) =>
      if frame.context === context {
        Some(frame.value)
      } else {
        walk(frame.parent)
      }
    | None => None
    }
  walk(current.contents)
}

let provide = (context: Obj.t, value: Obj.t): unit =>
  if inBody.contents {
    push(~context, ~value)
  } else {
    JsError.throwWithMessage(
      "[Xote] Context.provide was called outside a component body. Call it while the component renders, or use <Context.Provider>.",
    )
  }

let installBoundary = (boundary: boundary): unit =>
  push(~context=noContext, ~value=noContext, ~boundary=Nullable.make(boundary))

let makeSuspense = (): suspense => {
  pending: Signal.make(0),
  parent: suspenseOf(current.contents),
  heldRefs: [],
  heldMounts: [],
}

let installSuspense = (suspense: suspense): unit =>
  push(~context=noContext, ~value=noContext, ~suspense=Nullable.make(suspense))

/* The innermost suspense, from `suspense` outwards, that is still waiting:
   where work scheduled under `suspense` has to wait. */
let rec waitingSuspense = (suspense: Nullable.t<suspense>): option<suspense> =>
  switch suspense->Nullable.toOption {
  | Some(suspense) =>
    if Signal.peek(suspense.pending) > 0 {
      Some(suspense)
    } else {
      waitingSuspense(suspense.parent)
    }
  | None => None
  }

/* A failure that reached code with no boundary above it, and so propagates.
   It can still pass through a boundary on its way out — a write made while a
   boundary's subtree renders flushes regions elsewhere in the page, on the
   same stack — and that boundary must not claim it. Marked on the thrown value
   itself: a JavaScript error is rewrapped each time ReScript catches it. */
let escaped: WeakSet.t<Obj.t> = WeakSet.make()

let thrownValue: exn => Obj.t = %raw(`function (exn) {
  return exn != null && exn.RE_EXN_ID === "JsExn" ? exn._1 : exn
}`)

let isObject: Obj.t => bool = %raw(`function (value) {
  return value !== null && (typeof value === "object" || typeof value === "function")
}`)

let escape = (exn: exn): 'a => {
  let value = thrownValue(exn)
  if isObject(value) {
    escaped->WeakSet.add(value)->ignore
  }
  throw(exn)
}

let hasEscaped = (exn: exn): bool => {
  let value = thrownValue(exn)
  isObject(value) && escaped->WeakSet.has(value)
}

/* A failure under `frame` goes to the nearest boundary, or propagates as it
   always has when there is none. */
let fail = (frame: Nullable.t<frame>, exn: exn): unit =>
  switch boundaryOf(frame)->Nullable.toOption {
  | None => escape(exn)
  | Some(_) if hasEscaped(exn) => throw(exn)
  | Some(boundary) =>
    if boundary.rendering {
      switch boundary.caught {
      | None => boundary.caught = Some(exn)
      | Some(_) => Signal.untrack(() => boundary.notify(exn))
      }
    } else {
      /* The failing effect is still the running observer: nothing the
         boundary's callbacks read may subscribe it. */
      Signal.untrack(() => boundary.report(exn))
    }
  }

/* Run `fn` under `frame`, outside any component body, handing a failure to
   the frame's boundary. */
let within = (frame: Nullable.t<frame>, fn: unit => 'a, ~onFailure: unit => 'a): 'a => {
  let savedFrame = current.contents
  let savedBody = inBody.contents
  current := frame
  inBody := false
  try {
    let result = fn()
    current := savedFrame
    inBody := savedBody
    result
  } catch {
  | exn => {
      current := savedFrame
      inBody := savedBody
      fail(frame, exn)
      onFailure()
    }
  }
}

/* Run an effect body, and the cleanup it returns, under the frame the effect
   was created under, handing a failure to the frame's boundary.

   An effect created under no frame still needs restoring to none: a write
   made while a component renders flushes effects on the same stack, and one
   that ran under the frame installed there would render its region with
   context from elsewhere, and hand its failures to a boundary that is not
   its own. In the usual case nothing is installed when it runs, and the body
   runs as is. */
let bind = (fn: unit => option<unit => unit>): (unit => option<unit => unit>) => {
  let frame = current.contents
  let wrapCleanup = (cleanup: option<unit => unit>) =>
    switch cleanup {
    | Some(cleanup) => Some(() => within(frame, cleanup, ~onFailure=() => ()))
    | None => None
    }
  switch frame->Nullable.toOption {
  | None => () =>
      if Nullable.isNullable(current.contents) && !inBody.contents {
        fn()
      } else {
        within(frame, fn, ~onFailure=() => None)
      }
  | Some(_) => () => wrapCleanup(within(frame, fn, ~onFailure=() => None))
  }
}

/* The subtree of a component that installed a boundary renders under an owner
   of its own, so a render that fails partway can be released whole before the
   fallback takes its place. A failure in an effect's first run lands in
   `caught` instead of escaping, and is treated the same way. */
let renderBoundary = (
  boundary: boundary,
  node: RuntimeNode.node,
  render: RuntimeNode.node => 'a,
  ~outer: Nullable.t<frame>,
): 'a => {
  let owner = RuntimeOwner.createOwner()
  RuntimeOwner.track(RuntimeOwner.addDisposer, () => RuntimeOwner.disposeOwner(owner))
  let wasRendering = boundary.rendering
  boundary.rendering = true
  boundary.caught = None
  let outcome = try {
    Ok(RuntimeOwner.runWithOwner(owner, () => render(node)))
  } catch {
  | exn =>
    if hasEscaped(exn) {
      /* Not this boundary's to handle: release what rendered, and let it go
         on to the caller. */
      RuntimeOwner.disposeOwner(owner)
      boundary.rendering = wasRendering
      boundary.caught = None
      throw(exn)
    } else {
      Error(exn)
    }
  }
  let caught = boundary.caught
  switch (outcome, caught) {
  | (Ok(result), None) => {
      boundary.rendering = wasRendering
      result
    }
  | (Error(exn), _) | (Ok(_), Some(exn)) => {
      /* Released while still rendering, so a cleanup that fails on the way
         out is recorded here rather than reported as a new failure. */
      RuntimeOwner.disposeOwner(owner)
      boundary.rendering = wasRendering
      boundary.caught = None
      /* The fallback renders outside the boundary, so a fallback that fails in
         turn goes to the boundary above. Like a component body, building it
         subscribes nothing. */
      current := outer
      render(Signal.untrack(() => boundary.fallback(exn)))
    }
  }
}

/* Evaluate a component and render what it returned, with the component's
   provisions in place for its result and gone afterwards; a component that
   installed a boundary renders its result through `renderBoundary`. The body
   runs untracked: rendering happens inside the enclosing region's effect, and
   an eager read in a body must not subscribe that region. */
let renderComponent = (fn: unit => RuntimeNode.node, render: RuntimeNode.node => 'a): 'a => {
  let savedFrame = current.contents
  let savedBody = inBody.contents
  inBody := true
  try {
    let node = Signal.untrack(fn)
    inBody := savedBody
    let installed = boundaryOf(current.contents)
    let result = if installed === boundaryOf(savedFrame) {
      render(node)
    } else {
      switch installed->Nullable.toOption {
      | Some(boundary) => renderBoundary(boundary, node, render, ~outer=savedFrame)
      | None => render(node)
      }
    }
    current := savedFrame
    result
  } catch {
  | exn => {
      current := savedFrame
      inBody := savedBody
      throw(exn)
    }
  }
}
