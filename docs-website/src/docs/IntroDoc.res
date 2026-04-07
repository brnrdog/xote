// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/getting-started/introduction.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Node.text("Getting Started")} </h1>
    <p>
      {Node.text("Welcome to Xote (pronounced ")}
      {Node.text(") - a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.")}
    </p>
    <h2 id="what-is-xote"> {Node.text("What is Xote?")} </h2>
    <p>
      {Node.text("Xote provides a declarative component system and signal-based router built on top of ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(". It focuses on:")}
    </p>
    <ul>
      <li>
        {Node.text("Fine-grained reactivity: Direct DOM updates without a virtual DOM")}
      </li>
      <li>
        {Node.text("Automatic dependency tracking: No manual subscription management (powered by rescript-signals)")}
      </li>
      <li>
        {Node.text("Lightweight: Minimal runtime footprint")}
      </li>
      <li>
        {Node.text("Type-safe: Leverages ReScript's powerful type system")}
      </li>
      <li>
        {Node.text("JSX Support: Declarative component syntax with full ReScript type safety")}
      </li>
    </ul>
    <h2 id="quick-example"> {Node.text("Quick Example")} </h2>
    <p>
      {Node.text("Here's a simple counter application to get you started:")}
    </p>
    <h3 id="using-jsx-syntax"> {Node.text("Using JSX Syntax")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

// Create reactive state
let count = Signal.make(0)

// Event handler
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build the UI
let app = () => {
  <div>
    <h1> {Node.text("Counter")} </h1>
    <p>
      {Node.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </p>
    <button onClick={increment}>
      {Node.text("Increment")}
    </button>
  </div>
}

// Mount to the DOM
Node.mountById(app(), "app")`)}
      </code>
    </pre>
    <p>
      {Node.text("When you click the button, the counter updates reactively - only the text node displaying the count is updated, not the entire component tree.")}
    </p>
    <h2 id="core-concepts"> {Node.text("Core Concepts")} </h2>
    <p>
      {Node.text("Xote re-exports reactive primitives from rescript-signals and adds UI features:")}
    </p>
    <h3 id="reactive-primitives-from-rescript-signals"> {Node.text("Reactive Primitives (from rescript-signals)")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
      {Node.text(": Reactive state containers that notify dependents when they change")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Computed Values")], ())}
      {Node.text(": Derived values that automatically update when their dependencies change")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects")], ())}
      {Node.text(": Side effects that re-run when dependencies change")}
      </li>
    </ul>
    <h3 id="xote-features"> {Node.text("Xote Features")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(": Declarative UI builder with JSX support and fine-grained DOM updates")}
      </li>
      <li>
        {Node.text("Router: Signal-based SPA navigation with pattern matching")}
      </li>
    </ul>
    <h2 id="installation"> {Node.text("Installation")} </h2>
    <p>
      {Node.text("Get started with Xote in your ReScript project:")}
    </p>
    <pre>
      <code>
        {Node.text(`npm install xote
# or
yarn add xote
# or
pnpm add xote`)}
      </code>
    </pre>
    <p>
      {Node.text("Then add it to your ")}
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
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
      {Node.text(" - the foundation of reactive state")}
      </li>
      <li>
        {Node.text("Explore ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(" - building UIs with Xote")}
      </li>
      <li>
        {Node.text("Check out the ")}
      {Router.link(~to="/demos", ~children=[Node.text("Demos")], ())}
      {Node.text(" to see Xote in action")}
      </li>
      <li>
        {Node.text("Read the ")}
      {Router.link(~to="/docs/api/signals", ~children=[Node.text("API Reference")], ())}
      {Node.text(" for detailed documentation")}
      </li>
    </ul>
    <h2 id="philosophy"> {Node.text("Philosophy")} </h2>
    <p>
      {Node.text("Xote focuses on clarity, control, and performance. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM.")}
    </p>
    <p>
      {Node.text("By building on ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(" (which implements the ")}
      <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Node.text("TC39 Signals proposal")} </a>
      {Node.text("), Xote ensures your reactive code aligns with emerging JavaScript standards while providing ReScript-specific UI features.")}
    </p>
  </div>
}
