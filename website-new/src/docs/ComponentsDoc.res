open Xote

let content = () => {
  <div>
    <h1> {Component.text("Components Overview")} </h1>
    <p>
      {Component.text(
        "Xote provides a lightweight component system for building reactive UIs. Components are functions that return virtual nodes, which are then rendered to the DOM.",
      )}
    </p>
    <p> {Component.text("Xote supports two syntax styles for building components:")} </p>
    <ul>
      <li>
        <strong> {Component.text("JSX Syntax:")} </strong>
        {Component.text(" Modern, declarative JSX syntax (recommended)")}
      </li>
      <li>
        <strong> {Component.text("Function API:")} </strong>
        {Component.text(" Explicit function calls with labeled parameters")}
      </li>
    </ul>
    <h2> {Component.text("What are Components?")} </h2>
    <p>
      {Component.text("In Xote, a component is simply a function that returns a ")}
      <code> {Component.text("Component.node")} </code>
      {Component.text(":")}
    </p>
    <h3> {Component.text("JSX Syntax")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

let greeting = () => {
  <div>
    <h1> {Component.text("Hello, Xote!")} </h1>
  </div>
}`)}
      </code>
    </pre>
    <h3> {Component.text("Function API")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

let greeting = () => {
  Component.div(
    ~children=[
      Component.h1(~children=[Component.text("Hello, Xote!")], ())
    ],
    ()
  )
}`)}
      </code>
    </pre>
    <h2> {Component.text("JSX Configuration")} </h2>
    <p>
      {Component.text("To use JSX syntax, configure your ")}
      <code> {Component.text("rescript.json")} </code>
      {Component.text(":")}
    </p>
    <pre>
      <code>
        {Component.text(`{
  "jsx": {
    "version": 4,
    "module": "Xote__JSX"
  }
}`)}
      </code>
    </pre>
    <h2> {Component.text("Text Nodes")} </h2>
    <h3> {Component.text("Static Text")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Component.text()")} </code>
      {Component.text(" for static text:")}
    </p>
    <pre>
      <code>
        {Component.text(`<div>
  {Component.text("This text never changes")}
</div>`)}
      </code>
    </pre>
    <h3> {Component.text("Reactive Text")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Component.textSignal()")} </code>
      {Component.text(" for text that updates with signals:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)

<div>
  {Component.textSignal(() =>
    "Count: " ++ Int.toString(Signal.get(count))
  )}
</div>`)}
      </code>
    </pre>
    <p>
      {Component.text("The function is tracked, so the text automatically updates when ")}
      <code> {Component.text("count")} </code>
      {Component.text(" changes.")}
    </p>
    <h2> {Component.text("Attributes")} </h2>
    <h3> {Component.text("JSX Props")} </h3>
    <p> {Component.text("JSX elements support common HTML attributes:")} </p>
    <ul>
      <li>
        <code> {Component.text("class")} </code>
        {Component.text(" - CSS classes (note: ")}
        <code> {Component.text("class")} </code>
        {Component.text(", not ")}
        <code> {Component.text("className")} </code>
        {Component.text(")")}
      </li>
      <li>
        <code> {Component.text("id")} </code>
        {Component.text(" - Element ID")}
      </li>
      <li>
        <code> {Component.text("style")} </code>
        {Component.text(" - Inline styles")}
      </li>
      <li>
        <code> {Component.text("type_")} </code>
        {Component.text(" - Input type (with underscore to avoid keyword conflict)")}
      </li>
      <li>
        <code> {Component.text("value")} </code>
        {Component.text(" - Input value")}
      </li>
      <li>
        <code> {Component.text("placeholder")} </code>
        {Component.text(" - Input placeholder")}
      </li>
      <li>
        <code> {Component.text("disabled")} </code>
        {Component.text(" - Boolean disabled state")}
      </li>
      <li>
        <code> {Component.text("checked")} </code>
        {Component.text(" - Boolean checked state")}
      </li>
    </ul>
    <pre>
      <code>
        {Component.text(`<button
  class="btn btn-primary"
  type_="button"
  disabled={true}>
  {Component.text("Submit")}
</button>`)}
      </code>
    </pre>
    <h3> {Component.text("Static Attributes (Function API)")} </h3>
    <pre>
      <code>
        {Component.text(`Component.button(
  ~attrs=[
    Component.attr("class", "btn btn-primary"),
    Component.attr("type", "button"),
    Component.attr("disabled", "true"),
  ],
  ()
)`)}
      </code>
    </pre>
    <h3> {Component.text("Reactive Attributes")} </h3>
    <p> {Component.text("Function API supports reactive attributes:")} </p>
    <pre>
      <code>
        {Component.text(`let isActive = Signal.make(false)

Component.div(
  ~attrs=[
    Component.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
  ],
  ()
)`)}
      </code>
    </pre>
    <h2> {Component.text("Event Handlers")} </h2>
    <h3> {Component.text("JSX Event Props")} </h3>
    <p> {Component.text("JSX elements support common event handlers:")} </p>
    <ul>
      <li>
        <code> {Component.text("onClick")} </code>
        {Component.text(" - Click events")}
      </li>
      <li>
        <code> {Component.text("onInput")} </code>
        {Component.text(" - Input events")}
      </li>
      <li>
        <code> {Component.text("onChange")} </code>
        {Component.text(" - Change events")}
      </li>
      <li>
        <code> {Component.text("onSubmit")} </code>
        {Component.text(" - Form submit events")}
      </li>
      <li>
        <code> {Component.text("onFocus")} </code>
        {Component.text(", ")}
        <code> {Component.text("onBlur")} </code>
        {Component.text(" - Focus events")}
      </li>
      <li>
        <code> {Component.text("onKeyDown")} </code>
        {Component.text(", ")}
        <code> {Component.text("onKeyUp")} </code>
        {Component.text(" - Keyboard events")}
      </li>
    </ul>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

<button onClick={increment}>
  {Component.text("+1")}
</button>`)}
      </code>
    </pre>
    <h2> {Component.text("Lists")} </h2>
    <h3> {Component.text("Simple Lists (Non-Keyed)")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Component.list()")} </code>
      {Component.text(
        " for simple lists where the entire list re-renders on any change:",
      )}
    </p>
    <pre>
      <code>
        {Component.text(`let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {Component.list(items, item =>
    <li> {Component.text(item)} </li>
  )}
</ul>`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Note:")} </strong>
      {Component.text(
        " Simple lists re-render completely when the array changes (no diffing). For better performance, use keyed lists.",
      )}
    </p>
    <h3> {Component.text("Keyed Lists (Efficient Reconciliation)")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Component.listKeyed()")} </code>
      {Component.text(" for efficient list rendering with DOM element reuse:")}
    </p>
    <pre>
      <code>
        {Component.text(`type todo = {id: int, text: string, completed: bool}
let todos = Signal.make([
  {id: 1, text: "Buy milk", completed: false},
  {id: 2, text: "Walk dog", completed: true},
])

<ul>
  {Component.listKeyed(
    todos,
    todo => todo.id->Int.toString,  // Key extractor
    todo => <li> {Component.text(todo.text)} </li>  // Renderer
  )}
</ul>`)}
      </code>
    </pre>
    <p> <strong> {Component.text("Benefits of keyed lists:")} </strong> </p>
    <ul>
      <li>
        <strong> {Component.text("Reuses DOM elements")} </strong>
        {Component.text(" - Only updates what changed")}
      </li>
      <li>
        <strong> {Component.text("Preserves component state")} </strong>
        {Component.text(" - When list items move position")}
      </li>
      <li>
        <strong> {Component.text("Better performance")} </strong>
        {Component.text(" - Fewer DOM operations for large lists")}
      </li>
      <li>
        <strong> {Component.text("Efficient reconciliation")} </strong>
        {Component.text(" - Adds/removes/moves only necessary elements")}
      </li>
    </ul>
    <p> <strong> {Component.text("Best practices:")} </strong> </p>
    <ul>
      <li> {Component.text("Always use unique, stable keys (like database IDs)")} </li>
      <li> {Component.text("Don't use array indices as keys")} </li>
      <li> {Component.text("Keys should be strings")} </li>
      <li>
        {Component.text(
          "Use listKeyed for any list that can be reordered, filtered, or modified",
        )}
      </li>
    </ul>
    <h2> {Component.text("Mounting to the DOM")} </h2>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("mountById")} </code>
      {Component.text(" to attach your component to an existing DOM element:")}
    </p>
    <pre>
      <code>
        {Component.text(`let app = () => {
  <div> {Component.text("Hello, World!")} </div>
}

Component.mountById(app(), "app")`)}
      </code>
    </pre>
    <h2> {Component.text("Example: Counter Component")} </h2>
    <p> {Component.text("Here's a complete counter component using JSX:")} </p>
    <pre>
      <code>
        {Component.text(`open Xote

type counterProps = {initialValue: int}

let counter = (props: counterProps) => {
  let count = Signal.make(props.initialValue)

  let increment = (_evt: Dom.event) => {
    Signal.update(count, n => n + 1)
  }

  let decrement = (_evt: Dom.event) => {
    Signal.update(count, n => n - 1)
  }

  <div class="counter">
    <h2>
      {Component.textSignal(() =>
        "Count: " ++ Int.toString(Signal.get(count))
      )}
    </h2>
    <div class="controls">
      <button onClick={decrement}>
        {Component.text("-")}
      </button>
      <button onClick={increment}>
        {Component.text("+")}
      </button>
    </div>
  </div>
}

// Use the component
let app = counter({initialValue: 10})
Component.mountById(app, "app")`)}
      </code>
    </pre>
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Keep components small:")} </strong>
        {Component.text(" Each component should do one thing well")}
      </li>
      <li>
        <strong> {Component.text("Use signals for local state:")} </strong>
        {Component.text(" Create signals inside components for component-specific state")}
      </li>
      <li>
        <strong> {Component.text("Pass data via props:")} </strong>
        {Component.text(" Use record types for component parameters")}
      </li>
      <li>
        <strong> {Component.text("Compose components:")} </strong>
        {Component.text(" Build complex UIs from simple, reusable components")}
      </li>
      <li>
        <strong> {Component.text("Choose the right list type:")} </strong>
        {Component.text(" Use ")}
        <code> {Component.text("listKeyed")} </code>
        {Component.text(" for dynamic lists, ")}
        <code> {Component.text("list")} </code>
        {Component.text(" for simple static lists")}
      </li>
      <li>
        <strong> {Component.text("Use class not className:")} </strong>
        {Component.text(" In JSX, use the ")}
        <code> {Component.text("class")} </code>
        {Component.text(" prop for CSS classes")}
      </li>
    </ul>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Try the ")}
        {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
        {Component.text(" to see components in action")}
      </li>
      <li>
        {Component.text("Learn about ")}
        {Router.link(~to="/docs/router/overview", ~children=[Component.text("Routing")], ())}
        {Component.text(" for building SPAs")}
      </li>
      <li>
        {Component.text("Explore the ")}
        {Router.link(~to="/docs/api/signals", ~children=[Component.text("API Reference")], ())}
        {Component.text(" for detailed documentation")}
      </li>
    </ul>
  </div>
}
