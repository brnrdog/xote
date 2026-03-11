// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/effects.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Effects")} </h1>
    <p>
      {Component.text("Effects are functions that run side effects in response to reactive state changes. They automatically re-execute when any signal they depend on changes.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Component.text("Info:")} </strong>
      {Component.text(" Xote re-exports ")}
      <code> {Component.text("Effect")} </code>
      {Component.text(" from ")}
      <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(". The API and behavior are provided by that library.")}
      </p>
    </div>
    <h2> {Component.text("Creating Effects")} </h2>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Effect.run()")} </code>
      {Component.text(" to create an effect. The effect function can optionally return a cleanup function:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count is now:", Signal.get(count))
  None // No cleanup needed
})
// Prints: "Count is now: 0"

Signal.set(count, 1)
// Prints: "Count is now: 1"`)}
      </code>
    </pre>
    <h2> {Component.text("How Effects Work")} </h2>
    <ol>
      <li>
        {Component.text("The effect function runs immediately when created")}
      </li>
      <li>
        {Component.text("Any Signal.get() calls during execution are tracked as dependencies")}
      </li>
      <li>
        {Component.text("When a dependency changes, the effect re-runs")}
      </li>
      <li>
        {Component.text("Dependencies are re-tracked on every execution")}
      </li>
      <li>
        {Component.text("If a cleanup function was returned, it runs before re-execution")}
      </li>
    </ol>
    <h2> {Component.text("Cleanup Callbacks")} </h2>
    <p>
      {Component.text("Effects can return an optional cleanup function that runs before the effect re-executes or when the effect is disposed:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

let url = Signal.make("https://api.example.com/data")

Effect.run(() => {
  let currentUrl = Signal.get(url)
  Console.log2("Fetching:", currentUrl)

  // Simulate an API call with AbortController
  let controller = AbortController.make()

  fetch(currentUrl, {signal: controller.signal})
    ->Promise.then(response => {
      Console.log("Data received")
      Promise.resolve()
    })
    ->ignore

  // Return cleanup function
  Some(() => {
    Console.log("Aborting previous request")
    controller.abort()
  })
})

// When url changes, the cleanup function runs first,
// then the effect re-executes with the new URL
Signal.set(url, "https://api.example.com/other-data")`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Key points about cleanup:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Return None when no cleanup is needed")}
      </li>
      <li>
        {Component.text("Return Some(cleanupFn) to register cleanup")}
      </li>
      <li>
        {Component.text("Cleanup runs before the effect re-executes")}
      </li>
      <li>
        {Component.text("Cleanup runs when the effect is disposed via dispose()")}
      </li>
      <li>
        {Component.text("Cleanup is useful for canceling requests, clearing timers, removing event listeners, etc.")}
      </li>
    </ul>
    <h2> {Component.text("Common Use Cases")} </h2>
    <h3> {Component.text("Timers with Cleanup")} </h3>
    <p>
      {Component.text("Properly clean up timers:")}
    </p>
    <pre>
      <code>
        {Component.text(`let interval = Signal.make(1000)

Effect.run(() => {
  let ms = Signal.get(interval)

  let timerId = setInterval(() => {
    Console.log("Tick")
  }, ms)

  // Clear timer when interval changes or effect disposes
  Some(() => {
    clearInterval(timerId)
  })
})`)}
      </code>
    </pre>
    <h3> {Component.text("Logging and Debugging")} </h3>
    <p>
      {Component.text("Track state changes for debugging:")}
    </p>
    <pre>
      <code>
        {Component.text(`let user = Signal.make({id: 1, name: "Alice"})

Effect.run(() => {
  let currentUser = Signal.get(user)
  Console.log2("User changed:", currentUser)
  None // No cleanup needed
})`)}
      </code>
    </pre>
    <h3> {Component.text("Synchronization")} </h3>
    <p>
      {Component.text("Sync reactive state with external systems:")}
    </p>
    <pre>
      <code>
        {Component.text(`let settings = Signal.make({theme: "dark", language: "en"})

Effect.run(() => {
  let current = Signal.get(settings)
  // Save to localStorage
  LocalStorage.setItem("settings", JSON.stringify(current))
  None // No cleanup needed
})`)}
      </code>
    </pre>
    <h2> {Component.text("Disposing Effects")} </h2>
    <p>
      {Component.text("Effect.run() returns a disposer object with a dispose() method to stop the effect. When disposed, any registered cleanup function is called:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)

let disposer = Effect.run(() => {
  Console.log(Signal.get(count))
  None // No cleanup needed
})

Signal.set(count, 1) // Effect runs
Signal.set(count, 2) // Effect runs

disposer.dispose() // Stop the effect

Signal.set(count, 3) // Effect does NOT run`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("With cleanup:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`let disposer = Effect.run(() => {
  let timerId = setInterval(() => Console.log("Tick"), 1000)

  // Cleanup function
  Some(() => {
    clearInterval(timerId)
    Console.log("Timer cleared")
  })
})

// Later...
disposer.dispose() // Runs cleanup, prints "Timer cleared"`)}
      </code>
    </pre>
    <h2> {Component.text("Dynamic Dependencies")} </h2>
    <p>
      {Component.text("Effects re-track dependencies on each execution, adapting to conditional logic:")}
    </p>
    <pre>
      <code>
        {Component.text(`let showDetails = Signal.make(false)
let name = Signal.make("Alice")
let age = Signal.make(30)

Effect.run(() => {
  Console.log(Signal.get(name))

  if Signal.get(showDetails) {
    Console.log2("Age:", Signal.get(age))
  }

  None // No cleanup needed
})

// Initially depends on: name, showDetails
// After setting showDetails to true, depends on: name, showDetails, age`)}
      </code>
    </pre>
    <h2> {Component.text("Avoiding Dependencies")} </h2>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Signal.peek()")} </code>
      {Component.text(" to read signals without creating dependencies:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)
let debug = Signal.make(true)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))

  // Read debug flag without depending on it
  if Signal.peek(debug) {
    Console.log("Debug mode is on")
  }

  None // No cleanup needed
})`)}
      </code>
    </pre>
    <h2> {Component.text("Example: Auto-save")} </h2>
    <p>
      {Component.text("Here's a practical example of an auto-save effect with proper cleanup:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

type draft = {
  title: string,
  content: string,
}

let draft = Signal.make({
  title: "",
  content: "",
})

let saveStatus = Signal.make("Saved")

// Auto-save effect with debouncing and cleanup
Effect.run(() => {
  let current = Signal.get(draft)

  Signal.set(saveStatus, "Unsaved changes...")

  // Save after 1 second of no changes
  let timeoutId = setTimeout(() => {
    // Save to server
    saveToServer(current)
    Signal.set(saveStatus, "Saved")
  }, 1000)

  // Clean up timeout when draft changes again
  Some(() => {
    clearTimeout(timeoutId)
  })
})`)}
      </code>
    </pre>
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Keep effects focused:")} </strong>
      {Component.text(" Each effect should do one thing")}
      </li>
      <li>
        <strong> {Component.text("Clean up resources:")} </strong>
      {Component.text(" Return cleanup functions for timers, listeners, subscriptions, etc.")}
      </li>
      <li>
        <strong> {Component.text("Dispose effects:")} </strong>
      {Component.text(" Use the disposer when effects are no longer needed (e.g., component unmount)")}
      </li>
      <li>
        <strong> {Component.text("Avoid infinite loops:")} </strong>
      {Component.text(" Don't set signals that the effect depends on (unless using equality checks)")}
      </li>
      <li>
        <strong> {Component.text("Use for side effects only:")} </strong>
      {Component.text(" Effects should not compute values (use Computed instead)")}
      </li>
      <li>
        <strong> {Component.text("Return None when no cleanup needed:")} </strong>
      {Component.text(" Be explicit about cleanup needs")}
      </li>
    </ul>
    <h2> {Component.text("Effects vs Computed")} </h2>
    <table>
      <thead>
        <tr>
          <th> {Component.text("Feature")} </th>
          <th> {Component.text("Effect")} </th>
          <th> {Component.text("Computed")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> {Component.text("Purpose")} </td>
          <td> {Component.text("Side effects")} </td>
          <td> {Component.text("Derive values")} </td>
        </tr>
        <tr>
          <td> {Component.text("Returns")} </td>
          <td> {Component.text("Disposer")} </td>
          <td> {Component.text("Signal")} </td>
        </tr>
        <tr>
          <td> {Component.text("When runs")} </td>
          <td> {Component.text("Immediately and on changes")} </td>
          <td> {Component.text("Immediately and on changes")} </td>
        </tr>
        <tr>
          <td> {Component.text("Result")} </td>
          <td> {Component.text("None (performs actions)")} </td>
          <td> {Component.text("New reactive value")} </td>
        </tr>
      </tbody>
    </table>
    <p>
      {Component.text("Use ")}
      <strong> {Component.text("Computed")} </strong>
      {Component.text(" for pure calculations, ")}
      <strong> {Component.text("Effects")} </strong>
      {Component.text(" for side effects.")}
    </p>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/batching", ~children=[Component.text("Batching")], ())}
      {Component.text(" to optimize multiple updates")}
      </li>
      <li>
        {Component.text("See how effects work in ")}
      {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
      </li>
      <li>
        {Component.text("Try the ")}
      {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
      {Component.text(" to see effects in action")}
      </li>
    </ul>
  </div>
}
