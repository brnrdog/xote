module Signal = Xote.Signal
module Computed = Xote.Computed
module Component = Xote.Component

type todo = {
  id: int,
  text: string,
  completed: bool,
}

let todos = Signal.make([])
let nextId = ref(0)
let inputValue = Signal.make("")

// Computed values derived from todos
let completedCountComputed = Computed.make(() => {
  Signal.get(todos)->Array.filter(todo => todo.completed)->Array.length
})
let completedCount = completedCountComputed.signal

let activeCountComputed = Computed.make(() => {
  Signal.get(todos)->Array.filter(todo => !todo.completed)->Array.length
})
let activeCount = activeCountComputed.signal

let totalCountComputed = Computed.make(() => {
  Signal.get(todos)->Array.length
})
let totalCount = totalCountComputed.signal

let filterState = Signal.make("all")

let filteredTodosComputed = Computed.make(() => {
  switch Signal.get(filterState) {
  | "active" => Signal.get(todos)->Array.filter(todo => !todo.completed)
  | "completed" => Signal.get(todos)->Array.filter(todo => todo.completed)
  | _ => Signal.get(todos)
  }
})
let filteredTodos = filteredTodosComputed.signal

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
  switch querySelector(".todo-input")->Nullable.toOption {
  | Some(input) => setValue(input, "")
  | None => ()
  }
}

module TodoHeader = {
  type props = {}

  let make = (_props: props) => {
    <div class="flex items-center justify-between mb-4">
      <h1 class="text-2xl md:text-3xl font-bold text-stone-900 dark:text-white">
        {Component.text("Todo List")}
      </h1>
    </div>
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

module TodoItem = {
  type props = {todo: todo}

  let make = (props: props) => {
    let {todo} = props

    <li
      class={"flex items-center gap-3 p-3 bg-white dark:bg-stone-800 rounded-xl border-2 border-stone-200 dark:border-stone-700 mb-2 " ++ if (
        todo.completed
      ) {
        "completed"
      } else {
        ""
      }}>
      <input
        type_="checkbox"
        checked={todo.completed}
        class="w-5 h-5 cursor-pointer"
        onChange={_ => toggleTodo(todo.id)}
      />
      <span class="flex-1 text-stone-900 dark:text-stone-100"> {Component.text(todo.text)} </span>
      <button
        class="cursor-pointer text-xs text-stone-400 dark:text-stone-700 font-semibold uppercase tracking-wide"
        onClick={_ => removeTodo(todo.id)}>
        {Component.text("Delete")}
      </button>
    </li>
  }
}

module TodoList = {
  type props = {todos: Xote.Core.t<array<todo>>}

  let make = (props: props) => {
    <ul class="todo-list space-y-2">
      {Component.list(props.todos, todo => <TodoItem todo={todo} />)}
    </ul>
  }
}

let getInputValue = () => {
  switch querySelector(".todo-input")->Nullable.toOption {
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

module TodoForm = {
  type props = {}

  let make = (_props: props) => {
    <div class="flex flex-col sm:flex-row gap-2 mb-6">
      <input
        type_="text"
        placeholder="What needs to be done?"
        class="todo-input flex-1 px-4 py-2 border border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-800 text-stone-900 dark:text-stone-100 focus:outline-none focus:ring-2 focus:ring-stone-900/25 focus:ring-offset-2 focus:border-stone-900 border-2 placeholder:text-stone-400 dark:placeholder:text-stone-600"
        onInput={handleInput}
        onKeyDown={handleKeyDown}
      />
      <button
        class="px-6 py-2 bg-stone-900 dark:bg-stone-700 min-w-24 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors focus:outline-none focus:outline-none focus:ring-2 focus:ring-stone-900/25 focus:ring-offset-2 focus:border-stone-900"
        onClick={handleAddClick}>
        {Component.text("Add")}
      </button>
    </div>
  }
}

module FilterButton = {
  type props = {
    filterValue: string,
    onClick: Dom.event => unit,
  }

  let make = (props: props) => {
    let {filterValue, onClick} = props
    let isActiveComputed = Computed.make(() => Signal.get(filterState) == filterValue)
    let isActive = isActiveComputed.signal

    let classNameComputed = Computed.make(() => {
      "capitalize px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs transition-colors " ++ if (
        Signal.get(isActive)
      ) {
        "bg-stone-900 text-white dark:bg-stone-700 font-semibold"
      } else {
        "bg-stone-200 text-stone dark:bg-stone-800 dark:text-white"
      }
    })
    let className = classNameComputed.signal

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

module TodoFilter = {
  type props = {}

  let make = (_props: props) => {
    <div class="flex flex-wrap gap-2 items-center mb-4">
      <FilterButton filterValue="all" onClick={_ => Signal.set(filterState, "all")} />
      <FilterButton filterValue="active" onClick={_ => Signal.set(filterState, "active")} />
      <FilterButton filterValue="completed" onClick={_ => Signal.set(filterState, "completed")} />
    </div>
  }
}

let todoApp = () => {
  <div class="max-w-2xl mx-auto p-4 md:p-6 space-y-4">
    <div>
      <TodoHeader />
      <TodoForm />
      <TodoFilter />
      <TodoList todos={filteredTodos} />
    </div>
  </div>
}
