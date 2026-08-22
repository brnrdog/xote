/*
 * Xote benchmark application.
 *
 * Idiomatic fine-grained Xote: the list itself is a signal, and each row owns
 * a signal for its label so a label change writes one text node instead of
 * re-rendering the row.
 */

type rawRow = {id: int, label: string}

@module("../../shared/data.js")
external buildRawData: int => array<rawRow> = "buildData"

type row = {id: int, label: Signal.t<string>}

let makeRows = (count: int): array<row> =>
  buildRawData(count)->Array.map(raw => {id: raw.id, label: Signal.make(raw.label)})

let rows: Signal.t<array<row>> = Signal.make([])
let selected: Signal.t<int> = Signal.make(0)

let setRows = (next: array<row>) => Signal.set(rows, next)

let run = () => setRows(makeRows(1000))
let runLots = () => setRows(makeRows(10000))
let add = () => setRows(Array.concat(Signal.peek(rows), makeRows(1000)))
let clear = () => setRows([])

let update = () => {
  let current = Signal.peek(rows)
  let length = Array.length(current)

  Signal.batch(() => {
    let index = ref(0)
    while index.contents < length {
      switch current[index.contents] {
      | Some(row) => Signal.update(row.label, label => label ++ " !!!")
      | None => ()
      }
      index := index.contents + 10
    }
  })
}

let swapRows = () => {
  let current = Signal.peek(rows)

  if Array.length(current) > 998 {
    let next = Array.copy(current)
    let first = next->Array.getUnsafe(1)
    let second = next->Array.getUnsafe(998)
    next->Array.set(1, second)
    next->Array.set(998, first)
    setRows(next)
  }
}

let remove = (id: int) => setRows(Signal.peek(rows)->Array.filter(row => row.id != id))

let renderRow = (row: row) =>
  <tr class={() => Signal.get(selected) == row.id ? "danger" : ""}>
    <td class="col-md-1"> {View.int(row.id)} </td>
    <td class="col-md-4">
      <a class="lbl" onClick={_ => Signal.set(selected, row.id)}>
        {View.signalText(() => Signal.get(row.label))}
      </a>
    </td>
    <td class="col-md-1">
      <a class="remove" onClick={_ => remove(row.id)}>
        <span class="glyphicon glyphicon-remove" ariaHidden="true" />
      </a>
    </td>
    <td class="col-md-6" />
  </tr>

let app = () =>
  <div class="container">
    <div class="jumbotron">
      <h1> {View.text("Xote")} </h1>
      <div class="actions">
        <button id="run" onClick={_ => run()}> {View.text("Create 1,000 rows")} </button>
        <button id="runlots" onClick={_ => runLots()}> {View.text("Create 10,000 rows")} </button>
        <button id="add" onClick={_ => add()}> {View.text("Append 1,000 rows")} </button>
        <button id="update" onClick={_ => update()}> {View.text("Update every 10th row")} </button>
        <button id="clear" onClick={_ => clear()}> {View.text("Clear")} </button>
        <button id="swaprows" onClick={_ => swapRows()}> {View.text("Swap Rows")} </button>
      </div>
    </div>
    <table id="main-table">
      <tbody id="tbody"> {View.eachWithKey(rows, row => Int.toString(row.id), renderRow)} </tbody>
    </table>
  </div>

View.mountById(app(), "root")
