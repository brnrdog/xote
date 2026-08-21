open! Zekr

type item = {id: string, label: string}

let mountTo = (node, container) => {
  View.mount(node, container)
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
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      assertEqual(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    test("appends item at end", () => {
      let {container} = Dom.render("")
      let items = Signal.make([{id: "1", label: "Apple"}, {id: "2", label: "Banana"}])
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(
        items,
        [{id: "1", label: "Apple"}, {id: "2", label: "Banana"}, {id: "3", label: "Cherry"}],
      )
      assertEqual(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    test("prepends item at start", () => {
      let {container} = Dom.render("")
      let items = Signal.make([{id: "2", label: "Banana"}, {id: "3", label: "Cherry"}])
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(
        items,
        [{id: "1", label: "Apple"}, {id: "2", label: "Banana"}, {id: "3", label: "Cherry"}],
      )
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
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(items, [{id: "1", label: "Apple"}, {id: "3", label: "Cherry"}])
      combineResults([
        assertEqual(getItemTexts(container), ["Apple", "Cherry"]),
        Dom.Assert.toNotBeInTheDocument(Dom.Query.queryByText(container, "Banana")),
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
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(
        items,
        [{id: "3", label: "Cherry"}, {id: "1", label: "Apple"}, {id: "2", label: "Banana"}],
      )
      assertEqual(getItemTexts(container), ["Cherry", "Apple", "Banana"])
    }),
    test("clears all items", () => {
      let {container} = Dom.render("")
      let items = Signal.make([{id: "1", label: "Apple"}, {id: "2", label: "Banana"}])
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(items, [])
      assertEqual(getItemTexts(container), [])
    }),
    test("reorders and replaces an item in one update", () => {
      let {container} = Dom.render("")
      let apple = {id: "1", label: "Apple"}
      let banana = {id: "2", label: "Banana"}
      let cherry = {id: "3", label: "Cherry"}
      let items = Signal.make([apple, banana, cherry])
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      /* The replaced key's element is retired where it lives, not wherever the
         ordering pass happens to point: a reorder in the same update used to
         leave the old element behind as a duplicate. */
      Signal.set(items, [cherry, {id: "2", label: "Blueberry"}, apple])
      assertEqual(getItemTexts(container), ["Cherry", "Blueberry", "Apple"])
    }),
    test("keeps untouched rows reactive across a reorder + replace", () => {
      let {container} = Dom.render("")
      let theme = Signal.make("light")
      let apple = {id: "1", label: "Apple"}
      let banana = {id: "2", label: "Banana"}
      let cherry = {id: "3", label: "Cherry"}
      let items = Signal.make([apple, banana, cherry])
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item =>
                    Html.li(
                      ~attrs=[View.signalAttr("class", theme)],
                      ~children=[View.text(item.label)],
                      (),
                    ),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        container,
      )
      Signal.set(items, [cherry, {id: "2", label: "Blueberry"}, apple])
      Signal.set(theme, "dark")
      /* A row whose owner is disposed while it is still mounted stops updating,
         so this reads the class of every surviving row. */
      let classes =
        Zekr.Dom.Query.findAllByRole(container, "listitem")->Array.map(el =>
          Zekr__DomBindings.getAttribute(el, "class")->Nullable.toOption->Option.getOr("")
        )
      assertEqual(classes, ["dark", "dark", "dark"])
    }),
    test("handles rapid successive updates", () => {
      let {container} = Dom.render("")
      let items = Signal.make([{id: "1", label: "A"}])
      let _ = mountTo(
        Html.div(
          ~children=[
            Html.ul(
              ~children=[
                View.eachWithKey(
                  items,
                  item => item.id,
                  item => Html.li(~children=[View.text(item.label)], ()),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
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
