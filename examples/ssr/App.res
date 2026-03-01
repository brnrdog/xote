/*
 * Example SSR Application
 * This component can be rendered on the server and hydrated on the client
 */
open Xote

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
let app = (count, items, inputValue) => () => {
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
    let value: string = %raw(`evt.target.value`)
    Signal.set(inputValue, value)
  }

  Component.div(
    ~attrs=[Component.attr("class", "app")],
    ~children=[
      /* Header */
      Component.h1(~children=[Component.text("Xote SSR Demo")], ()),

      /* Counter section */
      Component.div(
        ~attrs=[Component.attr("class", "counter-section")],
        ~children=[
          Component.h2(~children=[Component.text("Counter")], ()),
          Component.p(~children=[
            Component.text("Count: "),
            Component.textSignal(() => Signal.get(count)->Int.toString),
          ], ()),
          Component.div(
            ~attrs=[Component.attr("class", "button-group")],
            ~children=[
              Component.button(
                ~attrs=[Component.attr("class", "btn")],
                ~events=[("click", decrement)],
                ~children=[Component.text("-")],
                (),
              ),
              Component.button(
                ~attrs=[Component.attr("class", "btn")],
                ~events=[("click", increment)],
                ~children=[Component.text("+")],
                (),
              ),
            ],
            (),
          ),
        ],
        (),
      ),

      /* Dynamic list section */
      Component.div(
        ~attrs=[Component.attr("class", "list-section")],
        ~children=[
          Component.h2(~children=[Component.text("Dynamic List")], ()),
          Component.div(
            ~attrs=[Component.attr("class", "input-group")],
            ~children=[
              Component.input(
                ~attrs=[
                  Component.attr("type", "text"),
                  Component.attr("placeholder", "Add item..."),
                  Component.signalAttr("value", inputValue),
                ],
                ~events=[("input", handleInput)],
                (),
              ),
              Component.button(
                ~attrs=[Component.attr("class", "btn")],
                ~events=[("click", addItem)],
                ~children=[Component.text("Add")],
                (),
              ),
            ],
            (),
          ),
          Component.ul(
            ~attrs=[Component.attr("class", "item-list")],
            ~children=[
              Component.list(items, item =>
                Component.li(~children=[Component.text(item)], ())
              ),
            ],
            (),
          ),
        ],
        (),
      ),

      /* Reactive attribute demo */
      Component.div(
        ~attrs=[Component.attr("class", "status-section")],
        ~children=[
          Component.h2(~children=[Component.text("Reactive Attributes")], ()),
          Component.div(
            ~attrs=[
              Component.computedAttr("class", () => {
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
              Component.textSignal(() => {
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
