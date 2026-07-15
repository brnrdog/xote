%%raw(`import "./setup.mjs"`)

open! Zekr

type item = {id: string, label: string}

let mountTo = (node, container) => {
  View.mount(node, container)
  container
}

let getItemTexts = (container): array<string> => {
  let items = DomTesting.Query.findAllByRole(container, "listitem")
  items->Array.map(el => DomBindings.textContent(el))
}

let suite = Suite.make(
  "KeyedList",
  [
    Test.make("renders initial items", () => {
      let {container} = DomTesting.render("")
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
      Assert.equal(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    Test.make("appends item at end", () => {
      let {container} = DomTesting.render("")
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
      Assert.equal(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    Test.make("prepends item at start", () => {
      let {container} = DomTesting.render("")
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
      Assert.equal(getItemTexts(container), ["Apple", "Banana", "Cherry"])
    }),
    Test.make("removes item", () => {
      let {container} = DomTesting.render("")
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
      Assert.combineResults([
        Assert.equal(getItemTexts(container), ["Apple", "Cherry"]),
        DomTesting.Assert.toNotBeInTheDocument(DomTesting.Query.queryByText(container, "Banana")),
      ])
    }),
    Test.make("reorders items", () => {
      let {container} = DomTesting.render("")
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
      Assert.equal(getItemTexts(container), ["Cherry", "Apple", "Banana"])
    }),
    Test.make("clears all items", () => {
      let {container} = DomTesting.render("")
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
      Assert.equal(getItemTexts(container), [])
    }),
    Test.make("handles rapid successive updates", () => {
      let {container} = DomTesting.render("")
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
      Assert.equal(getItemTexts(container), ["C", "D", "E"])
    }),
  ],
  ~afterEach=() => DomTesting.cleanup(),
)
