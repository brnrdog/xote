// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/batching.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("Batching lets you group several signal writes so dependent computeds and effects flush once after the batch finishes.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Info:")} </strong>
        {Node.text(" Updates still happen synchronously. Batching changes how many times dependents flush, not whether they flush immediately.")}
      </p>
    </div>

    <h2 id="why-and-when-to-batch"> {Node.text("Why and When to Batch")} </h2>
    <h3 id="why-batch"> {Node.text("Why Batch?")} </h3>
    <p>
      {Node.text("Without batching, each write can trigger a new round of downstream work. That is fine for isolated updates, but noisy for coordinated state changes.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let firstName = Signal.make("Ada")
let lastName = Signal.make("Lovelace")

let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

Effect.run(() => {
  Console.log(Signal.get(fullName))
  None
})

Signal.set(firstName, "Grace")
Signal.set(lastName, "Hopper")`)}
      </code>
    </pre>
    <p>
      {Node.text("That effect can run twice. If both writes belong to the same logical update, batch them.")}
    </p>

    <h2 id="using-batching"> {Node.text("Using Batching")} </h2>
    <h3 id="using-signal-batch"> {Node.text("Using Signal.batch()")} </h3>
    <p>
      {Node.text("Wrap related writes in ")}
      <code> {Node.text("Signal.batch")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.batch(() => {
  Signal.set(firstName, "Grace")
  Signal.set(lastName, "Hopper")
})`)}
      </code>
    </pre>

    <h3 id="how-batching-works"> {Node.text("How Batching Works")} </h3>
    <p>
      {Node.text("Inside a batch, signals update immediately, but scheduler flushing is deferred until the outermost batch completes. Readers inside the batch still see the latest values.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.batch(() => {
  Signal.set(firstName, "Grace")
  Signal.set(lastName, "Hopper")

  Console.log(Signal.peek(firstName)) // "Grace"
  Console.log(Signal.peek(lastName)) // "Hopper"
})`)}
      </code>
    </pre>

    <h3 id="common-cases"> {Node.text("Common Cases")} </h3>
    <p>
      {Node.text("Batching is most useful when one user action updates several related signals.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type formState = {
  name: string,
  email: string,
}

let form = Signal.make({name: "", email: ""})
let isSaving = Signal.make(false)
let saveError = Signal.make(None)

let submit = () => {
  Signal.batch(() => {
    Signal.set(isSaving, true)
    Signal.set(saveError, None)
  })
}`)}
      </code>
    </pre>

    <h3 id="nested-batches"> {Node.text("Nested Batches")} </h3>
    <p>
      {Node.text("Batches can be nested. Flushing happens when the outermost batch ends.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.batch(() => {
  Signal.set(count, 1)

  Signal.batch(() => {
    Signal.set(count, 2)
    Signal.set(count, 3)
  })
})`)}
      </code>
    </pre>

    <h3 id="returning-values-from-batches"> {Node.text("Returning Values from Batches")} </h3>
    <p>
      {Node.text("A batch returns whatever the callback returns, so you can compute and write in one block.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let result = Signal.batch(() => {
  Signal.set(count, 10)
  Signal.set(status, "ready")
  "ok"
})`)}
      </code>
    </pre>

    <h3 id="when-not-to-batch"> {Node.text("When Not to Batch")} </h3>
    <p>
      {Node.text("Do not batch by default. If one signal changes and the rest of the graph can react naturally, batching adds no clarity. Use it when several writes are one semantic update.")}
    </p>

    <h2 id="batching-working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Batch one logical unit of work, such as a submit action, a reset, or a reducer-style update.")}
      </li>
      <li>
        {Node.text("Keep batches short so the write order stays easy to reason about.")}
      </li>
      <li>
        {Node.text("Do not use batching to hide duplicated or awkward state. Fix the model first.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Go back to Signals")], ())}
        {Node.text(" if you want the update model before the scheduling details.")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Read Effects")], ())}
        {Node.text(" to see the downstream work that batching reduces.")}
      </li>
    </ul>
  </div>
}
