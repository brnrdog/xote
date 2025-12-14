// ReconciliationTest.res - Test to verify list reconciliation
module Signal = Xote.Signal
module Component = Xote.Component

type item = {
  id: int,
  text: string,
  color: string,
}

let items = Signal.make([
  {id: 1, text: "Item 1", color: "bg-red-500"},
  {id: 2, text: "Item 2", color: "bg-blue-500"},
  {id: 3, text: "Item 3", color: "bg-green-500"},
])

// Component that logs when it's created
let itemComponent = (item: item) => {
  // Log when this component is created (should only happen once per unique ID)
  Console.log(`Creating component for item ${Int.toString(item.id)}: ${item.text}`)

  Component.div(
    ~attrs=[
      Component.attr("class", `p-4 m-2 ${item.color} text-white rounded`),
      Component.attr("data-item-id", Int.toString(item.id)),
    ],
    ~children=[Component.text(item.text)],
    (),
  )
}

let app = () => {
  Component.div(
    ~attrs=[Component.attr("class", "p-8")],
    ~children=[
      Component.h1(
        ~attrs=[Component.attr("class", "text-2xl font-bold mb-4")],
        ~children=[Component.text("Reconciliation Test")],
        (),
      ),
      Component.p(
        ~attrs=[Component.attr("class", "mb-4 text-gray-600")],
        ~children=[
          Component.text(
            "Watch the console - items should only be created once, not on every update.",
          ),
        ],
        (),
      ),
      Component.div(
        ~attrs=[Component.attr("class", "mb-4 space-x-2")],
        ~children=[
          Component.button(
            ~attrs=[
              Component.attr(
                "class",
                "px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700",
              ),
            ],
            ~events=[
              (
                "click",
                _ => {
                  Console.log("🔀 Shuffling items (should reorder, not recreate)")
                  Signal.update(items, list => {
                    let shuffled = Array.copy(list)
                    // Simple shuffle - reverse the array
                    Array.reverse(shuffled)
                    shuffled
                  })
                },
              ),
            ],
            ~children=[Component.text("Shuffle Items")],
            (),
          ),
          Component.button(
            ~attrs=[
              Component.attr(
                "class",
                "px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700",
              ),
            ],
            ~events=[
              (
                "click",
                _ => {
                  Console.log("➕ Adding new item (should create only the new one)")
                  Signal.update(items, list => {
                    let newId = Array.length(list) + 1
                    Array.concat(list, [{id: newId, text: `Item ${Int.toString(newId)}`, color: "bg-purple-500"}])
                  })
                },
              ),
            ],
            ~children=[Component.text("Add Item")],
            (),
          ),
          Component.button(
            ~attrs=[
              Component.attr(
                "class",
                "px-4 py-2 bg-red-600 text-white rounded hover:bg-red-700",
              ),
            ],
            ~events=[
              (
                "click",
                _ => {
                  Console.log("🗑️ Removing first item (should remove only that one)")
                  Signal.update(items, list => Array.sliceToEnd(list, ~start=1))
                },
              ),
            ],
            ~children=[Component.text("Remove First")],
            (),
          ),
          Component.button(
            ~attrs=[
              Component.attr(
                "class",
                "px-4 py-2 bg-yellow-600 text-white rounded hover:bg-yellow-700",
              ),
            ],
            ~events=[
              (
                "click",
                _ => {
                  Console.log("✏️ Updating first item text (DOM should stay same)")
                  Signal.update(items, list => {
                    switch list[0] {
                    | Some(first) => {
                        let updated = {...first, text: `${first.text} (updated)`}
                        Array.concat([updated], Array.sliceToEnd(list, ~start=1))
                      }
                    | None => list
                    }
                  })
                },
              ),
            ],
            ~children=[Component.text("Update First")],
            (),
          ),
        ],
        (),
      ),
      Component.div(
        ~attrs=[Component.attr("class", "border-2 border-gray-300 rounded p-4")],
        ~children=[
          Component.keyedList(items, item => Int.toString(item.id), itemComponent),
        ],
        (),
      ),
    ],
    (),
  )
}

// Mount the app
Component.mountById(app(), "app")
