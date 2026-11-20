/* Async values: computeds over promises.

   A deliberate re-export of `rescript-signals` (see `Signal.res` for why), with
   one addition: during a server render no fetch starts, as for `Resource`. The
   value is simply not ready there, so the server renders what does not need
   it, and the client fetches once it hydrates. */

exception NotReady = Signals.Async.NotReady

let make = (fetch: unit => promise<'a>, ~name: option<string>=?): Signal.t<'a> =>
  if RuntimeLifecycle.serverRendering() {
    Obj.magic(Signals.Computed.make(() => throw(NotReady), ~name?))
  } else {
    Obj.magic(Signals.Async.make(fetch, ~name?))
  }

let isPending = Signals.Async.isPending
