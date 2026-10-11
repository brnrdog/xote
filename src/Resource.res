/* Asynchronous values as signals.

   A resource is a `Signal.t<state<'a>>` that a fetch keeps up to date: the fetch
   runs in an effect, so the signals it reads before its first `await` are its
   dependencies and a change to any of them fetches again. Only the latest fetch
   may settle the state; an earlier one that settles late is ignored.

   A resource created under a `View.Suspense` holds that suspense until its
   first fetch settles, through `RuntimeLifecycle.suspend`. Later fetches never
   suspend again: they show as `Refreshing` with the previous value kept. */

type state<'a> =
  | Pending
  | Ready('a)
  | Refreshing('a)
  | Failed(exn)

type t<'a> = Signal.t<state<'a>>

/* What `refetch` and `mutate` reach a resource's fetch through, keyed by its
   signal. */
type controller = {
  trigger: Signal.t<int>,
  /* Bumped by every fetch, by `mutate` and on disposal: a settling fetch that
     no longer holds the current version is ignored. */
  mutable version: int,
  /* Ends the wait of the suspense the resource was created under. */
  resume: unit => unit,
}

let controllers: WeakMap.t<Obj.t, controller> = WeakMap.make()

let make = (fetch: unit => promise<'a>): t<'a> => {
  let state: t<'a> = Signal.make(Pending)
  /* On the server nothing awaits the fetch, so none is started. */
  if !RuntimeLifecycle.serverRendering() {
    let controller = {
      trigger: Signal.make(0),
      version: 0,
      resume: RuntimeLifecycle.suspend(),
    }
    controllers->WeakMap.set(Obj.magic(state), controller)->ignore
    /* Released with the component that created it: whatever is in flight is
       dropped, and a suspense still waiting for it stops waiting. */
    RuntimeOwner.track(RuntimeOwner.addDisposer, () => {
      controller.version = controller.version + 1
      controller.resume()
    })

    Effect.run(() => {
      let _ = Signal.get(controller.trigger)
      controller.version = controller.version + 1
      let version = controller.version
      let settle = next =>
        if version == controller.version {
          Signal.set(state, next)
          controller.resume()
        }
      Signal.set(
        state,
        switch Signal.peek(state) {
        | Ready(value) | Refreshing(value) => Refreshing(value)
        | Pending | Failed(_) => Pending
        },
      )
      switch fetch() {
      | promise =>
        promise
        ->Promise.thenResolve(value => settle(Ready(value)))
        ->Promise.catch(exn => {
          settle(Failed(exn))
          Promise.resolve()
        })
        ->ignore
      | exception exn => settle(Failed(exn))
      }
      None
    })
  }
  state
}

let refetch = (resource: t<'a>): unit =>
  switch controllers->WeakMap.get(Obj.magic(resource)) {
  | Some(controller) => Signal.update(controller.trigger, count => count + 1)
  | None => ()
  }

let mutate = (resource: t<'a>, value: 'a): unit => {
  switch controllers->WeakMap.get(Obj.magic(resource)) {
  | Some(controller) => {
      controller.version = controller.version + 1
      controller.resume()
    }
  | None => ()
  }
  Signal.set(resource, Ready(value))
}

let value = (state: state<'a>): option<'a> =>
  switch state {
  | Ready(value) | Refreshing(value) => Some(value)
  | Pending | Failed(_) => None
  }

let isLoading = (state: state<'a>): bool =>
  switch state {
  | Pending | Refreshing(_) => true
  | Ready(_) | Failed(_) => false
  }
