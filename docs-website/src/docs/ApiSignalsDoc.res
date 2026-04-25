// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/api-reference/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("This page covers the ")}
      <code> {Node.text("Signal")} </code>
      {Node.text(" module directly and links out to ")}
      <code> {Node.text("Computed")} </code>
      {Node.text(" and ")}
      <code> {Node.text("Effect")} </code>
      {Node.text(" where their behavior intersects with signals.")}
    </p>

    <h2 id="signal-api"> {Node.text("Signal")} </h2>
    <h3 id="type"> {Node.text("Type")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type t<'a>`)}
      </code>
    </pre>
    <p>
      {Node.text("A signal stores a value of type ")}
      <code> {Node.text("'a")} </code>
      {Node.text(", plus the bookkeeping needed for dependency tracking and scheduling.")}
    </p>

    <h3 id="functions"> {Node.text("Functions")} </h3>

    <h4 id="make"> <code> {Node.text("make")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let make: (
  'a,
  ~name: option<string>=?,
  ~equals: option<('a, 'a) => bool>=?,
) => t<'a>`)}
      </code>
    </pre>
    <p>
      {Node.text("Create a signal with an initial value. ")}
      <code> {Node.text("~name")} </code>
      {Node.text(" is only for debugging. ")}
      <code> {Node.text("~equals")} </code>
      {Node.text(" overrides the default strict equality check.")}
    </p>

    <h4 id="get"> <code> {Node.text("get")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let get: t<'a> => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Read the current value and subscribe the active computed or effect, if one exists.")}
    </p>

    <h4 id="peek"> <code> {Node.text("peek")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let peek: t<'a> => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Read the current value without creating a dependency.")}
    </p>

    <h4 id="set"> <code> {Node.text("set")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let set: (t<'a>, 'a) => unit`)}
      </code>
    </pre>
    <p>
      {Node.text("Replace the signal value. Dependents are notified only if the equality check says the value changed.")}
    </p>

    <h4 id="update"> <code> {Node.text("update")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let update: (t<'a>, 'a => 'a) => unit`)}
      </code>
    </pre>
    <p>
      {Node.text("Compute the next value from the current one. Prefer this when the write depends on the existing state.")}
    </p>

    <h4 id="batch"> <code> {Node.text("batch")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let batch: (unit => 'a) => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Defer scheduler flushing until the batch completes, then return the callback result.")}
    </p>

    <h4 id="untrack"> <code> {Node.text("untrack")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let untrack: (unit => 'a) => 'a`)}
      </code>
    </pre>
    <p>
      {Node.text("Run a block without dependency capture. Use this when ")}
      <code> {Node.text("peek")} </code>
      {Node.text(" is too narrow and a full untracked region is clearer.")}
    </p>

    <h2 id="related-signal-apis"> {Node.text("Related APIs")} </h2>
    <h3 id="behavior-notes"> {Node.text("Behavior Notes")} </h3>
    <ul>
      <li>
        <strong> {Node.text("Default equality is strict equality:")} </strong>
        <code> {Node.text("===")} </code>
        {Node.text(" is used unless you pass ")}
        <code> {Node.text("~equals")} </code>
      </li>
      <li>
        <strong> {Node.text("Reads can be tracked or untracked:")} </strong>
        {Node.text(" use get for subscriptions, peek or untrack for snapshots")}
      </li>
      <li>
        <strong> {Node.text("Updates are synchronous:")} </strong>
        {Node.text(" dependents flush immediately unless wrapped in batch")}
      </li>
      <li>
        <strong> {Node.text("Computeds are just signal values at the type level:")} </strong>
        {Node.text(" read them with get or peek")}
      </li>
    </ul>

    <h3 id="companion-modules"> {Node.text("Companion Modules")} </h3>
    <p>
      {Node.text("Most signal-heavy code also uses ")}
      <code> {Node.text("Computed")} </code>
      {Node.text(" and ")}
      <code> {Node.text("Effect")} </code>
      {Node.text(". Their key entry points are:")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Computed.make : (
  unit => 'a,
  ~name: option<string>=?,
  ~equals: option<('a, 'a) => bool>=?,
) => Signal.t<'a>

Computed.dispose : Signal.t<'a> => unit

Effect.run : (
  unit => option<unit => unit>,
  ~name: option<string>=?,
) => unit

Effect.runWithDisposer : (
  unit => option<unit => unit>,
  ~name: option<string>=?,
) => {dispose: unit => unit}`)}
      </code>
    </pre>

    <h2 id="signals-in-practice"> {Node.text("In Practice")} </h2>
    <h3 id="examples"> {Node.text("Examples")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Effect.run(() => {
  Console.log2("count", Signal.get(count))
  Console.log2("doubled", Signal.get(doubled))
  None
})

Signal.update(count, n => n + 1)`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type filters = {query: string, page: int}

let filters = Signal.make(
  {query: "", page: 1},
  ~equals=(a, b) => a.query == b.query && a.page == b.page,
)`)}
      </code>
    </pre>

    <h2 id="where-to-go-next"> {Node.text("Where to Go Next")} </h2>
    <h3 id="see-also"> {Node.text("See Also")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Computeds guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/batching", ~children=[Node.text("Batching")], ())}
      </li>
    </ul>
  </div>
}
