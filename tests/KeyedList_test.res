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

/* Stamp each row with the text it was built with, so a later reorder can be
   checked for *identity*: a row that still carries its original stamp is the
   same DOM node moved, not a fresh one rendered in its place. */
let stampRows: 'container => unit = %raw(`function (container) {
  container.querySelectorAll("li").forEach((el) => { el.__stamp = el.textContent })
}`)

let rowsKeptIdentity: 'container => bool = %raw(`function (container) {
  return Array.from(container.querySelectorAll("li")).every((el) => el.__stamp === el.textContent)
}`)

/* How many nodes a reordering update actually moves. The stamp check above
   cannot see this — a node keeps its stamp however often it is moved — so
   without counting, a reconciler that reinserts the whole list still looks
   correct. That is exactly the regression this guards. */
let countNodeMoves: (unit => unit) => int = %raw(`function (run) {
  const proto = globalThis.Node.prototype
  const original = proto.insertBefore
  let moves = 0
  proto.insertBefore = function (...args) { moves++; return original.apply(this, args) }
  try { run() } finally { proto.insertBefore = original }
  return moves
}`)

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
    test("survives arbitrary permutations without rebuilding rows", () => {
      let {container} = Dom.render("")
      let start = ["1", "2", "3", "4", "5", "6", "7", "8"]
      /* Reuse the *same* record instances throughout: a keyed row is rebuilt
         when its item identity changes, so allocating fresh records per update
         would rebuild every row and say nothing about reordering. */
      let pool = start->Array.map(id => {id, label: "L" ++ id})
      let build = ids =>
        ids->Array.filterMap(id => pool->Array.find(item => item.id == id))
      let items = Signal.make(build(start))
      let _ = mountTo(
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
        container,
      )
      stampRows(container)

      /* Reordering moves the complement of a longest increasing subsequence,
         so the shapes that matter are the ones that shrink that subsequence:
         a full reverse leaves only one row in place, a rotation splits the list
         in two, an interleave alternates. Each must still land in exactly the
         requested order, with every row the same node it started as. */
      let apply = order => {
        Signal.set(items, build(order))
        (getItemTexts(container), rowsKeptIdentity(container))
      }
      let expected = order => order->Array.map(id => "L" ++ id)

      let reversedOrder = ["8", "7", "6", "5", "4", "3", "2", "1"]
      let (reversed, reversedIntact) = apply(reversedOrder)

      let rotatedOrder = ["4", "5", "6", "7", "8", "1", "2", "3"]
      let (rotated, rotatedIntact) = apply(rotatedOrder)

      let endsSwappedOrder = ["3", "5", "6", "7", "8", "1", "2", "4"]
      let (endsSwapped, endsSwappedIntact) = apply(endsSwappedOrder)

      let interleavedOrder = ["2", "4", "6", "8", "1", "3", "5", "7"]
      let (interleaved, interleavedIntact) = apply(interleavedOrder)

      let (restored, restoredIntact) = apply(start)

      combineResults([
        assertEqual(reversed, expected(reversedOrder)),
        assertTrue(reversedIntact),
        assertEqual(rotated, expected(rotatedOrder)),
        assertTrue(rotatedIntact),
        assertEqual(endsSwapped, expected(endsSwappedOrder)),
        assertTrue(endsSwappedIntact),
        assertEqual(interleaved, expected(interleavedOrder)),
        assertTrue(interleavedIntact),
        assertEqual(restored, expected(start)),
        assertTrue(restoredIntact),
      ])
    }),
    test("swapping two rows moves two nodes, not the whole list", () => {
      let {container} = Dom.render("")
      let pool = Belt.Array.makeBy(100, i => {
        let id = Int.toString(i)
        {id, label: "L" ++ id}
      })
      let items = Signal.make(pool)
      let _ = mountTo(
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
        container,
      )

      /* Walking the desired order against the live DOM reinserted every node
         past the first mismatch, so this swap cost 97 moves in a 100-row list
         (997 in the 1,000-row benchmark). Only the two swapped rows are out of
         relative order, so only they should move. */
      let swapped = pool->Array.copy
      let first = swapped->Array.getUnsafe(1)
      let second = swapped->Array.getUnsafe(98)
      swapped->Array.set(1, second)
      swapped->Array.set(98, first)

      let moves = countNodeMoves(() => Signal.set(items, swapped))
      let texts = getItemTexts(container)

      combineResults([
        assertEqual(moves, 2),
        assertEqual(texts->Array.getUnsafe(1), "L98"),
        assertEqual(texts->Array.getUnsafe(98), "L1"),
        assertEqual(Array.length(texts), 100),
      ])
    }),
    test("reorders around inserted and removed rows", () => {
      let {container} = Dom.render("")
      let build = ids => ids->Array.map(id => {id, label: "L" ++ id})
      let items = Signal.make(build(["1", "2", "3", "4", "5"]))
      let _ = mountTo(
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
        container,
      )

      /* A fresh row is not yet in the document, so it can never count as
         "already in place" — it has to be inserted even though its neighbours
         stay put. Mixing that with a removal and a reorder in one update is
         where an off-by-one in the placement walk would surface. */
      Signal.set(items, build(["5", "9", "1", "3", "7"]))
      let mixed = getItemTexts(container)

      Signal.set(items, build(["7", "3", "1", "9", "5"]))
      let reordered = getItemTexts(container)

      combineResults([
        assertEqual(mixed, ["L5", "L9", "L1", "L3", "L7"]),
        assertEqual(reordered, ["L7", "L3", "L1", "L9", "L5"]),
      ])
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
