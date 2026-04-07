/*
 * Example SSR Application
 * This component can be rendered on the server and hydrated on the client
 */

/* Shared state factory - creates signals that sync between server and client */
let makeAppState = () => {
  /* Using SSRState.make creates the signal and syncs it automatically */
  let count = SSRState.make("count", 0, SSRState.Codec.int)

  let items = SSRState.make(
    "items",
    ["Apple", "Banana", "Cherry"],
    SSRState.Codec.array(SSRState.Codec.string),
  )

  /* Input value doesn't need to be synced - always starts empty */
  let inputValue = Signal.make("")

  (count, items, inputValue)
}

/* The main App component */
let app = (count, items, inputValue) =>
  () => {
    let increment = (_: Dom.event) => Signal.update(count, n => n + 1)
    let decrement = (_: Dom.event) => Signal.update(count, n => n - 1)

    let addItem = (_: Dom.event) => {
      let value = Signal.peek(inputValue)
      if value != "" {
        Signal.update(items, arr => Array.concat(arr, [value]))
        Signal.set(inputValue, "")
      }
    }

    let handleInput = (evt: Dom.event) => {
      ignore(evt)
      let value: string = %raw(`evt.target.value`)
      Signal.set(inputValue, value)
    }

    Html.div(
      ~attrs=[Node.attr("class", "app")],
      ~children=[
        /* Header */
        Html.h1(~children=[Node.text("Xote SSR Demo")], ()),
        /* Counter section */
        Html.div(
          ~attrs=[Node.attr("class", "counter-section")],
          ~children=[
            Html.h2(~children=[Node.text("Counter")], ()),
            Html.p(
              ~children=[
                Node.text("Count: "),
                Node.signalText(() => Signal.get(count)->Int.toString),
              ],
              (),
            ),
            Html.div(
              ~attrs=[Node.attr("class", "button-group")],
              ~children=[
                Html.button(
                  ~attrs=[Node.attr("class", "btn")],
                  ~events=[("click", decrement)],
                  ~children=[Node.text("-")],
                  (),
                ),
                Html.button(
                  ~attrs=[Node.attr("class", "btn")],
                  ~events=[("click", increment)],
                  ~children=[Node.text("+")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        /* Dynamic list section */
        Html.div(
          ~attrs=[Node.attr("class", "list-section")],
          ~children=[
            Html.h2(~children=[Node.text("Dynamic List")], ()),
            Html.div(
              ~attrs=[Node.attr("class", "input-group")],
              ~children=[
                Html.input(
                  ~attrs=[
                    Node.attr("type", "text"),
                    Node.attr("placeholder", "Add item..."),
                    Node.signalAttr("value", inputValue),
                  ],
                  ~events=[("input", handleInput)],
                  (),
                ),
                Html.button(
                  ~attrs=[Node.attr("class", "btn")],
                  ~events=[("click", addItem)],
                  ~children=[Node.text("Add")],
                  (),
                ),
              ],
              (),
            ),
            Html.ul(
              ~attrs=[Node.attr("class", "item-list")],
              ~children=[
                Node.list(items, item => Html.li(~children=[Node.text(item)], ())),
              ],
              (),
            ),
          ],
          (),
        ),
        /* Reactive attribute demo */
        Html.div(
          ~attrs=[Node.attr("class", "status-section")],
          ~children=[
            Html.h2(~children=[Node.text("Reactive Attributes")], ()),
            Html.div(
              ~attrs=[
                Node.computedAttr("class", () => {
                  let c = Signal.get(count)
                  if c > 5 {
                    "status high"
                  } else if c < 0 {
                    "status low"
                  } else {
                    "status normal"
                  }
                }),
              ],
              ~children=[
                Node.signalText(() => {
                  let c = Signal.get(count)
                  if c > 5 {
                    "Count is HIGH!"
                  } else if c < 0 {
                    "Count is LOW!"
                  } else {
                    "Count is normal"
                  }
                }),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
