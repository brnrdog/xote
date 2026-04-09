// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Signals")} </h1>
    <p>
      {Node.text("Signals are the foundation of reactive state in Xote. A signal is a reactive state container that automatically notifies its dependents when its value changes.")}
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
      {Node.text(". The API and behavior are provided by that library.")}
      </p>
    </div>
    <h2 id="creating-signals"> {Node.text("Creating Signals")} </h2>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.make()")} </code>
      {Node.text(" to create a new signal with an initial value:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

let count = Signal.make(0)
let name = Signal.make("Alice")
let isActive = Signal.make(true)`)}
      </code>
    </pre>
    <h2 id="reading-signal-values"> {Node.text("Reading Signal Values")} </h2>
    <h3 id="signal-get"> <code> {Node.text("Signal.get()")} </code> </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.get()")} </code>
      {Node.text(" to read a signal's value. When called inside a tracking context (like an effect or computed value), it automatically registers the signal as a dependency:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)
let value = Signal.get(count) // Returns 5`)}
      </code>
    </pre>
    <h3 id="signal-peek"> <code> {Node.text("Signal.peek()")} </code> </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.peek()")} </code>
      {Node.text(" to read a signal's value without creating a dependency:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)

Effect.run(() => {
  // This creates a dependency
  let current = Signal.get(count)

  // This does NOT create a dependency
  let peeked = Signal.peek(count)

  Console.log2("Current:", current)
  Console.log2("Peeked:", peeked)
})`)}
      </code>
    </pre>
    <h2 id="updating-signals"> {Node.text("Updating Signals")} </h2>
    <h3 id="signal-set"> <code> {Node.text("Signal.set()")} </code> </h3>
    <p>
      {Node.text("Replace a signal's value entirely:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
Signal.set(count, 10) // count is now 10`)}
      </code>
    </pre>
    <h3 id="signal-update"> <code> {Node.text("Signal.update()")} </code> </h3>
    <p>
      {Node.text("Update a signal based on its current value:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2`)}
      </code>
    </pre>
    <h2 id="important-behaviors"> {Node.text("Important Behaviors")} </h2>
    <h3 id="structural-equality-check"> {Node.text("Structural Equality Check")} </h3>
    <p>
      {Node.text("Signals use structural equality (")}
      <code> {Node.text("==")} </code>
      {Node.text(") to check if a value has changed. If the new value equals the old value, dependents are not notified:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)

Effect.run(() => {
  Console.log(Signal.get(count))
})

Signal.set(count, 5) // Effect does NOT run - value didn't change
Signal.set(count, 6) // Effect runs - value changed`)}
      </code>
    </pre>
    <p>
      {Node.text("This prevents unnecessary updates and helps avoid accidental infinite loops in reactive code.")}
    </p>
    <h3 id="custom-equality-check"> {Node.text("Custom Equality Check")} </h3>
    <p>
      {Node.text("By default, signals use strict referential equality (")}
      <code> {Node.text("===")} </code>
      {Node.text(") to determine if a value has changed. For complex types like records or objects where structurally equivalent values may have different references, you can provide a custom equality function via the ")}
      <code> {Node.text("~equals")} </code>
      {Node.text(" parameter:")}
    </p>
    <pre>
      <code>
        {Node.text(`type position = { x: int, y: int }

// Without custom equality: every set() triggers updates,
// even if x and y are the same
let pos1 = Signal.make({ x: 0, y: 0 })

// With custom equality: only triggers updates when
// x or y actually change
let pos2 = Signal.make(
  { x: 0, y: 0 },
  ~equals=(a, b) => a.x == b.x && a.y == b.y,
)

Effect.run(() => {
  let { x, y } = Signal.get(pos2)
  Console.log(\`Position: \${Int.toString(x)}, \${Int.toString(y)}\`)
  None
})

// This will NOT trigger the effect - values are equal
Signal.set(pos2, { x: 0, y: 0 })

// This WILL trigger the effect - y changed
Signal.set(pos2, { x: 0, y: 1 })`)}
      </code>
    </pre>
    <p>
      {Node.text("Custom equality is useful when working with records, tuples, or other compound types where you want to compare by value rather than by reference.")}
    </p>
    <h3 id="automatic-dependency-tracking"> {Node.text("Automatic Dependency Tracking")} </h3>
    <p>
      {Node.text("When you call ")}
      <code> {Node.text("Signal.get()")} </code>
      {Node.text(" inside a tracking context, the dependency is automatically registered:")}
    </p>
    <pre>
      <code>
        {Node.text(`let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// This computed automatically depends on both firstName and lastName
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)`)}
      </code>
    </pre>
    <h2 id="example-counter"> {Node.text("Example: Counter")} </h2>
    <p>
      {Node.text("Here's a complete example showing signals in action:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

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
      {Node.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </h1>
    <button onClick={increment}>
      {Node.text("+")}
    </button>
    <button onClick={decrement}>
      {Node.text("-")}
    </button>
    <button onClick={reset}>
      {Node.text("Reset")}
    </button>
  </div>
}

Node.mountById(app(), "app")`)}
      </code>
    </pre>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Keep signals focused:")} </strong>
      {Node.text(" Each signal should represent a single piece of state")}
      </li>
      <li>
        <strong> {Node.text("Use peek() to avoid dependencies:")} </strong>
      {Node.text(" When you need to read a value without tracking, use peek()")}
      </li>
      <li>
        <strong> {Node.text("Prefer update() over get() + set():")} </strong>
      {Node.text(" It's more concise and clearer in intent")}
      </li>
    </ul>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Computed Values")], ())}
      {Node.text(" for derived state")}
      </li>
      <li>
        {Node.text("Understand ")}
      {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects")], ())}
      {Node.text(" for side effects")}
      </li>
      <li>
        {Node.text("See the ")}
      {Router.link(~to="/docs/api/signals", ~children=[Node.text("API Reference")], ())}
      {Node.text(" for complete signal API")}
      </li>
    </ul>
  </div>
}
