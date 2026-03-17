// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/components/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Components Overview")} </h1>
    <p>
      {Component.text("Xote provides a lightweight component system for building reactive UIs. Components are functions that return virtual nodes, which are then rendered to the DOM.")}
    </p>
    <p>
      {Component.text("Xote supports two syntax styles for building components:")}
    </p>
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
    <h2 id="what-are-components"> {Component.text("What are Components?")} </h2>
    <p>
      {Component.text("In Xote, a component is simply a function that returns a ")}
      <code> {Component.text("Component.node")} </code>
      {Component.text(". The recommended way to define components is with the ")}
      <strong> {Component.text("component module pattern")} </strong>
      {Component.text(" using ")}
      <code> {Component.text("@jsx.component")} </code>
      {Component.text(":")}
    </p>
    <h3 id="component-module-pattern"> {Component.text("Component Module Pattern (Recommended)")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("@jsx.component")} </code>
      {Component.text(" to define components as modules with a ")}
      <code> {Component.text("make")} </code>
      {Component.text(" function. This decorator automatically generates the props type from labeled arguments, enabling clean JSX usage:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

module Greeting = {
  @jsx.component
  let make = (~name: string) => {
    <div>
      <h1> {Component.text("Hello, " ++ name ++ "!")} </h1>
    </div>
  }
}

// Usage in JSX:
<Greeting name="World" />`)}
      </code>
    </pre>
    <p>
      {Component.text("Components without props simply omit the labeled arguments:")}
    </p>
    <pre>
      <code>
        {Component.text(`module Header = {
  @jsx.component
  let make = () => {
    <header>
      <h1> {Component.text("My App")} </h1>
    </header>
  }
}

// Usage:
<Header />`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Key points:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Components are defined as modules with a ")}
        <code> {Component.text("make")} </code>
        {Component.text(" function")}
      </li>
      <li>
        {Component.text("The ")}
        <code> {Component.text("@jsx.component")} </code>
        {Component.text(" decorator transforms labeled arguments (")}
        <code> {Component.text("~propName")} </code>
        {Component.text(") into a props record type automatically")}
      </li>
      <li>
        {Component.text("Components are used in JSX with ")}
        <code> {Component.text("<ComponentName prop={value} />")} </code>
        {Component.text(" syntax")}
      </li>
      <li>
        {Component.text("File-level modules can also be components \u2014 just add ")}
        <code> {Component.text("@jsx.component")} </code>
        {Component.text(" to a top-level ")}
        <code> {Component.text("make")} </code>
        {Component.text(" function")}
      </li>
    </ul>
    <h3 id="jsx-syntax"> {Component.text("Plain JSX Syntax")} </h3>
    <p>
      {Component.text("You can also define components as simple functions without the decorator:")}
    </p>
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
    <h3 id="function-api"> {Component.text("Function API")} </h3>
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
    <h2 id="jsx-configuration"> {Component.text("JSX Configuration")} </h2>
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
    <h2 id="text-nodes"> {Component.text("Text Nodes")} </h2>
    <h3 id="static-text"> {Component.text("Static Text")} </h3>
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
    <h3 id="reactive-text"> {Component.text("Reactive Text")} </h3>
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
    <h2 id="attributes"> {Component.text("Attributes")} </h2>
    <h3 id="jsx-props"> {Component.text("JSX Props")} </h3>
    <p>
      {Component.text("JSX elements support common HTML attributes:")}
    </p>
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
    <h3 id="static-attributes-function-api"> {Component.text("Static Attributes (Function API)")} </h3>
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
    <h3 id="reactive-attributes"> {Component.text("Reactive Attributes")} </h3>
    <p>
      {Component.text("Function API supports reactive attributes:")}
    </p>
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
    <h2 id="event-handlers"> {Component.text("Event Handlers")} </h2>
    <h3 id="jsx-event-props"> {Component.text("JSX Event Props")} </h3>
    <p>
      {Component.text("JSX elements support common event handlers:")}
    </p>
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
    <h2 id="lists"> {Component.text("Lists")} </h2>
    <h3 id="simple-lists-non-keyed"> {Component.text("Simple Lists (Non-Keyed)")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Component.list()")} </code>
      {Component.text(" for simple lists where the entire list re-renders on any change:")}
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
      {Component.text(" Simple lists re-render completely when the array changes (no diffing). For better performance, use keyed lists.")}
    </p>
    <h3 id="keyed-lists-efficient-reconciliation"> {Component.text("Keyed Lists (Efficient Reconciliation)")} </h3>
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
    <p>
      <strong> {Component.text("Benefits of keyed lists:")} </strong>
    </p>
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
    <p>
      <strong> {Component.text("Best practices:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Always use unique, stable keys (like database IDs)")}
      </li>
      <li>
        {Component.text("Don't use array indices as keys")}
      </li>
      <li>
        {Component.text("Keys should be strings")}
      </li>
      <li>
        {Component.text("Use listKeyed for any list that can be reordered, filtered, or modified")}
      </li>
    </ul>
    <h2 id="mounting-to-the-dom"> {Component.text("Mounting to the DOM")} </h2>
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
    <h2 id="example-counter-component"> {Component.text("Example: Counter Component")} </h2>
    <p>
      {Component.text("Here's a complete counter component using the component module pattern:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

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
}

// Use the component in JSX
module App = {
  @jsx.component
  let make = () => {
    <Counter initialValue={10} />
  }
}

Component.mountById(App.make({}), "app")`)}
      </code>
    </pre>
    <h2 id="best-practices"> {Component.text("Best Practices")} </h2>
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
    <h2 id="next-steps"> {Component.text("Next Steps")} </h2>
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
