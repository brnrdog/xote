open Xote

type todo = {
  id: int,
  text: string,
  completed: bool,
}

let todos = Signal.make([])
let nextId = ref(0)
let inputValue = Signal.make("")

let completedCount = Computed.make(() => {
  Signal.get(todos)->Array.filter(todo => todo.completed)->Array.length
})

let activeCount = Computed.make(() => {
  Signal.get(todos)->Array.filter(todo => !todo.completed)->Array.length
})

let totalCount = Computed.make(() => {
  Signal.get(todos)->Array.length
})

let filterState = Signal.make("all")

let filteredTodos = Computed.make(() => {
  switch Signal.get(filterState) {
  | "active" => Signal.get(todos)->Array.filter(todo => !todo.completed)
  | "completed" => Signal.get(todos)->Array.filter(todo => todo.completed)
  | _ => Signal.get(todos)
  }
})

let addTodo = (text: string) => {
  if String.trim(text) != "" {
    Signal.update(todos, list => {
      Array.concat(list, [{id: nextId.contents, text, completed: false}])
    })
    nextId := nextId.contents + 1
    Signal.set(inputValue, "")
  }
}

@val @scope("document") external querySelector: string => Nullable.t<Dom.element> = "querySelector"
@get external target: Dom.event => Dom.element = "target"
@get external value: Dom.element => string = "value"
@set external setValue: (Dom.element, string) => unit = "value"
@get external key: Dom.event => string = "key"

let clearInput = () => {
  switch querySelector(".todo-demo-input")->Nullable.toOption {
  | Some(input) => setValue(input, "")
  | None => ()
  }
}

let toggleTodo = (id: int) => {
  todos->Signal.update(todos => {
    let markAsComplete = todo => todo.id == id ? {...todo, completed: !todo.completed} : todo
    todos->Array.map(markAsComplete)
  })
}

let removeTodo = (id: int) => {
  todos->Signal.update(todos => todos->Array.filter(todo => todo.id != id))
}

let getInputValue = () => {
  switch querySelector(".todo-demo-input")->Nullable.toOption {
  | Some(input) => input->value
  | None => ""
  }
}

let handleInput = (evt: Dom.event) => {
  let newValue = evt->target->value
  Signal.set(inputValue, newValue)
}

let handleKeyDown = (evt: Dom.event) => {
  if evt->key == "Enter" {
    addTodo(getInputValue())
    clearInput()
  }
}

let handleAddClick = (_evt: Dom.event) => {
  addTodo(getInputValue())
  clearInput()
}

module TodoItem = {
  type props = {todo: todo}

  let make = (props: props) => {
    let {todo} = props

    let itemClass =
      "todo-demo-item" ++
      if todo.completed {
        " todo-demo-item-completed"
      } else {
        ""
      }

    <li class={itemClass}>
      <input
        type_="checkbox"
        checked={todo.completed}
        class="todo-demo-checkbox"
        onChange={_ => toggleTodo(todo.id)}
      />
      <span class="todo-demo-item-text"> {Component.text(todo.text)} </span>
      <button class="todo-demo-delete-btn" onClick={_ => removeTodo(todo.id)}>
        {Component.text("Delete")}
      </button>
    </li>
  }
}

module FilterButton = {
  type props = {
    filterValue: string,
    onClick: Dom.event => unit,
  }

  let make = (props: props) => {
    let {filterValue, onClick} = props
    let isActive = Computed.make(() => Signal.get(filterState) == filterValue)

    let className = Computed.make(() => {
      "todo-demo-filter-btn" ++
      if Signal.get(isActive) {
        " todo-demo-filter-btn-active"
      } else {
        ""
      }
    })

    <button class={className} onClick={onClick}>
      {Component.text(filterValue)}
      {Component.text(" ")}
      {Component.textSignal(() =>
        switch filterValue {
        | "all" => "(" ++ Signal.get(totalCount)->Int.toString ++ ")"
        | "active" => "(" ++ Signal.get(activeCount)->Int.toString ++ ")"
        | "completed" => "(" ++ Signal.get(completedCount)->Int.toString ++ ")"
        | _ => ""
        }
      )}
    </button>
  }
}

let content = () => {
  <div class="demo-container">
    <div class="demo-section">
      <div class="todo-demo-form">
        <input
          type_="text"
          placeholder="What needs to be done?"
          class="todo-demo-input demo-input"
          onInput={handleInput}
          onKeyDown={handleKeyDown}
        />
        <button class="demo-btn demo-btn-primary" onClick={handleAddClick}>
          {Component.text("Add")}
        </button>
      </div>
    </div>
    <div class="demo-section">
      <div class="todo-demo-filters">
        <FilterButton filterValue="all" onClick={_ => Signal.set(filterState, "all")} />
        <FilterButton filterValue="active" onClick={_ => Signal.set(filterState, "active")} />
        <FilterButton
          filterValue="completed" onClick={_ => Signal.set(filterState, "completed")}
        />
      </div>
    </div>
    <div class="demo-section">
      <ul class="todo-demo-list">
        {Component.keyedList(
          filteredTodos,
          todo => todo.id->Int.toString,
          todo => <TodoItem todo={todo} />,
        )}
      </ul>
    </div>
  </div>
}
