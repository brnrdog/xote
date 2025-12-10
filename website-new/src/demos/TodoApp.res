module Signal = Xote.Signal
module Component = Xote.Component

@get external target: Dom.event => Dom.element = "target"
@get external value: Dom.element => string = "value"
@send external preventDefault: Dom.event => unit = "preventDefault"

type todo = {
  id: int,
  text: string,
  completed: bool,
}

let todos = Signal.make([])
let nextId = ref(0)
let inputValue = Signal.make("")

let handleInput = (evt: Dom.event) => {
  Signal.set(inputValue, evt->target->value)
}

let addTodo = event => {
  preventDefault(event)
  let text = Signal.get(inputValue)->String.trim
  if text != "" {
    Signal.update(todos, list =>
      Array.concat(list, [{id: nextId.contents, text, completed: false}])
    )
    nextId := nextId.contents + 1
    Signal.set(inputValue, "")
  }
}

let toggleTodo = (id: int) => {
  todos->Signal.update(todos =>
    todos->Array.map(todo => todo.id == id ? {...todo, completed: !todo.completed} : todo)
  )
}

let removeTodo = (id: int) => {
  todos->Signal.update(todos => todos->Array.filter(todo => todo.id != id))
}

module TodoItem = {
  type props = {todo: todo}

  let make = ({todo}: props) => {
    <li class="todo-item">
      <input
        type_="checkbox"
        checked={todo.completed}
        class="todo-checkbox"
        onChange={_ => toggleTodo(todo.id)}
      />
      <span class="todo-text"> {Component.text(todo.text)} </span>
      <button class="todo-delete-button" onClick={_ => removeTodo(todo.id)}>
        {Component.text("Delete")}
      </button>
    </li>
  }
}

type props = {}

let make = (_: props) => {
  <div class="todo-app-container">
    <h1 class="todo-title"> {Component.text("Todo List")} </h1>

    <form class="todo-form" onSubmit={addTodo}>
      <input
        type_="text"
        class="todo-input"
        placeholder="What needs to be done?"
        onInput={handleInput}
        value={Signal.get(inputValue)}
      />
      <button class="todo-add-button" onClick={addTodo}> {Component.text("Add")} </button>
    </form>

    <ul class="todo-list"> {Component.list(todos, todo => <TodoItem todo={todo} />)} </ul>
  </div>
}
