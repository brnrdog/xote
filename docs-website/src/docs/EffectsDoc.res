// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/effects.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("Effects connect the reactive graph to the outside world. They run immediately, track the signals they read, and re-run when those dependencies change.")}
    </p>
    <p>
      {View.text("Use them for DOM APIs, timers, network coordination, logging, or any other work that should happen because state changed. Do not use them to compute values that could stay inside the reactive graph.")}
    </p>

    <h2 id="working-with-effects"> {View.text("Working with Effects")} </h2>
    <h3 id="creating-effects"> {View.text("Creating Effects")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("Effect.run")} </code>
      {View.text(" for fire-and-forget effects and ")}
      <code> {View.text("Effect.runWithDisposer")} </code>
      {View.text(" when you need to stop the effect manually.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = Signal.make(0)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))
  None
})`)}
      </code>
    </pre>

    <h3 id="dependency-tracking"> {View.text("Dependency Tracking")} </h3>
    <p>
      {View.text("Effects track dependencies automatically. Every ")}
      <code> {View.text("Signal.get")} </code>
      {View.text(" call inside the effect subscribes the effect to that signal. On each run, dependencies are cleared and tracked again.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let showDetails = Signal.make(false)
let name = Signal.make("Ada")
let age = Signal.make(36)

Effect.run(() => {
  if Signal.get(showDetails) {
    Console.log2("Name:", Signal.get(name))
    Console.log2("Age:", Signal.get(age))
  }
  None
})`)}
      </code>
    </pre>

    <h3 id="cleanup-callbacks"> {View.text("Cleanup Callbacks")} </h3>
    <p>
      {View.text("An effect can return ")}
      <code> {View.text("Some(cleanupFn)")} </code>
      {View.text(" or ")}
      <code> {View.text("None")} </code>
      {View.text(". Cleanup runs before the next execution and when the effect is disposed.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let url = Signal.make("/api/users")

Effect.run(() => {
  let currentUrl = Signal.get(url)
  let controller = AbortController.make()

  fetch(currentUrl, {"signal": controller##signal})->ignore

  Some(() => controller##abort())
})`)}
      </code>
    </pre>

    <h3 id="disposing-effects"> {View.text("Disposing Effects")} </h3>
    <p>
      {View.text("When you need explicit teardown, use ")}
      <code> {View.text("Effect.runWithDisposer")} </code>
      {View.text(". It returns an object with a ")}
      <code> {View.text("dispose()")} </code>
      {View.text(" method.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let disposer = Effect.runWithDisposer(() => {
  Console.log(Signal.get(count))
  None
})

disposer.dispose()`)}
      </code>
    </pre>

    <h3 id="avoiding-dependencies"> {View.text("Avoiding Dependencies")} </h3>
    <p>
      {View.text("If you need a value inside an effect without subscribing to it, use ")}
      <code> {View.text("Signal.peek")} </code>
      {View.text(" for one read or ")}
      <code> {View.text("Signal.untrack")} </code>
      {View.text(" for a larger block.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let debug = Signal.make(true)

Effect.run(() => {
  let tracked = Signal.get(count)

  if Signal.peek(debug) {
    Console.log2("Debug count:", tracked)
  }

  None
})`)}
      </code>
    </pre>

    <h2 id="effects-common-patterns"> {View.text("Common Patterns")} </h2>
    <h3 id="common-use-cases"> {View.text("Common Use Cases")} </h3>
    <ul>
      <li>
        <strong> {View.text("Browser APIs:")} </strong>
        {View.text(" document title, localStorage, media queries, history, and scroll state")}
      </li>
      <li>
        <strong> {View.text("Timers and subscriptions:")} </strong>
        {View.text(" intervals, event listeners, sockets, and observers")}
      </li>
      <li>
        <strong> {View.text("Synchronization:")} </strong>
        {View.text(" push reactive state into another system")}
      </li>
      <li>
        <strong> {View.text("Diagnostics:")} </strong>
        {View.text(" logging, instrumentation, and dev-only inspection")}
      </li>
    </ul>

    <h3 id="example-auto-save"> {View.text("Example: Auto-save")} </h3>
    <p>
      {View.text("This pattern is common: track a draft, debounce the work, and clean up old timers when the draft changes again.")}
    </p>
    <DocsExamplePanel
      filename="DraftAutoSave.res"
      caption="fig. 1 - an effect debounces auto-save work"
      code={`open Xote

let draft = Signal.make("")
let saveStatus = Signal.make("Start typing to queue a save")

let handleInput = evt => {
  let target: {"value": string} = (evt->Obj.magic)["target"]
  Signal.set(draft, target["value"])
}

Effect.run(() => {
  let currentDraft = Signal.get(draft)->String.trim

  if currentDraft == "" {
    Signal.set(saveStatus, "Start typing to queue a save")
    None
  } else {
    Signal.set(saveStatus, "Saving in 600ms")

  let timeoutId = setTimeout(() => {
      Console.log2("Saving draft:", currentDraft)
  }, 500)

    Some(() => clearTimeout(timeoutId))
  }
})`}
    >
      <EffectAutosaveDemo />
    </DocsExamplePanel>

    <h3 id="effects-vs-computed"> {View.text("Effects vs Computed")} </h3>
    <p>
      {View.text("Ask one question: is the result another value inside the reactive graph, or is it work outside the graph?")}
    </p>
    <ul>
      <li>
        <strong> {View.text("Use a computed")} </strong>
        {View.text(" when you are deriving a value from other values")}
      </li>
      <li>
        <strong> {View.text("Use an effect")} </strong>
        {View.text(" when you need to talk to something external")}
      </li>
    </ul>

    <h2 id="effects-working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Keep one effect focused on one kind of external work so cleanup stays obvious.")}
      </li>
      <li>
        {View.text("Return cleanup whenever you allocate timers, listeners, requests, or subscriptions.")}
      </li>
      <li>
        {View.text("Do not use effects to keep derived state in sync. If the output is another value, use a computed.")}
      </li>
      <li>
        {View.text("Use ")}
        <code> {View.text("peek")} </code>
        {View.text(" and ")}
        <code> {View.text("untrack")} </code>
        {View.text(" deliberately, because they opt out of tracking.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("Move to View")], ())}
        {View.text(" to see how effects fit into real UI code.")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/batching", ~children=[View.text("Read Batching")], ())}
        {View.text(" when several writes should flush as one coordinated update.")}
      </li>
    </ul>
  </div>
}
