/* Internal: the context values a component renders under, and how they follow
   the subtree into the effects that update it later.

   The values form a *frame*: an immutable list of what the components above
   provided. A component body that provides something pushes an entry; the
   renderer puts the frame back once that component's result has rendered, so
   siblings never see it. Rendering is synchronous, but updates are not: a
   `tracked` pass, a keyed reconcile or a component's own effect runs long after
   the component above it returned. Every effect therefore captures the frame it
   was created under and runs under it again, so a later pass renders with the
   context its first pass had. */

type rec frame = {
  context: Obj.t,
  value: Obj.t,
  parent: Nullable.t<frame>,
}

/* The frame the current render or effect runs under; null when nothing above
   provided anything, which keeps effects in an app without providers free of
   any wrapping. */
let current: ref<Nullable.t<frame>> = ref(Nullable.null)

/* Whether a component body is running, the only place `provide` may be called:
   anywhere else there is no render to scope the entry to, and it would stay in
   place for everything rendered afterwards. */
let inBody = ref(false)

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
    current := Nullable.make({context, value, parent: current.contents})
  } else {
    JsError.throwWithMessage(
      "[Xote] Context.provide was called outside a component body. Call it while the component renders, or use <Context.Provider>.",
    )
  }

/* Run an effect body under the frame it was created under. Without a frame
   there is nothing to restore, so the body is returned as is. */
let bind = (fn: unit => option<unit => unit>): (unit => option<unit => unit>) =>
  switch current.contents->Nullable.toOption {
  | None => fn
  | Some(_) => {
      let frame = current.contents
      () => {
        let savedFrame = current.contents
        let savedBody = inBody.contents
        current := frame
        inBody := false
        try {
          let cleanup = fn()
          current := savedFrame
          inBody := savedBody
          cleanup
        } catch {
        | exn => {
            current := savedFrame
            inBody := savedBody
            throw(exn)
          }
        }
      }
    }
  }

/* Evaluate a component and render what it returned, with the component's
   provisions in place for its result and gone afterwards. The body runs
   untracked: rendering happens inside the enclosing region's effect, and an
   eager read in a body must not subscribe that region. */
let renderComponent = (fn: unit => RuntimeNode.node, render: RuntimeNode.node => 'a): 'a => {
  let savedFrame = current.contents
  let savedBody = inBody.contents
  inBody := true
  try {
    let node = Signal.untrack(fn)
    inBody := savedBody
    let result = render(node)
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
