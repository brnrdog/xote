// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/getting-started/introduction.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Getting Started")} </h1>
    <p>
      {Component.text("Welcome to Xote (pronounced ")}
      {Component.text(") - a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.")}
    </p>
    <h2> {Component.text("What is Xote?")} </h2>
    <p>
      {Component.text("Xote provides a declarative component system and signal-based router built on top of ")}
      <a href="https://github.com/brnrdog/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(". It focuses on:")}
    </p>
    <ul>
      <li>
        {Component.text("Fine-grained reactivity: Direct DOM updates without a virtual DOM")}
      </li>
      <li>
        {Component.text("Automatic dependency tracking: No manual subscription management (powered by rescript-signals)")}
      </li>
      <li>
        {Component.text("Lightweight: Minimal runtime footprint")}
      </li>
      <li>
        {Component.text("Type-safe: Leverages ReScript's powerful type system")}
      </li>
      <li>
        {Component.text("JSX Support: Declarative component syntax with full ReScript type safety")}
      </li>
    </ul>
    <h2> {Component.text("Quick Example")} </h2>
    <p>
      {Component.text("Here's a simple counter application to get you started:")}
    </p>
    <h3> {Component.text("Using JSX Syntax")} </h3>
    <pre>
      <code class="language-rescript">
        {Component.text(`open Xote

// Create reactive state
let count = Signal.make(0)

// Event handler
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build the UI
let app = () => {
  <div>
    <h1> {Component.text("Counter")} </h1>
    <p>
      {Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </p>
    <button onClick={increment}>
      {Component.text("Increment")}
    </button>
  </div>
}

// Mount to the DOM
Component.mountById(app(), "app")`)}
      </code>
    </pre>
    <p>
      {Component.text("When you click the button, the counter updates reactively - only the text node displaying the count is updated, not the entire component tree.")}
    </p>
    <h2> {Component.text("Core Concepts")} </h2>
    <p>
      {Component.text("Xote re-exports reactive primitives from rescript-signals and adds UI features:")}
    </p>
    <h3> {Component.text("Reactive Primitives (from rescript-signals)")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Signals")], ())}
      {Component.text(": Reactive state containers that notify dependents when they change")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Component.text("Computed Values")], ())}
      {Component.text(": Derived values that automatically update when their dependencies change")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Component.text("Effects")], ())}
      {Component.text(": Side effects that re-run when dependencies change")}
      </li>
    </ul>
    <h3> {Component.text("Xote Features")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
      {Component.text(": Declarative UI builder with JSX support and fine-grained DOM updates")}
      </li>
      <li>
        {Component.text("Router: Signal-based SPA navigation with pattern matching")}
      </li>
    </ul>
    <h2> {Component.text("Installation")} </h2>
    <p>
      {Component.text("Get started with Xote in your ReScript project:")}
    </p>
    <pre>
      <code class="language-bash">
        {Component.text(`npm install xote
# or
yarn add xote
# or
pnpm add xote`)}
      </code>
    </pre>
    <p>
      {Component.text("Then add it to your ")}
      <code> {Component.text("rescript.json")} </code>
      {Component.text(":")}
    </p>
    <pre>
      <code class="language-json">
        {Component.text(`{
  "bs-dependencies": ["xote"]
}`)}
      </code>
    </pre>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Signals")], ())}
      {Component.text(" - the foundation of reactive state")}
      </li>
      <li>
        {Component.text("Explore ")}
      {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
      {Component.text(" - building UIs with Xote")}
      </li>
      <li>
        {Component.text("Check out the ")}
      {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
      {Component.text(" to see Xote in action")}
      </li>
      <li>
        {Component.text("Read the ")}
      {Router.link(~to="/docs/api/signals", ~children=[Component.text("API Reference")], ())}
      {Component.text(" for detailed documentation")}
      </li>
    </ul>
    <h2> {Component.text("Philosophy")} </h2>
    <p>
      {Component.text("Xote focuses on clarity, control, and performance. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM.")}
    </p>
    <p>
      {Component.text("By building on ")}
      <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(" (which implements the ")}
      <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Component.text("TC39 Signals proposal")} </a>
      {Component.text("), Xote ensures your reactive code aligns with emerging JavaScript standards while providing ReScript-specific UI features.")}
    </p>
  </div>
}
