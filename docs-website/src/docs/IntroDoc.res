// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/getting-started/introduction.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h2 id="what-is-xote"> {View.text("What is Xote?")} </h2>
    <p>
      {View.text("Xote is a UI library for ReScript built around fine-grained reactivity. It re-exports ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {View.text("rescript-signals")} </a>
      {View.text(" for state, derived values, and effects, then adds the pieces you need to build applications: components, JSX support, routing, SSR, and hydration.")}
    </p>
    <p>
      {View.text("The design goal is simple: keep the reactive model small and explicit, then let updates flow directly to the DOM instead of re-running whole component trees.")}
    </p>
    <ul>
      <li>
        {View.text("Signals for local and shared state")}
      </li>
      <li>
        {View.text("Computed values for derived state")}
      </li>
      <li>
        {View.text("Effects for external side effects")}
      </li>
      <li>
        {View.text("View primitives and JSX for UI composition")}
      </li>
      <li>
        {View.text("A built-in router, SSR, and hydration")}
      </li>
    </ul>

    <h2 id="quick-example"> {View.text("Start Here")} </h2>
    <p>
      {View.text("This counter shows the core model: a signal stores state, an event updates it, and a reactive view node reads it.")}
    </p>
    <h3 id="using-jsx-syntax"> {View.text("Using JSX Syntax")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

let app = () => {
  <div>
    <h1> {View.text("Counter")} </h1>
    <p>
      {View.signalText(() => \`Count: \${Signal.get(count)->Int.toString}\`)}
    </p>
    <button onClick={increment}>
      {View.text("Increment")}
    </button>
  </div>
}

View.mountById(app(), "app")`)}
      </code>
    </pre>
    <p>
      {View.text("When ")}
      <code> {View.text("count")} </code>
      {View.text(" changes, only the reactive view node updates. The component does not need a render loop or a dependency array.")}
    </p>

    <h2 id="core-modules"> {View.text("How the Docs Are Organized")} </h2>
    <p>
      {View.text("The docs make more sense if you move from the reactive core outward into UI, routing, and server rendering.")}
    </p>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Signals")], ())}
        {View.text(" - state containers you can read and update")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[View.text("Computeds")], ())}
        {View.text(" - derived values that stay in sync")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[View.text("Effects")], ())}
        {View.text(" - side effects that react to state changes")}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("View")], ())}
        {View.text(" - the View module, JSX, attributes, events, and lists")}
      </li>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[View.text("Router")], ())}
        {View.text(" - client-side navigation and route matching")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[View.text("Server-Side Rendering")], ())}
        {View.text(" - rendering on the server and hydrating on the client")}
      </li>
    </ul>

    <h3 id="installation"> {View.text("Installation")} </h3>
    <p>
      {View.text("Install the package, then point ReScript's JSX transform at ")}
      <code> {View.text("XoteJSX")} </code>
      {View.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`npm install xote
# or
yarn add xote
# or
pnpm add xote`)}
      </code>
    </pre>
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

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Read Signals first")], ())}
        {View.text(" if you want the shortest path into the reactive model.")}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("Move to View next")], ())}
        {View.text(" once the state model feels clear.")}
      </li>
      <li>
        {Router.link(~to="/docs/api/signals", ~children=[View.text("Keep the Signals API nearby")], ())}
        {View.text(" while you are writing real code.")}
      </li>
    </ul>

    <h2 id="philosophy"> {View.text("Philosophy")} </h2>
    <p>
      {View.text("Xote keeps the runtime surface small and explicit. State lives in signals, derived state lives in computeds, and external work lives in effects. That separation makes update paths easier to follow and easier to debug.")}
    </p>
    <p>
      {View.text("Because Xote builds on ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {View.text("rescript-signals")} </a>
      {View.text(", the reactive core stays close to the broader signals direction in JavaScript while exposing a UI API that feels natural in ReScript.")}
    </p>
  </div>
}
