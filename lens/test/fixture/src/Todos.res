/* A keyed list, an input, and an effect that writes what it reads. */

type todo = {id: string, title: string}

let inputValue: Dom.event => string = %raw(`function (event) { return event.target.value }`)

let todos = Signal.make([{id: "a", title: "Write"}, {id: "b", title: "Test"}], ~name="todos")
let draft = Signal.make("", ~name="draft")
let count = Signal.make(0, ~name="todoCount")

/* Writes `count`, which it also reads: the get-in-effect finding. */
let _ = Effect.run(() => {
  let n = Array.length(Signal.get(todos))
  if Signal.get(count) != n {
    Signal.set(count, n)
  }
  None
}, ~name="syncCount")

let add = () => {
  let title = Signal.peek(draft)
  if title != "" {
    Signal.update(todos, list => Array.concat(list, [{id: title, title}]))
    Signal.set(draft, "")
  }
}

@xote.component
let make = () =>
  <section id="todos">
    <input id="draft" value={Signal.get(draft)} onInput={event => Signal.set(draft, inputValue(event))} />
    <button id="add" onClick={_ => add()}> {"Add"} </button>
    <button id="reverse" onClick={_ => Signal.update(todos, list => list->Array.toReversed)}> {"Reverse"} </button>
    <button id="clear" onClick={_ => Signal.set(todos, [])}> {"Clear"} </button>
    <ul>
      {View.eachWithKey(todos, todo => todo.id, todo => <li> {todo.title} </li>)}
    </ul>
  </section>
