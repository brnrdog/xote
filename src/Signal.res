/* Reactive state cells.

   This is a deliberate, reviewed re-export of `rescript-signals` rather than an
   `include`: Xote's public API must not grow whenever the upstream package adds
   a helper. `t` is abstract (see `Signal.resi`), so the underlying record - and
   in particular its `mutable value` field - cannot be written behind the
   scheduler's back. */

type t<'a> = Signals.Signal.t<'a>

let make = Signals.Signal.make
let get = Signals.Signal.get
let peek = Signals.Signal.peek
let set = Signals.Signal.set
let update = Signals.Signal.update
let batch = Signals.Signal.batch
let untrack = Signals.Signal.untrack
