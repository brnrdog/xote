/* Rows that start an effect nothing owns: removing a row leaves it running. */

let ticks = Signal.make(0, ~name="ticks")
let rows = Signal.make(["one"], ~name="rows")

module Row = {
  @xote.component
  let make = (~label: string) => {
    Signals.Effect.run(() => {
      let _ = Signal.get(ticks)
      None
    }, ~name="rowTicker")
    <li> {label} </li>
  }
}

@xote.component
let make = () =>
  <div>
    <button id="remove" onClick={_ => Signal.set(rows, [])}> {"Remove"} </button>
    <ul> {View.eachWithKey(rows, row => row, row => <Row label=row />)} </ul>
  </div>
