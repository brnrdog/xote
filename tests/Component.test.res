%%raw(`import "./setup.mjs"`)

open! Zekr

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let suite = Suite.make(
  "Component",
  [
    Test.make("renders static text", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(View.text("hello world"), container)
      DomTesting.Assert.toHaveTextContent(container, "hello world")
    }),
    Test.make("renders reactive text that updates when signal changes", () => {
      let {container} = DomTesting.render("")
      let name = Signal.make("Alice")
      let _ = mountTo(View.signalText(() => "Hello, " ++ Signal.get(name)), container)
      let r1 = DomTesting.Assert.toHaveTextContent(container, "Hello, Alice")
      Signal.set(name, "Bob")
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Hello, Bob")
      Assert.combineResults([r1, r2])
    }),
    Test.make("renders signalInt", () => {
      let {container} = DomTesting.render("")
      let count = Signal.make(42)
      let _ = mountTo(View.signalInt(() => Signal.get(count)), container)
      let r1 = DomTesting.Assert.toHaveTextContent(container, "42")
      Signal.set(count, 99)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "99")
      Assert.combineResults([r1, r2])
    }),
    Test.make("renders signalFloat", () => {
      let {container} = DomTesting.render("")
      let price = Signal.make(3.14)
      let _ = mountTo(View.signalFloat(() => Signal.get(price)), container)
      DomTesting.Assert.toHaveTextContent(container, "3.14")
    }),
    Test.make("renders static int and float helpers", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(View.fragment([View.int(42), View.text(" "), View.float(2.5)]), container)
      DomTesting.Assert.toHaveTextContent(container, "42 2.5")
    }),
    Test.make("renders element with static class attribute", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        Html.div(~attrs=[View.attr("class", "box primary")], ~children=[View.text("content")], ()),
        container,
      )
      let el = DomTesting.Query.getByText(container, "content")
      DomTesting.Assert.toHaveClass(el, "box primary")
    }),
    Test.make("updates element attribute when signal changes", () => {
      let {container} = DomTesting.render("")
      let cls = Signal.make("inactive")
      let _ = mountTo(
        Html.div(~attrs=[View.signalAttr("class", cls)], ~children=[View.text("item")], ()),
        container,
      )
      let el = DomTesting.Query.getByText(container, "item")
      let r1 = DomTesting.Assert.toHaveClass(el, "inactive")
      Signal.set(cls, "active")
      let r2 = DomTesting.Assert.toHaveClass(el, "active")
      Assert.combineResults([r1, r2])
    }),
    Test.make("updates element attribute from computed", () => {
      let {container} = DomTesting.render("")
      let isActive = Signal.make(false)
      let _ = mountTo(
        Html.div(
          ~attrs=[View.computedAttr("class", () => Signal.get(isActive) ? "active" : "inactive")],
          ~children=[View.text("toggle")],
          (),
        ),
        container,
      )
      let el = DomTesting.Query.getByText(container, "toggle")
      let r1 = DomTesting.Assert.toHaveClass(el, "inactive")
      Signal.set(isActive, true)
      let r2 = DomTesting.Assert.toHaveClass(el, "active")
      Assert.combineResults([r1, r2])
    }),
    Test.make("handles click events", () => {
      let {container} = DomTesting.render("")
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
      let btn = DomTesting.Query.getByRole(container, "button")
      let r1 = DomTesting.Assert.toHaveTextContent(container, "Click me0")
      DomTesting.Event.click(btn)
      let r2 = DomTesting.Assert.toHaveTextContent(container, "Click me1")
      DomTesting.Event.click(btn)
      let r3 = DomTesting.Assert.toHaveTextContent(container, "Click me2")
      Assert.combineResults([r1, r2, r3])
    }),
    Test.make("renders fragment with multiple children", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(
        View.fragment([View.text("first"), View.text(" "), View.text("second")]),
        container,
      )
      DomTesting.Assert.toHaveTextContent(container, "first second")
    }),
    Test.make("signal fragment replaces children when signal changes", () => {
      let {container} = DomTesting.render("")
      let items = Signal.make([View.text("original")])
      let frag = View.signalFragment(items)
      let _ = mountTo(frag, container)
      let r1 = DomTesting.Assert.toHaveTextContent(container, "original")
      Signal.set(items, [View.text("replaced")])
      let r2 = DomTesting.Assert.toHaveTextContent(container, "replaced")
      Assert.combineResults([r1, r2])
    }),
    Test.make("null node renders empty content", () => {
      let {container} = DomTesting.render("")
      let _ = mountTo(Html.div(~children=[View.null(), View.text("visible")], ()), container)
      DomTesting.Assert.toHaveTextContent(container, "visible")
    }),
    Test.make("renders nested element hierarchy", () => {
      let {container} = DomTesting.render("")
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
      let items = DomTesting.Query.getAllByRole(container, "listitem")
      Assert.combineResults([
        Assert.equal(Array.length(items), 2),
        DomTesting.Assert.toHaveTextContent(items->Array.getUnsafe(0), "Item 1"),
        DomTesting.Assert.toHaveTextContent(items->Array.getUnsafe(1), "Item 2"),
      ])
    }),
    Test.make("simple list re-renders all items on change", () => {
      let {container} = DomTesting.render("")
      let items = Signal.make(["Apple", "Banana"])
      let _ = mountTo(
        Html.div(~children=[View.each(items, item => Html.p(~children=[View.text(item)], ()))], ()),
        container,
      )
      let r1 = DomTesting.Assert.toHaveTextContent(container, "AppleBanana")
      Signal.set(items, ["Apple", "Banana", "Cherry"])
      let r2 = DomTesting.Assert.toHaveTextContent(container, "AppleBananaCherry")
      Assert.combineResults([r1, r2])
    }),
    Test.make("lazy component defers evaluation", () => {
      let {container} = DomTesting.render("")
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
      Assert.combineResults([
        Assert.isTrue(evaluated.contents),
        DomTesting.Assert.toHaveTextContent(container, "lazy content"),
      ])
    }),
  ],
  ~afterEach=() => DomTesting.cleanup(),
)
