open! Zekr

type row = {id: string, label: string}

/* Stamp each row with the text it was built with: a row that still carries its
   original stamp after an update is the same node moved, not a fresh one. */
let stampRows: 'container => unit = %raw(`function (container) {
  container.querySelectorAll("li").forEach((el) => { el.__stamp = el.textContent })
}`)

let rowsKeptIdentity: 'container => bool = %raw(`function (container) {
  return Array.from(container.querySelectorAll("li")).every((el) => el.__stamp === el.textContent)
}`)

/* Nodes parsed from the server markup belong to the document that parsed them,
   which is not necessarily the one on `globalThis` — patching the global
   `Node.prototype` would miss every call and report a reassuring zero. Take the
   prototype from the container's own realm. */
let countNodeMoves: ('container, unit => unit) => int = %raw(`function (container, run) {
  const proto = container.ownerDocument.defaultView.Node.prototype
  const original = proto.insertBefore
  let moves = 0
  proto.insertBefore = function (...args) { moves++; return original.apply(this, args) }
  try { run() } finally { proto.insertBefore = original }
  return moves
}`)

let rowTexts = (container): array<string> =>
  Dom.Query.findAllByRole(container, "listitem")->Array.map(Zekr__DomBindings.textContent)

let keyedList = (rows: Signal.t<array<row>>) =>
  Html.ul(
    ~children=[
      View.eachWithKey(rows, row => row.id, row => Html.li(~children=[View.text(row.label)], ())),
    ],
    (),
  )


let suite = Zekr.suite(
  "Hydration",
  [
    test("static content is preserved after hydration", () => {
      let component = () =>
        Html.div(~children=[Html.p(~children=[View.text("Server rendered")], ())], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      Dom.Assert.toHaveTextContent(container, "Server rendered")
    }),
    test("reactive text becomes interactive after hydration", () => {
      let count = Signal.make(0)
      let component = () =>
        Html.div(
          ~children=[View.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))],
          (),
        )
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
          ~children=[View.text("Click")],
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
        Html.div(~attrs=[View.signalAttr("class", cls)], ~children=[View.text("box")], ())
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      let el = Dom.Query.getByText(container, "box")
      let r1 = Dom.Assert.toHaveClass(el, "initial")
      Signal.set(cls, "updated")
      let r2 = Dom.Assert.toHaveClass(el, "updated")
      combineResults([r1, r2])
    }),
    test("optional attributes toggle presence after hydration", () => {
      let open_ = Signal.make(true)
      let component = () =>
        Html.div(
          ~attrs=[View.optionalComputedAttr("data-open", () => Signal.get(open_) ? Some("") : None)],
          ~children=[View.text("panel")],
          (),
        )
      let ssrHtml = SSR.renderToString(component)
      let {container} = Dom.render(ssrHtml)
      Hydration.hydrate(component, container)
      let el = Dom.Query.getByText(container, "panel")
      let r1 = Dom.Assert.toHaveAttribute(el, "data-open", ~value="")
      Signal.set(open_, false)
      combineResults([
        assertContains(ssrHtml, `data-open=""`),
        r1,
        Dom.Assert.toNotHaveAttribute(el, "data-open"),
      ])
    }),
    test("nested elements hydrate correctly", () => {
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
    test("a hydrated keyed list reconciles rather than rebuilding", () => {
      /* The keyed branch of the hydration path never subscribed to its signal:
         it parsed the server's rows into a dict and dropped it, so a hydrated
         `View.For` rendered once and then ignored every write for the life of
         the page. It now runs the same reconcile pass the render path does. */
      let pool = [
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ]
      let at = i => pool->Array.getUnsafe(i)
      let rows = Signal.make([at(0), at(1), at(2)])
      let component = () => keyedList(rows)
      let {container} = Dom.render(SSR.renderToString(component))
      Hydration.hydrate(component, container)
      let r1 = assertEqual(rowTexts(container), ["Apple", "Banana", "Cherry"])
      stampRows(container)
      /* Reuse the instances: the reconciler rebuilds a key whose identity
         changed, so fresh records would rebuild every row legitimately and the
         identity check below would prove nothing. */
      Signal.set(rows, [at(2), at(0), at(1)])
      combineResults([
        r1,
        assertEqual(rowTexts(container), ["Cherry", "Apple", "Banana"]),
        assertTrue(rowsKeptIdentity(container)),
      ])
    }),
    test("a hydrated keyed list adopts the server rows and moves the minimum", () => {
      let pool = [
        {id: "1", label: "a"},
        {id: "2", label: "b"},
        {id: "3", label: "c"},
        {id: "4", label: "d"},
      ]
      let at = i => pool->Array.getUnsafe(i)
      let rows = Signal.make([at(0), at(1), at(2), at(3)])
      let component = () => keyedList(rows)
      let {container} = Dom.render(SSR.renderToString(component))
      Hydration.hydrate(component, container)
      stampRows(container)
      /* Swapping the ends leaves b and c in order, so a minimal reconciler moves
         two nodes. Rebuilding the list from the signal instead of adopting what
         the server sent would move four and lose every stamp. */
      let moves = countNodeMoves(container, () =>
        Signal.set(rows, [at(3), at(1), at(2), at(0)])
      )
      combineResults([
        assertEqual(rowTexts(container), ["d", "b", "c", "a"]),
        assertEqual(moves, 2),
        assertTrue(rowsKeptIdentity(container)),
      ])
    }),
    test("a hydrated keyed row is interactive, not just markup", () => {
      /* Adoption is only worth having if the row comes back alive. The rows are
         hydrated through the ordinary path, so their handlers and reactive
         bindings attach to the server's own nodes — no rebuild. */
      let clicks = ref(0)
      let label = Signal.make("a")
      let pool = [{id: "1", label: "x"}, {id: "2", label: "y"}]
      let rows = Signal.make([pool->Array.getUnsafe(0), pool->Array.getUnsafe(1)])
      let component = () =>
        Html.ul(
          ~children=[
            View.eachWithKey(
              rows,
              row => row.id,
              row =>
                Html.li(
                  ~attrs=[View.signalAttr("data-tag", label)],
                  ~events=[("click", _ => clicks := clicks.contents + 1)],
                  ~children=[View.signalText(() => Signal.get(label) ++ row.id)],
                  (),
                ),
            ),
          ],
          (),
        )
      let {container} = Dom.render(SSR.renderToString(component))
      Hydration.hydrate(component, container)
      let firstRow = Dom.Query.findAllByRole(container, "listitem")->Array.getUnsafe(0)
      Dom.Event.click(firstRow)
      let clicked = assertEqual(clicks.contents, 1)
      Signal.set(label, "z")
      combineResults([
        clicked,
        assertEqual(rowTexts(container), ["z1", "z2"]),
        Dom.Assert.toHaveAttribute(firstRow, "data-tag", ~value="z"),
        /* `firstRow` was captured before the write, so this proves the row that
           updated is the server's own node rather than a replacement. */
        assertTrue(
          Dom.Query.findAllByRole(container, "listitem")->Array.getUnsafe(0) === firstRow,
        ),
      ])
    }),
    test("a hydrated keyed list replacing non-keyed children retires them", () => {
      /* The render path had this hole and was fixed; hydration reaches the same
         reconciler by its own route, so it needs the same guard. */
      let show = Signal.make(false)
      let component = () =>
        View.Show.make({
          when_: MaybeSignal.reactive(show),
          children: View.For.make({
            each: MaybeSignal.static(["a", "b"]),
            by: item => item,
            render: item => Html.li(~children=[View.text(item)], ()),
          }),
          fallback: Html.p(~children=[View.text("empty")], ()),
        })
      let {container} = Dom.render(SSR.renderToString(component))
      Hydration.hydrate(component, container)
      let r1 = Dom.Assert.toHaveTextContent(container, "empty")
      Signal.set(show, true)
      let listed = Dom.Assert.toHaveTextContent(container, "ab")
      let fallbackGone = assertTrue(
        Zekr__DomBindings.querySelector(container, "p")->Nullable.toOption->Option.isNone,
      )
      Signal.set(show, false)
      combineResults([r1, listed, fallbackGone, Dom.Assert.toHaveTextContent(container, "empty")])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
