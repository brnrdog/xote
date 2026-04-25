// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/components/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("A Xote component is a function that returns a ")}
      <code> {Node.text("Node.node")} </code>
      {Node.text(". The component usually runs once, sets up its reactive graph, and then reactive nodes update in place over time.")}
    </p>
    <p>
      {Node.text("The recommended path is JSX plus ")}
      <code> {Node.text("@jsx.component")} </code>
      {Node.text(". The function-based ")}
      <code> {Node.text("Node")} </code>
      {Node.text(" and ")}
      <code> {Node.text("Html")} </code>
      {Node.text(" APIs stay available when you need lower-level control or are generating UI programmatically.")}
    </p>

    <h2 id="component-model"> {Node.text("Component Model")} </h2>
    <p>
      {Node.text("Think in two layers:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Static structure:")} </strong>
        {Node.text(" the component function builds the node tree")}
      </li>
      <li>
        <strong> {Node.text("Reactive bindings:")} </strong>
        {Node.text(" signal reads inside reactive nodes, computeds, and effects keep specific parts up to date")}
      </li>
    </ul>

    <h2 id="building-components"> {Node.text("Building Components")} </h2>
    <h3 id="jsx-configuration"> {Node.text("JSX Configuration")} </h3>
    <p>
      {Node.text("To use JSX with Xote, point ReScript at ")}
      <code> {Node.text("XoteJSX")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`{
  "bs-dependencies": ["xote"],
  "jsx": {
    "version": 4,
    "module": "XoteJSX"
  },
  "compiler-flags": ["-open Xote"]
}`)}
      </code>
    </pre>

    <h3 id="writing-components"> {Node.text("Writing Components")} </h3>
    <h4 id="component-module-pattern"> {Node.text("Recommended Pattern")} </h4>
    <p>
      {Node.text("Use a module with a ")}
      <code> {Node.text("make")} </code>
      {Node.text(" function and annotate it with ")}
      <code> {Node.text("@jsx.component")} </code>
      {Node.text(". ReScript derives the props shape from labeled arguments.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

module Greeting = {
  @jsx.component
  let make = (~name: string, ~emphasis=false) => {
    <div class={emphasis ? "greeting strong" : "greeting"}>
      <h1> {Node.text("Hello, " ++ name)} </h1>
    </div>
  }
}

let app = () => {
  <Greeting name="World" emphasis />
}`)}
      </code>
    </pre>
    <h4 id="function-api"> {Node.text("Function API")} </h4>
    <p>
      {Node.text("The lower-level API is still useful when JSX is not a good fit.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let greeting = (name: string) => {
  Html.div(
    ~children=[
      Html.h1(~children=[Node.text("Hello, " ++ name)], ())
    ],
    (),
  )
}`)}
      </code>
    </pre>

    <h3 id="reactive-output"> {Node.text("Reactive Output")} </h3>
    <p>
      {Node.text("JSX expressions are just nodes. For reactive text, use ")}
      <code> {Node.text("Node.signalText")} </code>
      {Node.text(". For arrays of reactive children, use ")}
      <code> {Node.text("Node.signalFragment")} </code>
      {Node.text(" or one of the list helpers.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = Signal.make(0)

<div>
  {Node.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
</div>`)}
      </code>
    </pre>

    <h3 id="attributes-and-events"> {Node.text("Attributes and Events")} </h3>
    <p>
      {Node.text("In JSX, common HTML props are exposed directly. In the function API, use ")}
      <code> {Node.text("Node.attr")} </code>
      {Node.text(", ")}
      <code> {Node.text("Node.signalAttr")} </code>
      {Node.text(", and ")}
      <code> {Node.text("Node.computedAttr")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let isActive = Signal.make(false)

let toggle = (_evt: Dom.event) => {
  Signal.update(isActive, active => !active)
}

<button
  class={Signal.get(isActive) ? "btn active" : "btn"}
  onClick={toggle}>
  {Node.text("Toggle")}
</button>`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Html.button(
  ~attrs=[
    Node.computedAttr("class", () =>
      Signal.get(isActive) ? "btn active" : "btn"
    ),
  ],
  ~events=[("click", toggle)],
  ~children=[Node.text("Toggle")],
  (),
)`)}
      </code>
    </pre>
    <p>
      {Node.text("In JSX, use ")}
      <code> {Node.text("class")} </code>
      {Node.text(", not ")}
      <code> {Node.text("className")} </code>
      {Node.text(". Use ")}
      <code> {Node.text("type_")} </code>
      {Node.text(" for the HTML ")}
      <code> {Node.text("type")} </code>
      {Node.text(" attribute because ")}
      <code> {Node.text("type")} </code>
      {Node.text(" is reserved in ReScript.")}
    </p>

    <h3 id="lists"> {Node.text("Lists")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Node.list")} </code>
      {Node.text(" for simple arrays that can be fully re-rendered, and ")}
      <code> {Node.text("Node.keyedList")} </code>
      {Node.text(" when item identity matters.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {Node.list(items, item => <li> {Node.text(item)} </li>)}
</ul>`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type todo = {id: string, text: string}
let todos = Signal.make([
  {id: "1", text: "Write docs"},
  {id: "2", text: "Ship release"},
])

<ul>
  {Node.keyedList(
    todos,
    todo => todo.id,
    todo => <li> {Node.text(todo.text)} </li>,
  )}
</ul>`)}
      </code>
    </pre>
    <p>
      {Node.text("Choose stable keys. Database IDs and route slugs are good. Array indexes are not.")}
    </p>

    <h3 id="mounting"> {Node.text("Mounting")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Node.mount")} </code>
      {Node.text(" when you already have a DOM element, or ")}
      <code> {Node.text("Node.mountById")} </code>
      {Node.text(" when you want to look one up by id.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let app = () => {
  <div> {Node.text("Hello, Xote")} </div>
}

Node.mountById(app(), "app")`)}
      </code>
    </pre>

    <h2 id="components-in-practice"> {Node.text("In Practice")} </h2>
    <h3 id="example-counter-component"> {Node.text("Example: Counter Component")} </h3>
    <p>
      {Node.text("This example keeps state local to the component and exposes only props.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

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
        {Node.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
      </h2>
      <button onClick={decrement}> {Node.text("-")} </button>
      <button onClick={increment}> {Node.text("+")} </button>
    </div>
  }
}

let app = () => {
  <Counter initialValue={10} />
}`)}
      </code>
    </pre>

    <h2 id="components-working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Default to the JSX module pattern when there is no reason to drop lower.")}
      </li>
      <li>
        {Node.text("Keep state close to where it is used. Local signals are cheap and usually easier to follow.")}
      </li>
      <li>
        {Node.text("Use ")}
        <code> {Node.text("Node.keyedList")} </code>
        {Node.text(" for collections that reorder, insert, or preserve local DOM state.")}
      </li>
      <li>
        {Node.text("Be explicit about reactive output so the update boundaries stay readable in the component.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[Node.text("Read Router")], ())}
        {Node.text(" when these components need client-side navigation.")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[Node.text("Read Server-Side Rendering")], ())}
        {Node.text(" if the same components need to render on the server.")}
      </li>
    </ul>
  </div>
}
