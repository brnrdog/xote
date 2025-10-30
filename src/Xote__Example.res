open Xote

type todo = {
  id: int,
  text: string,
  completed: bool,
}

let todos = Signal.make([])
let nextId = ref(0)
let inputValue = Signal.make("")

let addTodo = (text: string) => {
  if String.trim(text) != "" {
    Signal.update(todos, list => {
      Array.concat(list, [{id: nextId.contents, text, completed: false}])
    })
    nextId := nextId.contents + 1
  }
}

let toggleTodo = (id: int) => {
  Signal.update(todos, list =>
    Array.map(list, todo => todo.id == id ? {...todo, completed: !todo.completed} : todo)
  )
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

let handleKeyDown = (evt: Dom.event) => {
  if evt->key == "Enter" {
    addTodo(Signal.get(inputValue))
    clearInput()
  }
}

let handleAddClick = (_evt: Dom.event) => {
  addTodo(Signal.get(inputValue))
  clearInput()
}

let todoItem = (todo: todo) => {
  let checkboxAttrs = todo.completed
    ? [("type", "checkbox"), ("checked", "checked")]
    : [("type", "checkbox")]

  Component.li(
    ~attrs=[("class", todo.completed ? "completed" : "")],
    ~children=[
      Component.input(
        ~attrs=checkboxAttrs,
        ~events=[("change", _ => toggleTodo(todo.id))],
        (),
      ),
      Component.span(~children=[Component.text(todo.text)], ()),
    ],
    (),
  )
}

let inputElement = Component.input(
  ~attrs=[
    ("type", "text"),
    ("placeholder", "What needs to be done?"),
    ("class", "todo-input"),
  ],
  ~events=[("input", handleInput), ("keydown", handleKeyDown)],
  (),
)

let app = Component.div(
  ~attrs=[("class", "todo-app")],
  ~children=[
    Component.h1(~children=[Component.text("Todo List")], ()),
    Component.div(
      ~attrs=[("class", "todo-input-container")],
      ~children=[
        inputElement,
        Component.button(
          ~attrs=[("class", "add-button")],
          ~events=[("click", handleAddClick)],
          ~children=[Component.text("Add")],
          (),
        ),
      ],
      (),
    ),
    Component.ul(
      ~attrs=[("class", "todo-list")],
      ~children=[Component.list(todos, todoItem)],
      (),
    ),
  ],
  (),
)

Component.mountById(app, "app")
