/* Internal: what a component renders under — the context values provided above
   it and the nearest error boundary — and how that follows the subtree into the
   effects that update it later.

   Both live in a *frame*: an immutable list of what the components above
   provided, each entry also carrying the nearest boundary so finding it is one
   read. A component body that provides something pushes an entry; the
   renderer puts the frame back once that component's result has rendered, so
   siblings never see it. Rendering is synchronous, but updates are not: a
   `tracked` pass, a keyed reconcile or a component's own effect runs long after
   the component above it returned. Every effect therefore captures the frame it
   was created under and runs under it again, so a later pass renders with the
   context and the boundary its first pass had. */

type boundary = {
  /* What renders in place of the subtree when its synchronous render fails. */
  fallback: exn => RuntimeNode.node,
  /* Takes a failure from a later update, after the subtree has rendered. */
  report: exn => unit,
  /* True while the subtree renders synchronously: a failure inside an effect's
     first run is recorded rather than reported, and the render that started it
     falls back once it returns. */
  mutable rendering: bool,
  mutable caught: option<exn>,
}

type rec frame = {
  context: Obj.t,
  value: Obj.t,
  parent: Nullable.t<frame>,
  boundary: Nullable.t<boundary>,
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

let push = (~context: Obj.t, ~value: Obj.t, ~boundary: Nullable.t<boundary>): unit =>
  current := Nullable.make({context, value, parent: current.contents, boundary})

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
    push(~context, ~value, ~boundary=boundaryOf(current.contents))
  } else {
    JsError.throwWithMessage(
      "[Xote] Context.provide was called outside a component body. Call it while the component renders, or use <Context.Provider>.",
    )
  }

let installBoundary = (boundary: boundary): unit =>
  push(~context=noContext, ~value=noContext, ~boundary=Nullable.make(boundary))

/* A failure under `frame` goes to the nearest boundary, or propagates as it
   always has when there is none. */
let fail = (frame: Nullable.t<frame>, exn: exn): unit =>
  switch boundaryOf(frame)->Nullable.toOption {
  | None => throw(exn)
  | Some(boundary) =>
    if boundary.rendering {
      if boundary.caught == None {
        boundary.caught = Some(exn)
      }
    } else {
      /* The failing effect is still the running observer: nothing the
         boundary's callbacks read may subscribe it. */
      Signal.untrack(() => boundary.report(exn))
    }
  }

/* Run an effect body under the frame it was created under, handing a failure
   to the frame's boundary. Without a frame there is nothing to restore and no
   boundary to report to, so the body is returned as is. */
let bind = (fn: unit => option<unit => unit>): (unit => option<unit => unit>) =>
  switch current.contents->Nullable.toOption {
  | None => fn
  | Some(_) => {
      let frame = current.contents
      () => {
        let savedFrame = current.contents
        current := frame
        try {
          let cleanup = fn()
          current := savedFrame
          cleanup
        } catch {
        | exn => {
            current := savedFrame
            fail(frame, exn)
            None
          }
        }
      }
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
  | exn => Error(exn)
  }
  boundary.rendering = wasRendering
  let caught = boundary.caught
  boundary.caught = None
  switch (outcome, caught) {
  | (Ok(result), None) => result
  | (Error(exn), _) | (Ok(_), Some(exn)) => {
      RuntimeOwner.disposeOwner(owner)
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
