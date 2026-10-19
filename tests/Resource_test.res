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
