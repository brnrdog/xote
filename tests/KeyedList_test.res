open Zekr
open Xote

type item = {id: string, label: string}

let mountTo = (node, container) => {
  Component.mount(node, container)
  container
}

let getItemTexts = (container): array<string> => {
  let items = Zekr.Dom.Query.findAllByRole(container, "listitem")
  items->Array.map(el => Zekr__DomBindings.textContent(el))
}

let suite = Zekr.suite(
  "KeyedList",
  [
    test("renders initial items", () => {
      let {container} = Dom.render("")
      let items = Signal.make([
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      assertEqual(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    test("appends item at end", () => {
      let {container} = Dom.render("")
      let items = Signal.make([
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
      ])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      Signal.set(items, [
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ])
      assertEqual(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    test("prepends item at start", () => {
      let {container} = Dom.render("")
      let items = Signal.make([
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      Signal.set(items, [
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ])
      assertEqual(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    test("removes item", () => {
      let {container} = Dom.render("")
      let items = Signal.make([
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      Signal.set(items, [
        {id: "1", label: "Apple"},
        {id: "3", label: "Cherry"},
      ])
      combineResults([
        assertEqual(getItemTexts(container), ["Apple", "Cherry"]),
        Dom.Assert.toNotBeInTheDocument(
          Dom.Query.queryByText(container, "Banana"),
        ),
      ])
    }),
    test("reorders items", () => {
      let {container} = Dom.render("")
      let items = Signal.make([
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
        {id: "3", label: "Cherry"},
      ])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      Signal.set(items, [
        {id: "3", label: "Cherry"},
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
      ])
      assertEqual(getItemTexts(container), ["Cherry", "Apple", "Banana"])
    }),
    test("clears all items", () => {
      let {container} = Dom.render("")
      let items = Signal.make([
        {id: "1", label: "Apple"},
        {id: "2", label: "Banana"},
      ])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      Signal.set(items, [])
      assertEqual(getItemTexts(container), [])
    }),
    test("handles rapid successive updates", () => {
      let {container} = Dom.render("")
      let items = Signal.make([{id: "1", label: "A"}])
      let _ = mountTo(
        Component.div(~children=[
          Component.ul(~children=[
            Component.keyedList(items, item => item.id, item =>
              Component.li(~children=[Component.text(item.label)], ())
            ),
          ], ()),
        ], ()),
        container,
      )
      Signal.set(items, [{id: "1", label: "A"}, {id: "2", label: "B"}])
      Signal.set(items, [{id: "2", label: "B"}, {id: "3", label: "C"}])
      Signal.set(items, [{id: "3", label: "C"}, {id: "4", label: "D"}, {id: "5", label: "E"}])
      assertEqual(getItemTexts(container), ["C", "D", "E"])
    }),
  ],
  ~afterEach=() => Dom.cleanup(),
)
