open! TestHelpers

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let suite = Suite.make(
  "Component",
  [
    test("renders static text", () => {
      let {container} = Dom.render("")
      let _ = mountTo(View.text("hello world"), container)
      Dom.Assert.toHaveTextContent(container, "hello world")
    }),
    test("renders reactive text that updates when signal changes", () => {
      let {container} = Dom.render("")
      let name = Signal.make("Alice")
      let _ = mountTo(View.signalText(() => "Hello, " ++ Signal.get(name)), container)
      let r1 = Dom.Assert.toHaveTextContent(container, "Hello, Alice")
      Signal.set(name, "Bob")
      let r2 = Dom.Assert.toHaveTextContent(container, "Hello, Bob")
      combineResults([r1, r2])
    }),
    test("renders signalInt", () => {
      let {container} = Dom.render("")
      let count = Signal.make(42)
      let _ = mountTo(View.signalInt(() => Signal.get(count)), container)
      let r1 = Dom.Assert.toHaveTextContent(container, "42")
      Signal.set(count, 99)
      let r2 = Dom.Assert.toHaveTextContent(container, "99")
      combineResults([r1, r2])
    }),
    test("renders signalFloat", () => {
      let {container} = Dom.render("")
      let price = Signal.make(3.14)
      let _ = mountTo(View.signalFloat(() => Signal.get(price)), container)
      Dom.Assert.toHaveTextContent(container, "3.14")
    }),
    test("renders static int and float helpers", () => {
      let {container} = Dom.render("")
      let _ = mountTo(View.fragment([View.int(42), View.text(" "), View.float(2.5)]), container)
      Dom.Assert.toHaveTextContent(container, "42 2.5")
    }),
    test("renders element with static class attribute", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Html.div(~attrs=[View.attr("class", "box primary")], ~children=[View.text("content")], ()),
        container,
      )
      let el = Dom.Query.getByText(container, "content")
      Dom.Assert.toHaveClass(el, "box primary")
    }),
    test("updates element attribute when signal changes", () => {
      let {container} = Dom.render("")
      let cls = Signal.make("inactive")
      let _ = mountTo(
        Html.div(~attrs=[View.signalAttr("class", cls)], ~children=[View.text("item")], ()),
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
        Html.div(
          ~attrs=[View.computedAttr("class", () => Signal.get(isActive) ? "active" : "inactive")],
          ~children=[View.text("toggle")],
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
        Html.div(
          ~children=[
            Html.button(
              ~events=[("click", _evt => Signal.update(count, n => n + 1))],
              ~children=[View.text("Click me")],
              (),
            ),
            View.signalInt(() => Signal.get(count)),
          ],
          (),
        ),
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
        View.fragment([View.text("first"), View.text(" "), View.text("second")]),
        container,
      )
      Dom.Assert.toHaveTextContent(container, "first second")
    }),
    test("signal fragment replaces children when signal changes", () => {
      let {container} = Dom.render("")
      let items = Signal.make([View.text("original")])
      let frag = View.signalFragment(items)
      let _ = mountTo(frag, container)
      let r1 = Dom.Assert.toHaveTextContent(container, "original")
      Signal.set(items, [View.text("replaced")])
      let r2 = Dom.Assert.toHaveTextContent(container, "replaced")
      combineResults([r1, r2])
    }),
    test("null node renders empty content", () => {
      let {container} = Dom.render("")
      let _ = mountTo(Html.div(~children=[View.null(), View.text("visible")], ()), container)
      Dom.Assert.toHaveTextContent(container, "visible")
    }),
    test("renders nested element hierarchy", () => {
      let {container} = Dom.render("")
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                Html.li(~children=[View.text("Item 1")], ()),
                Html.li(~children=[View.text("Item 2")], ()),
              ],
              (),
            ),
          ],
          (),
        ),
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
        Html.div(~children=[View.each(items, item => Html.p(~children=[View.text(item)], ()))], ()),
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
        LazyComponent(
          () => {
            evaluated := true
            View.text("lazy content")
          },
        ),
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
