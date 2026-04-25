// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/advanced/technical-overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("This page explains how Xote is put together at a module and runtime level. It is meant for readers who already know the public API and want the internal model behind it.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Scope:")} </strong>
        {Node.text(" This is architecture-level guidance, not a substitute for the API docs.")}
      </p>
    </div>

    <h2 id="system-shape"> {Node.text("System Shape")} </h2>
    <h3 id="architecture-overview"> {Node.text("Architecture Overview")} </h3>
    <h3 id="module-structure"> {Node.text("Module Structure")} </h3>
    <p>
      {Node.text("The public surface is intentionally small. Xote re-exports reactive primitives and layers UI-focused modules on top.")}
    </p>
    <ul>
      <li>
        <code> {Node.text("Signal")} </code>
        {Node.text(", ")}
        <code> {Node.text("Computed")} </code>
        {Node.text(", ")}
        <code> {Node.text("Effect")} </code>
        {Node.text(" - state, derived state, and side effects")}
      </li>
      <li>
        <code> {Node.text("Node")} </code>
        {Node.text(" and ")}
        <code> {Node.text("Html")} </code>
        {Node.text(" - node constructors, attributes, mounting, and HTML helpers")}
      </li>
      <li>
        <code> {Node.text("XoteJSX")} </code>
        {Node.text(" - generic JSX v4 integration")}
      </li>
      <li>
        <code> {Node.text("Router")} </code>
        {Node.text(" and ")}
        <code> {Node.text("Route")} </code>
        {Node.text(" - navigation and route matching")}
      </li>
      <li>
        <code> {Node.text("SSR")} </code>
        {Node.text(", ")}
        <code> {Node.text("SSRState")} </code>
        {Node.text(", ")}
        <code> {Node.text("Hydration")} </code>
        {Node.text(", and ")}
        <code> {Node.text("SSRContext")} </code>
        {Node.text(" - server rendering and client resume")}
      </li>
    </ul>
    <p>
      {Node.text("Source files stay as bare module names in ")}
      <code> {Node.text("src/")} </code>
      {Node.text(". ReScript's ")}
      <code> {Node.text("namespace: true")} </code>
      {Node.text(" setting scopes them under ")}
      <code> {Node.text("Xote")} </code>
      {Node.text(" for consumers.")}
    </p>

    <h2 id="runtime-model"> {Node.text("Runtime Model")} </h2>
    <h3 id="reactivity-model"> {Node.text("Reactivity Model")} </h3>
    <p>
      {Node.text("Xote delegates reactivity to rescript-signals. The important runtime properties are:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Tracked reads:")} </strong>
        {Node.text(" Signal.get subscribes the active observer")}
      </li>
      <li>
        <strong> {Node.text("Synchronous scheduling:")} </strong>
        {Node.text(" updates flush immediately unless wrapped in Signal.batch")}
      </li>
      <li>
        <strong> {Node.text("Lazy computeds:")} </strong>
        {Node.text(" upstream changes mark them dirty, but recomputation happens on read")}
      </li>
      <li>
        <strong> {Node.text("Equality checks on write:")} </strong>
        {Node.text(" signals notify only when the new value is considered different")}
      </li>
    </ul>

    <h3 id="component-rendering"> {Node.text("Component Rendering")} </h3>
    <p>
      {Node.text("Xote does not rely on a general virtual DOM diff for updates. Components produce node structures once, and reactive nodes handle fine-grained updates after mounting.")}
    </p>
    <p>
      {Node.text("The public node variants cover the main cases: text, elements, fragments, signal-backed text, signal-backed fragments, lazy components, and keyed lists.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Node.text : string => node
Node.signalText : (unit => string) => node
Node.fragment : array<node> => node
Node.signalFragment : Signal.t<array<node>> => node
Node.list : (Signal.t<array<'a>>, 'a => node) => node
Node.keyedList : (Signal.t<array<'a>>, 'a => string, 'a => node) => node`)}
      </code>
    </pre>

    <h3 id="router-architecture"> {Node.text("Router Architecture")} </h3>
    <p>
      {Node.text("The router stores its state in a global singleton keyed with ")}
      <code> {Node.text("Symbol.for")} </code>
      {Node.text(". That keeps routing shared even if more than one Xote bundle ends up on the page.")}
    </p>
    <p>
      {Node.text("At the public layer, the router is just a signal-driven location source plus helpers for matching and navigation.")}
    </p>

    <h3 id="ssr-and-hydration"> {Node.text("SSR and Hydration")} </h3>
    <p>
      {Node.text("Server rendering serializes the component tree to HTML and inserts comment markers around reactive boundaries. Hydration walks that DOM, finds the markers, and reattaches reactive behavior instead of rebuilding the tree from scratch.")}
    </p>
    <p>
      {Node.text("SSRState is separate from HTML rendering. That split keeps state transfer explicit and codec-driven instead of hiding it behind a framework convention.")}
    </p>

    <h3 id="execution-characteristics"> {Node.text("Execution Characteristics")} </h3>
    <ul>
      <li>
        <strong> {Node.text("Component functions are cheap to reason about:")} </strong>
        {Node.text(" most of the time they run once")}
      </li>
      <li>
        <strong> {Node.text("Reactive work is localized:")} </strong>
        {Node.text(" only consumers of changed signals update")}
      </li>
      <li>
        <strong> {Node.text("Owner-based cleanup prevents leaks:")} </strong>
        {Node.text(" DOM removal disposes associated reactive resources")}
      </li>
      <li>
        <strong> {Node.text("Batching is explicit:")} </strong>
        {Node.text(" coordinated writes are opt-in, not automatic")}
      </li>
    </ul>

    <h2 id="reference-map"> {Node.text("Reference Map")} </h2>
    <h3 id="api-summary"> {Node.text("API Summary")} </h3>
    <h3 id="reactive-primitives"> {Node.text("Reactive Primitives")} </h3>
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
    <h3 id="component-helpers"> {Node.text("Component Helpers")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Node.attr : (string, string) => (string, Node.attrValue)
Node.signalAttr : (string, Signal.t<string>) => (string, Node.attrValue)
Node.computedAttr : (string, unit => string) => (string, Node.attrValue)
Node.mountById : (Node.node, string) => unit`)}
      </code>
    </pre>
    <h3 id="router-helpers"> {Node.text("Router Helpers")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.init : (~basePath: string=?, unit) => unit
Router.initSSR : (~basePath: string=?, ~pathname: string, ~search: string=?, ~hash: string=?, unit) => unit
Router.location : unit => Signal.t<{pathname: string, search: string, hash: string}>
Router.push : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.routes : array<routeConfig> => Node.node`)}
      </code>
    </pre>

    <h2 id="working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Model derived values as computeds so write paths stay smaller and easier to trust.")}
      </li>
      <li>
        {Node.text("Keep the public explanation aligned with the real module boundaries: signals, nodes, router, and SSR each own a distinct concern.")}
      </li>
      <li>
        {Node.text("Treat ")}
        <code> {Node.text("SSRState")} </code>
        {Node.text(" as explicit infrastructure. Hidden state transfer is harder to debug.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Go back to the Core Modules guides")], ())}
        {Node.text(" for the day-to-day API surface.")}
      </li>
      <li>
        {Router.link(~to="/docs/api/signals", ~children=[Node.text("Use the Signals API page")], ())}
        {Node.text(" as the quick reference while reading the architecture back into the code.")}
      </li>
    </ul>
  </div>
}
