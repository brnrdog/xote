let fruits = [
  "Apple", "Apricot", "Banana", "Blackberry", "Blueberry", "Cherry", "Grape", "Lemon",
  "Lime", "Mango", "Orange", "Peach", "Pear", "Plum", "Raspberry", "Strawberry",
]

// A pretend server: answers after 400ms.
let searchFruits = (query: string): promise<array<string>> =>
  Promise.make((resolve, _reject) => {
    let _ = setTimeout(() => {
      let q = query->String.toLowerCase
      resolve(fruits->Array.filter(fruit => fruit->String.toLowerCase->String.includes(q)))
    }, 400)
  })

@xote.component
let make = () => {
  let text = Signal.make("")
  let query = Signal.make("")

  // Search only after a 300ms pause in typing.
  Effect.run(() => {
    let next = Signal.get(text)
    let id = setTimeout(() => Signal.set(query, next), 300)
    Some(() => clearTimeout(id))
  })

  let results = Resource.make(() => searchFruits(Signal.get(query)))

  let onInput = (event: Dom.event) => {
    let target: {"value": string} = (event->Obj.magic)["target"]
    Signal.set(text, target["value"])
  }

  <div class="fetch-demo">
    <input
      type_="search"
      class="fetch-demo-input"
      placeholder="Search fruit"
      value={Signal.get(text)}
      onInput
    />
    {switch Signal.get(results) {
    | Pending => <p class="fetch-demo-status"> {"Searching..."} </p>
    | Failed(_) => <p class="fetch-demo-status"> {"Search failed. Try again."} </p>
    | Ready([]) => <p class="fetch-demo-status"> {"No fruit matches."} </p>
    | Ready(items) | Refreshing(items) =>
      <ul class={Resource.isLoading(Signal.get(results)) ? "fetch-demo-list is-stale" : "fetch-demo-list"}>
        {items->Array.map(fruit => <li> {fruit} </li>)->View.fragment}
      </ul>
    }}
  </div>
}
