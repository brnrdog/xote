// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/core-concepts/effects.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("Effects connect the reactive graph to the outside world. They run immediately, track the signals they read, and re-run when those dependencies change.")}
    </p>
    <p>
      {Node.text("Use them for DOM APIs, timers, network coordination, logging, or any other work that should happen because state changed. Do not use them to compute values that could stay inside the reactive graph.")}
    </p>

    <h2 id="working-with-effects"> {Node.text("Working with Effects")} </h2>
    <h3 id="creating-effects"> {Node.text("Creating Effects")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Effect.run")} </code>
      {Node.text(" for fire-and-forget effects and ")}
      <code> {Node.text("Effect.runWithDisposer")} </code>
      {Node.text(" when you need to stop the effect manually.")}
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

    <h3 id="dependency-tracking"> {Node.text("Dependency Tracking")} </h3>
    <p>
      {Node.text("Effects track dependencies automatically. Every ")}
      <code> {Node.text("Signal.get")} </code>
      {Node.text(" call inside the effect subscribes the effect to that signal. On each run, dependencies are cleared and tracked again.")}
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

    <h3 id="cleanup-callbacks"> {Node.text("Cleanup Callbacks")} </h3>
    <p>
      {Node.text("An effect can return ")}
      <code> {Node.text("Some(cleanupFn)")} </code>
      {Node.text(" or ")}
      <code> {Node.text("None")} </code>
      {Node.text(". Cleanup runs before the next execution and when the effect is disposed.")}
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

    <h3 id="disposing-effects"> {Node.text("Disposing Effects")} </h3>
    <p>
      {Node.text("When you need explicit teardown, use ")}
      <code> {Node.text("Effect.runWithDisposer")} </code>
      {Node.text(". It returns an object with a ")}
      <code> {Node.text("dispose()")} </code>
      {Node.text(" method.")}
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

    <h3 id="avoiding-dependencies"> {Node.text("Avoiding Dependencies")} </h3>
    <p>
      {Node.text("If you need a value inside an effect without subscribing to it, use ")}
      <code> {Node.text("Signal.peek")} </code>
      {Node.text(" for one read or ")}
      <code> {Node.text("Signal.untrack")} </code>
      {Node.text(" for a larger block.")}
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

    <h2 id="effects-common-patterns"> {Node.text("Common Patterns")} </h2>
    <h3 id="common-use-cases"> {Node.text("Common Use Cases")} </h3>
    <ul>
      <li>
        <strong> {Node.text("Browser APIs:")} </strong>
        {Node.text(" document title, localStorage, media queries, history, and scroll state")}
      </li>
      <li>
        <strong> {Node.text("Timers and subscriptions:")} </strong>
        {Node.text(" intervals, event listeners, sockets, and observers")}
      </li>
      <li>
        <strong> {Node.text("Synchronization:")} </strong>
        {Node.text(" push reactive state into another system")}
      </li>
      <li>
        <strong> {Node.text("Diagnostics:")} </strong>
        {Node.text(" logging, instrumentation, and dev-only inspection")}
      </li>
    </ul>

    <h3 id="example-auto-save"> {Node.text("Example: Auto-save")} </h3>
    <p>
      {Node.text("This pattern is common: track a draft, debounce the work, and clean up old timers when the draft changes again.")}
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

    <h3 id="effects-vs-computed"> {Node.text("Effects vs Computed")} </h3>
    <p>
      {Node.text("Ask one question: is the result another value inside the reactive graph, or is it work outside the graph?")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Use a computed")} </strong>
        {Node.text(" when you are deriving a value from other values")}
      </li>
      <li>
        <strong> {Node.text("Use an effect")} </strong>
        {Node.text(" when you need to talk to something external")}
      </li>
    </ul>

    <h2 id="effects-working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Keep one effect focused on one kind of external work so cleanup stays obvious.")}
      </li>
      <li>
        {Node.text("Return cleanup whenever you allocate timers, listeners, requests, or subscriptions.")}
      </li>
      <li>
        {Node.text("Do not use effects to keep derived state in sync. If the output is another value, use a computed.")}
      </li>
      <li>
        {Node.text("Use ")}
        <code> {Node.text("peek")} </code>
        {Node.text(" and ")}
        <code> {Node.text("untrack")} </code>
        {Node.text(" deliberately, because they opt out of tracking.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Node.text("Move to Components")], ())}
        {Node.text(" to see how effects fit into real UI code.")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/batching", ~children=[Node.text("Read Batching")], ())}
        {Node.text(" when several writes should flush as one coordinated update.")}
      </li>
    </ul>
  </div>
}
