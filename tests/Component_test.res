open Zekr
open Xote

let mountTo = (node, container) => {
  Component.mount(node, container)
  container
}

let suite = Zekr.suite(
  "Component",
  [
    test("renders static text", () => {
      let {container} = Dom.render("")
      let _ = mountTo(Component.text("hello world"), container)
      Dom.Assert.toHaveTextContent(container, "hello world")
    }),
    test("renders reactive text that updates when signal changes", () => {
      let {container} = Dom.render("")
      let name = Signal.make("Alice")
      let _ = mountTo(Component.textSignal(() => "Hello, " ++ Signal.get(name)), container)
      let r1 = Dom.Assert.toHaveTextContent(container, "Hello, Alice")
      Signal.set(name, "Bob")
      let r2 = Dom.Assert.toHaveTextContent(container, "Hello, Bob")
      combineResults([r1, r2])
    }),
    test("renders reactiveInt", () => {
      let {container} = Dom.render("")
      let count = Signal.make(42)
      let _ = mountTo(Component.reactiveInt(() => Signal.get(count)), container)
      let r1 = Dom.Assert.toHaveTextContent(container, "42")
      Signal.set(count, 99)
      let r2 = Dom.Assert.toHaveTextContent(container, "99")
      combineResults([r1, r2])
    }),
    test("renders reactiveFloat", () => {
      let {container} = Dom.render("")
      let price = Signal.make(3.14)
      let _ = mountTo(Component.reactiveFloat(() => Signal.get(price)), container)
      Dom.Assert.toHaveTextContent(container, "3.14")
    }),
    test("renders static int and float helpers", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Component.fragment([Component.int(42), Component.text(" "), Component.float(2.5)]),
        container,
      )
      Dom.Assert.toHaveTextContent(container, "42 2.5")
    }),
    test("renders element with static class attribute", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Component.div(
          ~attrs=[Component.attr("class", "box primary")],
          ~children=[Component.text("content")],
          (),
        ),
        container,
      )
      let el = Dom.Query.getByText(container, "content")
      Dom.Assert.toHaveClass(el, "box primary")
    }),
    test("updates element attribute when signal changes", () => {
      let {container} = Dom.render("")
      let cls = Signal.make("inactive")
      let _ = mountTo(
        Component.div(
          ~attrs=[Component.signalAttr("class", cls)],
          ~children=[Component.text("item")],
          (),
        ),
        container,
      )
      let el = Dom.Query.getByText(container, "item")
      let r1 = Dom.Assert.toHaveClass(el, "inactive")
      Signal.set(cls, "active")
      let r2 = Dom.Assert.toHaveClass(el, "active")
      combineResults([r1, r2])
    }),
    test("updates element attribute from computed", () => {
      let {container} = Dom.render("")
      let isActive = Signal.make(false)
      let _ = mountTo(
        Component.div(
          ~attrs=[
            Component.computedAttr("class", () =>
              Signal.get(isActive) ? "active" : "inactive"
            ),
          ],
          ~children=[Component.text("toggle")],
          (),
        ),
        container,
      )
      let el = Dom.Query.getByText(container, "toggle")
      let r1 = Dom.Assert.toHaveClass(el, "inactive")
      Signal.set(isActive, true)
      let r2 = Dom.Assert.toHaveClass(el, "active")
      combineResults([r1, r2])
    }),
    test("handles click events", () => {
      let {container} = Dom.render("")
      let count = Signal.make(0)
      let _ = mountTo(
        Component.div(~children=[
          Component.button(
            ~events=[("click", _evt => Signal.update(count, n => n + 1))],
            ~children=[Component.text("Click me")],
            (),
          ),
          Component.reactiveInt(() => Signal.get(count)),
        ], ()),
        container,
      )
      let btn = Dom.Query.getByRole(container, "button")
      let r1 = Dom.Assert.toHaveTextContent(container, "Click me0")
      Dom.Event.click(btn)
      let r2 = Dom.Assert.toHaveTextContent(container, "Click me1")
      Dom.Event.click(btn)
      let r3 = Dom.Assert.toHaveTextContent(container, "Click me2")
      combineResults([r1, r2, r3])
    }),
    test("renders fragment with multiple children", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Component.fragment([
          Component.text("first"),
          Component.text(" "),
          Component.text("second"),
        ]),
        container,
      )
      Dom.Assert.toHaveTextContent(container, "first second")
    }),
    test("signal fragment replaces children when signal changes", () => {
      let {container} = Dom.render("")
      let items = Signal.make([Component.text("original")])
      let frag = Component.signalFragment(items)
      let _ = mountTo(frag, container)
      let r1 = Dom.Assert.toHaveTextContent(container, "original")
      Signal.set(items, [Component.text("replaced")])
      let r2 = Dom.Assert.toHaveTextContent(container, "replaced")
      combineResults([r1, r2])
    }),
    test("null node renders empty content", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Component.div(~children=[Component.null(), Component.text("visible")], ()),
        container,
      )
      Dom.Assert.toHaveTextContent(container, "visible")
    }),
    test("renders nested element hierarchy", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.li(~children=[Component.text("Item 1")], ()),
            Component.li(~children=[Component.text("Item 2")], ()),
          ], ()),
        ], ()),
        container,
      )
      let items = Dom.Query.getAllByRole(container, "listitem")
      combineResults([
        assertEqual(Array.length(items), 2),
        Dom.Assert.toHaveTextContent(items->Array.getUnsafe(0), "Item 1"),
        Dom.Assert.toHaveTextContent(items->Array.getUnsafe(1), "Item 2"),
      ])
    }),
    test("simple list re-renders all items on change", () => {
      let {container} = Dom.render("")
      let items = Signal.make(["Apple", "Banana"])
      let _ = mountTo(
        Component.div(~children=[
          Component.list(items, item =>
            Component.p(~children=[Component.text(item)], ())
          ),
        ], ()),
        container,
      )
      let r1 = Dom.Assert.toHaveTextContent(container, "AppleBanana")
      Signal.set(items, ["Apple", "Banana", "Cherry"])
      let r2 = Dom.Assert.toHaveTextContent(container, "AppleBananaCherry")
      combineResults([r1, r2])
    }),
    test("lazy component defers evaluation", () => {
      let {container} = Dom.render("")
      let evaluated = ref(false)
      let _ = mountTo(
        LazyComponent(() => {
          evaluated := true
          Component.text("lazy content")
        }),
        container,
      )
      combineResults([
        assertTrue(evaluated.contents),
        Dom.Assert.toHaveTextContent(container, "lazy content"),
      ])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
