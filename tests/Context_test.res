open! Zekr

@send external querySelector: ('a, string) => Nullable.t<'b> = "querySelector"
let querySelectorAll: ('a, string) => array<'b> = %raw(`function (container, selector) {
  return Array.from(container.querySelectorAll(selector))
}`)
@send external click: 'a => unit = "click"

let theme = Context.make("light")

let texts = (container, selector): array<string> =>
  querySelectorAll(container, selector)->Array.map(Zekr__DomBindings.textContent)

let find = (container, selector) =>
  querySelector(container, selector)->Nullable.toOption->Option.getOrThrow

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

module Badge = {
  @jsx.component
  let make = () => <span class="badge"> {View.text(Context.use(theme))} </span>
}

/* Provides in its own body, so each instance scopes its own value. */
module Themed = {
  @jsx.component
  let make = (~name: string, ~children: View.node) => {
    Context.provide(theme, name)
    <section> {children} </section>
  }
}

/* A row whose text comes from a component nested below it, so a cloned row
   evaluates that component through the template fill path. */
module Label = {
  @jsx.component
  let make = (~id: string) =>
    <em class="label"> {View.text(id ++ ":" ++ Context.use(theme))} </em>
}

module Row = {
  @jsx.component
  let make = (~id: string) => <li> <Label id /> </li>
}

/* An effect set up in a body re-runs long after the body returned. */
module Watcher = {
  @jsx.component
  let make = (~ticks: Signal.t<int>, ~seen: array<string>) => {
    Effect.run(() => {
      let _ = Signal.get(ticks)
      seen->Array.push(Context.use(theme))->ignore
      None
    })
    <span />
  }
}

let suite = Zekr.suite(
  "Context",
  [
    test("use returns the default when nothing provides a value", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<div> <Badge /> </div>, container)
      assertEqual(texts(container, ".badge"), ["light"])
    }),
    test("a provider reaches its subtree and nothing outside it", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <div>
          <Badge />
          <Context.Provider context=theme value="dark">
            <Badge />
            <div>
              <Badge />
            </div>
          </Context.Provider>
          <Badge />
        </div>,
        container,
      )
      assertEqual(texts(container, ".badge"), ["light", "dark", "dark", "light"])
    }),
    test("the nearest provider wins", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <Context.Provider context=theme value="high-contrast">
            <Badge />
          </Context.Provider>
          <Badge />
        </Context.Provider>,
        container,
      )
      assertEqual(texts(container, ".badge"), ["high-contrast", "dark"])
    }),
    test("each instance of a providing component scopes its own value", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        <div>
          <Themed name="first">
            <Badge />
          </Themed>
          <Themed name="second">
            <Badge />
          </Themed>
          <Badge />
        </div>,
        container,
      )
      assertEqual(texts(container, ".badge"), ["first", "second", "light"])
    }),
    test("the function form provides like the component", () => {
      let {container} = Dom.render("")
      let _ = mountTo(<div> {Context.provider(theme, "dark", <Badge />)} </div>, container)
      assertEqual(texts(container, ".badge"), ["dark"])
    }),
    test("a reactive block re-rendered after the provider returned keeps its context", () => {
      let {container} = Dom.render("")
      let visible = Signal.make(false)
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <Badge />
          </View.Show>
        </Context.Provider>,
        container,
      )
      Signal.set(visible, true)
      let first = texts(container, ".badge")
      Signal.set(visible, false)
      Signal.set(visible, true)
      combineResults([
        assertEqual(first, ["dark"]),
        assertEqual(texts(container, ".badge"), ["dark"]),
      ])
    }),
    test("keyed rows built on a later update keep their context, cloned or not", () => {
      let {container} = Dom.render("")
      let ids = Signal.make(["a"])
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <ul>
            <View.For each={MaybeSignal.reactive(ids)} by={id => id} render={id => <Row id />} />
          </ul>
        </Context.Provider>,
        container,
      )
      /* The third row onwards is cloned from a template learned on the second. */
      Signal.set(ids, ["a", "b", "c", "d"])
      assertEqual(texts(container, ".label"), ["a:dark", "b:dark", "c:dark", "d:dark"])
    }),
    test("an effect created in a body re-runs under the body's context", () => {
      let {container} = Dom.render("")
      let ticks = Signal.make(0)
      let seen = []
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <Watcher ticks seen />
        </Context.Provider>,
        container,
      )
      Signal.set(ticks, 1)
      assertEqual(seen, ["dark", "dark"])
    }),
    test("an event handler runs outside the render and reads the default", () => {
      let {container} = Dom.render("")
      let read = ref("")
      let _ = mountTo(
        <Context.Provider context=theme value="dark">
          <button onClick={_ => read := Context.use(theme)} />
        </Context.Provider>,
        container,
      )
      click(find(container, "button"))
      assertEqual(read.contents, "light")
    }),
    test("provide outside a component body raises", () => {
      let raised = try {
        Context.provide(theme, "dark")
        false
      } catch {
      | _ => true
      }
      let {container} = Dom.render("")
      let _ = mountTo(<div> <Badge /> </div>, container)
      combineResults([
        assertTrue(raised),
        /* and leaves nothing behind for later renders */
        assertEqual(texts(container, ".badge"), ["light"]),
      ])
    }),
    test("a failing body leaves no provision behind", () => {
      let failing = () =>
        View.LazyComponent(
          () => {
            Context.provide(theme, "leaked")
            throw(Failure("render failed"))
          },
        )
      let raised = try {
        let _ = View.mount(failing(), Dom.render("").container)
        false
      } catch {
      | _ => true
      }
      let {container} = Dom.render("")
      let _ = mountTo(<div> <Badge /> </div>, container)
      combineResults([assertTrue(raised), assertEqual(texts(container, ".badge"), ["light"])])
    }),
    test("server rendering and hydration see the provided value", () => {
      let visible = Signal.make(true)
      let component = () =>
        <Context.Provider context=theme value="dark">
          <Badge />
          <View.Show when_={MaybeSignal.reactive(visible)}>
            <Badge />
          </View.Show>
        </Context.Provider>
      let html = SSR.renderToString(component)
      let {container} = Dom.render(html)
      Hydration.hydrate(component, container)
      let hydrated = texts(container, ".badge")
      Signal.set(visible, false)
      Signal.set(visible, true)
      combineResults([
        assertTrue(String.includes(html, ">dark</span>")),
        assertEqual(hydrated, ["dark", "dark"]),
        assertEqual(texts(container, ".badge"), ["dark", "dark"]),
      ])
    }),
  ],
)
