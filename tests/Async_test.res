/* Async values (`Xote.Async`) in the renderer: leaves, blocks, lists,
   Suspense, error boundaries, server rendering and hydration. */
type domElement = Dom.element

open! Zekr

let deferred = Resource_test.deferred
let settle = Resource_test.settle
let text = Resource_test.text
let has = Resource_test.has
let display = Resource_test.display
let mountTo = Resource_test.mountTo
let pendingProbe = Resource_test.pendingProbe

exception Offline(string)

/* An async value whose every fetch waits on a promise of its own, kept in
   order; `input`, read before the promise, is its dependency. */
let controlled = (~input: Signal.t<string>=Signal.make("1"), ()) => {
  let fetches: array<Resource_test.deferred<string>> = []
  let value = Async.make(() => {
    let _ = Signal.get(input)
    let fetch = deferred()
    fetches->Array.push(fetch)->ignore
    fetch.promise
  })
  (value, fetches)
}

let resolveNth = (fetches: array<Resource_test.deferred<string>>, n, value) =>
  (fetches->Array.getUnsafe(n)).resolve(value)

/* What an error boundary was handed: a JavaScript error's message, or the
   exception's name. */
let messageOf: exn => string = %raw(`function (e) {
  const v = e && e.RE_EXN_ID === "JsExn" ? e._1 : e
  return String((v && v.message) || (v && v.RE_EXN_ID) || v)
}`)

let suite = Zekr.asyncSuite(
  "Async values",
  [
    asyncTest("a text leaf renders once its value arrives", async () => {
      let {container} = Dom.render("")
      let (user, fetches) = controlled()
      let _ = mountTo(<p class="name"> {View.signalText(() => Signal.get(user))} </p>, container)
      let before = text(container, ".name")
      resolveNth(fetches, 0, "ada")
      await settle()
      combineResults([assertEqual(before, Some("")), assertEqual(text(container, ".name"), Some("ada"))])
    }),
    asyncTest("a text leaf beside other children, and in repeated rows, renders once ready", async () => {
      let {container} = Dom.render("")
      let (user, fetches) = controlled()
      let _ = mountTo(
        <div>
          <p class="greeting"> {View.text("Hi ")} {View.signalText(() => Signal.get(user))} </p>
          <ul class="rows">
            {View.each(Signal.make(["a", "b", "c"]), row =>
              <li> {View.text(row ++ ":")} {View.signalText(() => Signal.get(user))} </li>
            )}
          </ul>
        </div>,
        container,
      )
      let before = (text(container, ".greeting"), text(container, ".rows"))
      resolveNth(fetches, 0, "ada")
      await settle()
      combineResults([
        assertEqual(before, (Some("Hi "), Some("a:b:c:"))),
        assertEqual(text(container, ".greeting"), Some("Hi ada")),
        assertEqual(text(container, ".rows"), Some("a:adab:adac:ada")),
      ])
    }),
    asyncTest("an attribute waits for its value", async () => {
      let {container} = Dom.render("")
      let (role, fetches) = controlled()
      let _ = mountTo(<p class="item" title={() => Signal.get(role)} />, container)
      let attribute = () =>
        Resource_test.querySelector(container, ".item")
        ->Nullable.toOption
        ->Option.flatMap(el => Zekr__DomBindings.getAttribute(el, "title")->Nullable.toOption)
      let before = attribute()
      resolveNth(fetches, 0, "admin")
      await settle()
      combineResults([assertEqual(before, None), assertEqual(attribute(), Some("admin"))])
    }),
    asyncTest("a tracked block renders once ready, and keeps its content while fetching again", async () => {
      let {container} = Dom.render("")
      let input = Signal.make("1")
      let (user, fetches) = controlled(~input, ())
      let _ = mountTo(
        <div>
          {View.tracked(() => <span class="block"> {View.text(Signal.get(user))} </span>)}
        </div>,
        container,
      )
      let before = has(container, ".block")
      resolveNth(fetches, 0, "ada")
      await settle()
      let loaded = text(container, ".block")
      Signal.set(input, "2")
      let fetching = text(container, ".block")
      resolveNth(fetches, 1, "grace")
      await settle()
      combineResults([
        assertFalse(before),
        assertEqual(loaded, Some("ada")),
        assertEqual(fetching, Some("ada")),
        assertEqual(text(container, ".block"), Some("grace")),
      ])
    }),
    asyncTest("a computed over an async value renders once ready", async () => {
      let {container} = Dom.render("")
      let (user, fetches) = controlled()
      let shouted = Computed.make(() => Signal.get(user) ++ "!")
      let _ = mountTo(<p class="shout"> {View.signalText(() => Signal.get(shouted))} </p>, container)
      resolveNth(fetches, 0, "ada")
      await settle()
      assertEqual(text(container, ".shout"), Some("ada!"))
    }),
    asyncTest("a keyed list waits for its items", async () => {
      let {container} = Dom.render("")
      let fetch = deferred()
      let names = Async.make(() => fetch.promise)
      let _ = mountTo(
        <ul class="names">
          <View.For
            each={MaybeSignal.reactive(names)}
            by={name => name}
            render={name => <li> {View.text(name)} </li>}
          />
        </ul>,
        container,
      )
      let before = text(container, ".names")
      fetch.resolve(["ada", "grace"])
      await settle()
      combineResults([assertEqual(before, Some("")), assertEqual(text(container, ".names"), Some("adagrace"))])
    }),
    asyncTest("a suspense shows its fallback and holds onMount until a value read below arrives", async () => {
      let {container} = Dom.render("")
      let (user, fetches) = controlled()
      let log = []
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          {pendingProbe()}
          {View.LazyComponent(
            () => {
              View.onMount(() => log->Array.push("mount")->ignore)
              <span class="name"> {View.signalText(() => Signal.get(user))} </span>
            },
          )}
        </View.Suspense>,
        container,
      )
      let waiting = (has(container, ".fallback"), display(container, ".name"), Array.copy(log))
      let busy = text(container, ".probe")
      resolveNth(fetches, 0, "ada")
      await settle()
      combineResults([
        assertEqual(waiting, (true, "none", [])),
        assertEqual(busy, Some("busy")),
        assertFalse(has(container, ".fallback")),
        assertEqual(text(container, ".name"), Some("ada")),
        assertEqual(log, ["mount"]),
        assertEqual(text(container, ".probe"), Some("idle")),
      ])
    }),
    asyncTest("removing a waiting leaf ends its suspense's wait", async () => {
      let {container} = Dom.render("")
      let (user, _) = controlled()
      let shown = Signal.make(true)
      let _ = mountTo(
        <View.Suspense fallback={<p class="fallback" />}>
          <View.Show when_={MaybeSignal.reactive(shown)}>
            <span> {View.signalText(() => Signal.get(user))} </span>
          </View.Show>
        </View.Suspense>,
        container,
      )
      let waiting = has(container, ".fallback")
      Signal.set(shown, false)
      await settle()
      combineResults([assertTrue(waiting), assertFalse(has(container, ".fallback"))])
    }),
    asyncTest("an error boundary lets NotReady pass and catches a failed fetch", async () => {
      let {container} = Dom.render("")
      let fetch = deferred()
      let user: Signal.t<string> = Async.make(() => fetch.promise)
      let caught = []
      let _ = mountTo(
        <View.ErrorBoundary
          fallback={(exn, _) => {
            caught->Array.push(messageOf(exn))->ignore
            <p class="error" />
          }}>
          <span class="name"> {View.signalText(() => Signal.get(user))} </span>
        </View.ErrorBoundary>,
        container,
      )
      let whileLoading = has(container, ".error")
      fetch.reject(Offline("down"))
      await settle()
      combineResults([
        assertFalse(whileLoading),
        assertTrue(has(container, ".error")),
        assertEqual(Array.length(caught), 1),
      ])
    }),
    asyncTest("a component body that reads a value not ready yet is an error", async () => {
      let {container} = Dom.render("")
      let (user, _) = controlled()
      let caught = []
      let _ = mountTo(
        <View.ErrorBoundary
          fallback={(exn, _) => {
            caught->Array.push(messageOf(exn))->ignore
            <p class="error" />
          }}>
          {View.LazyComponent(
            () => {
              let name = Signal.get(user)
              <span> {View.text(name)} </span>
            },
          )}
        </View.ErrorBoundary>,
        container,
      )
      combineResults([
        assertTrue(has(container, ".error")),
        assertTrue(caught->Array.some(message => String.includes(message, "component body"))),
      ])
    }),
    asyncTest("isPending in an attribute follows a fetch again", async () => {
      let {container} = Dom.render("")
      let input = Signal.make("1")
      let (user, fetches) = controlled(~input, ())
      let _ = mountTo(
        <p
          class="status"
          title={() => Async.isPending(() => Signal.get(user)) ? "loading" : "idle"}
        />,
        container,
      )
      let title = () =>
        Resource_test.querySelector(container, ".status")
        ->Nullable.toOption
        ->Option.flatMap(el => Zekr__DomBindings.getAttribute(el, "title")->Nullable.toOption)
      let first = title()
      resolveNth(fetches, 0, "ada")
      await settle()
      let loaded = title()
      Signal.set(input, "2")
      let again = title()
      combineResults([
        assertEqual(first, Some("loading")),
        assertEqual(loaded, Some("idle")),
        assertEqual(again, Some("loading")),
      ])
    }),
    asyncTest("the server renders a value not ready as empty without fetching; hydration fills it in", async () => {
      let fetches = ref(0)
      let fetch = deferred()
      let component = () =>
        View.LazyComponent(
          () => {
            let user = Async.make(() => {
              fetches := fetches.contents + 1
              fetch.promise
            })
            <p class="name" title={() => Signal.get(user)}>
              {View.signalText(() => Signal.get(user))}
            </p>
          },
        )
      let html = SSR.renderToString(component)
      let serverFetches = fetches.contents
      let {container} = Dom.render(html)
      Hydration.hydrate(component, container)
      fetch.resolve("ada")
      await settle()
      combineResults([
        assertFalse(String.includes(html, "title=")),
        assertEqual(serverFetches, 0),
        assertEqual(fetches.contents, 1),
        assertEqual(text(container, ".name"), Some("ada")),
      ])
    }),
  ],
)
