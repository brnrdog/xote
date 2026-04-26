// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/getting-started/rescript-for-newcomers.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("ReScript is the language Xote is built for. If you are coming from JavaScript or TypeScript, the quickest way to get productive is to understand that ReScript keeps the JavaScript runtime model, but gives you stricter types, better data modeling, and a compiler that pushes you toward explicit code.")}
    </p>
    <h2 id="what-rescript-is"> {Node.text("What ReScript Is")} </h2>
    <p>
      {Node.text("ReScript is a statically typed language that compiles to readable JavaScript. It is designed for the JavaScript ecosystem rather than against it, so you still use npm packages, browser APIs, Node APIs, bundlers, and regular JavaScript interop when you need to.")}
    </p>
    <p>
      {Node.text("For Xote users, that matters because the code you write stays close to the platform. Signals, DOM events, and server rendering are still JavaScript work. ReScript mainly improves how safely and clearly you express that work.")}
    </p>
    <h2 id="why-it-matters"> {Node.text("Why It Matters")} </h2>
    <p>
      {Node.text("ReScript removes a lot of the background noise that tends to accumulate in large UI codebases.")}
    </p>
    <ul>
      <li>
        {Node.text("Type inference means you rarely annotate obvious types.")}
      </li>
      <li>
        <code> {Node.text("option")} </code>
      {Node.text(" replaces a large class of ")}
      <code> {Node.text("null")} </code>
      {Node.text(" and ")}
      <code> {Node.text("undefined")} </code>
      {Node.text(" mistakes.")}
      </li>
      <li>
        <code> {Node.text("switch")} </code>
      {Node.text(" with pattern matching makes branching on data shape clearer.")}
      </li>
      <li>
        {Node.text("Exhaustiveness checks catch missing cases at compile time.")}
      </li>
      <li>
        {Node.text("Modules map cleanly to files, which keeps code organization simple.")}
      </li>
    </ul>
    <h3 id="the-practical-payoff"> {Node.text("The Practical Payoff")} </h3>
    <p>
      {Node.text("The language is valuable when your UI grows beyond a few components. Refactors are safer, data modeling is more deliberate, and impossible states are harder to represent by accident.")}
    </p>
    <p>
      {Node.text("That does not mean every file looks radically different from JavaScript. Most of the time, ReScript feels like a cleaner way to write functions, records, and modules for code that still runs as JavaScript in the browser or on the server.")}
    </p>
    <h2 id="rescript-in-existing-js-or-ts-projects"> {Node.text("ReScript in Existing JS or TS Projects")} </h2>
    <p>
      {Node.text("You do not need to rewrite a whole codebase to use ReScript. It works well as an incremental addition inside an existing JavaScript or TypeScript project.")}
    </p>
    <ul>
      <li>
        {Node.text("A JavaScript or TypeScript app can import modules or libraries compiled from ReScript.")}
      </li>
      <li>
        {Node.text("A ReScript file can target the same runtime, bundler, and npm package graph as the rest of your app.")}
      </li>
      <li>
        {Node.text("That makes it practical to introduce ReScript one feature, component, or library at a time.")}
      </li>
    </ul>
    <p>
      {Node.text("This is useful for Xote too. You can build a library in ReScript and consume it from JavaScript or TypeScript, or add ReScript-powered UI to a broader JS or TS codebase without changing the whole stack at once.")}
    </p>
    <h2 id="syntax-you-will-see-often"> {Node.text("Syntax You Will See Often")} </h2>
    <h3 id="let-bindings-and-functions"> {Node.text("let Bindings and Functions")} </h3>
    <p>
      {Node.text("Most values are declared with ")}
      <code> {Node.text("let")} </code>
      {Node.text(". Functions are also regular values.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let name = "Ada"
let count = 1

let greet = person => \`Hello, \${person}\`
let add = (a, b) => a + b`)}
      </code>
    </pre>
    <p>
      {Node.text("Two things stand out quickly:")}
    </p>
    <ul>
      <li>
        {Node.text("Template strings use backticks and ")}
      <code> {Node.text("\${...}")} </code>
      {Node.text(" for interpolation")}
      </li>
      <li>
        {Node.text("Function calls use parentheses, but a single-argument anonymous function often reads like ")}
      <code> {Node.text("value => ...")} </code>
      </li>
    </ul>
    <h3 id="records-and-variants"> {Node.text("Records and Variants")} </h3>
    <p>
      {Node.text("Records are good for structured data. Variants are good for modeling a fixed set of states.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type user = {
  name: string,
  admin: bool,
}

type status =
  | Idle
  | Saving
  | Failed(string)

let currentUser = {name: "Ada", admin: true}
let currentStatus = Saving`)}
      </code>
    </pre>
    <p>
      {Node.text("Variants are one of the biggest upgrades from typical JavaScript data modeling. They make state machines and async UI states much easier to express safely.")}
    </p>
    <h3 id="switch-and-pattern-matching"> {Node.text("switch and Pattern Matching")} </h3>
    <p>
      <code> {Node.text("switch")} </code>
      {Node.text(" is one of the most useful parts of the language. You use it for branching, destructuring, and exhaustiveness checking.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let statusLabel = status =>
  switch status {
  | Idle => "Ready"
  | Saving => "Saving..."
  | Failed(message) => \`Failed: \${message}\`
  }`)}
      </code>
    </pre>
    <p>
      {Node.text("When you add a new variant case later, the compiler tells you every ")}
      <code> {Node.text("switch")} </code>
      {Node.text(" that now needs updating.")}
    </p>
    <h3 id="options-instead-of-null"> {Node.text("options Instead of null")} </h3>
    <p>
      {Node.text("ReScript uses ")}
      <code> {Node.text("option<'a>")} </code>
      {Node.text(" for values that may be missing.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let maybeName: option<string> = Some("Ada")
let missingName: option<string> = None

let displayName = name =>
  switch name {
  | Some(value) => value
  | None => "Anonymous"
  }`)}
      </code>
    </pre>
    <p>
      {Node.text("That pattern shows up often when working with DOM lookups, optional props, and server data.")}
    </p>
    <h3 id="modules-and-files"> {Node.text("Modules and Files")} </h3>
    <p>
      {Node.text("Each file becomes a module. If you have a file named ")}
      <code> {Node.text("Counter.res")} </code>
      {Node.text(", its values are available under ")}
      <code> {Node.text("Counter")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`/* Counter.res */
let initial = 0
let increment = count => count + 1

/* App.res */
let next = Counter.increment(Counter.initial)`)}
      </code>
    </pre>
    <p>
      {Node.text("This is one of the reasons ReScript codebases stay readable as they grow. Namespacing is simple and built into the file model.")}
    </p>
    <h2 id="xote-flavored-rescript-patterns"> {Node.text("Xote-Flavored ReScript Patterns")} </h2>
    <h3 id="event-handlers"> {Node.text("Event Handlers")} </h3>
    <p>
      {Node.text("A DOM event handler is usually just a small function that updates a signal.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}`)}
      </code>
    </pre>
    <p>
      {Node.text("The ")}
      <code> {Node.text("_evt")} </code>
      {Node.text(" name means the argument exists, but the function does not need to read it.")}
    </p>
    <h3 id="local-state-with-signals"> {Node.text("Local State with Signals")} </h3>
    <p>
      {Node.text("Signals are ordinary values, so local state does not need a special hook API.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

module Counter = {
  @jsx.component
  let make = () => {
    let count = Signal.make(0)

    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Node.signalText(() => \`Count: \${Signal.get(count)->Int.toString}\`)}
    </button>
  }
}`)}
      </code>
    </pre>
    <p>
      {Node.text("The component sets up its state once. Later updates happen through the reactive graph, not by re-running the whole component as the default update mechanism.")}
    </p>
    <h3 id="jsx-components"> {Node.text("JSX Components")} </h3>
    <p>
      {Node.text("A Xote component is usually a module with a ")}
      <code> {Node.text("make")} </code>
      {Node.text(" function marked with ")}
      <code> {Node.text("@jsx.component")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

module Greeting = {
  @jsx.component
  let make = (~name: string, ~highlight=false) => {
    <h1 class={highlight ? "hero" : "plain"}>
      {Node.text(\`Hello, \${name}\`)}
    </h1>
  }
}`)}
      </code>
    </pre>
    <p>
      {Node.text("Labeled arguments such as ")}
      <code> {Node.text("~name")} </code>
      {Node.text(" become component props. Optional props often use defaults like ")}
      <code> {Node.text("~highlight=false")} </code>
      {Node.text(".")}
    </p>
    <h2 id="official-docs"> {Node.text("Official Docs")} </h2>
    <p>
      {Node.text("The official ReScript docs are the right place for the full language reference and deeper syntax coverage.")}
    </p>
    <h3 id="recommended-deep-dives"> {Node.text("Recommended Deep Dives")} </h3>
    <ul>
      <li>
        <a href="https://rescript-lang.org/docs/manual/v12.0.0/introduction" target="_blank"> {Node.text("Introduction")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/overview" target="_blank"> {Node.text("Overview")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/pattern-matching-destructuring/" target="_blank"> {Node.text("Pattern Matching / Destructuring")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/module/" target="_blank"> {Node.text("Modules")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/api/" target="_blank"> {Node.text("API Reference")} </a>
      </li>
    </ul>
    <p>
      {Node.text("Once this page feels familiar, the best next step inside Xote's docs is ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
      {Node.text(", then ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(".")}
    </p>
  </div>
}
