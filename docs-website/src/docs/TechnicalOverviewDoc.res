// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/advanced/technical-overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Node.text("Technical Overview")} </h1>
    <p>
      {Node.text("This document describes the architecture of Xote, a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Node.text("Note:")} </strong>
      {Node.text(" Xote v3.0+ uses rescript-signals for all reactive primitives (Signal, Computed, Effect). This overview focuses on Xote-specific features: Components, Router, and JSX support.")}
      </p>
    </div>
    <h2 id="architecture-overview"> {Node.text("Architecture Overview")} </h2>
    <h3 id="module-structure"> {Node.text("Module Structure")} </h3>
    <p>
      {Node.text("Xote is organized into focused modules:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Reactive Primitives (from rescript-signals):")} </strong>
      </li>
    </ul>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Signal")} </code>
      {Node.text(" - Reactive state cells")}
    </p>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Computed")} </code>
      {Node.text(" - Derived values that auto-update")}
    </p>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Effect")} </code>
      {Node.text(" - Side effects that re-run on changes")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Xote Modules:")} </strong>
      </li>
    </ul>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Xote.Node")} </code>
      {Node.text(" - Component system and virtual DOM")}
    </p>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Xote.Html")} </code>
      {Node.text(" - Common HTML element constructors (div, button, p, ...)")}
    </p>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Xote.XoteJSX")} </code>
      {Node.text(" - Generic JSX v4 implementation")}
    </p>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Xote.Router")} </code>
      {Node.text(" - Signal-based routing")}
    </p>
    <p>
      {Node.text("  - ")}
      <code> {Node.text("Xote.Route")} </code>
      {Node.text(" - Route matching utilities")}
    </p>
    <p>
      {Node.text("Source files in src/ use bare module names (Node.res, Router.res, ...). ReScript's namespacing scopes them under Xote automatically — there is no Xote__ prefix and no central barrel module.")}
    </p>
    <h2 id="reactivity-model"> {Node.text("Reactivity Model")} </h2>
    <p>
      {Node.text("All reactive behavior is provided by ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(":")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Dependency Tracking:")} </strong>
      {Node.text(" When an observer (effect or computed) runs, any Signal.get calls register the signal as a dependency")}
      </li>
      <li>
        <strong> {Node.text("Scheduling:")} </strong>
      {Node.text(" When Signal.set is called, all dependent observers are scheduled and run synchronously")}
      </li>
      <li>
        <strong> {Node.text("Lazy Computeds with Dirty Flagging:")} </strong>
      {Node.text(" When dependencies change, computeds are marked dirty immediately but only recompute when read")}
      </li>
      <li>
        <strong> {Node.text("Structural Equality:")} </strong>
      {Node.text(" Signals use structural equality (==) to check if values have changed, preventing unnecessary updates")}
      </li>
    </ul>
    <h2 id="component-system"> {Node.text("Component System")} </h2>
    <h3 id="virtual-node-types"> {Node.text("Virtual Node Types")} </h3>
    <p>
      {Node.text("Xote uses several node types to represent UI elements:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Element:")} </strong>
      {Node.text(" Standard DOM elements (div, button, input, etc.)")}
      </li>
      <li>
        <strong> {Node.text("Text:")} </strong>
      {Node.text(" Static text nodes")}
      </li>
      <li>
        <strong> {Node.text("SignalText:")} </strong>
      {Node.text(" Reactive text that updates when signals change")}
      </li>
      <li>
        <strong> {Node.text("Fragment:")} </strong>
      {Node.text(" Groups multiple nodes without a wrapper element")}
      </li>
      <li>
        <strong> {Node.text("SignalFragment:")} </strong>
      {Node.text(" Reactive fragment that re-renders when a signal changes")}
      </li>
    </ul>
    <h3 id="rendering-behavior"> {Node.text("Rendering Behavior")} </h3>
    <ul>
      <li>
        <strong> {Node.text("SignalText:")} </strong>
      {Node.text(" Creates a DOM text node and sets up an effect that updates textContent when the signal changes")}
      </li>
      <li>
        <strong> {Node.text("SignalFragment:")} </strong>
      {Node.text(" Uses a container element with display: contents and replaces all children when the signal changes (no diffing)")}
      </li>
      <li>
        <strong> {Node.text("Lists:")} </strong>
      {Node.text(" Implemented as a computed signal + SignalFragment, so the entire list rerenders on any array change")}
      </li>
      <li>
        <strong> {Node.text("Reactive attributes:")} </strong>
      {Node.text(" Set up effects that update the DOM attribute when the signal/computed value changes")}
      </li>
    </ul>
    <h2 id="jsx-support"> {Node.text("JSX Support")} </h2>
    <p>
      {Node.text("Xote supports ReScript's generic JSX v4 for declarative component syntax:")}
    </p>
    <pre>
      <code>
        {Node.text(`{
  "jsx": {
    "version": 4,
    "module": "XoteJSX"
  },
  "compiler-flags": ["-open Xote"]
}`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Features:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Lowercase tags for HTML elements")}
      </li>
      <li>
        {Node.text("Props support for common attributes and events")}
      </li>
      <li>
        {Node.text("Children passed via JSX syntax")}
      </li>
      <li>
        {Node.text("Component functions called with props objects")}
      </li>
    </ul>
    <h2 id="router-architecture"> {Node.text("Router Architecture")} </h2>
    <h3 id="route-matching"> {Node.text("Route Matching")} </h3>
    <p>
      {Node.text("Pattern-based string matching with :param syntax:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("parsePattern(pattern)")} </code>
      {Node.text(" converts patterns like /users/:id into segment arrays")}
      </li>
      <li>
        <code> {Node.text("matchPath(pattern, pathname)")} </code>
      {Node.text(" returns Match(params) or NoMatch")}
      </li>
      <li>
        {Node.text("Parameters returned as Dict.t<string>")}
      </li>
    </ul>
    <h3 id="router-state"> {Node.text("Router State")} </h3>
    <ul>
      <li>
        <strong> {Node.text("Location signal:")} </strong>
      {Node.text(" ")}
      <code> {Node.text("Router.location")} </code>
      {Node.text(" contains {pathname, search, hash}")}
      </li>
      <li>
        <strong> {Node.text("History API integration:")} </strong>
      {Node.text(" Listens to popstate events for back/forward buttons")}
      </li>
      <li>
        <strong> {Node.text("Declarative routing:")} </strong>
      {Node.text(" Uses SignalFragment + Computed for reactive rendering")}
      </li>
      <li>
        <strong> {Node.text("Navigation links:")} </strong>
      {Node.text(" Intercepts clicks to prevent page reload")}
      </li>
    </ul>
    <h2 id="execution-characteristics"> {Node.text("Execution Characteristics")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Push-based Dirty Flagging, Lazy Recomputation:")} </strong>
      {Node.text(" Signals push dirty flags to dependent computeds; actual recomputation is lazy (on read)")}
      </li>
      <li>
        <strong> {Node.text("Auto-tracked:")} </strong>
      {Node.text(" Observers re-track dependencies on every run")}
      </li>
      <li>
        <strong> {Node.text("Synchronous:")} </strong>
      {Node.text(" Updates run synchronously by default")}
      </li>
      <li>
        <strong> {Node.text("Exception safe:")} </strong>
      {Node.text(" Scheduler wrapped in try/catch to ensure tracking state is restored")}
      </li>
    </ul>
    <h2 id="relation-to-tc39-signals-proposal"> {Node.text("Relation to TC39 Signals Proposal")} </h2>
    <p>
      {Node.text("Xote's reactive primitives (via rescript-signals) are inspired by the ")}
      <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Node.text("TC39 Signals proposal")} </a>
      {Node.text(":")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Aligned concepts:")} </strong>
      </li>
    </ul>
    <p>
      {Node.text("  - Automatic dependency tracking on read")}
    </p>
    <p>
      {Node.text("  - Observer-based recomputation and re-tracking")}
    </p>
    <p>
      {Node.text("  - Structural equality checks")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("Key differences:")} </strong>
      </li>
    </ul>
    <p>
      {Node.text("  - Computeds use lazy evaluation with push-based dirty flagging, similar to the proposal's pull-based approach")}
    </p>
    <p>
      {Node.text("  - Synchronous scheduling rather than microtask-based")}
    </p>
    <p>
      {Node.text("  - Effects can return cleanup callbacks (Some/None pattern)")}
    </p>
    <h2 id="api-summary"> {Node.text("API Summary")} </h2>
    <h3 id="reactive-primitives"> {Node.text("Reactive Primitives")} </h3>
    <pre>
      <code>
        {Node.text(`Signal.make : 'a => t<'a>
Signal.get : t<'a> => 'a
Signal.peek : t<'a> => 'a
Signal.set : (t<'a>, 'a) => unit
Signal.update : (t<'a>, 'a => 'a) => unit

Computed.make : (unit => 'a) => t<'a>
Computed.dispose : t<'a> => unit

Effect.run : (unit => option<unit => unit>) => {dispose: unit => unit}`)}
      </code>
    </pre>
    <h3 id="component-helpers"> {Node.text("Component Helpers")} </h3>
    <pre>
      <code>
        {Node.text(`Node.text : string => node
Node.signalText : (unit => string) => node
Node.list : (t<array<'a>>, 'a => node) => node
Node.listKeyed : (t<array<'a>>, 'a => string, 'a => node) => node
Node.mount : (node, Dom.element) => unit
Node.mountById : (node, string) => unit`)}
      </code>
    </pre>
    <h3 id="router-helpers"> {Node.text("Router Helpers")} </h3>
    <pre>
      <code>
        {Node.text(`Router.init : unit => unit
Router.location : t<{pathname: string, search: string, hash: string}>
Router.push : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.replace : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.routes : array<{pattern: string, render: params => node}> => node
Router.link : (~to: string, ~attrs: array=?, ~children: array=?, unit) => node`)}
      </code>
    </pre>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Trust auto-disposal:")} </strong>
      {Node.text(" Computeds auto-dispose when subscribers drop to zero")}
      </li>
      <li>
        <strong> {Node.text("Use structural equality:")} </strong>
      {Node.text(" Signal.set only notifies if values differ")}
      </li>
      <li>
        <strong> {Node.text("Prefer JSX:")} </strong>
      {Node.text(" More concise and familiar syntax")}
      </li>
      <li>
        <strong> {Node.text("Keep components small:")} </strong>
      {Node.text(" Each component should do one thing well")}
      </li>
      <li>
        <strong> {Node.text("Use keyed lists:")} </strong>
      {Node.text(" For efficient reconciliation of dynamic lists")}
      </li>
    </ul>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Explore the ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Core Concepts")], ())}
      {Node.text(" for reactive primitives")}
      </li>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(" for building UIs")}
      </li>
      <li>
        {Node.text("Check out ")}
      <a href="https://brnrdog.github.io/rescript-signals" target="_blank"> {Node.text("rescript-signals")} </a>
      {Node.text(" for reactive implementation details")}
      </li>
    </ul>
  </div>
}
