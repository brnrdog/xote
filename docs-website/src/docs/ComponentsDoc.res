// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/components/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("A Xote component is a function that returns a ")}
      <code> {View.text("View.node")} </code>
      {View.text(". The component usually runs once, sets up its reactive graph, and then reactive nodes update in place over time.")}
    </p>
    <p>
      {View.text("The recommended path is JSX plus ")}
      <code> {View.text("@jsx.component")} </code>
      {View.text(". The function-based ")}
      <code> {View.text("View")} </code>
      {View.text(" and ")}
      <code> {View.text("Html")} </code>
      {View.text(" APIs stay available when you need lower-level control or are generating UI programmatically.")}
    </p>

    <h2 id="component-model"> {View.text("View Module")} </h2>
    <p>
      {View.text("Think in two layers:")}
    </p>
    <ul>
      <li>
        <strong> {View.text("Static structure:")} </strong>
        {View.text(" the component function builds the node tree")}
      </li>
      <li>
        <strong> {View.text("Reactive bindings:")} </strong>
        {View.text(" signal reads inside reactive nodes, computeds, and effects keep specific parts up to date")}
      </li>
    </ul>

    <h2 id="building-components"> {View.text("Using View")} </h2>
    <h3 id="jsx-configuration"> {View.text("JSX Configuration")} </h3>
    <p>
      {View.text("To use JSX with Xote, point ReScript at ")}
      <code> {View.text("XoteJSX")} </code>
      {View.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`{
  "dependencies": ["xote"],
  "jsx": {
    "version": 4,
    "module": "XoteJSX"
  },
  "compiler-flags": ["-open Xote"]
}`)}
      </code>
    </pre>

    <h3 id="writing-components"> {View.text("Writing Components")} </h3>
    <h4 id="component-module-pattern"> {View.text("Recommended Pattern")} </h4>
    <p>
      {View.text("Use a module with a ")}
      <code> {View.text("make")} </code>
      {View.text(" function and annotate it with ")}
      <code> {View.text("@jsx.component")} </code>
      {View.text(". ReScript derives the props shape from labeled arguments.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

module Greeting = {
  @jsx.component
  let make = (~name: string, ~emphasis=false) => {
    <div class={emphasis ? "greeting strong" : "greeting"}>
      <h1> {View.text("Hello, " ++ name)} </h1>
    </div>
  }
}

let app = () => {
  <Greeting name="World" emphasis />
}`)}
      </code>
    </pre>
    <h4 id="function-api"> {View.text("Function API")} </h4>
    <p>
      {View.text("The lower-level API is still useful when JSX is not a good fit.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let greeting = (name: string) => {
  Html.div(
    ~children=[
      Html.h1(~children=[View.text("Hello, " ++ name)], ())
    ],
    (),
  )
}`)}
      </code>
    </pre>

    <h3 id="reactive-output"> {View.text("Reactive Output")} </h3>
    <p>
      {View.text("JSX expressions are just nodes. For reactive text, use ")}
      <code> {View.text("View.signalText")} </code>
      {View.text(". For arrays of reactive children, use ")}
      <code> {View.text("View.signalFragment")} </code>
      {View.text(" or one of the list helpers.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = Signal.make(0)

<div>
  {View.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
</div>`)}
      </code>
    </pre>

    <h3 id="attributes-and-events"> {View.text("Attributes and Events")} </h3>
    <p>
      {View.text("In JSX, common HTML props are exposed directly. In the function API, use ")}
      <code> {View.text("View.Attr.string")} </code>
      {View.text(", ")}
      <code> {View.text("View.Attr.signal")} </code>
      {View.text(", and ")}
      <code> {View.text("View.Attr.compute")} </code>
      {View.text(".")}
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
  {View.text("Toggle")}
</button>`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Html.button(
  ~attrs=[
    View.Attr.compute("class", () =>
      Signal.get(isActive) ? "btn active" : "btn"
    ),
  ],
  ~events=[("click", toggle)],
  ~children=[View.text("Toggle")],
  (),
)`)}
      </code>
    </pre>
    <p>
      {View.text("In JSX, use ")}
      <code> {View.text("class")} </code>
      {View.text(", not ")}
      <code> {View.text("className")} </code>
      {View.text(". Use ")}
      <code> {View.text("type_")} </code>
      {View.text(" for the HTML ")}
      <code> {View.text("type")} </code>
      {View.text(" attribute because ")}
      <code> {View.text("type")} </code>
      {View.text(" is reserved in ReScript.")}
    </p>

    <h3 id="lists"> {View.text("Lists")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("View.each")} </code>
      {View.text(" for simple arrays that can be fully re-rendered, and ")}
      <code> {View.text("View.eachWithKey")} </code>
      {View.text(" when item identity matters.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let items = Signal.make(["Apple", "Banana", "Cherry"])

<ul>
  {View.each(items, item => <li> {View.text(item)} </li>)}
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
  {View.eachWithKey(
    todos,
    todo => todo.id,
    todo => <li> {View.text(todo.text)} </li>,
  )}
</ul>`)}
      </code>
    </pre>
    <p>
      {View.text("Choose stable keys. Database IDs and route slugs are good. Array indexes are not.")}
    </p>

    <h3 id="mounting"> {View.text("Mounting")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("View.mount")} </code>
      {View.text(" when you already have a DOM element, or ")}
      <code> {View.text("View.mountById")} </code>
      {View.text(" when you want to look one up by id.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let app = () => {
  <div> {View.text("Hello, Xote")} </div>
}

View.mountById(app(), "app")`)}
      </code>
    </pre>

    <h2 id="components-in-practice"> {View.text("In Practice")} </h2>
    <h3 id="example-counter-component"> {View.text("Example: Counter View")} </h3>
    <p>
      {View.text("This example keeps state local to the component and exposes only props.")}
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
        {View.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
      </h2>
      <button onClick={decrement}> {View.text("-")} </button>
      <button onClick={increment}> {View.text("+")} </button>
    </div>
  }
}

let app = () => {
  <Counter initialValue={10} />
}`)}
      </code>
    </pre>

    <h2 id="components-working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Default to the JSX module pattern when there is no reason to drop lower.")}
      </li>
      <li>
        {View.text("Keep state close to where it is used. Local signals are cheap and usually easier to follow.")}
      </li>
      <li>
        {View.text("Use ")}
        <code> {View.text("View.eachWithKey")} </code>
        {View.text(" for collections that reorder, insert, or preserve local DOM state.")}
      </li>
      <li>
        {View.text("Be explicit about reactive output so the update boundaries stay readable in the component.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[View.text("Read Router")], ())}
        {View.text(" when these components need client-side navigation.")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[View.text("Read Server-Side Rendering")], ())}
        {View.text(" if the same components need to render on the server.")}
      </li>
    </ul>
  </div>
}
