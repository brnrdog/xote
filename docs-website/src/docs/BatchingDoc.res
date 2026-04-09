// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/batching.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Batching Updates")} </h1>
    <p>
      {Node.text("Batching allows you to group multiple signal updates together, ensuring that observers (effects and computed values) run only once after all updates complete, rather than after each individual update.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Info:")} </strong>
      {Node.text(" Batching is available through ")}
      <code> {Node.text("Signal.batch")} </code>
      {Node.text(" which is re-exported from ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(".")}
      </p>
    </div>
    <h2 id="why-batch"> {Node.text("Why Batch?")} </h2>
    <p>
      {Node.text("Without batching, each signal update triggers observers immediately:")}
    </p>
    <pre>
      <code>
        {Node.text(`let firstName = Signal.make("John")
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
      {Node.text("With batching, observers run once after all updates:")}
    </p>
    <pre>
      <code>
        {Node.text(`Signal.batch(() => {
  Signal.set(firstName, "Jane")  // Queued
  Signal.set(lastName, "Smith")  // Queued
})
// Logs: "Jane Smith" (only once)
// Effect runs once, computed recalculates once`)}
      </code>
    </pre>
    <h2 id="using-signal-batch"> {Node.text("Using Signal.batch()")} </h2>
    <p>
      {Node.text("Wrap multiple signal updates in a batch:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

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
    <h2 id="how-batching-works"> {Node.text("How Batching Works")} </h2>
    <ol>
      <li>
        {Node.text("When Signal.batch() is called, a batching flag is set")}
      </li>
      <li>
        {Node.text("Signal updates queue their observers instead of running them immediately")}
      </li>
      <li>
        {Node.text("When the batch function completes, all queued observers run")}
      </li>
      <li>
        {Node.text("Each observer runs only once, even if multiple dependencies changed")}
      </li>
    </ol>
    <h2 id="example-form-updates"> {Node.text("Example: Form Updates")} </h2>
    <p>
      {Node.text("Batching is especially useful when updating related state:")}
    </p>
    <pre>
      <code>
        {Node.text(`type formData = {
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
    <h2 id="nested-batches"> {Node.text("Nested Batches")} </h2>
    <p>
      {Node.text("Batches can be nested. The observers run when the outermost batch completes:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)

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
    <h2 id="returning-values-from-batches"> {Node.text("Returning Values from Batches")} </h2>
    <p>
      <code> {Node.text("Signal.batch()")} </code>
      {Node.text(" returns the result of the batch function:")}
    </p>
    <pre>
      <code>
        {Node.text(`let result = Signal.batch(() => {
  Signal.set(count, 10)
  Signal.set(name, "Alice")
  "Success"
})

Console.log(result) // "Success"`)}
      </code>
    </pre>
    <h2 id="when-to-use-batching"> {Node.text("When to Use Batching")} </h2>
    <p>
      {Node.text("Use batching when:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Updating multiple related signals:")} </strong>
      {Node.text(" Form state, coordinates, settings")}
      </li>
      <li>
        <strong> {Node.text("Performing complex state transitions:")} </strong>
      {Node.text(" Multi-step updates that should appear atomic")}
      </li>
      <li>
        <strong> {Node.text("Optimizing performance:")} </strong>
      {Node.text(" Reducing unnecessary recomputations")}
      </li>
      <li>
        <strong> {Node.text("Maintaining consistency:")} </strong>
      {Node.text(" Ensuring observers see a consistent state")}
      </li>
    </ul>
    <p>
      {Node.text("Don't batch when:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Single signal updates:")} </strong>
      {Node.text(" No benefit from batching")}
      </li>
      <li>
        <strong> {Node.text("Updates need to be visible immediately:")} </strong>
      {Node.text(" Rare, but sometimes intermediate states matter")}
      </li>
      <li>
        <strong> {Node.text("Debugging:")} </strong>
      {Node.text(" Batching can make it harder to trace state changes")}
      </li>
    </ul>
    <h2 id="example-animation"> {Node.text("Example: Animation")} </h2>
    <p>
      {Node.text("Batching is useful for coordinated updates in animations:")}
    </p>
    <pre>
      <code>
        {Node.text(`let x = Signal.make(0)
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
    <h2 id="performance-considerations"> {Node.text("Performance Considerations")} </h2>
    <p>
      {Node.text("Batching provides benefits when:")}
    </p>
    <ol>
      <li>
        {Node.text("Multiple signals feed into the same computed/effect")}
      </li>
      <li>
        {Node.text("Computed values have expensive calculations")}
      </li>
      <li>
        {Node.text("Effects perform costly side effects (DOM updates, network requests)")}
      </li>
    </ol>
    <p>
      {Node.text("In simple cases, batching overhead might not be worth it:")}
    </p>
    <pre>
      <code>
        {Node.text(`// Simple case: batching adds minimal benefit
let count = Signal.make(0)

Signal.batch(() => {
  Signal.set(count, 1)
}) // Overhead not worth it for single update`)}
      </code>
    </pre>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Batch related updates:")} </strong>
      {Node.text(" Group changes that logically belong together")}
      </li>
      <li>
        <strong> {Node.text("Keep batches small:")} </strong>
      {Node.text(" Don't batch unrelated updates")}
      </li>
      <li>
        <strong> {Node.text("Batch at the right level:")} </strong>
      {Node.text(" Batch where updates originate, not deep in the stack")}
      </li>
      <li>
        <strong> {Node.text("Document batching:")} </strong>
      {Node.text(" Comment why batching is needed if it's not obvious")}
      </li>
    </ul>
    <h2 id="example-shopping-cart"> {Node.text("Example: Shopping Cart")} </h2>
    <p>
      {Node.text("Here's a complete example showing effective batching:")}
    </p>
    <pre>
      <code>
        {Node.text(`type item = {id: int, quantity: int}
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
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("See how batching works with ")}
      {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects")], ())}
      </li>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(" which benefit from batching")}
      </li>
      <li>
        {Node.text("Try the ")}
      {Router.link(~to="/demos", ~children=[Node.text("Demos")], ())}
      {Node.text(" to see batching in action")}
      </li>
    </ul>
  </div>
}
