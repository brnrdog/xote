// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/api-reference/signals.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("This page covers the ")}
      <code> {View.text("Signal")} </code>
      {View.text(" module directly and links out to ")}
      <code> {View.text("Computed")} </code>
      {View.text(" and ")}
      <code> {View.text("Effect")} </code>
      {View.text(" where their behavior intersects with signals.")}
    </p>

    <h2 id="signal-api"> {View.text("Signal")} </h2>
    <h3 id="type"> {View.text("Type")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`type t<'a>`)}
      </code>
    </pre>
    <p>
      {View.text("A signal stores a value of type ")}
      <code> {View.text("'a")} </code>
      {View.text(", plus the bookkeeping needed for dependency tracking and scheduling.")}
    </p>

    <h3 id="functions"> {View.text("Functions")} </h3>

    <h4 id="make"> <code> {View.text("make")} </code> </h4>
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
      {View.text("Create a signal with an initial value. ")}
      <code> {View.text("~name")} </code>
      {View.text(" is only for debugging. ")}
      <code> {View.text("~equals")} </code>
      {View.text(" overrides the default strict equality check.")}
    </p>

    <h4 id="get"> <code> {View.text("get")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let get: t<'a> => 'a`)}
      </code>
    </pre>
    <p>
      {View.text("Read the current value and subscribe the active computed or effect, if one exists.")}
    </p>

    <h4 id="peek"> <code> {View.text("peek")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let peek: t<'a> => 'a`)}
      </code>
    </pre>
    <p>
      {View.text("Read the current value without creating a dependency.")}
    </p>

    <h4 id="set"> <code> {View.text("set")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let set: (t<'a>, 'a) => unit`)}
      </code>
    </pre>
    <p>
      {View.text("Replace the signal value. Dependents are notified only if the equality check says the value changed.")}
    </p>

    <h4 id="update"> <code> {View.text("update")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let update: (t<'a>, 'a => 'a) => unit`)}
      </code>
    </pre>
    <p>
      {View.text("Compute the next value from the current one. Prefer this when the write depends on the existing state.")}
    </p>

    <h4 id="batch"> <code> {View.text("batch")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let batch: (unit => 'a) => 'a`)}
      </code>
    </pre>
    <p>
      {View.text("Defer scheduler flushing until the batch completes, then return the callback result.")}
    </p>

    <h4 id="untrack"> <code> {View.text("untrack")} </code> </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let untrack: (unit => 'a) => 'a`)}
      </code>
    </pre>
    <p>
      {View.text("Run a block without dependency capture. Use this when ")}
      <code> {View.text("peek")} </code>
      {View.text(" is too narrow and a full untracked region is clearer.")}
    </p>

    <h2 id="related-signal-apis"> {View.text("Related APIs")} </h2>
    <h3 id="behavior-notes"> {View.text("Behavior Notes")} </h3>
    <ul>
      <li>
        <strong> {View.text("Default equality is strict equality:")} </strong>
        <code> {View.text("===")} </code>
        {View.text(" is used unless you pass ")}
        <code> {View.text("~equals")} </code>
      </li>
      <li>
        <strong> {View.text("Reads can be tracked or untracked:")} </strong>
        {View.text(" use get for subscriptions, peek or untrack for snapshots")}
      </li>
      <li>
        <strong> {View.text("Updates are synchronous:")} </strong>
        {View.text(" dependents flush immediately unless wrapped in batch")}
      </li>
      <li>
        <strong> {View.text("Computeds are just signal values at the type level:")} </strong>
        {View.text(" read them with get or peek")}
      </li>
    </ul>

    <h3 id="companion-modules"> {View.text("Companion Modules")} </h3>
    <p>
      {View.text("Most signal-heavy code also uses ")}
      <code> {View.text("Computed")} </code>
      {View.text(" and ")}
      <code> {View.text("Effect")} </code>
      {View.text(". Their key entry points are:")}
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

    <h2 id="signals-in-practice"> {View.text("In Practice")} </h2>
    <h3 id="examples"> {View.text("Examples")} </h3>
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

    <h2 id="where-to-go-next"> {View.text("Where to Go Next")} </h2>
    <h3 id="see-also"> {View.text("See Also")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Signals guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[View.text("Computeds guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[View.text("Effects guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/batching", ~children=[View.text("Batching")], ())}
      </li>
    </ul>
  </div>
}
