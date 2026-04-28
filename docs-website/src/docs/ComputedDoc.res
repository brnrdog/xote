// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/computed.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("Computeds are derived signals. They let you describe state in terms of other state instead of manually keeping multiple signals in sync.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {View.text("Important:")} </strong>
        {View.text(" ")}
        <code> {View.text("Computed.make")} </code>
        {View.text(" returns a ")}
        <code> {View.text("Signal.t<'a>")} </code>
        {View.text(". You read it with ")}
        <code> {View.text("Signal.get")} </code>
        {View.text(" or ")}
        <code> {View.text("Signal.peek")} </code>
        {View.text(", just like any other signal.")}
      </p>
    </div>

    <h2 id="working-with-computeds"> {View.text("Working with Computeds")} </h2>
    <h3 id="creating-computed-values"> {View.text("Creating Computed Values")} </h3>
    <p>
      {View.text("A computed is a function plus automatic dependency tracking. Every signal read inside the function becomes an input.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let price = Signal.make(100)
let quantity = Signal.make(3)

let subtotal = Computed.make(() =>
  Signal.get(price) * Signal.get(quantity)
)`)}
      </code>
    </pre>
    <p>
      {View.text("If you need to suppress downstream updates for equivalent derived values, ")}
      <code> {View.text("Computed.make")} </code>
      {View.text(" also accepts ")}
      <code> {View.text("~equals")} </code>
      {View.text(".")}
    </p>

    <h3 id="reading-computed-values"> {View.text("Reading Computed Values")} </h3>
    <p>
      {View.text("Read a computed exactly like a signal. Use ")}
      <code> {View.text("Signal.get")} </code>
      {View.text(" when the current code should subscribe, or ")}
      <code> {View.text("Signal.peek")} </code>
      {View.text(" for a one-off read.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let subtotal = Computed.make(() =>
  Signal.get(price) * Signal.get(quantity)
)

let total = Computed.make(() =>
  Signal.get(subtotal) + 50
)

Console.log(Signal.get(total))`)}
      </code>
    </pre>

    <h3 id="lazy-recomputation"> {View.text("Lazy Recomputation")} </h3>
    <p>
      {View.text("When an upstream signal changes, a computed is marked dirty immediately but does not recompute until someone reads it. This keeps unused derived values cheap.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = Signal.make(0)

let doubled = Computed.make(() => {
  Console.log("recomputing")
  Signal.get(count) * 2
})

Signal.set(count, 1)
// Nothing logged yet

ignore(Signal.get(doubled))
// Logs "recomputing"`)}
      </code>
    </pre>

    <h3 id="dynamic-dependencies"> {View.text("Dynamic Dependencies")} </h3>
    <p>
      {View.text("Computeds re-track their dependencies every time they run. That means conditionals are allowed: the current control flow determines the active inputs.")}
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

    <h2 id="computeds-in-practice"> {View.text("In Practice")} </h2>
    <h3 id="example-order-summary"> {View.text("Example: Order Summary")} </h3>
    <p>
      {View.text("This is a common computed pattern: keep the writable state small, then derive display values like subtotal, shipping, and total from it.")}
    </p>
    <DocsExamplePanel
      filename="OrderSummary.res"
      code={`open Xote

let unitPrice = Signal.make(24)
let quantity = Signal.make(2)
let expressShipping = Signal.make(false)

let subtotal = Computed.make(() =>
  Signal.get(unitPrice) * Signal.get(quantity)
)

let shippingCost = Computed.make(() =>
  if Signal.get(expressShipping) {
    15
  } else {
    0
  }
)

let total = Computed.make(() =>
  Signal.get(subtotal) + Signal.get(shippingCost)
)

let app = () => {
  <div>
    <p>
      {View.signalText(() => \`Subtotal: $\${Signal.get(subtotal)->Int.toString}\`)}
    </p>
    <p>
      {View.signalText(() => \`Shipping: $\${Signal.get(shippingCost)->Int.toString}\`)}
    </p>
    <p>
      {View.signalText(() => \`Total: $\${Signal.get(total)->Int.toString}\`)}
    </p>
  </div>
}`}
    >
      <ComputedOrderDemo />
    </DocsExamplePanel>

    <h2 id="computed-lifecycle"> {View.text("Lifecycle")} </h2>
    <h3 id="disposal"> {View.text("Disposal")} </h3>
    <p>
      {View.text("Most computeds do not need manual cleanup. They dispose automatically when nothing is subscribed to them anymore. In UI code that usually means they disappear with the DOM that owns them.")}
    </p>
    <h4 id="manual-disposal"> {View.text("Manual Disposal")} </h4>
    <p>
      {View.text("If you create a long-lived computed outside normal component ownership and want to tear it down explicitly, call ")}
      <code> {View.text("Computed.dispose")} </code>
      {View.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let doubled = Computed.make(() => Signal.get(count) * 2)

// Use it for a while...

Computed.dispose(doubled)`)}
      </code>
    </pre>

    <h3 id="computed-vs-manual-updates"> {View.text("Computed vs Manual Updates")} </h3>
    <p>
      {View.text("If a value can be derived from other reactive values, prefer a computed instead of mirroring it into another signal.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`// Avoid this
let count = Signal.make(0)
let doubled = Signal.make(0)

let increment = () => {
  Signal.update(count, n => n + 1)
  Signal.set(doubled, Signal.get(count) * 2)
}

// Prefer this
let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)`)}
      </code>
    </pre>

    <h2 id="computed-working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Keep computeds pure. If the code talks to the outside world, it probably belongs in an effect instead.")}
      </li>
      <li>
        {View.text("Read computeds with ")}
        <code> {View.text("Signal.get")} </code>
        {View.text(" or ")}
        <code> {View.text("Signal.peek")} </code>
        {View.text(", because they are signals at the type level.")}
      </li>
      <li>
        {View.text("Avoid copying derived values into writable signals unless you truly need editable local state.")}
      </li>
      <li>
        {View.text("Reach for custom equality only when downstream updates are too noisy with the default behavior.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[View.text("Read Effects")], ())}
        {View.text(" to see where reactive side effects fit on top of signals and computeds.")}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("Move to View")], ())}
        {View.text(" when you want to wire derived values into the UI layer.")}
      </li>
    </ul>
  </div>
}
