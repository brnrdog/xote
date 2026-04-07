open! Zekr

let suite = Zekr.suite(
  "Hydration",
  [
    test("static content is preserved after hydration", () => {
      let component = () =>
        Html.div(~children=[
          Html.p(~children=[Node.text("Server rendered")], ()),
        ], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      Dom.Assert.toHaveTextContent(container, "Server rendered")
    }),
    test("reactive text becomes interactive after hydration", () => {
      let count = Signal.make(0)
      let component = () =>
        Html.div(~children=[
          Node.signalText(() => "Count: " ++ Int.toString(Signal.get(count))),
        ], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      let r1 = Dom.Assert.toHaveTextContent(container, "Count: 0")
      Signal.set(count, 5)
      let r2 = Dom.Assert.toHaveTextContent(container, "Count: 5")
      combineResults([r1, r2])
    }),
    test("event handlers are attached after hydration", () => {
      let clicked = ref(false)
      let component = () =>
        Html.button(
          ~events=[("click", _evt => clicked := true)],
          ~children=[Node.text("Click")],
          (),
        )
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      let btn = Dom.Query.getByRole(container, "button")
      Dom.Event.click(btn)
      assertTrue(clicked.contents)
    }),
    test("reactive attributes update after hydration", () => {
      let cls = Signal.make("initial")
      let component = () =>
        Html.div(
          ~attrs=[Node.signalAttr("class", cls)],
          ~children=[Node.text("box")],
          (),
        )
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      let el = Dom.Query.getByText(container, "box")
      let r1 = Dom.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")
      let r2 = Dom.Assert.toHaveClass(el, "updated")
      combineResults([r1, r2])
    }),
    test("nested elements hydrate correctly", () => {
      let visible = Signal.make(true)
      let component = () =>
        Html.div(~children=[
          Html.h1(~children=[Node.text("Title")], ()),
          Html.p(
            ~attrs=[
              Node.computedAttr("class", () =>
                Signal.get(visible) ? "shown" : "hidden"
              ),
            ],
            ~children=[Node.text("Content")],
            (),
          ),
        ], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      let heading = Dom.Query.getByRole(container, "heading")
      let r1 = Dom.Assert.toHaveTextContent(heading, "Title")
      let content = Dom.Query.getByText(container, "Content")
      let r2 = Dom.Assert.toHaveClass(content, "shown")
      Signal.set(visible, false)
      let r3 = Dom.Assert.toHaveClass(content, "hidden")
      combineResults([r1, r2, r3])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
