type status = Loading | Ready(string)

let name = Signal.make("Ada")
let active = Signal.make(false)
let status = Signal.make(Loading)
let theme = Signal.make("light")

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

/* Case 2b: a branch whose leaf reads a *different* signal (theme) than the
   scrutinee (status). Branch decomposition keeps that leaf fine-grained, so
   the switch tracks only `status`: changing `theme` updates just the class and
   leaves the <strong> element in place (no branch rebuild). */
let switchLeaf = () => {
  @tracked
  <div id="switch-leaf">
    {switch Signal.get(status) {
    | Loading => <span> {View.text("Loading...")} </span>
    | Ready(msg) =>
      <strong id="ready-strong" class={Signal.get(theme)}> {View.text(msg)} </strong>
    }}
  </div>
}

/* Case 3: indirect read via a value alias — `let g = Signal.get` */
let aliased = () => {
  let g = Signal.get
  @tracked
  <div class={g(active) ? "on" : "off"} id="aliased">
    <View.Text> {`Hi, ${g(name)}`} </View.Text>
  </div>
}

/* Case 4: indirect read via a module alias — `module S = Signal` */
module S = Signal
let modAliased = () => {
  @tracked
  <div class={S.get(active) ? "on" : "off"} id="mod-aliased">
    <View.Text> {`Yo, ${S.get(name)}`} </View.Text>
  </div>
}

/* Case 5: indirect read via `open Signal` then a bare `get` */
let openAliased = () => {
  open Signal
  @tracked
  <div class={get(active) ? "on" : "off"} id="open-aliased">
    <View.Text> {`Hey, ${get(name)}`} </View.Text>
  </div>
}

/* Case 6: pipe form — `active->Signal.get` (desugars to Signal.get(active)) */
let piped = () => {
  @tracked
  <div class={active->Signal.get ? "on" : "off"} id="piped">
    <View.Text> {`Pipe, ${name->Signal.get}`} </View.Text>
  </div>
}
