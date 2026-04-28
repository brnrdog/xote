// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/getting-started/learning-rescript.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("ReScript compiles to readable JavaScript and fits into the same runtime, npm packages, and tooling you already use. What it changes is how precisely you can model data and program behavior before the code ships.")}
    </p>
    <h2 id="a-first-look"> {View.text("A First Look")} </h2>
    <p>
      {View.text("The point of ReScript is not just that types are nice. It gives you a way to model real program states so the compiler can enforce rules you would otherwise keep in your head.")}
    </p>
    <p>
      {View.text("In many codebases, a value like this ends up spread across string values, nullable fields, and defensive checks. It works until one branch is forgotten during a refactor. ReScript pushes that information into the type itself:")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type user =
  | Guest
  | SignedIn(string)
  | Banned(string)

let greeting = user =>
  switch user {
  | Guest => "Welcome, stranger"
  | SignedIn(name) => \`Hello, \${name}\`
  | Banned(reason) => \`Access denied: \${reason}\`
  }`)}
      </code>
    </pre>
    <p>
      {View.text("A few things matter here:")}
    </p>
    <ul>
      <li>
        <code> {View.text("type user")} </code>
      {View.text(" declares a *variant* — a closed set of cases. The compiler knows every value ")}
      <code> {View.text("user")} </code>
      {View.text(" can hold.")}
      </li>
      <li>
        <code> {View.text("switch")} </code>
      {View.text(" matches each case directly. Add a new case to ")}
      <code> {View.text("user")} </code>
      {View.text(" later (say, ")}
      <code> {View.text("Suspended")} </code>
      {View.text("), and the compiler points out every ")}
      <code> {View.text("switch")} </code>
      {View.text(" that no longer covers the type.")}
      </li>
      <li>
        {View.text("The function reads like straightforward application code, but the guarantees are stronger: there is no ambiguity about what shape can arrive at runtime.")}
      </li>
      <li>
        {View.text("Types are inferred, so ")}
      <code> {View.text("greeting")} </code>
      {View.text(" does not need an annotation. You get compiler help without turning the example into a wall of type syntax.")}
      </li>
      <li>
        {View.text("Template strings use backticks and ")}
      <code> {View.text("\${...}")} </code>
      {View.text(" for interpolation, like in modern JavaScript.")}
      </li>
    </ul>
    <p>
      {View.text("This is the practical case for ReScript: instead of relying on conventions, comments, or discipline to keep state handling correct, you encode the valid cases once and let the compiler enforce them everywhere.")}
    </p>
    <p>
      {View.text("Exhaustiveness checking is on by default. You cannot ship a ")}
      <code> {View.text("switch")} </code>
      {View.text(" with a missing case, which removes a whole class of forgotten-state bugs before the code runs.")}
    </p>
    <h2 id="let-bindings-and-functions"> {View.text("Let Bindings and Functions")} </h2>
    <p>
      {View.text("Most values are declared with ")}
      <code> {View.text("let")} </code>
      {View.text(". Functions take their arguments in parentheses.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = 1
let add = (a, b) => a + b

let total = add(count, 41)`)}
      </code>
    </pre>
    <p>
      {View.text("Bindings are immutable by default. That usually makes code easier to follow because values do not quietly change underneath you.")}
    </p>
    <h2 id="records-and-variants"> {View.text("Records and Variants")} </h2>
    <p>
      {View.text("Records are object-like data with known fields. Variants are a fixed set of cases.")}
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
      {View.text("Variants are especially useful anywhere a value can be in one of several known states. You model the allowed cases once, then the compiler checks every place that consumes them.")}
    </p>
    <h2 id="pattern-matching-with-switch"> {View.text("Pattern Matching with switch")} </h2>
    <p>
      <code> {View.text("switch")} </code>
      {View.text(" is the main branching construct. It handles destructuring and case coverage in one place.")}
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
      {View.text("If you add a new variant case later, the compiler points out every ")}
      <code> {View.text("switch")} </code>
      {View.text(" that needs updating. The same applies when you match on records, tuples, or nested data:")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type role =
  | Guest
  | Member
  | Admin

type page =
  | Home
  | Settings

let canView = (role, page) =>
  switch (role, page) {
  | (Guest, Home) => true
  | (Guest, Settings) => false
  | (Member, _) => true
  | (Admin, _) => true
  }`)}
      </code>
    </pre>
    <p>
      <code> {View.text("switch")} </code>
      {View.text(" here matches a tuple of two variants. That is useful whenever behavior depends on more than one piece of state at once.")}
    </p>
    <h2 id="options-instead-of-null"> {View.text("Options Instead of null")} </h2>
    <p>
      {View.text("Missing values use ")}
      <code> {View.text("option<'a>")} </code>
      {View.text(", with two cases: ")}
      <code> {View.text("Some(value)")} </code>
      {View.text(" and ")}
      <code> {View.text("None")} </code>
      {View.text(".")}
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
      {View.text("This changes day-to-day code in a few practical ways:")}
    </p>
    <ul>
      <li>
        {View.text("Missing values are explicit in the type, so you can see right away which values need handling.")}
      </li>
      <li>
        {View.text("You cannot accidentally read through ")}
      <code> {View.text("undefined")} </code>
      {View.text(" at runtime. The compiler makes you handle ")}
      <code> {View.text("None")} </code>
      {View.text(" first.")}
      </li>
      <li>
        {View.text("There is one absence model instead of juggling ")}
      <code> {View.text("null")} </code>
      {View.text(", ")}
      <code> {View.text("undefined")} </code>
      {View.text(", and missing keys.")}
      </li>
    </ul>
    <p>
      {View.text("You will see this often in optional arguments, lookups, and decoded data.")}
    </p>
    <h2 id="modules-and-files"> {View.text("Modules and Files")} </h2>
    <p>
      {View.text("Each file becomes a module. A file named ")}
      <code> {View.text("Counter.res")} </code>
      {View.text(" exposes its values under ")}
      <code> {View.text("Counter")} </code>
      {View.text(".")}
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
      {View.text("You get namespacing by default, which keeps larger codebases from turning into import and naming sprawl.")}
    </p>
    <h2 id="why-its-worth-it"> {View.text("Why It's Worth It")} </h2>
    <p>
      {View.text("Once the syntax clicks, the benefits are mostly about reducing ambiguity in the code:")}
    </p>
    <ul>
      <li>
        {View.text("You model state directly instead of spreading it across booleans, strings, and nullable fields.")}
      </li>
      <li>
        {View.text("Refactors are safer because the compiler shows you every affected branch.")}
      </li>
      <li>
        <code> {View.text("option")} </code>
      {View.text(" removes a large class of ")}
      <code> {View.text("null")} </code>
      {View.text(" and ")}
      <code> {View.text("undefined")} </code>
      {View.text(" bugs.")}
      </li>
      <li>
        {View.text("Types are inferred, so the code stays compact.")}
      </li>
      <li>
        {View.text("The output still fits naturally into existing JavaScript tooling.")}
      </li>
    </ul>
    <p>
      {View.text("The payoff gets bigger as the codebase grows. The more branches, edge cases, and moving parts you have, the more valuable those guarantees become.")}
    </p>
    <h2 id="adding-rescript-incrementally"> {View.text("Adding ReScript Incrementally")} </h2>
    <p>
      {View.text("You do not need a rewrite to try it:")}
    </p>
    <ul>
      <li>
        {View.text("A JS or TS app can import modules compiled from ReScript.")}
      </li>
      <li>
        {View.text("ReScript targets the same runtime, bundler, and npm packages as the rest of your app.")}
      </li>
      <li>
        {View.text("You can adopt it one module, feature, or library at a time.")}
      </li>
    </ul>
    <p>
      {View.text("That makes it easy to start with one bounded part of a codebase and expand only if it proves useful.")}
    </p>
    <h2 id="keep-learning"> {View.text("Keep Learning")} </h2>
    <p>
      {View.text("The official ReScript site covers the full language and toolchain:")}
    </p>
    <ul>
      <li>
        <a href="https://rescript-lang.org/docs/manual/v12.0.0/introduction" target="_blank"> {View.text("Introduction")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/overview" target="_blank"> {View.text("Overview")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/pattern-matching-destructuring/" target="_blank"> {View.text("Pattern Matching / Destructuring")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/module/" target="_blank"> {View.text("Modules")} </a>
      </li>
      <li>
        <a href="https://rescript-lang.org/docs/manual/api/" target="_blank"> {View.text("API Reference")} </a>
      </li>
    </ul>
    <p>
      {View.text("Once this page feels familiar, the next step inside Xote's docs is ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Signals")], ())}
      {View.text(", then ")}
      {Router.link(~to="/docs/view/overview", ~children=[View.text("View")], ())}
      {View.text(".")}
    </p>
  </div>
}
