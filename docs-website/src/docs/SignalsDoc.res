// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("Signals are the state primitive in Xote. A signal stores a value, tracks who reads it, and notifies dependents when the value actually changes.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {View.text("Info:")} </strong>
        {View.text(" Xote re-exports ")}
        <code> {View.text("Signal")} </code>
        {View.text(", ")}
        <code> {View.text("Computed")} </code>
        {View.text(", and ")}
        <code> {View.text("Effect")} </code>
        {View.text(" from ")}
        <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {View.text("rescript-signals")} </a>
        {View.text(".")}
      </p>
    </div>

    <h2 id="working-with-signals"> {View.text("Working with Signals")} </h2>
    <h3 id="creating-signals"> {View.text("Creating Signals")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("Signal.make")} </code>
      {View.text(" to create a signal. You can optionally pass ")}
      <code> {View.text("~name")} </code>
      {View.text(" for debugging and ")}
      <code> {View.text("~equals")} </code>
      {View.text(" when the default equality is not enough.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = Signal.make(0)
let userName = Signal.make("Ada", ~name="user-name")
let settings = Signal.make({
  theme: "dark",
  compact: false,
})`)}
      </code>
    </pre>

    <h3 id="reading-signal-values"> {View.text("Reading Signal Values")} </h3>
    <p>
      {View.text("There are two read modes. Choose based on whether the current code should subscribe to future updates.")}
    </p>
    <h4 id="signal-get"> <code> {View.text("Signal.get()")} </code> </h4>
    <p>
      {View.text("Use ")}
      <code> {View.text("Signal.get")} </code>
      {View.text(" inside a computed, effect, or reactive node when the current code should re-run if the signal changes.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let firstName = Signal.make("Ada")
let lastName = Signal.make("Lovelace")

let fullName = Computed.make(() =>
  \`\${Signal.get(firstName)} \${Signal.get(lastName)}\`
)`)}
      </code>
    </pre>
    <h4 id="signal-peek"> <code> {View.text("Signal.peek()")} </code> </h4>
    <p>
      {View.text("Use ")}
      <code> {View.text("Signal.peek")} </code>
      {View.text(" when you need the current value without subscribing. This is useful for logging, snapshots, and one-off reads inside effects.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Effect.run(() => {
  let tracked = Signal.get(count)
  let snapshot = Signal.peek(settings)

  Console.log2("Tracked count:", tracked)
  Console.log2("Current theme:", snapshot.theme)
  None
})`)}
      </code>
    </pre>

    <h3 id="updating-signals"> {View.text("Updating Signals")} </h3>
    <h4 id="signal-set"> <code> {View.text("Signal.set()")} </code> </h4>
    <p>
      {View.text("Use ")}
      <code> {View.text("Signal.set")} </code>
      {View.text(" when you already know the next value.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.set(count, 10)
Signal.set(userName, "Grace")`)}
      </code>
    </pre>
    <h4 id="signal-update"> <code> {View.text("Signal.update()")} </code> </h4>
    <p>
      {View.text("Use ")}
      <code> {View.text("Signal.update")} </code>
      {View.text(" when the next value depends on the current one. This keeps the intent obvious and avoids an extra read.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.update(count, n => n + 1)

Signal.update(settings, current => {
  ...current,
  compact: !current.compact,
})`)}
      </code>
    </pre>

    <h2 id="how-signals-decide-to-update"> {View.text("How Signals Decide to Update")} </h2>
    <h3 id="equality-and-change-detection"> {View.text("Equality and Change Detection")} </h3>
    <p>
      {View.text("Signals only notify dependents when the new value is considered different from the current value. By default that check uses JavaScript strict equality, ")}
      <code> {View.text("===")} </code>
      {View.text(".")}
    </p>
    <h4 id="default-equality"> {View.text("Default Equality")} </h4>
    <p>
      {View.text("For primitives, setting the same value is a no-op. For arrays, records, and objects, a new reference counts as a change even when the fields look the same.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = Signal.make(5)

Signal.set(count, 5) // No update
Signal.set(count, 6) // Notifies dependents

let items = Signal.make([1, 2, 3])
Signal.set(items, [1, 2, 3]) // New array reference, so this updates`)}
      </code>
    </pre>
    <h4 id="custom-equality"> {View.text("Custom Equality")} </h4>
    <p>
      {View.text("When you want value-based comparison for compound data, pass ")}
      <code> {View.text("~equals")} </code>
      {View.text(" to ")}
      <code> {View.text("Signal.make")} </code>
      {View.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type position = {x: int, y: int}

let position = Signal.make(
  {x: 0, y: 0},
  ~equals=(a, b) => a.x == b.x && a.y == b.y,
)

Signal.set(position, {x: 0, y: 0}) // No update
Signal.set(position, {x: 0, y: 1}) // Update`)}
      </code>
    </pre>

    <h3 id="dependency-tracking"> {View.text("Dependency Tracking")} </h3>
    <p>
      {View.text("Every ")}
      <code> {View.text("Signal.get")} </code>
      {View.text(" call inside an active computed or effect becomes a dependency. On the next run, dependencies are cleared and tracked again, so the graph follows control flow instead of staying fixed forever.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let useMetric = Signal.make(true)
let celsius = Signal.make(20)
let fahrenheit = Signal.make(68)

let temperature = Computed.make(() =>
  if Signal.get(useMetric) {
    Signal.get(celsius)
  } else {
    Signal.get(fahrenheit)
  }
)`)}
      </code>
    </pre>

    <h2 id="signals-in-practice"> {View.text("In Practice")} </h2>
    <h3 id="example-counter"> {View.text("Example: Counter")} </h3>
    <p>
      {View.text("This is the same pattern most Xote state starts with: a signal, a few updates, and a reactive view read in the UI.")}
    </p>
    <DocsExamplePanel
      filename="Counter.res"
      caption="fig. 1 - a counter driven by one signal"
      code={`open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}

let decrement = (_evt: Dom.event) => {
  Signal.update(count, n => n - 1)
}

let reset = (_evt: Dom.event) => {
  Signal.set(count, 0)
}

let app = () => {
  <div>
    <h1>
      {View.signalText(() => \`Count: \${Signal.get(count)->Int.toString}\`)}
    </h1>
    <button onClick={increment}>
      {View.text("+")}
    </button>
    <button onClick={decrement}>
      {View.text("-")}
    </button>
    <button onClick={reset}>
      {View.text("Reset")}
    </button>
  </div>
}

View.mountById(app(), "app")`}
    >
      <CounterDemo />
    </DocsExamplePanel>

    <h2 id="signals-working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Keep one signal focused on one job. A small record is fine; a grab-bag of unrelated state is not.")}
      </li>
      <li>
        {View.text("Prefer ")}
        <code> {View.text("Signal.update")} </code>
        {View.text(" when the next value depends on the current one.")}
      </li>
      <li>
        {View.text("Treat ")}
        <code> {View.text("Signal.peek")} </code>
        {View.text(" as a snapshot tool, not your default read API.")}
      </li>
      <li>
        {View.text("Add custom equality only when strict equality creates real noise in the UI or effects.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[View.text("Read Computeds")], ())}
        {View.text(" if the next question is how to derive state instead of storing it twice.")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[View.text("Read Effects")], ())}
        {View.text(" if you need to connect signals to timers, network requests, or browser APIs.")}
      </li>
      <li>
        {Router.link(~to="/docs/api/signals", ~children=[View.text("Use the Signals API reference")], ())}
        {View.text(" when you want signatures and quick examples.")}
      </li>
    </ul>
  </div>
}
