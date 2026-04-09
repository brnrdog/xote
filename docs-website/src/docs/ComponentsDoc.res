// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/components/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Components Overview")} </h1>
    <p>
      {Node.text("Xote provides a lightweight component system for building reactive UIs. Components are functions that return virtual nodes, which are then rendered to the DOM.")}
    </p>
    <p>
      {Node.text("Xote supports two syntax styles for building components:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("JSX Syntax:")} </strong>
      {Node.text(" Modern, declarative JSX syntax (recommended)")}
      </li>
      <li>
        <strong> {Node.text("Function API:")} </strong>
      {Node.text(" Explicit function calls with labeled parameters")}
      </li>
    </ul>
    <h2 id="what-are-components"> {Node.text("What are Components?")} </h2>
    <p>
      {Node.text("In Xote, a component is simply a function that returns a ")}
      <code> {Node.text("Node.node")} </code>
      {Node.text(". The recommended way to define components is with the ")}
      <strong> {Node.text("component module pattern")} </strong>
      {Node.text(" using ")}
      <code> {Node.text("@jsx.component")} </code>
      {Node.text(":")}
    </p>
    <h3 id="component-module-pattern"> {Node.text("Component Module Pattern (Recommended)")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("@jsx.component")} </code>
      {Node.text(" to define components as modules with a ")}
      <code> {Node.text("make")} </code>
      {Node.text(" function. This decorator automatically generates the props type from labeled arguments, enabling clean JSX usage:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

module Greeting = {
  @jsx.component
  let make = (~name: string) => {
    <div>
      <h1> {Node.text("Hello, " ++ name ++ "!")} </h1>
    </div>
  }
}

// Usage in JSX:
<Greeting name="World" />`)}
      </code>
    </pre>
    <p>
      {Node.text("Components without props simply omit the labeled arguments:")}
    </p>
    <pre>
      <code>
        {Node.text(`module Header = {
  @jsx.component
  let make = () => {
    <header>
      <h1> {Node.text("My App")} </h1>
    </header>
  }
}

// Usage:
<Header />`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Key points:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Components are defined as modules with a ")}
        <code> {Node.text("make")} </code>
        {Node.text(" function")}
      </li>
      <li>
        {Node.text("The ")}
        <code> {Node.text("@jsx.component")} </code>
        {Node.text(" decorator transforms labeled arguments (")}
        <code> {Node.text("~propName")} </code>
        {Node.text(") into a props record type automatically")}
      </li>
      <li>
        {Node.text("Components are used in JSX with ")}
        <code> {Node.text("<ComponentName prop={value} />")} </code>
        {Node.text(" syntax")}
      </li>
      <li>
        {Node.text("File-level modules can also be components \u2014 just add ")}
        <code> {Node.text("@jsx.component")} </code>
        {Node.text(" to a top-level ")}
        <code> {Node.text("make")} </code>
        {Node.text(" function")}
      </li>
    </ul>
    <h3 id="jsx-syntax"> {Node.text("Plain JSX Syntax")} </h3>
    <p>
      {Node.text("You can also define components as simple functions without the decorator:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

let greeting = () => {
  <div>
    <h1> {Node.text("Hello, Xote!")} </h1>
  </div>
}`)}
      </code>
    </pre>
    <h3 id="function-api"> {Node.text("Function API")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

let greeting = () => {
  Html.div(
    ~children=[
      Html.h1(~children=[Node.text("Hello, Xote!")], ())
    ],
    ()
  )
}`)}
      </code>
    </pre>
    <h2 id="jsx-configuration"> {Node.text("JSX Configuration")} </h2>
    <p>
      {Node.text("To use JSX syntax, configure your ")}
      <code> {Node.text("rescript.json")} </code>
      {Node.text(":")}
    </p>
    <pre>
      <code>
        {Node.text(`{
  "bs-dependencies": ["xote"],
  "jsx": {
    "version": 4,
    "module": "XoteJSX"
  },
  "compiler-flags": ["-open Xote"]
}`)}
      </code>
    </pre>
    <h2 id="text-nodes"> {Node.text("Text Nodes")} </h2>
    <h3 id="static-text"> {Node.text("Static Text")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Node.text()")} </code>
      {Node.text(" for static text:")}
    </p>
    <pre>
      <code>
        {Node.text(`<div>
  {Node.text("This text never changes")}
</div>`)}
      </code>
    </pre>
    <h3 id="reactive-text"> {Node.text("Reactive Text")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Node.signalText()")} </code>
      {Node.text(" for text that updates with signals:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)

<div>
  {Node.signalText(() =>
    "Count: " ++ Int.toString(Signal.get(count))
  )}
</div>`)}
      </code>
    </pre>
    <p>
      {Node.text("The function is tracked, so the text automatically updates when ")}
      <code> {Node.text("count")} </code>
      {Node.text(" changes.")}
    </p>
    <h2 id="attributes"> {Node.text("Attributes")} </h2>
    <h3 id="jsx-props"> {Node.text("JSX Props")} </h3>
    <p>
      {Node.text("JSX elements support common HTML attributes:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("class")} </code>
      {Node.text(" - CSS classes (note: ")}
      <code> {Node.text("class")} </code>
      {Node.text(", not ")}
      <code> {Node.text("className")} </code>
      {Node.text(")")}
      </li>
      <li>
        <code> {Node.text("id")} </code>
      {Node.text(" - Element ID")}
      </li>
      <li>
        <code> {Node.text("style")} </code>
      {Node.text(" - Inline styles")}
      </li>
      <li>
        <code> {Node.text("type_")} </code>
      {Node.text(" - Input type (with underscore to avoid keyword conflict)")}
      </li>
      <li>
        <code> {Node.text("value")} </code>
      {Node.text(" - Input value")}
      </li>
      <li>
        <code> {Node.text("placeholder")} </code>
      {Node.text(" - Input placeholder")}
      </li>
      <li>
        <code> {Node.text("disabled")} </code>
      {Node.text(" - Boolean disabled state")}
      </li>
      <li>
        <code> {Node.text("checked")} </code>
      {Node.text(" - Boolean checked state")}
      </li>
    </ul>
    <pre>
      <code>
        {Node.text(`<button
  class="btn btn-primary"
  type_="button"
  disabled={true}>
  {Node.text("Submit")}
</button>`)}
      </code>
    </pre>
    <h3 id="static-attributes-function-api"> {Node.text("Static Attributes (Function API)")} </h3>
    <pre>
      <code>
        {Node.text(`Html.button(
  ~attrs=[
    Node.attr("class", "btn btn-primary"),
    Node.attr("type", "button"),
    Node.attr("disabled", "true"),
  ],
  ()
)`)}
      </code>
    </pre>
    <h3 id="reactive-attributes"> {Node.text("Reactive Attributes")} </h3>
    <p>
      {Node.text("Function API supports reactive attributes:")}
    </p>
    <pre>
      <code>
        {Node.text(`let isActive = Signal.make(false)

Html.div(
  ~attrs=[
    Node.computedAttr("class", () =>
      Signal.get(isActive) ? "active" : "inactive"
    )
  ],
  ()
)`)}
      </code>
    </pre>
    <h2 id="event-handlers"> {Node.text("Event Handlers")} </h2>
    <h3 id="jsx-event-props"> {Node.text("JSX Event Props")} </h3>
    <p>
      {Node.text("JSX elements support common event handlers:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("onClick")} </code>
      {Node.text(" - Click events")}
      </li>
      <li>
        <code> {Node.text("onInput")} </code>
      {Node.text(" - Input events")}
      </li>
      <li>
        <code> {Node.text("onChange")} </code>
      {Node.text(" - Change events")}
      </li>
      <li>
        <code> {Node.text("onSubmit")} </code>
      {Node.text(" - Form submit events")}
      </li>
      <li>
        <code> {Node.text("onFocus")} </code>
      {Node.text(", ")}
      <code> {Node.text("onBlur")} </code>
      {Node.text(" - Focus events")}
      </li>
      <li>
        <code> {Node.text("onKeyDown")} </code>
      {Node.text(", ")}
      <code> {Node.text("onKeyUp")} </code>
      {Node.text(" - Keyboard events")}
      </li>
    </ul>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

<button onClick={increment}>
  {Node.text("+1")}
</button>`)}
      </code>
    </pre>
    <h2 id="lists"> {Node.text("Lists")} </h2>
    <h3 id="simple-lists-non-keyed"> {Node.text("Simple Lists (Non-Keyed)")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Node.list()")} </code>
      {Node.text(" for simple lists where the entire list re-renders on any change:")}
    </p>
    <pre>
      <code>
        {Node.text(`let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {Node.list(items, item =>
    <li> {Node.text(item)} </li>
  )}
</ul>`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Note:")} </strong>
      {Node.text(" Simple lists re-render completely when the array changes (no diffing). For better performance, use keyed lists.")}
    </p>
    <h3 id="keyed-lists-efficient-reconciliation"> {Node.text("Keyed Lists (Efficient Reconciliation)")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Node.listKeyed()")} </code>
      {Node.text(" for efficient list rendering with DOM element reuse:")}
    </p>
    <pre>
      <code>
        {Node.text(`type todo = {id: int, text: string, completed: bool}
let todos = Signal.make([
  {id: 1, text: "Buy milk", completed: false},
  {id: 2, text: "Walk dog", completed: true},
])

<ul>
  {Node.listKeyed(
    todos,
    todo => todo.id->Int.toString,  // Key extractor
    todo => <li> {Node.text(todo.text)} </li>  // Renderer
  )}
</ul>`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Benefits of keyed lists:")} </strong>
    </p>
    <ul>
      <li>
        <strong> {Node.text("Reuses DOM elements")} </strong>
      {Node.text(" - Only updates what changed")}
      </li>
      <li>
        <strong> {Node.text("Preserves component state")} </strong>
      {Node.text(" - When list items move position")}
      </li>
      <li>
        <strong> {Node.text("Better performance")} </strong>
      {Node.text(" - Fewer DOM operations for large lists")}
      </li>
      <li>
        <strong> {Node.text("Efficient reconciliation")} </strong>
      {Node.text(" - Adds/removes/moves only necessary elements")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Best practices:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Always use unique, stable keys (like database IDs)")}
      </li>
      <li>
        {Node.text("Don't use array indices as keys")}
      </li>
      <li>
        {Node.text("Keys should be strings")}
      </li>
      <li>
        {Node.text("Use listKeyed for any list that can be reordered, filtered, or modified")}
      </li>
    </ul>
    <h2 id="mounting-to-the-dom"> {Node.text("Mounting to the DOM")} </h2>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("mountById")} </code>
      {Node.text(" to attach your component to an existing DOM element:")}
    </p>
    <pre>
      <code>
        {Node.text(`let app = () => {
  <div> {Node.text("Hello, World!")} </div>
}

Node.mountById(app(), "app")`)}
      </code>
    </pre>
    <h2 id="example-counter-component"> {Node.text("Example: Counter Component")} </h2>
    <p>
      {Node.text("Here's a complete counter component using the component module pattern:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

module Counter = {
  @jsx.component
  let make = (~initialValue: int) => {
    let count = Signal.make(initialValue)

    let increment = (_evt: Dom.event) => {
      Signal.update(count, n => n + 1)
    }

    let decrement = (_evt: Dom.event) => {
      Signal.update(count, n => n - 1)
    }

    <div class="counter">
      <h2>
        {Node.signalText(() =>
          "Count: " ++ Int.toString(Signal.get(count))
        )}
      </h2>
      <div class="controls">
        <button onClick={decrement}>
          {Node.text("-")}
        </button>
        <button onClick={increment}>
          {Node.text("+")}
        </button>
      </div>
    </div>
  }
}

// Use the component in JSX
module App = {
  @jsx.component
  let make = () => {
    <Counter initialValue={10} />
  }
}

Node.mountById(App.make({}), "app")`)}
      </code>
    </pre>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Keep components small:")} </strong>
      {Node.text(" Each component should do one thing well")}
      </li>
      <li>
        <strong> {Node.text("Use signals for local state:")} </strong>
      {Node.text(" Create signals inside components for component-specific state")}
      </li>
      <li>
        <strong> {Node.text("Pass data via props:")} </strong>
      {Node.text(" Use record types for component parameters")}
      </li>
      <li>
        <strong> {Node.text("Compose components:")} </strong>
      {Node.text(" Build complex UIs from simple, reusable components")}
      </li>
      <li>
        <strong> {Node.text("Choose the right list type:")} </strong>
      {Node.text(" Use ")}
      <code> {Node.text("listKeyed")} </code>
      {Node.text(" for dynamic lists, ")}
      <code> {Node.text("list")} </code>
      {Node.text(" for simple static lists")}
      </li>
      <li>
        <strong> {Node.text("Use class not className:")} </strong>
      {Node.text(" In JSX, use the ")}
      <code> {Node.text("class")} </code>
      {Node.text(" prop for CSS classes")}
      </li>
    </ul>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Try the ")}
      {Router.link(~to="/demos", ~children=[Node.text("Demos")], ())}
      {Node.text(" to see components in action")}
      </li>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/router/overview", ~children=[Node.text("Routing")], ())}
      {Node.text(" for building SPAs")}
      </li>
      <li>
        {Node.text("Explore the ")}
      {Router.link(~to="/docs/api/signals", ~children=[Node.text("API Reference")], ())}
      {Node.text(" for detailed documentation")}
      </li>
    </ul>
  </div>
}
