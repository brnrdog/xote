/* Before `open! Zekr`, whose `Dom` shadows the standard one. */
type domElement = Dom.element

open! Zekr

@send external querySelector: ('a, string) => Nullable.t<domElement> = "querySelector"
@send external contains: (domElement, domElement) => bool = "contains"
@get external isConnected: domElement => bool = "isConnected"
@val @scope("document") external body: domElement = "body"
@val @scope("document") external createElement: string => domElement = "createElement"
@send external appendChild: (domElement, domElement) => unit = "appendChild"

let querySelectorAll: ('a, string) => array<domElement> = %raw(`function (container, selector) {
  return Array.from(container.querySelectorAll(selector))
}`)

/* Live subscriber links of a signal: what a leaked effect leaves behind. */
let subscriberCount: Signal.t<'a> => int = %raw(`function (signal) {
  let count = 0
  let link = signal.subs.first
  while (link) { count = count + 1; link = link.nextSub }
  return count
}`)

let find = (root, selector) => querySelector(root, selector)->Nullable.toOption

let text = (root, selector) => find(root, selector)->Option.map(Zekr__DomBindings.textContent)

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

/* A target element of its own, attached to the document. */
let freshTarget = () => {
  let target = createElement("div")
  body->appendChild(target)
  target
}

exception Boom

let theme = Context.make("light")

let suite = Zekr.suite(
  "Portals",
  [
    test("children render into the target, and nothing where the portal stands", () => {
      let {container} = Dom.render("")
      let target = freshTarget()
      let _ = mountTo(
        <div class="host">
          <span class="before" />
          <View.Portal target> <p class="portaled"> {View.text("Hello")} </p> </View.Portal>
          <span class="after" />
        </div>,
        container,
      )
      combineResults([
        assertEqual(text(target, ".portaled"), Some("Hello")),
        assertTrue(find(container, ".portaled")->Option.isNone),
        assertEqual(querySelectorAll(container, ".host > *")->Array.length, 2),
      ])
    }),
    test("without a target, children render into document.body", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<View.Portal> <p class="in-body" /> </View.Portal>, container)
      let portaled = find(body, ".in-body")
      combineResults([
        assertTrue(portaled->Option.isSome),
        assertFalse(contains(container, portaled->Option.getOrThrow)),
      ])
    }),
    test("removing the portal removes its children and releases what they set up", () => {
      let {container} = Dom.render("")
      let target = freshTarget()
      let shown = Signal.make(true)
      let ticks = Signal.make(0)
      let _ = mountTo(
        <View.Show when_={MaybeSignal.reactive(shown)}>
          <View.Portal target>
            <p class="portaled"> {View.signalText(() => Int.toString(Signal.get(ticks)))} </p>
            <p class="second" />
          </View.Portal>
        </View.Show>,
        container,
      )
      let mounted = (querySelectorAll(target, "p")->Array.length, subscriberCount(ticks))
      Signal.set(shown, false)
      combineResults([
        assertEqual(mounted, (2, 1)),
        assertEqual(querySelectorAll(target, "p")->Array.length, 0),
        assertEqual(subscriberCount(ticks), 0),
      ])
    }),
    test("portaled children stay reactive", () => {
      let {container} = Dom.render("")
      let target = freshTarget()
      let count = Signal.make(1)
      let _ = mountTo(
        <View.Portal target>
          <p class="count"> {View.signalText(() => Int.toString(Signal.get(count)))} </p>
        </View.Portal>,
        container,
      )
      Signal.set(count, 2)
      assertEqual(text(target, ".count"), Some("2"))
    }),
    test("portaled children see the context the portal renders under", () => {
      let {container} = Dom.render("")
      let target = freshTarget()
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <View.Portal target>
            {View.LazyComponent(() => <p class="themed"> {View.text(Context.use(theme))} </p>)}
          </View.Portal>
        </Context.Provider>,
        container,
      )
      assertEqual(text(target, ".themed"), Some("dark"))
    }),
    test("portaled children mount once they are in the target", () => {
      let {container} = Dom.render("")
      let target = freshTarget()
      let field = View.Ref.make()
      let mounted = ref(false)
      let _ = mountTo(
        <View.Portal target>
          {View.LazyComponent(
            () => {
              View.onMount(() =>
                mounted :=
                  View.Ref.peek(field)->Option.mapOr(false, element =>
                    isConnected(element) && contains(target, element)
                  )
              )
              <input ref=field />
            },
          )}
        </View.Portal>,
        container,
      )
      assertTrue(mounted.contents)
    }),
    test("a failure inside the portal goes to the error boundary around it", () => {
      let {container} = Dom.render("")
      let target = freshTarget()
      let _ = mountTo(
        <View.ErrorBoundary fallback={(_, _) => <p class="fallback" />}>
          <View.Portal target>
            <p class="first" />
            {View.LazyComponent(() => throw(Boom))}
          </View.Portal>
        </View.ErrorBoundary>,
        container,
      )
      combineResults([
        assertTrue(find(container, ".fallback")->Option.isSome),
        assertEqual(querySelectorAll(target, "p")->Array.length, 0),
      ])
    }),
    test("the server renders nothing; hydration renders the children into the target", () => {
      let target = freshTarget()
      let component = () =>
        <div class="host">
          <span class="before" />
          <View.Portal target> <p class="portaled" /> </View.Portal>
          <span class="after" />
        </div>
      let html = SSR.renderToString(component)
      let {container} = Dom.render(html)
      Hydration.hydrate(component, container)
      combineResults([
        assertFalse(String.includes(html, "portaled")),
        assertTrue(find(target, ".portaled")->Option.isSome),
        assertTrue(find(container, ".after")->Option.isSome),
      ])
    }),
  ],
)
