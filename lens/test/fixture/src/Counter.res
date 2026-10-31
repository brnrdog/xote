/* The counter the lens tests drive: one signal, a derived label, a button. */

let count = Signal.make(0, ~name="count")
let doubled = Computed.make(() => Signal.get(count) * 2, ~name="doubled")

module Label = {
  @xote.component
  let make = (~text: string) => <span id="label"> {text} </span>
}

@xote.component
let make = () =>
  <div id="counter">
    <p id="value"> {Signal.get(count)} </p>
    <p id="doubled"> {Signal.get(doubled)} </p>
    <button id="inc" onClick={_ => Signal.update(count, n => n + 1)}> {"+1"} </button>
    <Label text={Int.toString(Signal.get(count))} />
  </div>
