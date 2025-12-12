// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/batching.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Batching Updates")} </h1>
    <p>
      {Component.text("Batching allows you to group multiple signal updates together, ensuring that observers (effects and computed values) run only once after all updates complete, rather than after each individual update.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Component.text("Info:")} </strong>
      {Component.text(" Batching is available through ")}
      <code> {Component.text("Signal.batch")} </code>
      {Component.text(" which is re-exported from ")}
      <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(".")}
      </p>
    </div>
    <h2> {Component.text("Why Batch?")} </h2>
    <p>
      {Component.text("Without batching, each signal update triggers observers immediately:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

Effect.run(() => {
  Console.log(Signal.get(fullName))
  None
})

// Without batching
Signal.set(firstName, "Jane")  // Logs: "Jane Doe"
Signal.set(lastName, "Smith")  // Logs: "Jane Smith"
// Effect runs twice, computed recalculates twice`)}
      </code>
    </pre>
    <p>
      {Component.text("With batching, observers run once after all updates:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`Signal.batch(() => {
  Signal.set(firstName, "Jane")  // Queued
  Signal.set(lastName, "Smith")  // Queued
})
// Logs: "Jane Smith" (only once)
// Effect runs once, computed recalculates once`)}
      </code>
    </pre>
    <h2> {Component.text("Using Signal.batch()")} </h2>
    <p>
      {Component.text("Wrap multiple signal updates in a batch:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`open Xote

let x = Signal.make(0)
let y = Signal.make(0)

Effect.run(() => {
  Console.log2("Position:", (Signal.get(x), Signal.get(y)))
  None
})

// Update both coordinates together
Signal.batch(() => {
  Signal.set(x, 10)
  Signal.set(y, 20)
})
// Logs only once: "Position: (10, 20)"`)}
      </code>
    </pre>
    <h2> {Component.text("How Batching Works")} </h2>
    <ol>
      <li>
        {Component.text("When Signal.batch() is called, a batching flag is set")}
      </li>
      <li>
        {Component.text("Signal updates queue their observers instead of running them immediately")}
      </li>
      <li>
        {Component.text("When the batch function completes, all queued observers run")}
      </li>
      <li>
        {Component.text("Each observer runs only once, even if multiple dependencies changed")}
      </li>
    </ol>
    <h2> {Component.text("Example: Form Updates")} </h2>
    <p>
      {Component.text("Batching is especially useful when updating related state:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`type formData = {
  name: string,
  email: string,
  age: int,
}

let form = Signal.make({
  name: "",
  email: "",
  age: 0,
})

let errors = Computed.make(() => {
  let data = Signal.get(form)
  let errors = []

  if String.length(data.name) == 0 {
    errors->Array.push("Name is required")
  }
  if String.length(data.email) == 0 {
    errors->Array.push("Email is required")
  }
  if data.age < 18 {
    errors->Array.push("Must be 18 or older")
  }

  errors
})

// Update form fields together
let handleSubmit = () => {
  Signal.batch(() => {
    Signal.update(form, f => {...f, name: "Alice"})
    Signal.update(form, f => {...f, email: "alice@example.com"})
    Signal.update(form, f => {...f, age: 25})
  })
  // Validation runs once after all updates
}`)}
      </code>
    </pre>
    <h2> {Component.text("Nested Batches")} </h2>
    <p>
      {Component.text("Batches can be nested. The observers run when the outermost batch completes:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`let count = Signal.make(0)

Effect.run(() => {
  Console.log(Signal.get(count))
  None
})

Signal.batch(() => {
  Signal.set(count, 1)

  Signal.batch(() => {
    Signal.set(count, 2)
  })
  // No effect runs yet

  Signal.set(count, 3)
})
// Effect runs once: logs "3"`)}
      </code>
    </pre>
    <h2> {Component.text("Returning Values from Batches")} </h2>
    <p>
      <code> {Component.text("Signal.batch()")} </code>
      {Component.text(" returns the result of the batch function:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`let result = Signal.batch(() => {
  Signal.set(count, 10)
  Signal.set(name, "Alice")
  "Success"
})

Console.log(result) // "Success"`)}
      </code>
    </pre>
    <h2> {Component.text("When to Use Batching")} </h2>
    <p>
      {Component.text("Use batching when:")}
    </p>
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
    <p>
      {Component.text("Don't batch when:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Single signal updates:")} </strong>
      {Component.text(" No benefit from batching")}
      </li>
      <li>
        <strong> {Component.text("Updates need to be visible immediately:")} </strong>
      {Component.text(" Rare, but sometimes intermediate states matter")}
      </li>
      <li>
        <strong> {Component.text("Debugging:")} </strong>
      {Component.text(" Batching can make it harder to trace state changes")}
      </li>
    </ul>
    <h2> {Component.text("Example: Animation")} </h2>
    <p>
      {Component.text("Batching is useful for coordinated updates in animations:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`let x = Signal.make(0)
let y = Signal.make(0)
let rotation = Signal.make(0)
let scale = Signal.make(1.0)

let animationFrame = () => {
  Signal.batch(() => {
    Signal.update(x, v => v + 1)
    Signal.update(y, v => v + 2)
    Signal.update(rotation, v => v + 5)
    Signal.update(scale, v => v *. 1.01)
  })
  // All transform properties update together
}

let intervalId = setInterval(animationFrame, 16) // ~60fps`)}
      </code>
    </pre>
    <h2> {Component.text("Performance Considerations")} </h2>
    <p>
      {Component.text("Batching provides benefits when:")}
    </p>
    <ol>
      <li>
        {Component.text("Multiple signals feed into the same computed/effect")}
      </li>
      <li>
        {Component.text("Computed values have expensive calculations")}
      </li>
      <li>
        {Component.text("Effects perform costly side effects (DOM updates, network requests)")}
      </li>
    </ol>
    <p>
      {Component.text("In simple cases, batching overhead might not be worth it:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`// Simple case: batching adds minimal benefit
let count = Signal.make(0)

Signal.batch(() => {
  Signal.set(count, 1)
}) // Overhead not worth it for single update`)}
      </code>
    </pre>
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Batch related updates:")} </strong>
      {Component.text(" Group changes that logically belong together")}
      </li>
      <li>
        <strong> {Component.text("Keep batches small:")} </strong>
      {Component.text(" Don't batch unrelated updates")}
      </li>
      <li>
        <strong> {Component.text("Batch at the right level:")} </strong>
      {Component.text(" Batch where updates originate, not deep in the stack")}
      </li>
      <li>
        <strong> {Component.text("Document batching:")} </strong>
      {Component.text(" Comment why batching is needed if it's not obvious")}
      </li>
    </ul>
    <h2> {Component.text("Example: Shopping Cart")} </h2>
    <p>
      {Component.text("Here's a complete example showing effective batching:")}
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`type item = {id: int, quantity: int}
type cart = {
  items: array<item>,
  discountCode: option<string>,
  shippingMethod: string,
}

let cart = Signal.make({
  items: [],
  discountCode: None,
  shippingMethod: "standard",
})

let addItem = (id: int, quantity: int) => {
  Signal.batch(() => {
    Signal.update(cart, c => {
      ...c,
      items: Array.concat(c.items, [{id, quantity}])
    })

    // Clear discount if cart changes
    Signal.update(cart, c => {...c, discountCode: None})
  })
}

let applyDiscount = (code: string) => {
  Signal.batch(() => {
    Signal.update(cart, c => {...c, discountCode: Some(code)})
    Signal.update(cart, c => {...c, shippingMethod: "express"})
  })
}`)}
      </code>
    </pre>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("See how batching works with ")}
      {Router.link(~to="/docs/core-concepts/effects", ~children=[Component.text("Effects")], ())}
      </li>
      <li>
        {Component.text("Learn about ")}
      {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
      {Component.text(" which benefit from batching")}
      </li>
      <li>
        {Component.text("Try the ")}
      {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
      {Component.text(" to see batching in action")}
      </li>
    </ul>
  </div>
}
