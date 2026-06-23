/*
 * Example SSR Application
 * This component can be rendered on the server and hydrated on the client
 */

/* Shared state factory - creates signals that sync between server and client */
let makeAppState = () => {
  /* Using SSRState.signal creates the signal and syncs it automatically */
  let count = SSRState.signal("count", 0, SSRState.Codec.int)

  let items = SSRState.signal(
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
      ~attrs=[View.attr("class", "app")],
      ~children=[
        /* Header */
        Html.h1(~children=[View.text("Xote SSR Demo")], ()),
        /* Counter section */
        Html.div(
          ~attrs=[View.attr("class", "counter-section")],
          ~children=[
            Html.h2(~children=[View.text("Counter")], ()),
            Html.p(
              ~children=[
                View.text("Count: "),
                View.signalText(() => Signal.get(count)->Int.toString),
              ],
              (),
            ),
            Html.div(
              ~attrs=[View.attr("class", "button-group")],
              ~children=[
                Html.button(
                  ~attrs=[View.attr("class", "btn")],
                  ~events=[("click", decrement)],
                  ~children=[View.text("-")],
                  (),
                ),
                Html.button(
                  ~attrs=[View.attr("class", "btn")],
                  ~events=[("click", increment)],
                  ~children=[View.text("+")],
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
          ~attrs=[View.attr("class", "list-section")],
          ~children=[
            Html.h2(~children=[View.text("Dynamic List")], ()),
            Html.div(
              ~attrs=[View.attr("class", "input-group")],
              ~children=[
                Html.input(
                  ~attrs=[
                    View.attr("type", "text"),
                    View.attr("placeholder", "Add item..."),
                    View.signalAttr("value", inputValue),
                  ],
                  ~events=[("input", handleInput)],
                  (),
                ),
                Html.button(
                  ~attrs=[View.attr("class", "btn")],
                  ~events=[("click", addItem)],
                  ~children=[View.text("Add")],
                  (),
                ),
              ],
              (),
            ),
            Html.ul(
              ~attrs=[View.attr("class", "item-list")],
              ~children=[View.each(items, item => Html.li(~children=[View.text(item)], ()))],
              (),
            ),
          ],
          (),
        ),
        /* Reactive attribute demo */
        Html.div(
          ~attrs=[View.attr("class", "status-section")],
          ~children=[
            Html.h2(~children=[View.text("Reactive Attributes")], ()),
            Html.div(
              ~attrs=[
                View.computedAttr("class", () => {
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
                View.signalText(() => {
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
