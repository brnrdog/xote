open Xote

let content = () => {
  <div>
    <h1> {Component.text("Batching Updates")} </h1>
    <div class="warning-box">
      <p>
        <strong> {Component.text("Warning: Not Currently Available")} </strong>
      </p>
      <p>
        {Component.text(
          "Batching is not currently available in Xote as the underlying rescript-signals library does not expose batching functionality. This page is kept for reference and may be implemented in a future version.",
        )}
      </p>
    </div>
    <p>
      {Component.text(
        "By default, effects and computed values run synchronously when signals change. Batching would allow grouping multiple updates to defer observer execution until the batch completes.",
      )}
    </p>
    <h2> {Component.text("Why Batch?")} </h2>
    <p> {Component.text("Without batching, each signal update triggers observers immediately:")} </p>
    <pre>
      <code>
        {Component.text(`let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

Effect.run(() => {
  Console.log(Signal.get(fullName))
})

// Without batching
Signal.set(firstName, "Jane")  // Logs: "Jane Doe"
Signal.set(lastName, "Smith")  // Logs: "Jane Smith"
// Effect runs twice, computed recalculates twice`)}
      </code>
    </pre>
    <p> {Component.text("With batching, observers would run once after all updates:")} </p>
    <pre>
      <code>
        {Component.text(`Core.batch(() => {
  Signal.set(firstName, "Jane")  // Queued
  Signal.set(lastName, "Smith")  // Queued
})
// Would log: "Jane Smith" (only once)
// Effect would run once, computed would recalculate once`)}
      </code>
    </pre>
    <h2> {Component.text("How Batching Would Work")} </h2>
    <p> {Component.text("If batching were available:")} </p>
    <ol>
      <li> {Component.text("When Core.batch() is called, the batching flag would be set")} </li>
      <li> {Component.text("Signal updates would queue their observers instead of running them immediately")} </li>
      <li> {Component.text("When the batch function completes, all queued observers would run")} </li>
      <li> {Component.text("Each observer would run only once, even if multiple dependencies changed")} </li>
    </ol>
    <h2> {Component.text("When Batching Would Be Useful")} </h2>
    <p> {Component.text("Batching would be beneficial when:")} </p>
    <ul>
      <li>
        <strong> {Component.text("Updating multiple related signals:")} </strong>
        {Component.text(" Form state, coordinates, settings")}
      </li>
      <li>
        <strong> {Component.text("Performing complex state transitions:")} </strong>
        {Component.text(" Multi-step updates that should appear atomic")}
      </li>
      <li>
        <strong> {Component.text("Optimizing performance:")} </strong>
        {Component.text(" Reducing unnecessary recomputations")}
      </li>
      <li>
        <strong> {Component.text("Maintaining consistency:")} </strong>
        {Component.text(" Ensuring observers see a consistent state")}
      </li>
    </ul>
    <h2> {Component.text("Current Workarounds")} </h2>
    <p>
      {Component.text(
        "Without batching, you can minimize updates by using single signal updates when possible:",
      )}
    </p>
    <pre>
      <code>
        {Component.text(`// Instead of multiple signals
let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// Use a single signal for related data
type person = {
  firstName: string,
  lastName: string,
}

let person = Signal.make({
  firstName: "John",
  lastName: "Doe",
})

// Update both at once
Signal.set(person, {firstName: "Jane", lastName: "Smith"})`)}
      </code>
    </pre>
    <h3> {Component.text("Structural Equality Helps")} </h3>
    <p>
      {Component.text(
        "Xote's signals use structural equality checks, which prevents unnecessary updates when values don't actually change:",
      )}
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
    <h2> {Component.text("Future Implementation")} </h2>
    <p>
      {Component.text(
        "If batching becomes available in rescript-signals, it would likely be exposed through:",
      )}
    </p>
    <ul>
      <li>
        <code> {Component.text("Core.batch(() => { ... })")} </code>
        {Component.text(" - Batch multiple signal updates")}
      </li>
      <li> {Component.text("Nested batching support")} </li>
      <li> {Component.text("Return value support from batch functions")} </li>
    </ul>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Learn about ")}
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Component.text("Effects")], ())}
        {Component.text(" for reactive side effects")}
      </li>
      <li>
        {Component.text("See ")}
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
        {Component.text(" for building UIs with Xote")}
      </li>
      <li>
        {Component.text("Check the ")}
        <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank">
          {Component.text("rescript-signals")}
        </a>
        {Component.text(" repository for updates on batching support")}
      </li>
    </ul>
  </div>
}
