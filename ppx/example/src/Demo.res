type status = Loading | Ready(string)

let name = Signal.make("Ada")
let active = Signal.make(false)
let status = Signal.make(Loading)

/* Case 1: attribute + text leaves become fine-grained, static parts untouched */
let card = () => {
  @tracked
  <div class={Signal.get(active) ? "on" : "off"} id="card">
    <span class="static-label"> {View.text("Name:")} </span>
    <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text>
  </div>
}

/* Case 2: control flow in node position -> View.tracked (structural swap) */
let panel = () => {
  @tracked
  <div>
    {switch Signal.get(status) {
    | Loading => <span> {View.text("Loading...")} </span>
    | Ready(msg) => <strong> {View.text(msg)} </strong>
    }}
  </div>
}
