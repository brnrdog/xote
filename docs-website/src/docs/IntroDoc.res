// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/getting-started/introduction.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h2 id="what-is-xote"> {Node.text("What is Xote?")} </h2>
    <p>
      {Node.text("Xote is a UI library for ReScript built around fine-grained reactivity. It re-exports ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(" for state, derived values, and effects, then adds the pieces you need to build applications: components, JSX support, routing, SSR, and hydration.")}
    </p>
    <p>
      {Node.text("The design goal is simple: keep the reactive model small and explicit, then let updates flow directly to the DOM instead of re-running whole component trees.")}
    </p>
    <ul>
      <li>
        {Node.text("Signals for local and shared state")}
      </li>
      <li>
        {Node.text("Computed values for derived state")}
      </li>
      <li>
        {Node.text("Effects for external side effects")}
      </li>
      <li>
        {Node.text("View primitives and JSX for UI composition")}
      </li>
      <li>
        {Node.text("A built-in router, SSR, and hydration")}
      </li>
    </ul>

    <h2 id="quick-example"> {Node.text("Start Here")} </h2>
    <p>
      {Node.text("This counter shows the core model: a signal stores state, an event updates it, and a reactive view node reads it.")}
    </p>
    <h3 id="using-jsx-syntax"> {Node.text("Using JSX Syntax")} </h3>
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
      {View.computedText(() => "Count: " ++ Int.toString(Signal.get(count)))}
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
      {Node.text("When ")}
      <code> {Node.text("count")} </code>
      {Node.text(" changes, only the reactive view node updates. The component does not need a render loop or a dependency array.")}
    </p>

    <h2 id="core-modules"> {Node.text("How the Docs Are Organized")} </h2>
    <p>
      {Node.text("The docs make more sense if you move from the reactive core outward into UI, routing, and server rendering.")}
    </p>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
        {Node.text(" - state containers you can read and update")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Computeds")], ())}
        {Node.text(" - derived values that stay in sync")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects")], ())}
        {Node.text(" - side effects that react to state changes")}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[Node.text("View")], ())}
        {Node.text(" - the View module, JSX, attributes, events, and lists")}
      </li>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[Node.text("Router")], ())}
        {Node.text(" - client-side navigation and route matching")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[Node.text("Server-Side Rendering")], ())}
        {Node.text(" - rendering on the server and hydrating on the client")}
      </li>
    </ul>

    <h3 id="installation"> {Node.text("Installation")} </h3>
    <p>
      {Node.text("Install the package, then point ReScript's JSX transform at ")}
      <code> {Node.text("XoteJSX")} </code>
      {Node.text(".")}
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
  "bs-dependencies": ["xote"],
  "jsx": {
    "version": 4,
    "module": "XoteJSX"
  },
  "compiler-flags": ["-open Xote"]
}`)}
      </code>
    </pre>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Read Signals first")], ())}
        {Node.text(" if you want the shortest path into the reactive model.")}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[Node.text("Move to View next")], ())}
        {Node.text(" once the state model feels clear.")}
      </li>
      <li>
        {Router.link(~to="/docs/api/signals", ~children=[Node.text("Keep the Signals API nearby")], ())}
        {Node.text(" while you are writing real code.")}
      </li>
    </ul>

    <h2 id="philosophy"> {Node.text("Philosophy")} </h2>
    <p>
      {Node.text("Xote keeps the runtime surface small and explicit. State lives in signals, derived state lives in computeds, and external work lives in effects. That separation makes update paths easier to follow and easier to debug.")}
    </p>
    <p>
      {Node.text("Because Xote builds on ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(", the reactive core stays close to the broader signals direction in JavaScript while exposing a UI API that feels natural in ReScript.")}
    </p>
  </div>
}
