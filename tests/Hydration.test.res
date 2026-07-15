%%raw(`import "./setup.mjs"`)

open! Zekr

let suite = Suite.make(
  "Hydration",
  [
    Test.make("static content is preserved after hydration", () => {
      let component = () =>
        Html.div(~children=[Html.p(~children=[View.text("Server rendered")], ())], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = DomTesting.render(ssrHtml)
      Hydration.hydrate(component, container)
      DomTesting.Assert.toHaveTextContent(container, "Server rendered")
    }),
    Test.make("reactive text becomes interactive after hydration", () => {
      let count = Signal.make(0)
      let component = () =>
        Html.div(
          ~children=[View.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))],
          (),
        )
      let ssrHtml = SSR.renderToString(component)
      let {container} = DomTesting.render(ssrHtml)
      Hydration.hydrate(component, container)
      let r1 = DomTesting.Assert.toHaveTextContent(container, "Count: 0")
      Signal.set(count, 5)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Count: 5")
      Assert.combineResults([r1, r2])
    }),
    Test.make("event handlers are attached after hydration", () => {
      let clicked = ref(false)
      let component = () =>
        Html.button(
          ~events=[("click", _evt => clicked := true)],
          ~children=[View.text("Click")],
          (),
        )
      let ssrHtml = SSR.renderToString(component)
      let {container} = DomTesting.render(ssrHtml)
      Hydration.hydrate(component, container)
      let btn = DomTesting.Query.getByRole(container, "button")
      DomTesting.Event.click(btn)
      Assert.isTrue(clicked.contents)
    }),
    Test.make("reactive attributes update after hydration", () => {
      let cls = Signal.make("initial")
      let component = () =>
        Html.div(~attrs=[View.signalAttr("class", cls)], ~children=[View.text("box")], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = DomTesting.render(ssrHtml)
      Hydration.hydrate(component, container)
      let el = DomTesting.Query.getByText(container, "box")
      let r1 = DomTesting.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")
      let r2 = DomTesting.Assert.toHaveClass(el, "updated")
      Assert.combineResults([r1, r2])
    }),
    Test.make("nested elements hydrate correctly", () => {
      let visible = Signal.make(true)
      let component = () =>
        Html.div(
          ~children=[
            Html.h1(~children=[View.text("Title")], ()),
            Html.p(
              ~attrs=[View.computedAttr("class", () => Signal.get(visible) ? "shown" : "hidden")],
              ~children=[View.text("Content")],
              (),
            ),
          ],
          (),
        )
      let ssrHtml = SSR.renderToString(component)
      let {container} = DomTesting.render(ssrHtml)
      Hydration.hydrate(component, container)
      let heading = DomTesting.Query.getByRole(container, "heading")
      let r1 = DomTesting.Assert.toHaveTextContent(heading, "Title")
      let content = DomTesting.Query.getByText(container, "Content")
      let r2 = DomTesting.Assert.toHaveClass(content, "shown")
      Signal.set(visible, false)
      let r3 = DomTesting.Assert.toHaveClass(content, "hidden")
      Assert.combineResults([r1, r2, r3])
    }),
  ],
  ~afterEach=() => DomTesting.cleanup(),
)
