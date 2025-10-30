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

let addTodo = (text: string) => {
  if String.trim(text) != "" {
    Signal.update(todos, list => {
      Array.concat(list, [{id: nextId.contents, text, completed: false}])
    })
    nextId := nextId.contents + 1
    Signal.set(inputValue, "")
  }
}

let toggleTodo = (id: int) => {
  Signal.update(todos, list => {
    Array.map(list, todo => todo.id == id ? {...todo, completed: !todo.completed} : todo)
  })
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

let handleInput = (evt: Dom.event) => {
  let newValue = evt->target->value
  Signal.set(inputValue, newValue)
}

let getInputValue = () => {
  switch querySelector(".todo-input")->Nullable.toOption {
  | Some(input) => input->value
  | None => ""
  }
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
    ? [("type", "checkbox"), ("checked", "checked"), ("class", "w-5 h-5 cursor-pointer")]
    : [("type", "checkbox"), ("class", "w-5 h-5 cursor-pointer")]

  Component.li(
    ~attrs=[
      (
        "class",
        "flex items-center gap-3 p-3 bg-white dark:bg-gray-800 rounded-lg border border-gray-200 dark:border-gray-700 mb-2 " ++
        (todo.completed ? "completed" : ""),
      ),
    ],
    ~children=[
      Component.input(~attrs=checkboxAttrs, ~events=[("change", _ => toggleTodo(todo.id))], ()),
      Component.span(
        ~attrs=[("class", "flex-1 text-gray-900 dark:text-gray-100")],
        ~children=[Component.text(todo.text)],
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
    ("class", "todo-input flex-1 px-4 py-2 border border-gray-300 dark:border-gray-600 rounded-lg bg-white dark:bg-gray-800 text-gray-900 dark:text-gray-100 focus:outline-none focus:ring-2 focus:ring-blue-500"),
  ],
  ~events=[("input", handleInput), ("keydown", handleKeyDown)],
  (),
)

let app = Component.div(
  ~attrs=[("class", "max-w-2xl mx-auto p-6 space-y-6")],
  ~children=[
    Component.div(
      ~attrs=[("class", "bg-white dark:bg-gray-800 rounded-xl shadow-lg p-8")],
      ~children=[
        Component.div(
          ~attrs=[("class", "flex items-center justify-between mb-6")],
          ~children=[
            Component.h1(
              ~attrs=[("class", "text-3xl font-bold text-gray-900 dark:text-white")],
              ~children=[Component.text("Todo List")],
              (),
            ),
            Component.button(
              ~attrs=[
                (
                  "class",
                  "px-4 py-2 rounded-lg bg-gray-200 dark:bg-gray-700 text-gray-800 dark:text-gray-200 hover:bg-gray-300 dark:hover:bg-gray-600 transition-colors",
                ),
              ],
              ~events=[("click", toggleTheme)],
              ~children=[
                Component.textSignal(
                  Computed.make(() => Signal.get(darkMode) ? "☀️ Light" : "🌙 Dark")
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        Component.div(
          ~attrs=[
            (
              "class",
              "grid grid-cols-3 gap-4 mb-6 p-4 bg-gray-50 dark:bg-gray-900 rounded-lg border border-gray-200 dark:border-gray-700",
            ),
          ],
          ~children=[
            Component.div(
              ~attrs=[("class", "flex flex-col items-center")],
              ~children=[
                Component.span(
                  ~attrs=[
                    ("class", "text-xs text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-1"),
                  ],
                  ~children=[Component.text("Total")],
                  (),
                ),
                Component.span(
                  ~attrs=[("class", "text-2xl font-bold text-gray-900 dark:text-white")],
                  ~children=[
                    Component.textSignal(Computed.make(() => Int.toString(Signal.get(totalCount)))),
                  ],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[("class", "flex flex-col items-center")],
              ~children=[
                Component.span(
                  ~attrs=[
                    ("class", "text-xs text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-1"),
                  ],
                  ~children=[Component.text("Active")],
                  (),
                ),
                Component.span(
                  ~attrs=[("class", "text-2xl font-bold text-blue-600 dark:text-blue-400")],
                  ~children=[
                    Component.textSignal(
                      Computed.make(() => Int.toString(Signal.get(activeCount)))
                    ),
                  ],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[("class", "flex flex-col items-center")],
              ~children=[
                Component.span(
                  ~attrs=[
                    ("class", "text-xs text-gray-600 dark:text-gray-400 uppercase tracking-wide mb-1"),
                  ],
                  ~children=[Component.text("Completed")],
                  (),
                ),
                Component.span(
                  ~attrs=[("class", "text-2xl font-bold text-green-600 dark:text-green-400")],
                  ~children=[
                    Component.textSignal(
                      Computed.make(() => Int.toString(Signal.get(completedCount)))
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
          ~attrs=[("class", "flex gap-2 mb-6")],
          ~children=[
            inputElement,
            Component.button(
              ~attrs=[
                (
                  "class",
                  "px-6 py-2 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500",
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
          ~attrs=[("class", "todo-list space-y-2")],
          ~children=[Component.list(todos, todoItem)],
          (),
        ),
      ],
      (),
    ),
  ],
  (),
)

Component.mountById(app, "app")
