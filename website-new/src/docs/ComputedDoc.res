open Xote

let content = () => {
  <div>
    <h1> {Component.text("Computed Values")} </h1>
    <p>
      {Component.text(
        "Computed values are derived signals that automatically recalculate when their dependencies change. They're perfect for deriving state from other reactive sources.",
      )}
    </p>
    <div class="info-box">
      <p>
        <strong> {Component.text("Info:")} </strong>
        {Component.text("Xote re-exports ")}
        <code> {Component.text("Computed")} </code>
        {Component.text(" from ")}
        <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank">
          {Component.text("rescript-signals")}
        </a>
        {Component.text(". The API and behavior are provided by that library.")}
      </p>
    </div>
    <h2> {Component.text("Creating Computed Values")} </h2>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Computed.make()")} </code>
      {Component.text(
        " with a function that computes the derived value. It returns the computed signal:",
      )}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

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
    <h2> {Component.text("How Computed Values Work")} </h2>
    <p> {Component.text("Computed values are push-based (eager), not pull-based (lazy):")} </p>
    <ol>
      <li> {Component.text("When created, the computation runs immediately to establish dependencies")} </li>
      <li> {Component.text("When any dependency changes, the computed automatically recalculates")} </li>
      <li> {Component.text("The new value is pushed to a backing signal")} </li>
      <li> {Component.text("Any observers of the computed are notified")} </li>
    </ol>
    <p>
      {Component.text(
        "This means computed values are always up-to-date, but they may recalculate even if their value is never read.",
      )}
    </p>
    <h2> {Component.text("Reading Computed Values")} </h2>
    <p>
      {Component.text("Computed values return a signal that can be read with ")}
      <code> {Component.text("Signal.get()")} </code>
      {Component.text(":")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // Prints: 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // Prints: 20`)}
      </code>
    </pre>
    <h2> {Component.text("Automatic Disposal")} </h2>
    <p>
      <strong>
        {Component.text(
          "Computed values automatically dispose when they lose all subscribers - you don't need to manually call Computed.dispose() in most cases!",
        )}
      </strong>
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
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
    <p> {Component.text("This works seamlessly with Components:")} </p>
    <pre>
      <code>
        {Component.text(`let app = () => {
  let count = Signal.make(0)
  let doubled = Computed.make(() => Signal.get(count) * 2)

  <div>
    {Component.textSignal(() => Signal.get(doubled)->Int.toString)}
  </div>
}

// When the component unmounts:
// 1. The textSignal effect is disposed
// 2. doubled loses its last subscriber
// 3. doubled is automatically disposed ✨`)}
      </code>
    </pre>
    <h3> {Component.text("Manual Disposal (Optional)")} </h3>
    <p> {Component.text("You can still manually dispose computeds when needed:")} </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

// Use it...
Console.log(Signal.get(doubled))

// Manually dispose when done
Computed.dispose(doubled)`)}
      </code>
    </pre>
    <p> <strong> {Component.text("Manual disposal is useful when:")} </strong> </p>
    <ul>
      <li> {Component.text("You want explicit control over lifecycle")} </li>
      <li> {Component.text("The computed has no subscribers but you want to stop it anyway")} </li>
      <li> {Component.text("You're managing complex dependency graphs manually")} </li>
    </ul>
    <h2> {Component.text("Chaining Computed Values")} </h2>
    <p> {Component.text("You can create computed values that depend on other computed values:")} </p>
    <pre>
      <code>
        {Component.text(`let price = Signal.make(100)
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
    <h2> {Component.text("Computed vs Manual Updates")} </h2>
    <p> {Component.text("Instead of manually updating derived state:")} </p>
    <pre>
      <code>
        {Component.text(`// ❌ Manual (error-prone)
let count = Signal.make(0)
let doubled = Signal.make(0)

let increment = () => {
  Signal.update(count, n => n + 1)
  Signal.set(doubled, Signal.get(count) * 2) // Easy to forget!
}`)}
      </code>
    </pre>
    <p> {Component.text("Use computed values for automatic updates:")} </p>
    <pre>
      <code>
        {Component.text(`// ✅ Automatic (safe)
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

let increment = () => {
  Signal.update(count, n => n + 1)
  // doubled automatically updates!
}`)}
      </code>
    </pre>
    <h2> {Component.text("Dynamic Dependencies")} </h2>
    <p>
      {Component.text(
        "Computed values re-track dependencies on every execution, so they adapt to control flow:",
      )}
    </p>
    <pre>
      <code>
        {Component.text(`let useMetric = Signal.make(true)
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
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Keep computations pure:")} </strong>
        {Component.text(" Computed functions should not have side effects")}
      </li>
      <li>
        <strong> {Component.text("Use for derived state:")} </strong>
        {Component.text(
          " Any value that can be calculated from other signals should be a computed",
        )}
      </li>
      <li>
        <strong> {Component.text("Avoid expensive operations:")} </strong>
        {Component.text(" Computed values recalculate eagerly, so keep them fast")}
      </li>
      <li>
        <strong> {Component.text("Don't nest effects:")} </strong>
        {Component.text(" Computed values should not call Effect.run() internally")}
      </li>
      <li>
        <strong> {Component.text("Trust auto-disposal:")} </strong>
        {Component.text(
          " In most cases, computeds will automatically clean up when their subscribers are disposed. Manual disposal is rarely needed",
        )}
      </li>
    </ul>
    <h2> {Component.text("Important Notes")} </h2>
    <h3> {Component.text("Cascading Auto-Disposal")} </h3>
    <p> {Component.text("Auto-disposal can cascade through chains of computeds:")} </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
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
      {Component.text(
        "This ensures the entire chain is cleaned up automatically when the leaf subscriber is removed!",
      )}
    </p>
    <h3> {Component.text("Push-based, Not Lazy")} </h3>
    <p> {Component.text("Unlike some reactive systems, Xote's computed values are eager:")} </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
let expensive = Computed.make(() => {
  Console.log("Computing...")
  Signal.get(count) * 2
})

// "Computing..." is logged immediately

Signal.set(count, 5)
// "Computing..." is logged again, even if we never read 'expensive'`)}
      </code>
    </pre>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Learn about ")}
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Component.text("Effects")], ())}
        {Component.text(" for side effects")}
      </li>
      <li>
        {Component.text("Understand ")}
        {Router.link(~to="/docs/core-concepts/batching", ~children=[Component.text("Batching")], ())}
        {Component.text(" for grouping updates")}
      </li>
      <li>
        {Component.text("See ")}
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
        {Component.text(" to use computed values in UIs")}
      </li>
    </ul>
  </div>
}
