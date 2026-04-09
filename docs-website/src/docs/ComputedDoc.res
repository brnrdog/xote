// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/computed.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Computed Values")} </h1>
    <p>
      {Node.text("Computed values are derived signals that automatically stay in sync with their dependencies. They use lazy evaluation — when dependencies change, computeds are marked dirty but only recalculate when read. They're perfect for deriving state from other reactive sources.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Info:")} </strong>
      {Node.text(" Xote re-exports ")}
      <code> {Node.text("Computed")} </code>
      {Node.text(" from ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(". The API and behavior are provided by that library.")}
      </p>
    </div>
    <p>
      {Node.text("Test")}
    </p>
    <h2 id="creating-computed-values"> {Node.text("Creating Computed Values")} </h2>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Computed.make()")} </code>
      {Node.text(" with a function that computes the derived value. It returns the computed signal:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

let firstName = Signal.make("John")
let lastName = Signal.make("Doe")

// Automatically updates when firstName or lastName changes
let fullName = Computed.make(() =>
  Signal.get(firstName) ++ " " ++ Signal.get(lastName)
)

// Read the computed value directly from the signal
Console.log(Signal.get(fullName)) // "John Doe"`)}
      </code>
    </pre>
    <h2 id="how-computed-values-work"> {Node.text("How Computed Values Work")} </h2>
    <p>
      {Node.text("Computed values use lazy evaluation with push-based dirty flagging:")}
    </p>
    <ol>
      <li>
        {Node.text("When created, the computation runs immediately to establish dependencies")}
      </li>
      <li>
        {Node.text("When any dependency changes, the computed is marked dirty (dirty flag is pushed)")}
      </li>
      <li>
        {Node.text("When the computed is read (via Signal.get or Signal.peek), it recomputes if dirty")}
      </li>
      <li>
        {Node.text("The new value is stored in the backing signal, and observers are notified if it changed")}
      </li>
    </ol>
    <p>
      {Node.text("This means computed values are always up-to-date when read, but they never recalculate if their value is not read — a dirty computed with no readers stays dirty and skips recomputation entirely.")}
    </p>
    <h2 id="reading-computed-values"> {Node.text("Reading Computed Values")} </h2>
    <p>
      {Node.text("Computed values return a signal that can be read with ")}
      <code> {Node.text("Signal.get()")} </code>
      {Node.text(":")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // Prints: 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // Prints: 20`)}
      </code>
    </pre>
    <h2 id="automatic-disposal"> {Node.text("Automatic Disposal")} </h2>
    <p>
      <strong> {Node.text("Computed values automatically dispose when they lose all subscribers - you don't need to manually call Computed.dispose() in most cases!")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Create an effect that subscribes to doubled
let disposer = Effect.run(() => {
  Console.log(Signal.get(doubled))  // doubled has 1 subscriber
  None
})

Signal.set(count, 5)  // doubled recomputes and logs

// Dispose the effect
disposer.dispose()
// ↑ doubled now has 0 subscribers - automatically disposed! ✨

Signal.set(count, 10)
// doubled doesn't recompute anymore (it was auto-disposed)`)}
      </code>
    </pre>
    <p>
      {Node.text("This works seamlessly with Components:")}
    </p>
    <pre>
      <code>
        {Node.text(`let app = () => {
  let count = Signal.make(0)
  let doubled = Computed.make(() => Signal.get(count) * 2)

  <div>
    {Node.signalText(() => Signal.get(doubled)->Int.toString)}
  </div>
}

// When the component unmounts:
// 1. The signalText effect is disposed
// 2. doubled loses its last subscriber
// 3. doubled is automatically disposed ✨`)}
      </code>
    </pre>
    <h3 id="manual-disposal-optional"> {Node.text("Manual Disposal (Optional)")} </h3>
    <p>
      {Node.text("You can still manually dispose computeds when needed:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Use it...
Console.log(Signal.get(doubled))

// Manually dispose when done
Computed.dispose(doubled)`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Manual disposal is useful when:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("You want explicit control over lifecycle")}
      </li>
      <li>
        {Node.text("The computed has no subscribers but you want to stop it anyway")}
      </li>
      <li>
        {Node.text("You're managing complex dependency graphs manually")}
      </li>
    </ul>
    <h2 id="chaining-computed-values"> {Node.text("Chaining Computed Values")} </h2>
    <p>
      {Node.text("You can create computed values that depend on other computed values:")}
    </p>
    <pre>
      <code>
        {Node.text(`let price = Signal.make(100)
let quantity = Signal.make(3)

let subtotal = Computed.make(() =>
  Signal.get(price) * Signal.get(quantity)
)

let tax = Computed.make(() =>
  Signal.get(subtotal) * 0.1
)

let total = Computed.make(() =>
  Signal.get(subtotal) + Signal.get(tax)
)

Console.log(Signal.get(total)) // 330

Signal.set(quantity, 5)
Console.log(Signal.get(total)) // 550`)}
      </code>
    </pre>
    <h2 id="computed-vs-manual-updates"> {Node.text("Computed vs Manual Updates")} </h2>
    <p>
      {Node.text("Instead of manually updating derived state:")}
    </p>
    <pre>
      <code>
        {Node.text(`// ❌ Manual (error-prone)
let count = Signal.make(0)
let doubled = Signal.make(0)

let increment = () => {
  Signal.update(count, n => n + 1)
  Signal.set(doubled, Signal.get(count) * 2) // Easy to forget!
}`)}
      </code>
    </pre>
    <p>
      {Node.text("Use computed values for automatic updates:")}
    </p>
    <pre>
      <code>
        {Node.text(`// ✅ Automatic (safe)
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

let increment = () => {
  Signal.update(count, n => n + 1)
  // doubled automatically updates!
}`)}
      </code>
    </pre>
    <h2 id="dynamic-dependencies"> {Node.text("Dynamic Dependencies")} </h2>
    <p>
      {Node.text("Computed values re-track dependencies on every execution, so they adapt to control flow:")}
    </p>
    <pre>
      <code>
        {Node.text(`let useMetric = Signal.make(true)
let celsius = Signal.make(20)
let fahrenheit = Signal.make(68)

let temperature = Computed.make(() => {
  if Signal.get(useMetric) {
    Signal.get(celsius)
  } else {
    Signal.get(fahrenheit)
  }
})

Console.log(Signal.get(temperature)) // 20

// Initially depends on: useMetric, celsius
Signal.set(useMetric, false)
// Now depends on: useMetric, fahrenheit
Console.log(Signal.get(temperature)) // 68`)}
      </code>
    </pre>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Keep computations pure:")} </strong>
      {Node.text(" Computed functions should not have side effects")}
      </li>
      <li>
        <strong> {Node.text("Use for derived state:")} </strong>
      {Node.text(" Any value that can be calculated from other signals should be a computed")}
      </li>
      <li>
        <strong> {Node.text("Avoid expensive operations:")} </strong>
      {Node.text(" Computed values recalculate when read, so keep them fast")}
      </li>
      <li>
        <strong> {Node.text("Don't nest effects:")} </strong>
      {Node.text(" Computed values should not call Effect.run() internally")}
      </li>
      <li>
        <strong> {Node.text("Trust auto-disposal:")} </strong>
      {Node.text(" In most cases, computeds will automatically clean up when their subscribers are disposed. Manual disposal is rarely needed")}
      </li>
    </ul>
    <h2 id="important-notes"> {Node.text("Important Notes")} </h2>
    <h3 id="cascading-auto-disposal"> {Node.text("Cascading Auto-Disposal")} </h3>
    <p>
      {Node.text("Auto-disposal can cascade through chains of computeds:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)
let quadrupled = Computed.make(() => Signal.get(doubled) * 2)

let disposer = Effect.run(() => {
  Console.log(Signal.get(quadrupled))
  None
})

// Dependency chain: count → doubled → quadrupled → effect

disposer.dispose()
// Effect disposed → quadrupled has 0 subscribers → auto-dispose quadrupled
// → doubled has 0 subscribers → auto-dispose doubled ✨`)}
      </code>
    </pre>
    <p>
      {Node.text("This ensures the entire chain is cleaned up automatically when the leaf subscriber is removed!")}
    </p>
    <h3 id="lazy-with-dirty-flagging"> {Node.text("Lazy with Push-based Dirty Flagging")} </h3>
    <p>
      {Node.text("Xote's computed values use lazy evaluation — they only recompute when read:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
let expensive = Computed.make(() => {
  Console.log("Computing...")
  Signal.get(count) * 2
})

// "Computing..." is logged once during creation (initial tracking)

Signal.set(count, 5)
// 'expensive' is marked dirty, but does NOT recompute yet

Signal.get(expensive)
// NOW "Computing..." is logged — recomputation happens on read`)}
      </code>
    </pre>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects")], ())}
      {Node.text(" for side effects")}
      </li>
      <li>
        {Node.text("Understand ")}
      {Router.link(~to="/docs/core-concepts/batching", ~children=[Node.text("Batching")], ())}
      {Node.text(" for grouping updates")}
      </li>
      <li>
        {Node.text("See ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(" to use computed values in UIs")}
      </li>
    </ul>
  </div>
}
