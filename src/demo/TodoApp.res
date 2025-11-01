open Xote

type todo = {
  id: int,
  text: string,
  completed: bool,
}

let todos = Signal.make([])
let nextId = ref(0)
let inputValue = Signal.make("")
let darkMode = Signal.make(false)

// Computed values derived from todos
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
  switch querySelector(".todo-input")->Nullable.toOption {
  | Some(input) => setValue(input, "")
  | None => ()
  }
}

let toggleTheme = (_evt: Dom.event) => {
  Signal.update(darkMode, mode => !mode)
}

module TodoHeader = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "flex items-center justify-between mb-4")],
      ~children=[
        Component.h1(
          ~attrs=[Component.attr("class", "text-3xl font-bold text-stone-900 dark:text-white")],
          ~children=[Component.text("Todo List")],
          (),
        ),
        Component.button(
          ~attrs=[
            Component.attr(
              "class",
              "px-4 py-2 rounded-xl bg-stone-200 dark:bg-stone-700 text-stone-800 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-600 transition-colors",
            ),
          ],
          ~events=[("click", toggleTheme)],
          ~children=[
            Component.textSignal(() => Signal.get(darkMode) ? "☀️ Light" : "🌙 Dark"),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module TodoItem = {
  let toggleTodo = (id: int) => {
    todos->Signal.update(todos => {
      let markAsComplete = todo => todo.id == id ? {...todo, completed: !todo.completed} : todo
      todos->Array.map(markAsComplete)
    })
  }

  let removeTodo = (id: int) => {
    todos->Signal.update(todos => todos->Array.filter(todo => todo.id != id))
  }

  let component = (todo: todo) => {
    let checkboxAttrs = todo.completed
      ? [
          Component.attr("type", "checkbox"),
          Component.attr("checked", "checked"),
          Component.attr("class", "w-5 h-5 cursor-pointer"),
        ]
      : [Component.attr("type", "checkbox"), Component.attr("class", "w-5 h-5 cursor-pointer")]

    Component.li(
      ~attrs=[
        Component.attr(
          "class",
          "flex items-center gap-3 p-3 bg-white dark:bg-stone-800 rounded-xl border-2 border-stone-200 dark:border-stone-700 mb-2 " ++ (
            todo.completed ? "completed" : ""
          ),
        ),
      ],
      ~children=[
        Component.input(~attrs=checkboxAttrs, ~events=[("change", _ => toggleTodo(todo.id))], ()),
        Component.span(
          ~attrs=[Component.attr("class", "flex-1 text-stone-900 dark:text-stone-100")],
          ~children=[Component.text(todo.text)],
          (),
        ),
        Component.button(
          ~events=[("click", _ => removeTodo(todo.id))],
          ~attrs=[
            Component.attr(
              "class",
              "cursor-pointer text-xs text-stone-400 dark:text-stone-700 font-semibold uppercase tracking-wide",
            ),
          ],
          ~children=[Component.text("Delete")],
          (),
        ),
      ],
      (),
    )
  }
}

module TodoList = {
  let component = (todos: Core.t<array<todo>>) => {
    Component.ul(
      ~attrs=[Component.attr("class", "todo-list space-y-2")],
      ~children=[Component.list(todos, TodoItem.component)],
      (),
    )
  }
}

module TodoForm = {
  let getInputValue = () => {
    // Needs to be fixed
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

  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "flex gap-2 mb-6")],
      ~children=[
        Component.input(
          ~attrs=[
            Component.attr("type", "text"),
            Component.attr("placeholder", "What needs to be done?"),
            Component.attr(
              "class",
              "todo-input flex-1 px-4 py-2 border border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-800 text-stone-900 dark:text-stone-100 focus:outline-none focus:ring-2 focus:ring-stone-900/25 focus:ring-offset-2 focus:border-stone-900 border-2 placeholder:text-stone-400 dark:placeholder:text-stone-600",
            ),
          ],
          ~events=[("input", handleInput), ("keydown", handleKeyDown)],
          (),
        ),
        Component.button(
          ~attrs=[
            Component.attr(
              "class",
              "px-6 py-2 bg-stone-900 min-w-24 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500",
            ),
          ],
          ~events=[("click", handleAddClick)],
          ~children=[Component.text("Add")],
          (),
        ),
      ],
      (),
    )
  }
}

module TodoFilter = {
  let renderFilterButton = (filterState, filterValue) => {
    Component.button(
      ~events=[("click", _ => Signal.set(filterState, filterValue))],
      ~attrs=[
        Component.computedAttr("class", () => {
          "capitalize px-5 py-2 rounded-full text-xs transition-colors " ++ (
            Signal.get(filterState) == filterValue
              ? "bg-stone-900 text-white dark:bg-stone-700 font-semibold"
              : "bg-stone-200 text-stone dark:bg-stone-800 dark:text-white"
          )
        }),
      ],
      ~children=[
        Component.text(filterValue),
        Component.text(" "),
        Component.textSignal(() =>
          switch filterValue {
          | "all" => "(" ++ Signal.get(totalCount)->Int.toString ++ ")"
          | "active" => "(" ++ Signal.get(activeCount)->Int.toString ++ ")"
          | "completed" => "(" ++ Signal.get(completedCount)->Int.toString ++ ")"
          | _ => ""
          }
        ),
      ],
      (),
    )
  }

  let render = filterState => {
    Component.div(
      ~attrs=[Component.attr("class", "flex gap-2 items-center mb-4")],
      ~children=[
        renderFilterButton(filterState, "all"),
        renderFilterButton(filterState, "active"),
        renderFilterButton(filterState, "completed"),
      ],
      (),
    )
  }
}

module TodoApp = {
  let component = () => {
    // Effect to sync dark mode with HTML class
    let _ = Effect.run(() =>
      switch Signal.get(darkMode) {
      | true => %raw(`document.documentElement.classList.add('dark')`)
      | false => %raw(`document.documentElement.classList.remove('dark')`)
      }
    )

    Component.div(
      ~attrs=[Component.attr("class", "max-w-2xl mx-auto p-6 space-y-4")],
      ~children=[
        Component.div(
          ~children=[
            TodoHeader.component(),
            TodoForm.component(),
            TodoFilter.render(filterState),
            TodoList.component(filteredTodos),
          ],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "text-xs text-stone-600 dark:text-stone-400")],
          ~children=[
            Component.text("Powered by "),
            Component.a(
              ~attrs=[
                Component.attr("href", "https://github.com/brnrdog/xote"),
                Component.attr("target", "_blank"),
                Component.attr("class", "font-semibold dark:text-white underline"),
              ],
              ~children=[Component.text("Xote")],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

Component.mountById(TodoApp.component(), "app")
