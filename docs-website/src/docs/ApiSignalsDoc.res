// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/api-reference/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Signal API Reference")} </h1>
    <p>
      {Node.text("Complete API documentation for Xote signals.")}
    </p>
    <h2 id="type"> {Node.text("Type")} </h2>
    <pre>
      <code>
        {Node.text(`type t<'a>`)}
      </code>
    </pre>
    <p>
      {Node.text("A signal is an opaque type representing a reactive state container. The type parameter ")}
      <code> {Node.text("'a")} </code>
      {Node.text(" is the type of value the signal holds.")}
    </p>
    <h2 id="functions"> {Node.text("Functions")} </h2>
    <h3 id="make"> <code> {Node.text("make")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let make: ('a, ~equals: ('a, 'a) => bool=?) => t<'a>`)}
      </code>
    </pre>
    <p>
      {Node.text("Creates a new signal with an initial value. Optionally accepts a custom equality function to control when dependents are notified.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("initialValue: 'a")} </code>
      {Node.text(" - The initial value for the signal")}
      </li>
      <li>
        <code> {Node.text("~equals: ('a, 'a) => bool")} </code>
      {Node.text(" (optional) - Custom equality function. Returns ")}
      <code> {Node.text("true")} </code>
      {Node.text(" if two values should be considered equal (skipping notification). Defaults to strict referential equality (")}
      <code> {Node.text("===")} </code>
      {Node.text(").")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("t<'a>")} </code>
      {Node.text(" - A new signal")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
let name = Signal.make("Alice")
let items = Signal.make([1, 2, 3])`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("With custom equality:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`type position = { x: int, y: int }

let pos = Signal.make(
  { x: 0, y: 0 },
  ~equals=(a, b) => a.x == b.x && a.y == b.y,
)

// Won't notify dependents - values are equal
Signal.set(pos, { x: 0, y: 0 })

// Will notify dependents - y changed
Signal.set(pos, { x: 0, y: 1 })`)}
      </code>
    </pre>
    <hr />
    <h3 id="get"> <code> {Node.text("get")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let get: t<'a> => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Reads the current value from a signal. When called inside a tracking context (effect or computed), automatically registers the signal as a dependency.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("signal: t<'a>")} </code>
      {Node.text(" - The signal to read from")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("'a")} </code>
      {Node.text(" - The current value")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)
let value = Signal.get(count) // Returns 5

Effect.run(() => {
  // Creates a dependency on count
  Console.log(Signal.get(count))
  None
})`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Note:")} </strong>
      {Node.text(" Always creates a dependency when called in a tracking context. Use ")}
      <code> {Node.text("peek()")} </code>
      {Node.text(" to read without tracking.")}
    </p>
    <hr />
    <h3 id="peek"> <code> {Node.text("peek")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let peek: t<'a> => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Reads the current value from a signal ")}
      <strong> {Node.text("without")} </strong>
      {Node.text(" creating a dependency, even in tracking contexts.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("signal: t<'a>")} </code>
      {Node.text(" - The signal to read from")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("'a")} </code>
      {Node.text(" - The current value")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)

Effect.run(() => {
  // Does NOT create a dependency
  let value = Signal.peek(count)
  Console.log(value)
  None
})

Signal.set(count, 10) // Effect will NOT re-run`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Use cases:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Reading signals in effects without creating dependencies")}
      </li>
      <li>
        {Node.text("Debugging (logging signal values without tracking)")}
      </li>
      <li>
        {Node.text("Reading configuration values that don't need to trigger updates")}
      </li>
    </ul>
    <hr />
    <h3 id="set"> <code> {Node.text("set")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let set: (t<'a>, 'a) => unit`)}
      </code>
    </pre>
    <p>
      {Node.text("Sets a new value for the signal and notifies all dependent observers if the value has changed.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("signal: t<'a>")} </code>
      {Node.text(" - The signal to update")}
      </li>
      <li>
        <code> {Node.text("value: 'a")} </code>
      {Node.text(" - The new value")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("unit")} </code>
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
Signal.set(count, 10) // count is now 10, observers notified

Signal.set(count, 10) // Same value - no notification`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Equality Check:")} </strong>
      {Node.text(" Uses the signal's equality function to check if the value has changed. By default, this is strict referential equality (")}
      <code> {Node.text("===")} </code>
      {Node.text("). Only notifies dependent observers if the new value differs from the current value. This prevents unnecessary recomputations and helps avoid infinite loops when effects write back to their dependencies.")}
    </p>
    <p>
      <strong> {Node.text("Note:")} </strong>
      {Node.text(" A custom equality function can be provided when creating the signal via ")}
      <code> {Node.text("Signal.make(value, ~equals=...)")} </code>
      {Node.text(". See ")}
      <code> {Node.text("make")} </code>
      {Node.text(" above for details and examples.")}
    </p>
    <hr />
    <h3 id="update"> <code> {Node.text("update")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let update: (t<'a>, 'a => 'a) => unit`)}
      </code>
    </pre>
    <p>
      {Node.text("Updates a signal's value based on its current value.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("signal: t<'a>")} </code>
      {Node.text(" - The signal to update")}
      </li>
      <li>
        <code> {Node.text("fn: 'a => 'a")} </code>
      {Node.text(" - Function that receives the current value and returns the new value")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("unit")} </code>
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2

let items = Signal.make([1, 2, 3])
Signal.update(items, arr => Array.concat(arr, [4, 5])) // [1, 2, 3, 4, 5]`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Note:")} </strong>
      {Node.text(" Equivalent to ")}
      <code> {Node.text("Signal.set(signal, fn(Signal.get(signal)))")} </code>
      {Node.text(" but more concise.")}
    </p>
    <hr />
    <h3 id="batch"> <code> {Node.text("batch")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let batch: (unit => 'a) => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Groups multiple signal updates together, ensuring observers run only once after all updates complete.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("fn: unit => 'a")} </code>
      {Node.text(" - Function containing signal updates")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("'a")} </code>
      {Node.text(" - The return value of the function")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`Signal.batch(() => {
  Signal.set(firstName, "Jane")
  Signal.set(lastName, "Smith")
})
// Observers run once with both updates`)}
      </code>
    </pre>
    <hr />
    <h3 id="untrack"> <code> {Node.text("untrack")} </code> </h3>
    <pre>
      <code>
        {Node.text(`let untrack: (unit => 'a) => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Executes a function without tracking any signal dependencies.")}
    </p>
    <p>
      <strong> {Node.text("Parameters:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("fn: unit => 'a")} </code>
      {Node.text(" - Function to execute untracked")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Returns:")} </strong>
    </p>
    <ul>
      <li>
        <code> {Node.text("'a")} </code>
      {Node.text(" - The return value of the function")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Example:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`Effect.run(() => {
  let tracked = Signal.get(count)

  Signal.untrack(() => {
    let untracked = Signal.get(otherSignal) // Not tracked
  })

  None
})`)}
      </code>
    </pre>
    <hr />
    <h2 id="examples"> {Node.text("Examples")} </h2>
    <h3 id="basic-usage"> {Node.text("Basic Usage")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

let count = Signal.make(0)

// Read
Console.log(Signal.get(count)) // 0

// Update
Signal.set(count, 5)
Console.log(Signal.get(count)) // 5

// Update based on current value
Signal.update(count, n => n + 1)
Console.log(Signal.get(count)) // 6`)}
      </code>
    </pre>
    <h3 id="with-effects"> {Node.text("With Effects")} </h3>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
  None
})

Signal.set(count, 1) // Logs: "Count changed: 1"
Signal.set(count, 2) // Logs: "Count changed: 2"`)}
      </code>
    </pre>
    <h3 id="with-computed"> {Node.text("With Computed")} </h3>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(5)
let doubled = Computed.make(() => Signal.get(count) * 2)

Console.log(Signal.get(doubled)) // 10

Signal.set(count, 10)
Console.log(Signal.get(doubled)) // 20`)}
      </code>
    </pre>
    <h3 id="complex-state"> {Node.text("Complex State")} </h3>
    <pre>
      <code>
        {Node.text(`type user = {
  id: int,
  name: string,
  email: string,
}

let user = Signal.make({
  id: 1,
  name: "Alice",
  email: "alice@example.com",
})

// Update specific fields
Signal.update(user, u => {...u, name: "Alice Smith"})
Signal.update(user, u => {...u, email: "alice.smith@example.com"})`)}
      </code>
    </pre>
    <h3 id="array-operations"> {Node.text("Array Operations")} </h3>
    <pre>
      <code>
        {Node.text(`let todos = Signal.make([])

// Add item
Signal.update(todos, arr => Array.concat(arr, ["Buy milk"]))

// Remove item
Signal.update(todos, arr => Array.filter(arr, item => item != "Buy milk"))

// Update item
Signal.update(todos, arr =>
  Array.map(arr, item =>
    item == "Buy milk" ? "Buy oat milk" : item
  )
)`)}
      </code>
    </pre>
    <h2 id="notes"> {Node.text("Notes")} </h2>
    <ul>
      <li>
        {Node.text("Signals use strict referential equality (")}
      <code> {Node.text("===")} </code>
      {Node.text(") by default - only notify dependents when the value actually changes. Use ")}
      <code> {Node.text("~equals")} </code>
      {Node.text(" for custom comparison logic.")}
      </li>
      <li>
        {Node.text("Use ")}
      <code> {Node.text("peek()")} </code>
      {Node.text(" to avoid creating dependencies in effects")}
      </li>
      <li>
        {Node.text("Signals work with any type: primitives, records, arrays, etc.")}
      </li>
      <li>
        {Node.text("Use ")}
      <code> {Node.text("Signal.batch()")} </code>
      {Node.text(" to group multiple updates")}
      </li>
      <li>
        {Node.text("The equality check prevents accidental infinite loops and unnecessary recomputations")}
      </li>
    </ul>
    <h2 id="see-also"> {Node.text("See Also")} </h2>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals Guide")], ())}
      {Node.text(" - Conceptual overview")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Computed Guide")], ())}
      {Node.text(" - Derived values")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects Guide")], ())}
      {Node.text(" - Side effects")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/batching", ~children=[Node.text("Batching Guide")], ())}
      {Node.text(" - Batching updates")}
      </li>
    </ul>
  </div>
}
