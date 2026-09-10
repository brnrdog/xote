/* Side effects that re-run when their dependencies change.

   The effect body returns `Some(cleanup)` to register teardown that runs before
   the next execution and on disposal, or `None` when there is nothing to clean
   up. */

type disposer = {dispose: unit => unit}

/* Fire-and-forget: the effect lives until its owner is disposed */
let run: (unit => option<unit => unit>, ~name: string=?) => unit

/* Returns a disposer for manual teardown */
let runWithDisposer: (unit => option<unit => unit>, ~name: string=?) => disposer
