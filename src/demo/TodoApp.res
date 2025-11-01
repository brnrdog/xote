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

// Effect to sync dark mode with HTML class
let _ = Effect.run(() => {
  let isDark = Signal.get(darkMode)
  if isDark {
    %raw(`document.documentElement.classList.add('dark')`)
  } else {
    %raw(`document.documentElement.classList.remove('dark')`)
  }
})

let todoItem = (todo: todo) => {
  let checkboxAttrs = todo.completed
    ? [
        ("type", "checkbox"),
        ("checked", "checked"),
        ("class", "h-4 w-4 cursor-pointer accent-neutral-600 dark:accent-neutral-500"),
      ]
    : [
        ("type", "checkbox"),
        ("class", "h-4 w-4 cursor-pointer accent-neutral-600 dark:accent-neutral-500"),
      ]

  let textCls =
    "flex-1 text-neutral-900 dark:text-neutral-100" ++ (
      todo.completed ? " line-through text-neutral-500 dark:text-neutral-400" : ""
    )

  Component.li(
    ~attrs=[
      (
        "class",
        "flex items-center gap-3 px-3 py-2 bg-white dark:bg-neutral-900 rounded-md border border-neutral-200 dark:border-neutral-800 mb-1.5 " ++ (
          todo.completed ? "opacity-80" : ""
        ),
      ),
    ],
    ~children=[
      Component.input(~attrs=checkboxAttrs, ~events=[("change", _ => toggleTodo(todo.id))], ()),
      Component.span(~attrs=[("class", textCls)], ~children=[Component.text(todo.text)], ()),
      Component.button(
        ~attrs=[
          (
            "class",
            "px-2 py-1 rounded-md text-neutral-600 hover:text-neutral-900 dark:text-neutral-400 dark:hover:text-neutral-100 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors",
          ),
        ],
        ~events=[("click", _ => removeTodo(todo.id))],
        ~children=[Component.Text("Delete")],
        (),
      ),
    ],
    (),
  )
}

let inputElement = Component.input(
  ~attrs=[
    ("type", "text"),
    ("placeholder", "What needs to be done?"),
    (
      "class",
      "todo-input flex-1 px-3.5 py-2 rounded-md border border-neutral-200 dark:border-neutral-800 bg-white dark:bg-neutral-900 text-neutral-900 dark:text-neutral-100 placeholder:text-neutral-400 focus:outline-none focus:ring-2 focus:ring-neutral-300 dark:focus:ring-neutral-700",
    ),
  ],
  ~events=[("input", handleInput), ("keydown", handleKeyDown)],
  (),
)

let app = Component.div(
  ~attrs=[
    (
      "class",
      "max-w-2xl mx-auto p-6 md:p-8 space-y-6 min-h-screen bg-stone-50 dark:bg-neutral-950",
    ),
  ],
  ~children=[
    Component.div(
      ~attrs=[
        (
          "class",
          "bg-white dark:bg-neutral-900 rounded-xl border border-neutral-200 dark:border-neutral-800 shadow-sm p-6 md:p-7",
        ),
      ],
      ~children=[
        Component.div(
          ~attrs=[("class", "flex items-center justify-between mb-5")],
          ~children=[
            Component.h1(
              ~attrs=[
                (
                  "class",
                  "text-2xl font-semibold tracking-tight text-neutral-900 dark:text-neutral-100",
                ),
              ],
              ~children=[Component.text("Todo List")],
              (),
            ),
            Component.button(
              ~attrs=[
                (
                  "class",
                  "inline-flex items-center gap-2 px-3 py-1.5 rounded-md border border-neutral-200 dark:border-neutral-800 bg-neutral-50 dark:bg-neutral-900 text-neutral-700 dark:text-neutral-300 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors",
                ),
              ],
              ~events=[("click", toggleTheme)],
              ~children=[
                Component.textSignal(
                  Computed.make(() => Signal.get(darkMode) ? "☀️ Light" : "🌙 Dark"),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        Component.div(
          ~attrs=[("class", "flex gap-2 mb-4")],
          ~children=[
            inputElement,
            Component.button(
              ~attrs=[
                (
                  "class",
                  "px-4 py-2 rounded-md border border-neutral-200 dark:border-neutral-800 bg-neutral-50 dark:bg-neutral-900 text-neutral-900 dark:text-neutral-100 hover:bg-neutral-100 dark:hover:bg-neutral-800 transition-colors",
                ),
              ],
              ~events=[("click", handleAddClick)],
              ~children=[Component.text("Add")],
              (),
            ),
          ],
          (),
        ),
        Component.ul(
          ~attrs=[("class", "todo-list space-y-1.5")],
          ~children=[Component.list(filteredTodos, todoItem)],
          (),
        ),
        Component.div(
          ~attrs=[("class", "flex gap-1 justify-center mt-6")],
          ~children=[
            Component.button(
              ~events=[("click", _ => Signal.set(filterState, "all"))],
              ~attrs=[
                (
                  "class",
                  "px-3 py-1.5 rounded-md border border-transparent hover:border-neutral-300 dark:hover:border-neutral-700 hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-700 dark:text-neutral-300 transition-colors",
                ),
              ],
              ~children=[
                Component.textSignal(
                  Computed.make(() => "All " ++ Int.toString(Signal.get(totalCount))),
                ),
              ],
              (),
            ),
            Component.button(
              ~events=[("click", _ => Signal.set(filterState, "active"))],
              ~attrs=[
                (
                  "class",
                  "px-3 py-1.5 rounded-md border border-transparent hover:border-neutral-300 dark:hover:border-neutral-700 hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-700 dark:text-neutral-300 transition-colors",
                ),
              ],
              ~children=[
                Component.textSignal(
                  Computed.make(() => "Active " ++ Int.toString(Signal.get(activeCount))),
                ),
              ],
              (),
            ),
            Component.button(
              ~events=[("click", _ => Signal.set(filterState, "completed"))],
              ~attrs=[
                (
                  "class",
                  "px-3 py-1.5 rounded-md border border-transparent hover:border-neutral-300 dark:hover:border-neutral-700 hover:bg-neutral-100 dark:hover:bg-neutral-800 text-neutral-700 dark:text-neutral-300 transition-colors",
                ),
              ],
              ~children=[
                Component.textSignal(
                  Computed.make(() => "Completed " ++ Int.toString(Signal.get(completedCount))),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    ),
    Component.div(
      ~attrs=[("class", "text-center text-xs text-neutral-600 dark:text-neutral-400")],
      ~children=[
        Component.text("Powered by "),
        Component.a(
          ~attrs=[
            ("href", "https://github.com/brnrdog/xote"),
            ("target", "_blank"),
            (
              "class",
              "underline decoration-neutral-300 hover:decoration-neutral-500 text-neutral-700 dark:text-neutral-300",
            ),
          ],
          ~children=[Component.text("xote")],
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
      ? [("type", "checkbox"), ("checked", "checked"), ("class", "w-5 h-5 cursor-pointer")]
      : [("type", "checkbox"), ("class", "w-5 h-5 cursor-pointer")]

    Component.li(
      ~attrs=[
        (
          "class",
          "flex items-center gap-3 p-3 bg-white dark:bg-stone-800 rounded-xl border-2 border-stone-200 dark:border-stone-700 mb-2 " ++ (
            todo.completed ? "completed" : ""
          ),
        ),
      ],
      ~children=[
        Component.input(~attrs=checkboxAttrs, ~events=[("change", _ => toggleTodo(todo.id))], ()),
        Component.span(
          ~attrs=[("class", "flex-1 text-stone-900 dark:text-stone-100")],
          ~children=[Component.text(todo.text)],
          (),
        ),
        Component.button(
          ~events=[("click", _ => removeTodo(todo.id))],
          ~attrs=[
            (
              "class",
              "cursor-pointer text-xs text-stone-400 dark:text-stone-700 font-semibold uppercase tracking-wide",
            ),
          ],
          ~children=[Component.Text("Delete")],
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
      ~attrs=[("class", "todo-list space-y-2")],
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
      ~attrs=[("class", "flex gap-2 mb-6")],
      ~children=[
        Component.input(
          ~attrs=[
            ("type", "text"),
            ("placeholder", "What needs to be done?"),
            (
              "class",
              "todo-input flex-1 px-4 py-2 border border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-800 text-stone-900 dark:text-stone-100 focus:outline-none focus:ring-2 focus:ring-stone-900/25 focus:ring-offset-2 focus:border-stone-900 border-2 placeholder:text-stone-400 dark:placeholder:text-stone-600",
            ),
          ],
          ~events=[("input", handleInput), ("keydown", handleKeyDown)],
          (),
        ),
        Component.button(
          ~attrs=[
            (
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
    let count = Computed.make(() =>
      switch filterValue {
      | "all" => "(" ++ Signal.get(totalCount)->Int.toString ++ ")"
      | "active" => "(" ++ Signal.get(activeCount)->Int.toString ++ ")"
      | "completed" => "(" ++ Signal.get(completedCount)->Int.toString ++ ")"
      | _ => ""
      }
    )

    Component.button(
      ~events=[("click", _ => Signal.set(filterState, filterValue))],
      ~signalAttrs=[
        Component.computedAttr("class", () => {
          "capitalize px-5 py-2 rounded-full text-xs transition-colors " ++ (
            Signal.get(filterState) == filterValue
              ? "bg-stone-900 text-white dark:bg-stone-700 font-semibold"
              : "bg-stone-200 text-stone dark:bg-stone-800 dark:text-white"
          )
        }),
      ],
      ~children=[Component.text(filterValue ++ " "), Component.textSignalComputed(count)],
      (),
    )
  }

  let render = filterState => {
    Component.div(
      ~attrs=[("class", "flex gap-2 items-center mb-4")],
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
      ~attrs=[("class", "max-w-2xl mx-auto p-6 space-y-4")],
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
          ~attrs=[("class", "text-xs text-stone-600 dark:text-stone-400")],
          ~children=[
            Component.text("Powered by "),
            Component.a(
              ~attrs=[
                ("href", "https://github.com/brnrdog/xote"),
                ("target", "_blank"),
                ("class", "font-semibold dark:text-white underline"),
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
