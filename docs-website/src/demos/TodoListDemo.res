type todo = {
  id: string,
  text: string,
  done: bool,
}

let todos = Signal.make([
  {id: "1", text: "Learn ReScript", done: true},
  {id: "2", text: "Learn signals", done: false},
  {id: "3", text: "Write my first Xote component", done: false},
])

let draft = Signal.make("")
let nextId = ref(4)

@get external target: Dom.event => Dom.element = "target"
@get external value: Dom.element => string = "value"

let remainingCount = Computed.make(() =>
  Signal.get(todos)->Array.filter(todo => !todo.done)->Array.length
)

let totalCount = Computed.make(() => Signal.get(todos)->Array.length)

let handleInput = (evt: Dom.event) => {
  Signal.set(draft, evt->target->value)
}

let addTodo = (_evt: Dom.event) => {
  let text = Signal.peek(draft)->String.trim

  if text != "" {
    Signal.update(todos, current =>
      Array.concat(current, [{id: nextId.contents->Int.toString, text, done: false}])
    )
    nextId := nextId.contents + 1
    Signal.set(draft, "")
  }
}

let toggleTodo = id => {
  Signal.update(todos, current =>
    current->Array.map(todo =>
      if todo.id == id {
        {...todo, done: !todo.done}
      } else {
        todo
      }
    )
  )
}

let removeTodo = id => {
  Signal.update(todos, current => current->Array.filter(todo => todo.id != id))
}

module TodoComposer = {
  @jsx.component
  let make = () => {
    <div class="todo-demo-form">
      <input
        type_="text"
        placeholder="Add a task"
        class="todo-demo-input demo-input"
        value={() => Signal.get(draft)}
        onInput={handleInput}
      />
      <button class="demo-btn demo-btn-primary" onClick={addTodo}>
        {View.text("Add")}
      </button>
    </div>
  }
}

module TodoSummary = {
  @jsx.component
  let make = () => {
    <div class="todo-list-demo-toolbar">
      <div class="todo-demo-summary">
        {View.signalText(() => {
          let remaining = Signal.get(remainingCount)
          if remaining == 1 {
            "1 task left"
          } else {
            Int.toString(remaining) ++ " tasks left"
          }
        })}
      </div>
      <div class="todo-list-demo-count">
        <View.Int value={Prop.signal(totalCount)} />
        {View.text(" total")}
      </div>
    </div>
  }
}

module TodoRow = {
  @jsx.component
  let make = (~todo: todo) => {
    let itemClass =
      "todo-demo-item" ++
      if todo.done {
        " todo-demo-item-completed"
      } else {
        ""
      }

    <li class={itemClass}>
      <input
        type_="checkbox"
        checked={todo.done}
        class="todo-demo-checkbox"
        onChange={_ => toggleTodo(todo.id)}
      />
      <span class="todo-demo-item-text"> {View.text(todo.text)} </span>
      <button class="todo-demo-delete-btn" onClick={_ => removeTodo(todo.id)}>
        {View.text("Remove")}
      </button>
    </li>
  }
}

module TodoList = {
  @jsx.component
  let make = () => {
    <ul class="todo-demo-list">
      <View.For
        each={Prop.signal(todos)}
        by={todo => todo.id}
        render={todo => <TodoRow todo />}
      />
    </ul>
  }
}

@jsx.component
let make = () => {
  <div class="todo-list-demo">
    <div class="todo-list-demo-hero">
      <div class="counter-demo-kicker"> {View.text("View composition")} </div>
      <h3 class="todo-list-demo-title"> {View.text("Todo list")} </h3>
      <p class="todo-list-demo-copy">
        {View.text("One signal drives a small set of focused components.")}
      </p>
    </div>

    <div class="todo-list-demo-section">
      <TodoComposer />
    </div>

    <div class="todo-list-demo-section">
      <TodoSummary />
    </div>

    <div class="todo-list-demo-section">
      <TodoList />
    </div>
  </div>
}
