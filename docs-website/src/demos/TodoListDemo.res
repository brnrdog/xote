type todo = {
  id: int,
  text: string,
  done: Signal.t<bool>,
}

let makeTodo = (id, text, done) => {id, text, done: Signal.make(done)}

let todos = Signal.make([
  makeTodo(1, "Learn ReScript", true),
  makeTodo(2, "Learn signals", false),
  makeTodo(3, "Write my first Xote component", false),
])

let draft = Signal.make("")
let nextId = ref(4)

@get external target: Dom.event => {..} = "target"

let remaining = Computed.make(() =>
  Signal.get(todos)->Array.filter(todo => !Signal.get(todo.done))->Array.length
)

let addTodo = () => {
  let text = Signal.peek(draft)->String.trim
  if text != "" {
    Signal.update(todos, list => Array.concat(list, [makeTodo(nextId.contents, text, false)]))
    nextId := nextId.contents + 1
    Signal.set(draft, "")
  }
}

let removeTodo = id => Signal.update(todos, list => list->Array.filter(todo => todo.id != id))

module TodoComposer = {
  @xote.component
  let make = () =>
    <div class="todo-demo-form">
      <input
        class="todo-demo-input demo-input"
        placeholder="Add a task"
        value={Signal.get(draft)}
        onInput={event => Signal.set(draft, target(event)["value"])}
      />
      <button class="demo-btn demo-btn-primary" onClick={_ => addTodo()}> {"Add"} </button>
    </div>
}

module TodoRow = {
  @xote.component
  let make = (~todo: todo) =>
    <li class={Signal.get(todo.done) ? "todo-demo-item todo-demo-item-completed" : "todo-demo-item"}>
      <input
        type_="checkbox"
        class="todo-demo-checkbox"
        checked={Signal.get(todo.done)}
        onChange={_ => Signal.update(todo.done, done => !done)}
      />
      <span class="todo-demo-item-text"> {todo.text} </span>
      <button class="todo-demo-delete-btn" onClick={_ => removeTodo(todo.id)}> {"Remove"} </button>
    </li>
}

@xote.component
let make = () =>
  <div class="todo-list-demo">
    <div class="todo-list-demo-section">
      <TodoComposer />
    </div>
    <div class="todo-list-demo-section">
      <div class="todo-demo-summary"> {Signal.get(remaining)} {" left"} </div>
    </div>
    <div class="todo-list-demo-section">
      <ul class="todo-demo-list">
        <View.For
          each={MaybeSignal.reactive(todos)}
          by={todo => Int.toString(todo.id)}
          render={todo => <TodoRow todo />}
        />
      </ul>
    </div>
  </div>
