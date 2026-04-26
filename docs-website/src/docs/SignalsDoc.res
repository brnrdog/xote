// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("Signals are the state primitive in Xote. A signal stores a value, tracks who reads it, and notifies dependents when the value actually changes.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Info:")} </strong>
        {Node.text(" Xote re-exports ")}
        <code> {Node.text("Signal")} </code>
        {Node.text(", ")}
        <code> {Node.text("Computed")} </code>
        {Node.text(", and ")}
        <code> {Node.text("Effect")} </code>
        {Node.text(" from ")}
        <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
        {Node.text(".")}
      </p>
    </div>

    <h2 id="working-with-signals"> {Node.text("Working with Signals")} </h2>
    <h3 id="creating-signals"> {Node.text("Creating Signals")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.make")} </code>
      {Node.text(" to create a signal. You can optionally pass ")}
      <code> {Node.text("~name")} </code>
      {Node.text(" for debugging and ")}
      <code> {Node.text("~equals")} </code>
      {Node.text(" when the default equality is not enough.")}
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

    <h3 id="reading-signal-values"> {Node.text("Reading Signal Values")} </h3>
    <p>
      {Node.text("There are two read modes. Choose based on whether the current code should subscribe to future updates.")}
    </p>
    <h4 id="signal-get"> <code> {Node.text("Signal.get()")} </code> </h4>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.get")} </code>
      {Node.text(" inside a computed, effect, or reactive node when the current code should re-run if the signal changes.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let firstName = Signal.make("Ada")
let lastName = Signal.make("Lovelace")

let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)`)}
      </code>
    </pre>
    <h4 id="signal-peek"> <code> {Node.text("Signal.peek()")} </code> </h4>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.peek")} </code>
      {Node.text(" when you need the current value without subscribing. This is useful for logging, snapshots, and one-off reads inside effects.")}
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

    <h3 id="updating-signals"> {Node.text("Updating Signals")} </h3>
    <h4 id="signal-set"> <code> {Node.text("Signal.set()")} </code> </h4>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.set")} </code>
      {Node.text(" when you already know the next value.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.set(count, 10)
Signal.set(userName, "Grace")`)}
      </code>
    </pre>
    <h4 id="signal-update"> <code> {Node.text("Signal.update()")} </code> </h4>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.update")} </code>
      {Node.text(" when the next value depends on the current one. This keeps the intent obvious and avoids an extra read.")}
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

    <h2 id="how-signals-decide-to-update"> {Node.text("How Signals Decide to Update")} </h2>
    <h3 id="equality-and-change-detection"> {Node.text("Equality and Change Detection")} </h3>
    <p>
      {Node.text("Signals only notify dependents when the new value is considered different from the current value. By default that check uses JavaScript strict equality, ")}
      <code> {Node.text("===")} </code>
      {Node.text(".")}
    </p>
    <h4 id="default-equality"> {Node.text("Default Equality")} </h4>
    <p>
      {Node.text("For primitives, setting the same value is a no-op. For arrays, records, and objects, a new reference counts as a change even when the fields look the same.")}
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
    <h4 id="custom-equality"> {Node.text("Custom Equality")} </h4>
    <p>
      {Node.text("When you want value-based comparison for compound data, pass ")}
      <code> {Node.text("~equals")} </code>
      {Node.text(" to ")}
      <code> {Node.text("Signal.make")} </code>
      {Node.text(".")}
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

    <h3 id="dependency-tracking"> {Node.text("Dependency Tracking")} </h3>
    <p>
      {Node.text("Every ")}
      <code> {Node.text("Signal.get")} </code>
      {Node.text(" call inside an active computed or effect becomes a dependency. On the next run, dependencies are cleared and tracked again, so the graph follows control flow instead of staying fixed forever.")}
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

    <h2 id="signals-in-practice"> {Node.text("In Practice")} </h2>
    <h3 id="example-counter"> {Node.text("Example: Counter")} </h3>
    <p>
      {Node.text("This is the same pattern most Xote state starts with: a signal, a few updates, and a reactive view read in the UI.")}
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
      {View.computedText(() => "Count: " ++ Int.toString(Signal.get(count)))}
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

    <h2 id="signals-working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Keep one signal focused on one job. A small record is fine; a grab-bag of unrelated state is not.")}
      </li>
      <li>
        {Node.text("Prefer ")}
        <code> {Node.text("Signal.update")} </code>
        {Node.text(" when the next value depends on the current one.")}
      </li>
      <li>
        {Node.text("Treat ")}
        <code> {Node.text("Signal.peek")} </code>
        {Node.text(" as a snapshot tool, not your default read API.")}
      </li>
      <li>
        {Node.text("Add custom equality only when strict equality creates real noise in the UI or effects.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Read Computeds")], ())}
        {Node.text(" if the next question is how to derive state instead of storing it twice.")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Read Effects")], ())}
        {Node.text(" if you need to connect signals to timers, network requests, or browser APIs.")}
      </li>
      <li>
        {Router.link(~to="/docs/api/signals", ~children=[Node.text("Use the Signals API reference")], ())}
        {Node.text(" when you want signatures and quick examples.")}
      </li>
    </ul>
  </div>
}
