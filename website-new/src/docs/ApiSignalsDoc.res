open Xote

let content = () => {
  <div>
    <h1> {Component.text("Signal API Reference")} </h1>
    <p> {Component.text("Complete API documentation for Xote signals.")} </p>
    <h2> {Component.text("Type")} </h2>
    <pre>
      <code> {Component.text("type t<'a>")} </code>
    </pre>
    <p>
      {Component.text(
        "A signal is an opaque type representing a reactive state container. The type parameter 'a is the type of value the signal holds.",
      )}
    </p>
    <h2> {Component.text("Functions")} </h2>
    <h3>
      <code> {Component.text("make")} </code>
    </h3>
    <pre>
      <code> {Component.text("let make: 'a => t<'a>")} </code>
    </pre>
    <p> {Component.text("Creates a new signal with an initial value.")} </p>
    <p> <strong> {Component.text("Parameters:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("initialValue: 'a")} </code>
        {Component.text(" - The initial value for the signal")}
      </li>
    </ul>
    <p> <strong> {Component.text("Returns:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("t<'a>")} </code>
        {Component.text(" - A new signal")}
      </li>
    </ul>
    <p> <strong> {Component.text("Example:")} </strong> </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
let name = Signal.make("Alice")
let items = Signal.make([1, 2, 3])`)}
      </code>
    </pre>
    <hr />
    <h3>
      <code> {Component.text("get")} </code>
    </h3>
    <pre>
      <code> {Component.text("let get: t<'a> => 'a")} </code>
    </pre>
    <p>
      {Component.text(
        "Reads the current value from a signal. When called inside a tracking context (effect or computed), automatically registers the signal as a dependency.",
      )}
    </p>
    <p> <strong> {Component.text("Parameters:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("signal: t<'a>")} </code>
        {Component.text(" - The signal to read from")}
      </li>
    </ul>
    <p> <strong> {Component.text("Returns:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("'a")} </code>
        {Component.text(" - The current value")}
      </li>
    </ul>
    <p> <strong> {Component.text("Example:")} </strong> </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(5)
let value = Signal.get(count) // Returns 5

Effect.run(() => {
  // Creates a dependency on count
  Console.log(Signal.get(count))
})`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Note:")} </strong>
      {Component.text(
        " Always creates a dependency when called in a tracking context. Use peek() to read without tracking.",
      )}
    </p>
    <hr />
    <h3>
      <code> {Component.text("peek")} </code>
    </h3>
    <pre>
      <code> {Component.text("let peek: t<'a> => 'a")} </code>
    </pre>
    <p>
      {Component.text(
        "Reads the current value from a signal without creating a dependency, even in tracking contexts.",
      )}
    </p>
    <p> <strong> {Component.text("Parameters:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("signal: t<'a>")} </code>
        {Component.text(" - The signal to read from")}
      </li>
    </ul>
    <p> <strong> {Component.text("Returns:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("'a")} </code>
        {Component.text(" - The current value")}
      </li>
    </ul>
    <p> <strong> {Component.text("Example:")} </strong> </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(5)

Effect.run(() => {
  // Does NOT create a dependency
  let value = Signal.peek(count)
  Console.log(value)
})

Signal.set(count, 10) // Effect will NOT re-run`)}
      </code>
    </pre>
    <p> <strong> {Component.text("Use cases:")} </strong> </p>
    <ul>
      <li> {Component.text("Reading signals in effects without creating dependencies")} </li>
      <li> {Component.text("Debugging (logging signal values without tracking)")} </li>
      <li> {Component.text("Reading configuration values that don't need to trigger updates")} </li>
    </ul>
    <hr />
    <h3>
      <code> {Component.text("set")} </code>
    </h3>
    <pre>
      <code> {Component.text("let set: (t<'a>, 'a) => unit")} </code>
    </pre>
    <p>
      {Component.text(
        "Sets a new value for the signal and notifies all dependent observers if the value has changed.",
      )}
    </p>
    <p> <strong> {Component.text("Parameters:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("signal: t<'a>")} </code>
        {Component.text(" - The signal to update")}
      </li>
      <li>
        <code> {Component.text("value: 'a")} </code>
        {Component.text(" - The new value")}
      </li>
    </ul>
    <p> <strong> {Component.text("Returns:")} </strong> </p>
    <ul>
      <li> <code> {Component.text("unit")} </code> </li>
    </ul>
    <p> <strong> {Component.text("Example:")} </strong> </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
Signal.set(count, 10) // count is now 10, observers notified

Signal.set(count, 10) // Same value - no notification`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Equality Check:")} </strong>
      {Component.text(
        " Uses structural equality (!=) to check if the value has changed. Only notifies dependent observers if the new value differs from the current value. This prevents unnecessary recomputations and helps avoid infinite loops when effects write back to their dependencies.",
      )}
    </p>
    <hr />
    <h3>
      <code> {Component.text("update")} </code>
    </h3>
    <pre>
      <code> {Component.text("let update: (t<'a>, 'a => 'a) => unit")} </code>
    </pre>
    <p> {Component.text("Updates a signal's value based on its current value.")} </p>
    <p> <strong> {Component.text("Parameters:")} </strong> </p>
    <ul>
      <li>
        <code> {Component.text("signal: t<'a>")} </code>
        {Component.text(" - The signal to update")}
      </li>
      <li>
        <code> {Component.text("fn: 'a => 'a")} </code>
        {Component.text(" - Function that receives the current value and returns the new value")}
      </li>
    </ul>
    <p> <strong> {Component.text("Returns:")} </strong> </p>
    <ul>
      <li> <code> {Component.text("unit")} </code> </li>
    </ul>
    <p> <strong> {Component.text("Example:")} </strong> </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
Signal.update(count, n => n + 1) // count is now 1
Signal.update(count, n => n * 2) // count is now 2

let items = Signal.make([1, 2, 3])
Signal.update(items, arr => Array.concat(arr, [4, 5])) // [1, 2, 3, 4, 5]`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Note:")} </strong>
      {Component.text(" Equivalent to ")}
      <code> {Component.text("Signal.set(signal, fn(Signal.get(signal)))")} </code>
      {Component.text(" but more concise.")}
    </p>
    <h2> {Component.text("Examples")} </h2>
    <h3> {Component.text("Basic Usage")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

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
    <h3> {Component.text("With Effects")} </h3>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
})

Signal.set(count, 1) // Logs: "Count changed: 1"
Signal.set(count, 2) // Logs: "Count changed: 2"`)}
      </code>
    </pre>
    <h3> {Component.text("Complex State")} </h3>
    <pre>
      <code>
        {Component.text(`type user = {
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
    <h2> {Component.text("Notes")} </h2>
    <ul>
      <li>
        {Component.text(
          "Signals use structural equality checks - only notify dependents when the value actually changes",
        )}
      </li>
      <li> {Component.text("Use peek() to avoid creating dependencies in effects")} </li>
      <li> {Component.text("Signals work with any type: primitives, records, arrays, etc.")} </li>
      <li>
        {Component.text(
          "The equality check prevents accidental infinite loops and unnecessary recomputations",
        )}
      </li>
    </ul>
    <h2> {Component.text("See Also")} </h2>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Signals Guide")], ())}
        {Component.text(" - Conceptual overview")}
      </li>
      <li>
        {Router.link(
          ~to="/docs/core-concepts/computed",
          ~children=[Component.text("Computed Guide")],
          (),
        )}
        {Component.text(" - Derived values")}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Component.text("Effects Guide")], ())}
        {Component.text(" - Side effects")}
      </li>
    </ul>
  </div>
}
