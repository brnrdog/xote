/* Before `open! Zekr`, whose `Dom` shadows the standard one. */
type domElement = Dom.element

open! Zekr

@send external querySelector: ('a, string) => Nullable.t<domElement> = "querySelector"
@get external style: domElement => {..} = "style"

type deferred<'a> = {
  promise: promise<'a>,
  resolve: 'a => unit,
  reject: exn => unit,
}

let deferred: unit => deferred<'a> = %raw(`function () {
  let resolve, reject
  const promise = new Promise((ok, fail) => { resolve = ok; reject = fail })
  return { promise, resolve, reject }
}`)

/* Lets every settled promise run its callbacks. */
let settle = (): promise<unit> => Promise.make((resolve, _) => setTimeout(() => resolve(), 0)->ignore)

exception Unavailable(string)

let text = (container, selector): option<string> =>
  querySelector(container, selector)->Nullable.toOption->Option.map(Zekr__DomBindings.textContent)

let has = (container, selector) => querySelector(container, selector)->Nullable.toOption->Option.isSome

/* The display of the wrapper a suspense keeps its children in. */
let display = (container, selector): string =>
  switch querySelector(container, selector)->Nullable.toOption {
  | Some(element) =>
    switch Zekr__DomBindings.parentElement(element)->Nullable.toOption {
    | Some(wrapper) => style(wrapper)["display"]
    | None => "no wrapper"
    }
  | None => "missing"
  }

let describe = (state: Resource.state<string>): string =>
  switch state {
  | Pending => "pending"
  | Ready(value) => "ready:" ++ value
  | Refreshing(value) => "refreshing:" ++ value
  | Failed(Unavailable(reason)) => "failed:" ++ reason
  | Failed(_) => "failed"
  }

/* Renders the state of a resource it creates, and logs its mount. */
let loader = (~fetch, ~log: array<string>, ~name="loader") =>
  View.LazyComponent(
    () => {
      let resource = Resource.make(fetch)
      View.onMount(() => log->Array.push(name ++ ":mount")->ignore)
      <span class=name> {View.signalText(() => describe(Signal.get(resource)))} </span>
    },
  )

/* The style of the wrapper a suspense hides its children in, seen from an
   element inside it. */
let wrapperDisplay = (element: domElement): string =>
  switch Zekr__DomBindings.parentElement(element)->Nullable.toOption {
  | Some(wrapper) => style(wrapper)["display"]
  | None => "no wrapper"
  }

/* Logs its own mount, with what its wrapper's display was at that moment. */
let watcher = (~log: array<string>, ~name: string) =>
  View.LazyComponent(
    () => {
      let field = View.Ref.make()
      View.onMount(() =>
        log
        ->Array.push(
          name ++ ":" ++ View.Ref.peek(field)->Option.mapOr("no element", wrapperDisplay),
        )
        ->ignore
      )
      <i ref=field />
    },
  )

/* Creates its resource before its hooks, the natural order. */
let resourceFirst = (~fetch, ~log: array<string>) =>
  View.LazyComponent(
    () => {
      let _resource = Resource.make(fetch)
      View.onMount(() => log->Array.push("mount")->ignore)
      let field = View.Ref.fromCallback(_ => log->Array.push("ref")->ignore)
      <input ref=field />
    },
  )

/* Records unhandled promise rejections while `run` settles. */
let catchingRejections: (unit => promise<unit>) => promise<array<string>> = %raw(`async function (run) {
  const seen = []
  const handler = (reason) => { seen.push(String(reason && reason.RE_EXN_ID || reason)) }
  process.on("unhandledRejection", handler)
  try { await run() } finally {
    await new Promise((resolve) => setTimeout(resolve, 0))
    process.off("unhandledRejection", handler)
  }
  return seen
}`)

/* Renders whether the nearest suspense has a fetch in flight. */
let pendingProbe = (~name="probe") =>
  View.LazyComponent(
    () => {
      let pending = View.Suspense.pending()
      <span class=name> {View.signalText(() => Signal.get(pending) ? "busy" : "idle")} </span>
    },
  )

/* Holds a resource created elsewhere, renders its state and logs its mount. */
let holder = (resource: Resource.t<string>, ~log: array<string>, ~name="holder") =>
  View.LazyComponent(
    () => {
      Resource.hold(resource)
      View.onMount(() => log->Array.push(name ++ ":mount")->ignore)
      <span class=name> {View.signalText(() => describe(Signal.get(resource)))} </span>
    },
  )

/* What `console.warn` received while `run` ran. */
let capturingWarnings: (unit => unit) => array<string> = %raw(`function (run) {
  const seen = []
  const original = console.warn
  console.warn = (message) => { seen.push(String(message)) }
  try { run() } finally { console.warn = original }
  return seen
}`)

/* A resource whose every fetch waits on a promise of its own, kept in order so
   a test can settle the n-th fetch. */
let controlled = () => {
  let fetches: array<deferred<string>> = []
  let resource = Resource.make(() => {
    let fetch = deferred()
    fetches->Array.push(fetch)->ignore
    fetch.promise
  })
  (resource, fetches)
}

/* A chain over `source` that records the source values it fetched with, and
   waits on a promise of its own for each. */
let recordingChain = (source: Resource.t<string>) => {
  let inputs: array<string> = []
  let fetches: array<deferred<string>> = []
  let resource = source->Resource.chain(input => {
    inputs->Array.push(input)->ignore
    let fetch = deferred()
    fetches->Array.push(fetch)->ignore
    fetch.promise
  })
  (resource, inputs, fetches)
}

let peek = resource => describe(Signal.peek(resource))

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let suite = Zekr.asyncSuite(
  "Resources and Suspense",
  [
    asyncTest("a resource is Pending until its fetch settles", async () => {
      let pending = deferred()
      let resource = Resource.make(() => pending.promise)
      let before = describe(Signal.peek(resource))
      pending.resolve("ada")
      await settle()
      combineResults([assertEqual(before, "pending"), assertEqual(describe(Signal.peek(resource)), "ready:ada")])
    }),
    asyncTest("a dependency change fetches again, and a late earlier fetch is ignored", async () => {
      let id = Signal.make("1")
      let fetches: Dict.t<deferred<string>> = Dict.make()
      let resource = Resource.make(() => {
        let fetch = deferred()
        fetches->Dict.set(Signal.get(id), fetch)
        fetch.promise
      })
      (fetches->Dict.getUnsafe("1")).resolve("one")
      await settle()
      Signal.set(id, "2")
      let refreshing = describe(Signal.peek(resource))
      Signal.set(id, "3")
      (fetches->Dict.getUnsafe("3")).resolve("three")
      await settle()
      (fetches->Dict.getUnsafe("2")).resolve("two")
      await settle()
      combineResults([
        assertEqual(refreshing, "refreshing:one"),
        assertEqual(describe(Signal.peek(resource)), "ready:three"),
      ])
    }),
    asyncTest("a failed fetch settles as Failed, and refetch tries again", async () => {
      let attempts = ref(0)
      let resource = Resource.make(() => {
        attempts := attempts.contents + 1
        attempts.contents == 1 ? Promise.reject(Unavailable("offline")) : Promise.resolve("back")
      })
      await settle()
      let failed = describe(Signal.peek(resource))
      Resource.refetch(resource)
      let retrying = describe(Signal.peek(resource))
      await settle()
      combineResults([
        assertEqual(failed, "failed:offline"),
        assertEqual(retrying, "pending"),
        assertEqual(describe(Signal.peek(resource)), "ready:back"),
      ])
    }),
    asyncTest("a fetch that throws synchronously settles as Failed", async () => {
      let resource = Resource.make(() => throw(Unavailable("sync")))
      await settle()
      assertEqual(describe(Signal.peek(resource)), "failed:sync")
    }),
    asyncTest("mutate sets the value and drops the fetch in flight", async () => {
      let pending = deferred()
      let resource = Resource.make(() => pending.promise)
      Resource.mutate(resource, "optimistic")
      pending.resolve("server")
      await settle()
      assertEqual(describe(Signal.peek(resource)), "ready:optimistic")
    }),
    asyncTest("a suspense shows its fallback until its resources load", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback"> {View.text("Loading")} </p>}>
          {loader(~fetch=() => pending.promise, ~log=[])}
        </View.Suspense>,
        container,
      )
      let waiting = (has(container, ".fallback"), display(container, ".loader"))
      pending.resolve("ada")
      await settle()
      combineResults([
        assertEqual(waiting, (true, "none")),
        assertFalse(has(container, ".fallback")),
        assertEqual(display(container, ".loader"), "contents"),
        assertEqual(text(container, ".loader"), Some("ready:ada")),
      ])
    }),
    asyncTest("refs and onMount inside a suspense wait until it is shown", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let log = []
      let field = View.Ref.make()
      let _ = mountTo(
        <div>
          {View.LazyComponent(
            () => {
              View.onMount(() => log->Array.push("outside:mount")->ignore)
              <span />
            },
          )}
          <View.Suspense>
            {loader(~fetch=() => pending.promise, ~log)}
            <input ref=field />
          </View.Suspense>
        </div>,
        container,
      )
      let beforeLoad = (Array.copy(log), View.Ref.peek(field)->Option.isSome)
      pending.resolve("ada")
      await settle()
      combineResults([
        assertEqual(beforeLoad, (["outside:mount"], false)),
        assertEqual(log, ["outside:mount", "loader:mount"]),
        assertTrue(View.Ref.peek(field)->Option.isSome),
      ])
    }),
    asyncTest("a suspense waits for every resource, and only for their first load", async () => {
      let {container} = Dom.render("")
      let first = deferred()
      let second = deferred()
      let again = deferred()
      let calls = ref(0)
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {loader(~fetch=() => first.promise, ~log=[], ~name="first")}
          {View.LazyComponent(
            () => {
              let resource = Resource.make(() => {
                calls := calls.contents + 1
                calls.contents == 1 ? second.promise : again.promise
              })
              <button class="second" onClick={_ => Resource.refetch(resource)}>
                {View.signalText(() => describe(Signal.get(resource)))}
              </button>
            },
          )}
        </View.Suspense>,
        container,
      )
      first.resolve("a")
      await settle()
      let afterFirst = has(container, ".fallback")
      second.resolve("b")
      await settle()
      let afterBoth = has(container, ".fallback")
      Zekr__DomEvent.click(querySelector(container, ".second")->Nullable.getOrThrow)
      let refetching = (has(container, ".fallback"), text(container, ".second"))
      combineResults([
        assertTrue(afterFirst),
        assertFalse(afterBoth),
        assertEqual(refetching, (false, Some("refreshing:b"))),
      ])
    }),
    asyncTest("an inner suspense that is ready stays hidden while the outer one waits", async () => {
      let {container} = Dom.render("")
      let outer = deferred()
      let inner = deferred()
      let log = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="outer-fallback" />}>
          {loader(~fetch=() => outer.promise, ~log, ~name="outer")}
          <View.Suspense fallback={<p class="inner-fallback" />}>
            {loader(~fetch=() => inner.promise, ~log, ~name="inner")}
          </View.Suspense>
        </View.Suspense>,
        container,
      )
      inner.resolve("i")
      await settle()
      let innerReady = (has(container, ".inner-fallback"), has(container, ".outer-fallback"), Array.copy(log))
      outer.resolve("o")
      await settle()
      combineResults([
        assertEqual(innerReady, (false, true, [])),
        assertFalse(has(container, ".outer-fallback")),
        assertEqual(log, ["outer:mount", "inner:mount"]),
      ])
    }),
    asyncTest("removing a resource's component before it settles ends the wait", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          <View.Show when_={MaybeSignal.reactive(shown)}>
            {loader(~fetch=() => pending.promise, ~log=[])}
          </View.Show>
        </View.Suspense>,
        container,
      )
      let waiting = has(container, ".fallback")
      Signal.set(shown, false)
      pending.resolve("late")
      await settle()
      combineResults([assertTrue(waiting), assertFalse(has(container, ".fallback"))])
    }),
    asyncTest("a component removed while it waits never mounts, nor hands over its refs", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let log = []
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Suspense>
          <View.Show when_={MaybeSignal.reactive(shown)}>
            {resourceFirst(~fetch=() => pending.promise, ~log)}
          </View.Show>
        </View.Suspense>,
        container,
      )
      Signal.set(shown, false)
      await settle()
      pending.resolve("late")
      await settle()
      assertEqual(log, [])
    }),
    asyncTest("a suspense removed while it waits never mounts its children", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let log = []
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(shown)}>
          <View.Suspense> {resourceFirst(~fetch=() => pending.promise, ~log)} </View.Suspense>
        </View.Show>,
        container,
      )
      Signal.set(shown, false)
      await settle()
      assertEqual(log, [])
    }),
    asyncTest("what a suspense held runs once its children are shown, however the wait ends", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let log = []
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Suspense>
          {watcher(~log, ~name="sibling")}
          <View.Show when_={MaybeSignal.reactive(shown)}>
            {loader(~fetch=() => pending.promise, ~log=[])}
          </View.Show>
        </View.Suspense>,
        container,
      )
      /* The wait ends inside the Show's own update, when the only resource
         goes. */
      Signal.set(shown, false)
      await settle()
      assertEqual(log, ["sibling:contents"])
    }),
    asyncTest("a failure set off by settling does not make the resource Failed", async () => {
      let pending = deferred()
      let resource = Resource.make(() => pending.promise)
      let thrown = ref(false)
      Effect.run(() => {
        switch Signal.get(resource) {
        | Ready(_) if !thrown.contents => {
            thrown := true
            throw(Unavailable("view"))
          }
        | _ => ()
        }
        None
      })
      let rejections = await catchingRejections(async () => {
        pending.resolve("data")
        await settle()
      })
      combineResults([
        assertEqual(describe(Signal.peek(resource)), "ready:data"),
        assertEqual(Array.length(rejections), 1),
      ])
    }),
    asyncTest("an inner suspense that waits again holds its children past the outer one", async () => {
      let {container} = Dom.render("")
      let outer = deferred()
      let first = deferred()
      let second = deferred()
      let log = []
      let more = Signal.make(false)
      let _ = mountTo(
        <View.Suspense>
          {loader(~fetch=() => outer.promise, ~log=[], ~name="outer")}
          <View.Suspense>
            {loader(~fetch=() => first.promise, ~log=[], ~name="first")}
            {watcher(~log, ~name="inner")}
            <View.Show when_={MaybeSignal.reactive(more)}>
              {loader(~fetch=() => second.promise, ~log=[], ~name="second")}
            </View.Show>
          </View.Suspense>
        </View.Suspense>,
        container,
      )
      first.resolve("1")
      await settle()
      Signal.set(more, true)
      outer.resolve("o")
      await settle()
      let whileInnerWaits = Array.copy(log)
      second.resolve("2")
      await settle()
      combineResults([
        assertEqual(whileInnerWaits, []),
        assertEqual(log, ["inner:contents"]),
      ])
    }),
    asyncTest("a portal inside a waiting suspense reaches its target once the suspense shows", async () => {
      let {container} = Dom.render("")
      let target = Dom.render("").container
      let pending = deferred()
      let _ = mountTo(
        <View.Suspense>
          {loader(~fetch=() => pending.promise, ~log=[])}
          <View.Portal target> <p class="portaled" /> </View.Portal>
        </View.Suspense>,
        container,
      )
      let whileWaiting = has(target, ".portaled")
      pending.resolve("ready")
      await settle()
      combineResults([assertFalse(whileWaiting), assertTrue(has(target, ".portaled"))])
    }),
    asyncTest("a failure thrown where the state is read reaches an error boundary", async () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <View.ErrorBoundary fallback={(_, _) => <p class="error" />}>
          {View.LazyComponent(
            () => {
              let resource = Resource.make(() => Promise.reject(Unavailable("down")))
              <span>
                {View.signalText(() =>
                  switch Signal.get(resource) {
                  | Failed(exn) => throw(exn)
                  | state => describe(state)
                  }
                )}
              </span>
            },
          )}
        </View.ErrorBoundary>,
        container,
      )
      await settle()
      assertTrue(has(container, ".error"))
    }),
    asyncTest("pending is true while a fetch is in flight, first or later", async () => {
      let {container} = Dom.render("")
      let first = deferred()
      let again = deferred()
      let calls = ref(0)
      let resource = ref(None)
      let _ = mountTo(
        <View.Suspense>
          {pendingProbe()}
          {View.LazyComponent(
            () => {
              resource :=
                Some(
                  Resource.make(() => {
                    calls := calls.contents + 1
                    calls.contents == 1 ? first.promise : again.promise
                  }),
                )
              <span />
            },
          )}
        </View.Suspense>,
        container,
      )
      let loading = text(container, ".probe")
      first.resolve("a")
      await settle()
      let loaded = text(container, ".probe")
      Resource.refetch(resource.contents->Option.getOrThrow)
      let refreshing = text(container, ".probe")
      again.resolve("b")
      await settle()
      combineResults([
        assertEqual(loading, Some("busy")),
        assertEqual(loaded, Some("idle")),
        assertEqual(refreshing, Some("busy")),
        assertEqual(text(container, ".probe"), Some("idle")),
      ])
    }),
    asyncTest("pending stays true while a fetch that replaced another is in flight", async () => {
      let {container} = Dom.render("")
      let id = Signal.make("1")
      let fetches: Dict.t<deferred<string>> = Dict.make()
      let _ = mountTo(
        <View.Suspense>
          {pendingProbe()}
          {View.LazyComponent(
            () => {
              let _ = Resource.make(() => {
                let fetch = deferred()
                fetches->Dict.set(Signal.get(id), fetch)
                fetch.promise
              })
              <span />
            },
          )}
        </View.Suspense>,
        container,
      )
      Signal.set(id, "2")
      (fetches->Dict.getUnsafe("1")).resolve("late")
      await settle()
      let afterSuperseded = text(container, ".probe")
      (fetches->Dict.getUnsafe("2")).resolve("two")
      await settle()
      combineResults([
        assertEqual(afterSuperseded, Some("busy")),
        assertEqual(text(container, ".probe"), Some("idle")),
      ])
    }),
    asyncTest("pending follows mutate and the removal of the resource", async () => {
      let {container} = Dom.render("")
      let first = deferred()
      let second = deferred()
      let shown = Signal.make(true)
      let resource = ref(None)
      let _ = mountTo(
        <View.Suspense>
          {pendingProbe()}
          {View.LazyComponent(
            () => {
              resource := Some(Resource.make(() => first.promise))
              <span />
            },
          )}
          <View.Show when_={MaybeSignal.reactive(shown)}>
            {loader(~fetch=() => second.promise, ~log=[])}
          </View.Show>
        </View.Suspense>,
        container,
      )
      Resource.mutate(resource.contents->Option.getOrThrow, "optimistic")
      let afterMutate = text(container, ".probe")
      Signal.set(shown, false)
      let afterRemoval = text(container, ".probe")
      await settle()
      combineResults([
        assertEqual(afterMutate, Some("busy")),
        assertEqual(afterRemoval, Some("idle")),
      ])
    }),
    asyncTest("pending counts only the nearest suspense", async () => {
      let {container} = Dom.render("")
      let inner = deferred()
      let _ = mountTo(
        <View.Suspense>
          {pendingProbe(~name="outer")}
          <View.Suspense>
            {pendingProbe(~name="inner")}
            {loader(~fetch=() => inner.promise, ~log=[])}
          </View.Suspense>
        </View.Suspense>,
        container,
      )
      let whileLoading = (text(container, ".outer"), text(container, ".inner"))
      inner.resolve("i")
      await settle()
      combineResults([
        assertEqual(whileLoading, (Some("idle"), Some("busy"))),
        assertEqual(text(container, ".inner"), Some("idle")),
      ])
    }),
    asyncTest("pending outside any suspense is always false", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let _ = mountTo(
        <div>
          {pendingProbe()}
          {loader(~fetch=() => pending.promise, ~log=[])}
        </div>,
        container,
      )
      let whileLoading = text(container, ".probe")
      pending.resolve("a")
      await settle()
      assertEqual(whileLoading, Some("idle"))
    }),
    asyncTest("pending warns when called outside a component body, and not inside one", async () => {
      let {container} = Dom.render("")
      let outside = capturingWarnings(() => View.Suspense.pending()->ignore)
      let inside = capturingWarnings(() =>
        mountTo(<View.Suspense> {pendingProbe()} </View.Suspense>, container)->ignore
      )
      combineResults([
        assertEqual(Array.length(outside), 1),
        assertTrue(
          outside->Array.get(0)->Option.mapOr(false, message =>
            String.includes(message, "View.Suspense.pending")
          ),
        ),
        assertEqual(inside, []),
      ])
    }),
    asyncTest("hold makes a suspense wait for a resource created elsewhere", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let shared = Resource.make(() => pending.promise)
      let log = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {pendingProbe()}
          {holder(shared, ~log)}
        </View.Suspense>,
        container,
      )
      let waiting = (has(container, ".fallback"), Array.copy(log), text(container, ".probe"))
      pending.resolve("ada")
      await settle()
      combineResults([
        assertEqual(waiting, (true, [], Some("busy"))),
        assertFalse(has(container, ".fallback")),
        assertEqual(log, ["holder:mount"]),
        assertEqual(text(container, ".holder"), Some("ready:ada")),
        assertEqual(text(container, ".probe"), Some("idle")),
      ])
    }),
    asyncTest("hold counts a refetch toward pending but never brings the fallback back", async () => {
      let {container} = Dom.render("")
      let first = deferred()
      let again = deferred()
      let calls = ref(0)
      let shared = Resource.make(() => {
        calls := calls.contents + 1
        calls.contents == 1 ? first.promise : again.promise
      })
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {pendingProbe()}
          {holder(shared, ~log=[])}
        </View.Suspense>,
        container,
      )
      first.resolve("a")
      await settle()
      Resource.refetch(shared)
      let refreshing = (has(container, ".fallback"), text(container, ".probe"))
      again.resolve("b")
      await settle()
      combineResults([
        assertEqual(refreshing, (false, Some("busy"))),
        assertEqual(text(container, ".probe"), Some("idle")),
      ])
    }),
    asyncTest("hold ends its wait on a failure, and a retry does not wait again", async () => {
      let {container} = Dom.render("")
      let attempts = ref(0)
      let retry = deferred()
      let shared = Resource.make(() => {
        attempts := attempts.contents + 1
        attempts.contents == 1 ? Promise.reject(Unavailable("offline")) : retry.promise
      })
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}> {holder(shared, ~log=[])} </View.Suspense>,
        container,
      )
      await settle()
      let failed = (has(container, ".fallback"), text(container, ".holder"))
      Resource.refetch(shared)
      let retrying = (has(container, ".fallback"), text(container, ".holder"))
      retry.resolve("back")
      await settle()
      combineResults([
        assertEqual(failed, (false, Some("failed:offline"))),
        assertEqual(retrying, (false, Some("pending"))),
      ])
    }),
    asyncTest("hold on a resource that already has a value holds nothing", async () => {
      let {container} = Dom.render("")
      let shared = Resource.make(() => Promise.resolve("ready"))
      await settle()
      let log = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}> {holder(shared, ~log)} </View.Suspense>,
        container,
      )
      let shownAtOnce = has(container, ".fallback")
      await settle()
      combineResults([assertFalse(shownAtOnce), assertEqual(log, ["holder:mount"])])
    }),
    asyncTest("removing the holder ends its wait", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let shared = Resource.make(() => pending.promise)
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {pendingProbe()}
          <View.Show when_={MaybeSignal.reactive(shown)}> {holder(shared, ~log=[])} </View.Show>
        </View.Suspense>,
        container,
      )
      let waiting = has(container, ".fallback")
      Signal.set(shown, false)
      await settle()
      combineResults([
        assertTrue(waiting),
        assertFalse(has(container, ".fallback")),
        assertEqual(text(container, ".probe"), Some("idle")),
      ])
    }),
    asyncTest("holding a resource the component also created waits once", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let log = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {View.LazyComponent(
            () => {
              let resource = Resource.make(() => pending.promise)
              Resource.hold(resource)
              View.onMount(() => log->Array.push("mount")->ignore)
              <span class="both"> {View.signalText(() => describe(Signal.get(resource)))} </span>
            },
          )}
        </View.Suspense>,
        container,
      )
      let waiting = has(container, ".fallback")
      pending.resolve("a")
      await settle()
      combineResults([
        assertTrue(waiting),
        assertFalse(has(container, ".fallback")),
        assertEqual(log, ["mount"]),
      ])
    }),
    asyncTest("hold does nothing outside a suspense", async () => {
      let {container} = Dom.render("")
      let pending = deferred()
      let shared = Resource.make(() => pending.promise)
      let log = []
      let _ = mountTo(<div> {holder(shared, ~log)} </div>, container)
      await settle()
      combineResults([assertEqual(log, ["holder:mount"]), assertEqual(text(container, ".holder"), Some("pending"))])
    }),
    asyncTest("map follows its source and derives its value", async () => {
      let (source, fetches) = controlled()
      let shouted = Resource.map(source, name => name ++ "!")
      let before = peek(shouted)
      (fetches->Array.getUnsafe(0)).resolve("ada")
      await settle()
      let loaded = peek(shouted)
      Resource.refetch(source)
      let refreshing = peek(shouted)
      (fetches->Array.getUnsafe(1)).reject(Unavailable("offline"))
      await settle()
      combineResults([
        assertEqual(before, "pending"),
        assertEqual(loaded, "ready:ada!"),
        assertEqual(refreshing, "refreshing:ada!"),
        assertEqual(peek(shouted), "failed:offline"),
      ])
    }),
    asyncTest("map derives again only when the source's value changes", async () => {
      let (source, fetches) = controlled()
      let calls = ref(0)
      let wrapped = Resource.map(source, name => {
        calls := calls.contents + 1
        [name]
      })
      (fetches->Array.getUnsafe(0)).resolve("ada")
      await settle()
      let loaded = Signal.peek(wrapped)->Resource.value
      Resource.refetch(source)
      let refreshing = Signal.peek(wrapped)->Resource.value
      let callsWhileRefreshing = calls.contents
      (fetches->Array.getUnsafe(1)).resolve("grace")
      await settle()
      combineResults([
        assertTrue(loaded->Option.isSome && loaded === refreshing),
        assertEqual(callsWhileRefreshing, 1),
        assertEqual(Signal.peek(wrapped)->Resource.value, Some(["grace"])),
        assertEqual(calls.contents, 2),
      ])
    }),
    asyncTest("a derived resource fails first, then waits, then refreshes", async () => {
      let never = Resource.make(() => deferred().promise)
      let down = Resource.make(() => Promise.reject(Unavailable("down")))
      let alsoDown = Resource.make(() => Promise.reject(Unavailable("also")))
      let (slow, slowFetches) = controlled()
      let (quick, quickFetches) = controlled()
      let join = (a, b) => a ++ "+" ++ b
      let failedEarly = Resource.map2(never, down, join)
      let firstFailure = Resource.map2(down, alsoDown, join)
      let both = Resource.map2(slow, quick, join)
      (quickFetches->Array.getUnsafe(0)).resolve("q")
      await settle()
      let waitingForOne = peek(both)
      (slowFetches->Array.getUnsafe(0)).resolve("s")
      await settle()
      let ready = peek(both)
      Resource.refetch(quick)
      let refreshing = peek(both)
      combineResults([
        assertEqual(peek(failedEarly), "failed:down"),
        assertEqual(peek(firstFailure), "failed:down"),
        assertEqual(waitingForOne, "pending"),
        assertEqual(ready, "ready:s+q"),
        assertEqual(refreshing, "refreshing:s+q"),
      ])
    }),
    asyncTest("all combines in order and keeps its array until a value changes", async () => {
      let (first, firstFetches) = controlled()
      let (second, secondFetches) = controlled()
      let both = Resource.all([first, second])
      (secondFetches->Array.getUnsafe(0)).resolve("b")
      await settle()
      let waiting = Signal.peek(both)->Resource.isLoading
      (firstFetches->Array.getUnsafe(0)).resolve("a")
      await settle()
      let loaded = Signal.peek(both)->Resource.value
      Resource.refetch(first)
      let refreshing = Signal.peek(both)->Resource.value
      combineResults([
        assertTrue(waiting),
        assertEqual(loaded, Some(["a", "b"])),
        assertTrue(loaded === refreshing),
      ])
    }),
    asyncTest("a derive that throws makes the derived resource Failed", async () => {
      let source = Resource.make(() => Promise.resolve("ada"))
      let broken = Resource.map(source, _ => throw(Unavailable("derive")))
      await settle()
      assertEqual(describe(Signal.peek(broken)), "failed:derive")
    }),
    asyncTest("refetch on a derived resource fetches each source once", async () => {
      let (first, firstFetches) = controlled()
      let (second, secondFetches) = controlled()
      let derived = Resource.map3(first, second, Resource.map(first, name => name), (a, b, c) =>
        a ++ b ++ c
      )
      Resource.refetch(derived)
      combineResults([
        assertEqual(Array.length(firstFetches), 2),
        assertEqual(Array.length(secondFetches), 2),
      ])
    }),
    asyncTest("mutate on a derived resource does nothing; on its source it shows through", async () => {
      let source = Resource.make(() => Promise.resolve("ada"))
      let shouted = Resource.map(source, name => name ++ "!")
      /* A live reader: a write into the derived resource would reach it. */
      let seen = []
      Effect.run(() => {
        seen->Array.push(describe(Signal.get(shouted)))->ignore
        None
      })
      await settle()
      Resource.mutate(shouted, "ignored")
      let afterDerived = (Array.copy(seen), peek(source))
      Resource.mutate(source, "grace")
      combineResults([
        assertEqual(afterDerived, (["pending", "ready:ada!"], "ready:ada")),
        assertEqual(seen, ["pending", "ready:ada!", "ready:grace!"]),
      ])
    }),
    asyncTest("an equal state does not wake the readers of a derived resource", async () => {
      let source = Resource.make(() => Promise.resolve("ada"))
      let shouted = Resource.map(source, name => name ++ "!")
      let runs = ref(0)
      Effect.run(() => {
        let _ = Signal.get(shouted)
        runs := runs.contents + 1
        None
      })
      await settle()
      let afterLoad = runs.contents
      Resource.mutate(source, "ada")
      combineResults([assertEqual(afterLoad, 2), assertEqual(runs.contents, 2)])
    }),
    asyncTest("hold on a derived resource waits for every source", async () => {
      let {container} = Dom.render("")
      let (first, firstFetches) = controlled()
      let (second, secondFetches) = controlled()
      let both = Resource.map2(first, second, (a, b) => a ++ b)
      let log = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}> {holder(both, ~log)} </View.Suspense>,
        container,
      )
      (firstFetches->Array.getUnsafe(0)).resolve("a")
      await settle()
      let afterOne = (has(container, ".fallback"), Array.copy(log))
      (secondFetches->Array.getUnsafe(0)).resolve("b")
      await settle()
      combineResults([
        assertEqual(afterOne, (true, [])),
        assertFalse(has(container, ".fallback")),
        assertEqual(text(container, ".holder"), Some("ready:ab")),
      ])
    }),
    asyncTest("chain waits for its source, then fetches with its value", async () => {
      let (source, sourceFetches) = controlled()
      let (posts, inputs, fetches) = recordingChain(source)
      let before = (peek(posts), Array.copy(inputs))
      (sourceFetches->Array.getUnsafe(0)).resolve("user-1")
      await settle()
      let fetching = (peek(posts), Array.copy(inputs))
      (fetches->Array.getUnsafe(0)).resolve("posts-1")
      await settle()
      combineResults([
        assertEqual(before, ("pending", [])),
        assertEqual(fetching, ("pending", ["user-1"])),
        assertEqual(peek(posts), "ready:posts-1"),
      ])
    }),
    asyncTest("chain fetches when the source settles anew, not while it refreshes", async () => {
      let (source, sourceFetches) = controlled()
      let (posts, inputs, fetches) = recordingChain(source)
      (sourceFetches->Array.getUnsafe(0)).resolve("user-1")
      await settle()
      (fetches->Array.getUnsafe(0)).resolve("posts-1")
      await settle()
      Resource.refetch(source)
      let sourceRefreshing = (peek(posts), Array.copy(inputs))
      (sourceFetches->Array.getUnsafe(1)).resolve("user-2")
      await settle()
      let ownFetching = (peek(posts), Array.copy(inputs))
      (fetches->Array.getUnsafe(1)).resolve("posts-2")
      await settle()
      combineResults([
        assertEqual(sourceRefreshing, ("refreshing:posts-1", ["user-1"])),
        assertEqual(ownFetching, ("refreshing:posts-1", ["user-1", "user-2"])),
        assertEqual(peek(posts), "ready:posts-2"),
      ])
    }),
    asyncTest("chain is Failed while its source is, and fetches nothing", async () => {
      let source = Resource.make(() => Promise.reject(Unavailable("no user")))
      let (posts, inputs, _) = recordingChain(source)
      await settle()
      combineResults([assertEqual(peek(posts), "failed:no user"), assertEqual(inputs, [])])
    }),
    asyncTest("refetch on a chain runs its own fetch again and leaves the source alone", async () => {
      let (source, sourceFetches) = controlled()
      let (posts, inputs, fetches) = recordingChain(source)
      (sourceFetches->Array.getUnsafe(0)).resolve("user-1")
      await settle()
      (fetches->Array.getUnsafe(0)).resolve("posts-1")
      await settle()
      Resource.refetch(posts)
      let refreshing = peek(posts)
      combineResults([
        assertEqual(refreshing, "refreshing:posts-1"),
        assertEqual(inputs, ["user-1", "user-1"]),
        assertEqual(Array.length(sourceFetches), 1),
      ])
    }),
    asyncTest("mutate on a chain sets its own value and drops its fetch in flight", async () => {
      let source = Resource.make(() => Promise.resolve("user-1"))
      let (posts, _, fetches) = recordingChain(source)
      await settle()
      Resource.mutate(posts, "optimistic")
      (fetches->Array.getUnsafe(0)).resolve("server")
      await settle()
      combineResults([assertEqual(peek(posts), "ready:optimistic"), assertEqual(peek(source), "ready:user-1")])
    }),
    asyncTest("a chain's fetch for an earlier source value is ignored when it settles late", async () => {
      let (source, sourceFetches) = controlled()
      let (posts, _, fetches) = recordingChain(source)
      (sourceFetches->Array.getUnsafe(0)).resolve("user-1")
      await settle()
      Resource.refetch(source)
      (sourceFetches->Array.getUnsafe(1)).resolve("user-2")
      await settle()
      (fetches->Array.getUnsafe(1)).resolve("posts-2")
      await settle()
      (fetches->Array.getUnsafe(0)).resolve("posts-1")
      await settle()
      assertEqual(peek(posts), "ready:posts-2")
    }),
    asyncTest("a chain created while its source refreshes fetches with the value it has", async () => {
      let (source, sourceFetches) = controlled()
      (sourceFetches->Array.getUnsafe(0)).resolve("user-1")
      await settle()
      Resource.refetch(source)
      let (_, inputs, _) = recordingChain(source)
      assertEqual(inputs, ["user-1"])
    }),
    asyncTest("a chain under a suspense waits for its source and its own fetch", async () => {
      let {container} = Dom.render("")
      let (source, sourceFetches) = controlled()
      let fetches: array<deferred<string>> = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {pendingProbe()}
          {View.LazyComponent(
            () => {
              let posts = source->Resource.chain(_ => {
                let fetch = deferred()
                fetches->Array.push(fetch)->ignore
                fetch.promise
              })
              <span class="posts"> {View.signalText(() => describe(Signal.get(posts)))} </span>
            },
          )}
        </View.Suspense>,
        container,
      )
      (sourceFetches->Array.getUnsafe(0)).resolve("user-1")
      await settle()
      let sourceLoaded = has(container, ".fallback")
      (fetches->Array.getUnsafe(0)).resolve("posts-1")
      await settle()
      let shown = (has(container, ".fallback"), text(container, ".posts"), text(container, ".probe"))
      Resource.refetch(source)
      let sourceRefreshing = (has(container, ".fallback"), text(container, ".probe"))
      combineResults([
        assertTrue(sourceLoaded),
        assertEqual(shown, (false, Some("ready:posts-1"), Some("idle"))),
        assertEqual(sourceRefreshing, (false, Some("busy"))),
      ])
    }),
    asyncTest("the server renders the fallback without fetching; hydration loads", async () => {
      let pending = deferred()
      let fetches = ref(0)
      let component = () =>
        <div>
          <View.Suspense fallback={<p class="fallback"> {View.text("Loading")} </p>}>
            {loader(
              ~fetch=() => {
                fetches := fetches.contents + 1
                pending.promise
              },
              ~log=[],
            )}
          </View.Suspense>
        </div>
      let html = SSR.renderToString(component)
      let serverFetches = fetches.contents
      let {container} = Dom.render(html)
      Hydration.hydrate(component, container)
      let hydrated = has(container, ".fallback")
      pending.resolve("ada")
      await settle()
      combineResults([
        assertTrue(String.includes(html, "Loading") && !String.includes(html, "loader")),
        assertEqual(serverFetches, 0),
        assertTrue(hydrated),
        assertEqual(fetches.contents, 1),
        assertEqual(text(container, ".loader"), Some("ready:ada")),
        assertFalse(has(container, ".fallback")),
      ])
    }),
  ],
)
