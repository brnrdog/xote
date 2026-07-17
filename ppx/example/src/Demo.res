type status = Loading | Ready(string)

let name = Signal.make("Ada")
let active = Signal.make(false)
let status = Signal.make(Loading)
let theme = Signal.make("light")
module S = Signal

/* Every case is an @xote.component: one annotation derives props (it emits
   @jsx.component) and fine-grains the returned JSX into reactive leaves.
   @jsx.component allows only one component per module, so each lives in its
   own submodule (in real code, one per file). */

/* Case 1: attribute + text leaves become fine-grained, static parts untouched */
module Card = {
  @xote.component
  let make = () => {
    <div class={Signal.get(active) ? "on" : "off"} id="card">
      <span class="static-label"> {View.text("Name:")} </span>
      <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text>
    </div>
  }
}

/* Case 2: control flow in node position -> View.tracked (structural swap) */
module Panel = {
  @xote.component
  let make = () => {
    <div>
      {switch Signal.get(status) {
      | Loading => <span> {View.text("Loading...")} </span>
      | Ready(msg) => <strong> {View.text(msg)} </strong>
      }}
    </div>
  }
}

/* Case 2b: a branch whose leaf reads a *different* signal (theme) than the
   scrutinee (status). Branch decomposition keeps that leaf fine-grained, so
   the switch tracks only `status`: changing `theme` updates just the class and
   leaves the <strong> element in place (no branch rebuild). */
module SwitchLeaf = {
  @xote.component
  let make = () => {
    <div id="switch-leaf">
      {switch Signal.get(status) {
      | Loading => <span> {View.text("Loading...")} </span>
      | Ready(msg) =>
        <strong id="ready-strong" class={Signal.get(theme)}> {View.text(msg)} </strong>
      }}
    </div>
  }
}

/* Case 3: indirect read via a value alias — `let g = Signal.get` */
module Aliased = {
  @xote.component
  let make = () => {
    let g = Signal.get
    <div class={g(active) ? "on" : "off"} id="aliased">
      <View.Text> {`Hi, ${g(name)}`} </View.Text>
    </div>
  }
}

/* Case 4: indirect read via a module alias — `module S = Signal` (top level) */
module ModAliased = {
  @xote.component
  let make = () => {
    <div class={S.get(active) ? "on" : "off"} id="mod-aliased">
      <View.Text> {`Yo, ${S.get(name)}`} </View.Text>
    </div>
  }
}

/* Case 5: indirect read via `open Signal` then a bare `get` */
module OpenAliased = {
  @xote.component
  let make = () => {
    open Signal
    <div class={get(active) ? "on" : "off"} id="open-aliased">
      <View.Text> {`Hey, ${get(name)}`} </View.Text>
    </div>
  }
}

/* Case 6: pipe form — `active->Signal.get` (desugars to Signal.get(active)) */
module Piped = {
  @xote.component
  let make = () => {
    <div class={active->Signal.get ? "on" : "off"} id="piped">
      <View.Text> {`Pipe, ${name->Signal.get}`} </View.Text>
    </div>
  }
}

/* Case 7: a component with a prop — `label` (a prop) stays static while the
   signal reads become reactive leaves. */
module Labeled = {
  @xote.component
  let make = (~label: string) => {
    <div class={Signal.get(active) ? "on" : "off"} id="labeled">
      <View.Text> {`${label}: ${Signal.get(name)}`} </View.Text>
    </div>
  }
}
