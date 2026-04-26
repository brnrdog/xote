// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/advanced/technical-overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("This page explains how Xote is put together at a module and runtime level. It is meant for readers who already know the public API and want the internal model behind it.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {View.text("Scope:")} </strong>
        {View.text(" This is architecture-level guidance, not a substitute for the API docs.")}
      </p>
    </div>

    <h2 id="system-shape"> {View.text("System Shape")} </h2>
    <h3 id="architecture-overview"> {View.text("Architecture Overview")} </h3>
    <h3 id="module-structure"> {View.text("Module Structure")} </h3>
    <p>
      {View.text("The public surface is intentionally small. Xote re-exports reactive primitives and layers UI-focused modules on top.")}
    </p>
    <ul>
      <li>
        <code> {View.text("Signal")} </code>
        {View.text(", ")}
        <code> {View.text("Computed")} </code>
        {View.text(", ")}
        <code> {View.text("Effect")} </code>
        {View.text(" - state, derived state, and side effects")}
      </li>
      <li>
        <code> {View.text("View")} </code>
        {View.text(" and ")}
        <code> {View.text("Html")} </code>
        {View.text(" - UI node constructors, mounting, and HTML helpers")}
      </li>
      <li>
        <code> {View.text("XoteJSX")} </code>
        {View.text(" - generic JSX v4 integration")}
      </li>
      <li>
        <code> {View.text("Router")} </code>
        {View.text(" and ")}
        <code> {View.text("Route")} </code>
        {View.text(" - navigation and route matching")}
      </li>
      <li>
        <code> {View.text("SSR")} </code>
        {View.text(", ")}
        <code> {View.text("SSRState")} </code>
        {View.text(", ")}
        <code> {View.text("Hydration")} </code>
        {View.text(", and ")}
        <code> {View.text("SSRContext")} </code>
        {View.text(" - server rendering and client resume")}
      </li>
    </ul>
    <p>
      {View.text("Source files stay as bare module names in ")}
      <code> {View.text("src/")} </code>
      {View.text(". ReScript's ")}
      <code> {View.text("namespace: true")} </code>
      {View.text(" setting scopes them under ")}
      <code> {View.text("Xote")} </code>
      {View.text(" for consumers.")}
    </p>

    <h2 id="runtime-model"> {View.text("Runtime Model")} </h2>
    <h3 id="reactivity-model"> {View.text("Reactivity Model")} </h3>
    <p>
      {View.text("Xote delegates reactivity to rescript-signals. The important runtime properties are:")}
    </p>
    <ul>
      <li>
        <strong> {View.text("Tracked reads:")} </strong>
        {View.text(" Signal.get subscribes the active observer")}
      </li>
      <li>
        <strong> {View.text("Synchronous scheduling:")} </strong>
        {View.text(" updates flush immediately unless wrapped in Signal.batch")}
      </li>
      <li>
        <strong> {View.text("Lazy computeds:")} </strong>
        {View.text(" upstream changes mark them dirty, but recomputation happens on read")}
      </li>
      <li>
        <strong> {View.text("Equality checks on write:")} </strong>
        {View.text(" signals notify only when the new value is considered different")}
      </li>
    </ul>

    <h3 id="component-rendering"> {View.text("View Rendering")} </h3>
    <p>
      {View.text("Xote does not rely on a general virtual DOM diff for updates. View functions and JSX components produce node structures once, and reactive nodes handle fine-grained updates after mounting.")}
    </p>
    <p>
      {View.text("The public view variants cover the main cases: text, elements, fragments, signal-backed text, signal-backed fragments, lazy components, and keyed lists.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`View.text : string => node
View.signalText : (unit => string) => node
View.fragment : array<node> => node
View.signalFragment : Signal.t<array<node>> => node
View.each : (Signal.t<array<'a>>, 'a => node) => node
View.eachWithKey : (Signal.t<array<'a>>, 'a => string, 'a => node) => node`)}
      </code>
    </pre>

    <h3 id="router-architecture"> {View.text("Router Architecture")} </h3>
    <p>
      {View.text("The router stores its state in a global singleton keyed with ")}
      <code> {View.text("Symbol.for")} </code>
      {View.text(". That keeps routing shared even if more than one Xote bundle ends up on the page.")}
    </p>
    <p>
      {View.text("At the public layer, the router is just a signal-driven location source plus helpers for matching and navigation.")}
    </p>

    <h3 id="ssr-and-hydration"> {View.text("SSR and Hydration")} </h3>
    <p>
      {View.text("Server rendering serializes the component tree to HTML and inserts comment markers around reactive boundaries. Hydration walks that DOM, finds the markers, and reattaches reactive behavior instead of rebuilding the tree from scratch.")}
    </p>
    <p>
      {View.text("SSRState is separate from HTML rendering. That split keeps state transfer explicit and codec-driven instead of hiding it behind a framework convention.")}
    </p>

    <h3 id="execution-characteristics"> {View.text("Execution Characteristics")} </h3>
    <ul>
      <li>
        <strong> {View.text("Component functions are cheap to reason about:")} </strong>
        {View.text(" most of the time they run once")}
      </li>
      <li>
        <strong> {View.text("Reactive work is localized:")} </strong>
        {View.text(" only consumers of changed signals update")}
      </li>
      <li>
        <strong> {View.text("Owner-based cleanup prevents leaks:")} </strong>
        {View.text(" DOM removal disposes associated reactive resources")}
      </li>
      <li>
        <strong> {View.text("Batching is explicit:")} </strong>
        {View.text(" coordinated writes are opt-in, not automatic")}
      </li>
    </ul>

    <h2 id="reference-map"> {View.text("Reference Map")} </h2>
    <h3 id="api-summary"> {View.text("API Summary")} </h3>
    <h3 id="reactive-primitives"> {View.text("Reactive Primitives")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Signal.make : ('a, ~name: option<string>=?, ~equals: option<('a, 'a) => bool>=?) => Signal.t<'a>
Signal.get : Signal.t<'a> => 'a
Signal.peek : Signal.t<'a> => 'a
Signal.set : (Signal.t<'a>, 'a) => unit
Signal.update : (Signal.t<'a>, 'a => 'a) => unit
Signal.batch : (unit => 'a) => 'a
Computed.make : (unit => 'a, ~name: option<string>=?, ~equals: option<('a, 'a) => bool>=?) => Signal.t<'a>
Effect.run : (unit => option<unit => unit>, ~name: option<string>=?) => unit`)}
      </code>
    </pre>
    <h3 id="component-helpers"> {View.text("View Helpers")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`View.Attr.string : (string, string) => (string, View.attrValue)
View.Attr.signal : (string, Signal.t<string>) => (string, View.attrValue)
View.Attr.compute : (string, unit => string) => (string, View.attrValue)
View.mountById : (View.node, string) => unit`)}
      </code>
    </pre>
    <h3 id="router-helpers"> {View.text("Router Helpers")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.init : (~basePath: string=?, unit) => unit
Router.initSSR : (~basePath: string=?, ~pathname: string, ~search: string=?, ~hash: string=?, unit) => unit
Router.location : unit => Signal.t<{pathname: string, search: string, hash: string}>
Router.push : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.routes : array<routeConfig> => View.node`)}
      </code>
    </pre>

    <h2 id="working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Model derived values as computeds so write paths stay smaller and easier to trust.")}
      </li>
      <li>
        {View.text("Keep the public explanation aligned with the real module boundaries: signals, views, router, and SSR each own a distinct concern.")}
      </li>
      <li>
        {View.text("Treat ")}
        <code> {View.text("SSRState")} </code>
        {View.text(" as explicit infrastructure. Hidden state transfer is harder to debug.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Go back to the Core Modules guides")], ())}
        {View.text(" for the day-to-day API surface.")}
      </li>
      <li>
        {Router.link(~to="/docs/api/signals", ~children=[View.text("Use the Signals API page")], ())}
        {View.text(" as the quick reference while reading the architecture back into the code.")}
      </li>
    </ul>
  </div>
}
