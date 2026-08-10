/* Side effects that re-run when their dependencies change.

   A deliberate re-export of `rescript-signals` (see `Signal.res` for why). */

type disposer = Signals.Effect.disposer = {dispose: unit => unit}

let run = Signals.Effect.run
let runWithDisposer = Signals.Effect.runWithDisposer
