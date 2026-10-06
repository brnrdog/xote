open! Zekr

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
@send external click: 'a => unit = "click"

let querySelectorAll: ('a, string) => array<'b> = %raw(`function (container, selector) {
  return Array.from(container.querySelectorAll(selector))
}`)

/* Live subscriber links of a signal: what a leaked effect leaves behind. */
let subscriberCount: Signal.t<'a> => int = %raw(`function (signal) {
  let count = 0
  let link = signal.subs.first
  while (link) { count = count + 1; link = link.nextSub }
  return count
}`)

exception Boom(string)

let texts = (container, selector): array<string> =>
  querySelectorAll(container, selector)->Array.map(Zekr__DomBindings.textContent)

let has = (container, selector) => querySelector(container, selector)->Nullable.toOption->Option.isSome

let find = (container, selector) =>
  querySelector(container, selector)->Nullable.toOption->Option.getOrThrow

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let message = (exn: exn): string =>
  switch exn {
  | Boom(message) => message
  | _ => "unknown"
  }

let fallback = (exn, reset) =>
  <button class="fallback" onClick={_ => reset()}> {View.text(message(exn))} </button>

/* Fails while its body runs when `fails` holds true at that moment. */
module Fragile = {
  @jsx.component
  let make = (~fails: Signal.t<bool>, ~name: string="fragile") =>
    if Signal.peek(fails) {
      throw(Boom(name))
    } else {
      <span class="ok"> {View.text(name)} </span>
    }
}

/* Subscribes an effect, so a subtree abandoned after it rendered shows up as a
   subscriber left on `ticks`. */
module Subscriber = {
  @jsx.component
  let make = (~ticks: Signal.t<int>) => {
    Effect.run(() => {
      let _ = Signal.get(ticks)
      None
    })
    <span class="subscriber" />
  }
}

/* An effect in a body that fails on whichever run sees `fails` true. */
module FailingEffect = {
  @jsx.component
  let make = (~fails: Signal.t<bool>) => {
    Effect.run(() => {
      if Signal.get(fails) {
        throw(Boom("effect"))
      }
      None
    })
    <span class="ok"> {View.text("effect")} </span>
  }
}

let theme = Context.make("light")

module Badge = {
  @jsx.component
  let make = () => <span class="badge"> {View.text(Context.use(theme))} </span>
}

let suite = Zekr.suite(
  "ErrorBoundary",
  [
    test("renders its children when nothing fails", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(false)
      let _ = mountTo(
        <View.ErrorBoundary fallback> <Fragile fails /> </View.ErrorBoundary>,
        container,
      )
      combineResults([assertEqual(texts(container, ".ok"), ["fragile"]), assertFalse(has(container, ".fallback"))])
    }),
    test("a body that fails on the first render falls back, and only inside the boundary", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(true)
      let errors = []
      let _ = mountTo(
        <div>
          <span class="before" />
          <View.ErrorBoundary fallback onError={exn => errors->Array.push(message(exn))->ignore}>
            <span class="sibling" />
            <Fragile fails />
          </View.ErrorBoundary>
          <span class="after" />
        </div>,
        container,
      )
      combineResults([
        assertEqual(texts(container, ".fallback"), ["fragile"]),
        assertFalse(has(container, ".sibling")),
        assertTrue(has(container, ".before") && has(container, ".after")),
        assertEqual(errors, ["fragile"]),
      ])
    }),
    test("what the abandoned subtree set up is released", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(true)
      let ticks = Signal.make(0)
      let _ = mountTo(
        <View.ErrorBoundary fallback>
          <Subscriber ticks />
          <Fragile fails />
        </View.ErrorBoundary>,
        container,
      )
      assertEqual(subscriberCount(ticks), 0)
    }),
    test("reset renders the subtree again", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(true)
      let _ = mountTo(
        <View.ErrorBoundary fallback> <Fragile fails /> </View.ErrorBoundary>,
        container,
      )
      let failed = has(container, ".fallback")
      Signal.set(fails, false)
      click(find(container, ".fallback"))
      combineResults([
        assertTrue(failed),
        assertFalse(has(container, ".fallback")),
        assertEqual(texts(container, ".ok"), ["fragile"]),
      ])
    }),
    test("a failure in a later update replaces the subtree", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(false)
      let visible = Signal.make(false)
      let errors = ref(0)
      let _ = mountTo(
        <View.ErrorBoundary fallback onError={_ => errors := errors.contents + 1}>
          <span class="sibling" />
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <Fragile fails name="later" />
          </View.Show>
        </View.ErrorBoundary>,
        container,
      )
      Signal.set(fails, true)
      Signal.set(visible, true)
      combineResults([
        assertEqual(texts(container, ".fallback"), ["later"]),
        assertFalse(has(container, ".sibling")),
        assertEqual(errors.contents, 1),
      ])
    }),
    test("a reactive attribute that fails on update is caught", () => {
      let {container} = Dom.render("")
      let broken = Signal.make(false)
      let _ = mountTo(
        <View.ErrorBoundary fallback>
          <span class={() => Signal.get(broken) ? throw(Boom("attribute")) : "fine"} />
        </View.ErrorBoundary>,
        container,
      )
      let before = has(container, ".fine")
      Signal.set(broken, true)
      combineResults([assertTrue(before), assertEqual(texts(container, ".fallback"), ["attribute"])])
    }),
    test("an effect in a body is caught on its first run and on later runs", () => {
      let first = Dom.render("").container
      let failsAtOnce = Signal.make(true)
      let _ = mountTo(
        <View.ErrorBoundary fallback> <FailingEffect fails=failsAtOnce /> </View.ErrorBoundary>,
        first,
      )
      let later = Dom.render("").container
      let failsLater = Signal.make(false)
      let _ = mountTo(
        <View.ErrorBoundary fallback> <FailingEffect fails=failsLater /> </View.ErrorBoundary>,
        later,
      )
      let rendered = texts(later, ".ok")
      Signal.set(failsLater, true)
      combineResults([
        assertEqual(texts(first, ".fallback"), ["effect"]),
        assertFalse(has(first, ".ok")),
        assertEqual(rendered, ["effect"]),
        assertEqual(texts(later, ".fallback"), ["effect"]),
      ])
    }),
    test("the nearest boundary catches, and a failing fallback goes to the one above", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(true)
      let _ = mountTo(
        <div>
          <View.ErrorBoundary fallback={(_, _) => <span class="outer" />}>
            <View.ErrorBoundary fallback={(_, _) => <span class="inner" />}>
              <Fragile fails />
            </View.ErrorBoundary>
          </View.ErrorBoundary>
          <View.ErrorBoundary fallback={(_, _) => <span class="outer-2" />}>
            <View.ErrorBoundary fallback={(_, _) => throw(Boom("fallback"))}>
              <Fragile fails />
            </View.ErrorBoundary>
          </View.ErrorBoundary>
        </div>,
        container,
      )
      combineResults([
        assertTrue(has(container, ".inner")),
        assertFalse(has(container, ".outer")),
        assertTrue(has(container, ".outer-2")),
      ])
    }),
    test("a fallback that fails on a later update goes to the boundary above", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(true)
      let fallbackFails = Signal.make(false)
      let innerErrors = ref(0)
      let outerErrors = ref(0)
      let _ = mountTo(
        <View.ErrorBoundary
          fallback={(_, _) => <span class="outer" />}
          onError={_ => outerErrors := outerErrors.contents + 1}>
          <View.ErrorBoundary
            fallback={(_, _) => <FailingEffect fails=fallbackFails />}
            onError={_ => innerErrors := innerErrors.contents + 1}>
            <Fragile fails />
          </View.ErrorBoundary>
        </View.ErrorBoundary>,
        container,
      )
      let innerFallback = has(container, ".ok")
      Signal.set(fallbackFails, true)
      combineResults([
        assertTrue(innerFallback),
        assertTrue(has(container, ".outer")),
        assertEqual(innerErrors.contents, 1),
        assertEqual(outerErrors.contents, 1),
      ])
    }),
    test("a signal read while building the fallback subscribes nothing", () => {
      let {container} = Dom.render("")
      let failsAtOnce = Signal.make(true)
      let failsLater = Signal.make(false)
      let visible = Signal.make(false)
      let label = Signal.make("first")
      let readingFallback = (_, _) => <span class="fallback"> {View.text(Signal.get(label))} </span>
      let _ = mountTo(
        <div>
          <View.ErrorBoundary fallback=readingFallback> <Fragile fails=failsAtOnce /> </View.ErrorBoundary>
          <View.ErrorBoundary fallback=readingFallback>
            <View.Show when_={MaybeSignal.reactive(visible)}>
              <Fragile fails=failsLater />
            </View.Show>
          </View.ErrorBoundary>
        </div>,
        container,
      )
      Signal.set(failsLater, true)
      Signal.set(visible, true)
      let before = querySelectorAll(container, ".fallback")
      Signal.set(label, "second")
      let after = querySelectorAll(container, ".fallback")
      combineResults([
        assertEqual(Array.length(before), 2),
        assertTrue(before->Array.everyWithIndex((node, index) => node === after->Array.getUnsafe(index))),
        assertEqual(texts(container, ".fallback"), ["first", "first"]),
      ])
    }),
    test("without a boundary a failure propagates as before", () => {
      let fails = Signal.make(true)
      let raised = try {
        View.mount(<div> <Fragile fails /> </div>, Dom.render("").container)
        false
      } catch {
      | Boom(_) => true
      }
      assertTrue(raised)
    }),
    test("each keyed row can guard itself", () => {
      let {container} = Dom.render("")
      let ids = Signal.make(["a"])
      let failing = Signal.make(false)
      let row = id =>
        <li>
          <View.ErrorBoundary fallback>
            {id == "c" ? <Fragile fails=failing name=id /> : <Fragile fails={Signal.make(false)} name=id />}
          </View.ErrorBoundary>
        </li>
      let _ = mountTo(
        <ul> <View.For each={MaybeSignal.reactive(ids)} by={id => id} render=row /> </ul>,
        container,
      )
      Signal.set(failing, true)
      Signal.set(ids, ["a", "b", "c", "d"])
      combineResults([
        assertEqual(texts(container, ".ok"), ["a", "b", "d"]),
        assertEqual(texts(container, ".fallback"), ["c"]),
      ])
    }),
    test("the subtree keeps the context provided above the boundary", () => {
      let {container} = Dom.render("")
      let fails = Signal.make(true)
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <View.ErrorBoundary fallback>
            <Badge />
            <Fragile fails />
          </View.ErrorBoundary>
        </Context.Provider>,
        container,
      )
      Signal.set(fails, false)
      click(find(container, ".fallback"))
      assertEqual(texts(container, ".badge"), ["dark"])
    }),
    test("the server renders the fallback, and hydration renders the subtree again", () => {
      let fails = Signal.make(true)
      let component = () =>
        <div>
          <View.ErrorBoundary fallback> <Fragile fails /> </View.ErrorBoundary>
        </div>
      let html = SSR.renderToString(component)
      let {container} = Dom.render(html)
      Signal.set(fails, false)
      Hydration.hydrate(component, container)
      combineResults([
        assertTrue(String.includes(html, "class=\"fallback\"")),
        assertEqual(texts(container, ".ok"), ["fragile"]),
        assertFalse(has(container, ".fallback")),
      ])
    }),
  ],
)
