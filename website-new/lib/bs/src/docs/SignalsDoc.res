// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Signals")} </h1>
    <p>
      {Component.text("Signals are the foundation of reactive state in Xote. A signal is a reactive state container that automatically notifies its dependents when its value changes.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Component.text("Info:")} </strong>
      {Component.text(" Xote re-exports ")}
      <code> {Component.text("Signal")} </code>
      {Component.text(", ")}
      <code> {Component.text("Computed")} </code>
      {Component.text(", and ")}
      <code> {Component.text("Effect")} </code>
      {Component.text(" from ")}
      <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(". The API and behavior are provided by that library.")}
      </p>
    </div>
    <h2> {Component.text("Creating Signals")} </h2>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Signal.make()")} </code>
      {Component.text(" to create a new signal with an initial value:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

let count = Signal.make(0)
let name = Signal.make("Alice")
let isActive = Signal.make(true)`)}
      </code>
    </pre>
    <h2> {Component.text("Reading Signal Values")} </h2>
    <h3> <code> {Component.text("Signal.get()")} </code> </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Signal.get()")} </code>
      {Component.text(" to read a signal's value. When called inside a tracking context (like an effect or computed value), it automatically registers the signal as a dependency:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(5)
let value = Signal.get(count) // Returns 5`)}
      </code>
    </pre>
    <h3> <code> {Component.text("Signal.peek()")} </code> </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Signal.peek()")} </code>
      {Component.text(" to read a signal's value without creating a dependency:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(5)

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
    <h2> {Component.text("Updating Signals")} </h2>
    <h3> <code> {Component.text("Signal.set()")} </code> </h3>
    <p>
      {Component.text("Replace a signal's value entirely:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
Signal.set(count, 10) // count is now 10`)}
      </code>
    </pre>
    <h3> <code> {Component.text("Signal.update()")} </code> </h3>
    <p>
      {Component.text("Update a signal based on its current value:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2`)}
      </code>
    </pre>
    <h2> {Component.text("Important Behaviors")} </h2>
    <h3> {Component.text("Structural Equality Check")} </h3>
    <p>
      {Component.text("Signals use structural equality (")}
      <code> {Component.text("==")} </code>
      {Component.text(") to check if a value has changed. If the new value equals the old value, dependents are not notified:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(5)

Effect.run(() => {
  Console.log(Signal.get(count))
})

Signal.set(count, 5) // Effect does NOT run - value didn't change
Signal.set(count, 6) // Effect runs - value changed`)}
      </code>
    </pre>
    <p>
      {Component.text("This prevents unnecessary updates and helps avoid accidental infinite loops in reactive code.")}
    </p>
    <h3> {Component.text("Automatic Dependency Tracking")} </h3>
    <p>
      {Component.text("When you call ")}
      <code> {Component.text("Signal.get()")} </code>
      {Component.text(" inside a tracking context, the dependency is automatically registered:")}
    </p>
    <pre>
      <code>
        {Component.text(`let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// This computed automatically depends on both firstName and lastName
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)`)}
      </code>
    </pre>
    <h2> {Component.text("Example: Counter")} </h2>
    <p>
      {Component.text("Here's a complete example showing signals in action:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

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
      {Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </h1>
    <button onClick={increment}>
      {Component.text("+")}
    </button>
    <button onClick={decrement}>
      {Component.text("-")}
    </button>
    <button onClick={reset}>
      {Component.text("Reset")}
    </button>
  </div>
}

Component.mountById(app(), "app")`)}
      </code>
    </pre>
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Keep signals focused:")} </strong>
      {Component.text(" Each signal should represent a single piece of state")}
      </li>
      <li>
        <strong> {Component.text("Use peek() to avoid dependencies:")} </strong>
      {Component.text(" When you need to read a value without tracking, use peek()")}
      </li>
      <li>
        <strong> {Component.text("Prefer update() over get() + set():")} </strong>
      {Component.text(" It's more concise and clearer in intent")}
      </li>
    </ul>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/computed", ~children=[Component.text("Computed Values")], ())}
      {Component.text(" for derived state")}
      </li>
      <li>
        {Component.text("Understand ")}
      {Router.link(~to="/docs/core-concepts/effects", ~children=[Component.text("Effects")], ())}
      {Component.text(" for side effects")}
      </li>
      <li>
        {Component.text("See the ")}
      {Router.link(~to="/docs/api/signals", ~children=[Component.text("API Reference")], ())}
      {Component.text(" for complete signal API")}
      </li>
    </ul>
  </div>
}
