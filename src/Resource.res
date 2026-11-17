/* Asynchronous values as signals.

   A resource is a `Signal.t<state<'a>>` that a fetch keeps up to date: the fetch
   runs in an effect, so the signals it reads before its first `await` are its
   dependencies and a change to any of them fetches again. Only the latest fetch
   may settle the state; an earlier one that settles late is ignored.

   A resource created under a `View.Suspense` holds that suspense until its
   first fetch settles, through `RuntimeLifecycle.suspend`. Later fetches never
   suspend again: they show as `Refreshing` with the previous value kept. Every
   fetch, first or later, counts toward that suspense's `inFlight` while it is
   in flight, which is what `View.Suspense.pending` reads.

   `hold` lets a component make its own suspense wait for a resource created
   somewhere else, with the same rule: until the resource first has a value or
   fails. */

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
  /* This resource's share of that suspense's fetches in flight. */
  flight: RuntimeLifecycle.flight,
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
      flight: RuntimeLifecycle.flight(),
    }
    controllers->WeakMap.set(Obj.magic(state), controller)->ignore
    /* Released with the component that created it: whatever is in flight is
       dropped, and a suspense still waiting for it stops waiting. */
    RuntimeOwner.track(RuntimeOwner.addDisposer, () => {
      controller.version = controller.version + 1
      controller.resume()
      controller.flight.finish()
    })

    Effect.run(() => {
      let _ = Signal.get(controller.trigger)
      controller.version = controller.version + 1
      let version = controller.version
      let settle = next =>
        if version == controller.version {
          Signal.set(state, next)
          controller.resume()
          controller.flight.finish()
        }
      /* A fetch that replaces one still in flight keeps the count where it
         is: only the latest fetch settling ends it. */
      controller.flight.start()
      Signal.set(
        state,
        switch Signal.peek(state) {
        | Ready(value) | Refreshing(value) => Refreshing(value)
        | Pending | Failed(_) => Pending
        },
      )
      switch fetch() {
      | promise =>
        /* The outcome is read first and settled after: a failure in what
           settling sets off — a view that renders the value — is not the
           fetch failing, and must not turn into `Failed`. */
        promise
        ->Promise.thenResolve(value => Ready(value))
        ->Promise.catch(exn => Promise.resolve(Failed(exn)))
        ->Promise.thenResolve(settle)
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
      controller.flight.finish()
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

/* Make the suspense of the calling component wait for a resource created
   elsewhere. The wait follows the creator's rule: it lasts until the resource
   first leaves `Pending` — a value or a failure — and never comes back, so a
   resource that already has one holds nothing. Its fetches count toward the
   suspense's `inFlight` for as long as the hold lasts. Released with the
   calling component. */
let hold = (resource: t<'a>): unit =>
  if !RuntimeLifecycle.serverRendering() {
    switch RuntimeLifecycle.nearestSuspense() {
    | None => ()
    | Some(suspense) => {
        let flight = RuntimeLifecycle.flightOn(suspense)
        /* `None` before the first run; then the open wait, if any. Once the
           resource has left `Pending` it is `Some(noop)` for good. */
        let wait: ref<option<unit => unit>> = ref(None)
        let endWait = () =>
          switch wait.contents {
          | Some(resume) => {
              wait := Some(() => ())
              resume()
            }
          | None => wait := Some(() => ())
          }
        RuntimeOwner.track(RuntimeOwner.addDisposer, () => {
          endWait()
          flight.finish()
        })
        Effect.run(() => {
          let state = Signal.get(resource)
          switch (state, wait.contents) {
          | (Pending, None) => wait := Some(RuntimeLifecycle.suspendOn(suspense))
          | (Pending, Some(_)) => ()
          | (Ready(_) | Refreshing(_) | Failed(_), _) => endWait()
          }
          if isLoading(state) {
            flight.start()
          } else {
            flight.finish()
          }
          None
        })
      }
    }
  }
