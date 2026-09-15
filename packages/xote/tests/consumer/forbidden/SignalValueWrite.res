/* expect-error: value
   Mechanism: a record field on an abstract type. This is the one the issue
   called the sharpest edge - writing it desyncs the reactive graph without
   ever calling Signal.set. */
let bypassScheduler = (signal: Xote.Signal.t<int>) => signal.value = 99
