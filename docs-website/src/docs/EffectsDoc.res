// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/effects.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Effects")} </h1>
    <p>
      {Node.text("Effects are functions that run side effects in response to reactive state changes. They automatically re-execute when any signal they depend on changes.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Info:")} </strong>
      {Node.text(" Xote re-exports ")}
      <code> {Node.text("Effect")} </code>
      {Node.text(" from ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(". The API and behavior are provided by that library.")}
      </p>
    </div>
    <h2 id="creating-effects"> {Node.text("Creating Effects")} </h2>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Effect.run()")} </code>
      {Node.text(" to create an effect. The effect function can optionally return a cleanup function:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

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
    <h2 id="how-effects-work"> {Node.text("How Effects Work")} </h2>
    <ol>
      <li>
        {Node.text("The effect function runs immediately when created")}
      </li>
      <li>
        {Node.text("Any Signal.get() calls during execution are tracked as dependencies")}
      </li>
      <li>
        {Node.text("When a dependency changes, the effect re-runs")}
      </li>
      <li>
        {Node.text("Dependencies are re-tracked on every execution")}
      </li>
      <li>
        {Node.text("If a cleanup function was returned, it runs before re-execution")}
      </li>
    </ol>
    <h2 id="cleanup-callbacks"> {Node.text("Cleanup Callbacks")} </h2>
    <p>
      {Node.text("Effects can return an optional cleanup function that runs before the effect re-executes or when the effect is disposed:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

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
      <strong> {Node.text("Key points about cleanup:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Return None when no cleanup is needed")}
      </li>
      <li>
        {Node.text("Return Some(cleanupFn) to register cleanup")}
      </li>
      <li>
        {Node.text("Cleanup runs before the effect re-executes")}
      </li>
      <li>
        {Node.text("Cleanup runs when the effect is disposed via dispose()")}
      </li>
      <li>
        {Node.text("Cleanup is useful for canceling requests, clearing timers, removing event listeners, etc.")}
      </li>
    </ul>
    <h2 id="common-use-cases"> {Node.text("Common Use Cases")} </h2>
    <h3 id="timers-with-cleanup"> {Node.text("Timers with Cleanup")} </h3>
    <p>
      {Node.text("Properly clean up timers:")}
    </p>
    <pre>
      <code>
        {Node.text(`let interval = Signal.make(1000)

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
    <h3 id="logging-and-debugging"> {Node.text("Logging and Debugging")} </h3>
    <p>
      {Node.text("Track state changes for debugging:")}
    </p>
    <pre>
      <code>
        {Node.text(`let user = Signal.make({id: 1, name: "Alice"})

Effect.run(() => {
  let currentUser = Signal.get(user)
  Console.log2("User changed:", currentUser)
  None // No cleanup needed
})`)}
      </code>
    </pre>
    <h3 id="synchronization"> {Node.text("Synchronization")} </h3>
    <p>
      {Node.text("Sync reactive state with external systems:")}
    </p>
    <pre>
      <code>
        {Node.text(`let settings = Signal.make({theme: "dark", language: "en"})

Effect.run(() => {
  let current = Signal.get(settings)
  // Save to localStorage
  LocalStorage.setItem("settings", JSON.stringify(current))
  None // No cleanup needed
})`)}
      </code>
    </pre>
    <h2 id="disposing-effects"> {Node.text("Disposing Effects")} </h2>
    <p>
      {Node.text("Effect.runWithDisposer() returns a disposer object with a dispose() method to stop the effect. When disposed, any registered cleanup function is called. Use Effect.run() when you don't need the disposer (it returns unit):")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)

// Use Effect.runWithDisposer when you need to stop the effect later
let disposer = Effect.runWithDisposer(() => {
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
      <strong> {Node.text("With cleanup:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let disposer = Effect.runWithDisposer(() => {
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
    <h2 id="dynamic-dependencies"> {Node.text("Dynamic Dependencies")} </h2>
    <p>
      {Node.text("Effects re-track dependencies on each execution, adapting to conditional logic:")}
    </p>
    <pre>
      <code>
        {Node.text(`let showDetails = Signal.make(false)
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
    <h2 id="avoiding-dependencies"> {Node.text("Avoiding Dependencies")} </h2>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Signal.peek()")} </code>
      {Node.text(" to read signals without creating dependencies:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)
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
    <h2 id="example-auto-save"> {Node.text("Example: Auto-save")} </h2>
    <p>
      {Node.text("Here's a practical example of an auto-save effect with proper cleanup:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

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
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Keep effects focused:")} </strong>
      {Node.text(" Each effect should do one thing")}
      </li>
      <li>
        <strong> {Node.text("Clean up resources:")} </strong>
      {Node.text(" Return cleanup functions for timers, listeners, subscriptions, etc.")}
      </li>
      <li>
        <strong> {Node.text("Dispose effects:")} </strong>
      {Node.text(" Use the disposer when effects are no longer needed (e.g., component unmount)")}
      </li>
      <li>
        <strong> {Node.text("Avoid infinite loops:")} </strong>
      {Node.text(" Don't set signals that the effect depends on (unless using equality checks)")}
      </li>
      <li>
        <strong> {Node.text("Use for side effects only:")} </strong>
      {Node.text(" Effects should not compute values (use Computed instead)")}
      </li>
      <li>
        <strong> {Node.text("Return None when no cleanup needed:")} </strong>
      {Node.text(" Be explicit about cleanup needs")}
      </li>
    </ul>
    <h2 id="effects-vs-computed"> {Node.text("Effects vs Computed")} </h2>
    <table>
      <thead>
        <tr>
          <th> {Node.text("Feature")} </th>
          <th> {Node.text("Effect")} </th>
          <th> {Node.text("Computed")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> {Node.text("Purpose")} </td>
          <td> {Node.text("Side effects")} </td>
          <td> {Node.text("Derive values")} </td>
        </tr>
        <tr>
          <td> {Node.text("Returns")} </td>
          <td> {Node.text("unit (or Disposer via runWithDisposer)")} </td>
          <td> {Node.text("Signal")} </td>
        </tr>
        <tr>
          <td> {Node.text("When runs")} </td>
          <td> {Node.text("Immediately and on changes")} </td>
          <td> {Node.text("Immediately and on changes")} </td>
        </tr>
        <tr>
          <td> {Node.text("Result")} </td>
          <td> {Node.text("None (performs actions)")} </td>
          <td> {Node.text("New reactive value")} </td>
        </tr>
      </tbody>
    </table>
    <p>
      {Node.text("Use ")}
      <strong> {Node.text("Computed")} </strong>
      {Node.text(" for pure calculations, ")}
      <strong> {Node.text("Effects")} </strong>
      {Node.text(" for side effects.")}
    </p>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/batching", ~children=[Node.text("Batching")], ())}
      {Node.text(" to optimize multiple updates")}
      </li>
      <li>
        {Node.text("See how effects work in ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      </li>
      <li>
        {Node.text("Try the ")}
      {Router.link(~to="/demos", ~children=[Node.text("Demos")], ())}
      {Node.text(" to see effects in action")}
      </li>
    </ul>
  </div>
}
