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

/* A resource without a fetch of its own, and what `refetch` and `mutate` on it
   reach instead: a `chain` stands for the resource that runs its fetch, a
   derived resource (`map`, `all`, ...) for the resources it derives from. */
type link =
  | Own(Obj.t)
  | Sources(array<Obj.t>)

let links: WeakMap.t<Obj.t, link> = WeakMap.make()

/* The machinery behind `make` and `chain`. `run` is called in the fetch
   effect, so the signals it reads before returning are dependencies; it
   returns the fetch to start, or `None` when there is nothing to fetch yet —
   then nothing changes: no new version, no loading state, and a fetch already
   in flight goes on. A resource that `suspends` makes the nearest suspense
   wait for its first settle and counts its fetches toward it; one that does
   not leaves both to whoever wraps it. */
let makeWith = (~suspends: bool, run: unit => option<promise<'a>>): t<'a> => {
  let state: t<'a> = Signal.make(Pending)
  /* On the server nothing awaits the fetch, so none is started. */
  if !RuntimeLifecycle.serverRendering() {
    let controller = {
      trigger: Signal.make(0),
      version: 0,
      resume: suspends ? RuntimeLifecycle.suspend() : () => (),
      flight: suspends ? RuntimeLifecycle.flight() : RuntimeLifecycle.noFlight,
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
      /* Starts a fetch: a new version, and the loading state. Returns how the
         fetch settles. */
      let begin = () => {
        controller.version = controller.version + 1
        let version = controller.version
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
        next =>
          if version == controller.version {
            Signal.set(state, next)
            controller.resume()
            controller.flight.finish()
          }
      }
      switch run() {
      | Some(promise) =>
        let settle = begin()
        /* The outcome is read first and settled after: a failure in what
           settling sets off — a view that renders the value — is not the
           fetch failing, and must not turn into `Failed`. */
        promise
        ->Promise.thenResolve(value => Ready(value))
        ->Promise.catch(exn => Promise.resolve(Failed(exn)))
        ->Promise.thenResolve(settle)
        ->ignore
      | None => ()
      | exception exn => begin()(Failed(exn))
      }
      None
    })
  }
  state
}

let make = (fetch: unit => promise<'a>): t<'a> => makeWith(~suspends=true, () => Some(fetch()))

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

/* Two states are the same when they are the same case carrying the same
   value. A derived resource builds a new state on every recompute, so this
   is its cutoff: readers wake only when the case or the value changed. */
let sameState = (a: state<'a>, b: state<'a>): bool =>
  switch (a, b) {
  | (Pending, Pending) => true
  | (Ready(x), Ready(y)) | (Refreshing(x), Refreshing(y)) => x === y
  | (Failed(x), Failed(y)) => x === y
  | _ => false
  }

/* A resource derived from `sources`. Its state is:
   - `Failed` as soon as one source has failed (the first, in order);
   - else `Pending` while one source has no value yet;
   - else `derive` of every source's value, `Refreshing` while one source is
     fetching again and `Ready` otherwise.
   `derive` is not run again while every source still carries the same value,
   so a source that only starts or stops refreshing keeps the derived value as
   it was. A `derive` that throws makes the derived resource `Failed`. */
let derived = (sources: array<t<Obj.t>>, derive: array<Obj.t> => 'b): t<'b> => {
  let last: ref<option<(array<Obj.t>, 'b)>> = ref(None)
  let resource = Computed.make(() => {
    let states = sources->Array.map(Signal.get)
    let failure = states->Array.findMap(state =>
      switch state {
      | Failed(exn) => Some(exn)
      | Pending | Ready(_) | Refreshing(_) => None
      }
    )
    switch failure {
    | Some(exn) => Failed(exn)
    | None =>
      if states->Array.some(state =>
        switch state {
        | Pending => true
        | Ready(_) | Refreshing(_) | Failed(_) => false
        }
      ) {
        Pending
      } else {
        let values = states->Array.filterMap(value)
        let refreshing = states->Array.some(isLoading)
        let reused = switch last.contents {
        | Some((inputs, output)) if inputs->Array.everyWithIndex((input, index) =>
            input === values->Array.getUnsafe(index)
          ) =>
          Some(output)
        | _ => None
        }
        switch reused {
        | Some(output) => refreshing ? Refreshing(output) : Ready(output)
        | None =>
          switch derive(values) {
          | output => {
              last := Some((values, output))
              refreshing ? Refreshing(output) : Ready(output)
            }
          | exception exn => Failed(exn)
          }
        }
      }
    }
  }, ~equals=sameState)
  links->WeakMap.set(Obj.magic(resource), Sources(Obj.magic(sources)))->ignore
  resource
}

let map = (resource: t<'a>, fn: 'a => 'b): t<'b> =>
  derived([Obj.magic(resource)], values => fn(Obj.magic(values->Array.getUnsafe(0))))

let map2 = (first: t<'a>, second: t<'b>, fn: ('a, 'b) => 'c): t<'c> =>
  derived([Obj.magic(first), Obj.magic(second)], values =>
    fn(Obj.magic(values->Array.getUnsafe(0)), Obj.magic(values->Array.getUnsafe(1)))
  )

let map3 = (first: t<'a>, second: t<'b>, third: t<'c>, fn: ('a, 'b, 'c) => 'd): t<'d> =>
  derived([Obj.magic(first), Obj.magic(second), Obj.magic(third)], values =>
    fn(
      Obj.magic(values->Array.getUnsafe(0)),
      Obj.magic(values->Array.getUnsafe(1)),
      Obj.magic(values->Array.getUnsafe(2)),
    )
  )

let all = (resources: array<t<'a>>): t<array<'a>> =>
  derived(Obj.magic(resources), values => Obj.magic(values))

/* A resource whose fetch needs the value of another. The fetch runs when the
   source settles with a value (`Ready`), never while it has none or is only
   refreshing, so a slow source does not start a fetch per state change. Seen
   from outside, the chain is loading while either fetch is: `Pending` or
   `Failed` while the source is, and the chain's own state otherwise, shown as
   `Refreshing` while the source refreshes. Like `make`, it makes the
   suspense it is created under wait — here until it first has a value or
   fails, which takes the source too. */
let chain = (source: t<'a>, fetch: 'a => promise<'b>): t<'b> => {
  let started = ref(false)
  let own = makeWith(~suspends=false, () =>
    switch Signal.get(source) {
    | Ready(value) => {
        started := true
        Some(fetch(value))
      }
    /* Created while the source refreshes: what it has is the best there is,
       until it settles. */
    | Refreshing(value) if !started.contents => {
        started := true
        Some(fetch(value))
      }
    | Refreshing(_) | Pending | Failed(_) => None
    }
  )
  let resource = Computed.make(() =>
    switch (Signal.get(source), Signal.get(own)) {
    | (Pending, _) => Pending
    | (Failed(exn), _) => Failed(exn)
    | (Refreshing(_), Ready(value)) => Refreshing(value)
    | (Ready(_) | Refreshing(_), state) => state
    }
  , ~equals=sameState)
  links->WeakMap.set(Obj.magic(resource), Own(Obj.magic(own)))->ignore
  hold(resource)
  resource
}

/* The fetches `resource` stands for, each once however many paths lead to
   it: its own, or those of what it derives from. */
let rec collectTriggers = (resource: Obj.t, seen: Set.t<Obj.t>, triggers: array<Signal.t<int>>) =>
  if !(seen->Set.has(resource)) {
    seen->Set.add(resource)
    switch controllers->WeakMap.get(resource) {
    | Some(controller) => triggers->Array.push(controller.trigger)
    | None =>
      switch links->WeakMap.get(resource) {
      | Some(Own(own)) => collectTriggers(own, seen, triggers)
      | Some(Sources(sources)) => sources->Array.forEach(source => collectTriggers(source, seen, triggers))
      | None => ()
      }
    }
  }

let refetch = (resource: t<'a>): unit => {
  let triggers = []
  collectTriggers(Obj.magic(resource), Set.make(), triggers)
  /* One batch: a resource two of them lead to fetches once. */
  Signal.batch(() => triggers->Array.forEach(trigger => Signal.update(trigger, count => count + 1)))
}

let rec mutate = (resource: t<'a>, value: 'a): unit =>
  switch controllers->WeakMap.get(Obj.magic(resource)) {
  | Some(controller) => {
      controller.version = controller.version + 1
      controller.resume()
      controller.flight.finish()
      Signal.set(resource, Ready(value))
    }
  | None =>
    switch links->WeakMap.get(Obj.magic(resource)) {
    | Some(Own(own)) => mutate(Obj.magic(own), value)
    /* A derived value has no source of its own to set. */
    | Some(Sources(_)) => ()
    | None => Signal.set(resource, Ready(value))
    }
  }
