// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/advanced/technical-overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Technical Overview")} </h1>
    <p>
      {Component.text("This document describes the architecture of Xote, a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.")}
    </p>
    <div class="info-box">
      <p>
        <strong> {Component.text("Note:")} </strong>
      {Component.text(" Xote v3.0+ uses rescript-signals for all reactive primitives (Signal, Computed, Effect). This overview focuses on Xote-specific features: Components, Router, and JSX support.")}
      </p>
    </div>
    <h2> {Component.text("Architecture Overview")} </h2>
    <h3> {Component.text("Module Structure")} </h3>
    <p>
      {Component.text("Xote is organized into focused modules:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Reactive Primitives (from rescript-signals):")} </strong>
      </li>
    </ul>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Signal")} </code>
      {Component.text(" - Reactive state cells")}
    </p>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Computed")} </code>
      {Component.text(" - Derived values that auto-update")}
    </p>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Effect")} </code>
      {Component.text(" - Side effects that re-run on changes")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Xote Modules:")} </strong>
      </li>
    </ul>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Xote__Component")} </code>
      {Component.text(" - Component system and virtual DOM")}
    </p>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Xote__JSX")} </code>
      {Component.text(" - Generic JSX v4 implementation")}
    </p>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Xote__Router")} </code>
      {Component.text(" - Signal-based routing")}
    </p>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Xote__Route")} </code>
      {Component.text(" - Route matching utilities")}
    </p>
    <p>
      {Component.text("  - ")}
      <code> {Component.text("Xote.res")} </code>
      {Component.text(" - Public API surface")}
    </p>
    <h2> {Component.text("Reactivity Model")} </h2>
    <p>
      {Component.text("All reactive behavior is provided by ")}
      <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(":")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Dependency Tracking:")} </strong>
      {Component.text(" When an observer (effect or computed) runs, any Signal.get calls register the signal as a dependency")}
      </li>
      <li>
        <strong> {Component.text("Scheduling:")} </strong>
      {Component.text(" When Signal.set is called, all dependent observers are scheduled and run synchronously")}
      </li>
      <li>
        <strong> {Component.text("Push-based Computeds:")} </strong>
      {Component.text(" Computeds eagerly recompute when dependencies change and push results to their backing signal")}
      </li>
      <li>
        <strong> {Component.text("Structural Equality:")} </strong>
      {Component.text(" Signals use structural equality (==) to check if values have changed, preventing unnecessary updates")}
      </li>
    </ul>
    <h2> {Component.text("Component System")} </h2>
    <h3> {Component.text("Virtual Node Types")} </h3>
    <p>
      {Component.text("Xote uses several node types to represent UI elements:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Element:")} </strong>
      {Component.text(" Standard DOM elements (div, button, input, etc.)")}
      </li>
      <li>
        <strong> {Component.text("Text:")} </strong>
      {Component.text(" Static text nodes")}
      </li>
      <li>
        <strong> {Component.text("SignalText:")} </strong>
      {Component.text(" Reactive text that updates when signals change")}
      </li>
      <li>
        <strong> {Component.text("Fragment:")} </strong>
      {Component.text(" Groups multiple nodes without a wrapper element")}
      </li>
      <li>
        <strong> {Component.text("SignalFragment:")} </strong>
      {Component.text(" Reactive fragment that re-renders when a signal changes")}
      </li>
    </ul>
    <h3> {Component.text("Rendering Behavior")} </h3>
    <ul>
      <li>
        <strong> {Component.text("SignalText:")} </strong>
      {Component.text(" Creates a DOM text node and sets up an effect that updates textContent when the signal changes")}
      </li>
      <li>
        <strong> {Component.text("SignalFragment:")} </strong>
      {Component.text(" Uses a container element with display: contents and replaces all children when the signal changes (no diffing)")}
      </li>
      <li>
        <strong> {Component.text("Lists:")} </strong>
      {Component.text(" Implemented as a computed signal + SignalFragment, so the entire list rerenders on any array change")}
      </li>
      <li>
        <strong> {Component.text("Reactive attributes:")} </strong>
      {Component.text(" Set up effects that update the DOM attribute when the signal/computed value changes")}
      </li>
    </ul>
    <h2> {Component.text("JSX Support")} </h2>
    <p>
      {Component.text("Xote supports ReScript's generic JSX v4 for declarative component syntax:")}
    </p>
    <pre>
      <code class="language-json">
        {Component.text(`{
  "jsx": {
    "version": 4,
    "module": "Xote__JSX"
  }
}`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Features:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Lowercase tags for HTML elements")}
      </li>
      <li>
        {Component.text("Props support for common attributes and events")}
      </li>
      <li>
        {Component.text("Children passed via JSX syntax")}
      </li>
      <li>
        {Component.text("Component functions called with props objects")}
      </li>
    </ul>
    <h2> {Component.text("Router Architecture")} </h2>
    <h3> {Component.text("Route Matching")} </h3>
    <p>
      {Component.text("Pattern-based string matching with :param syntax:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("parsePattern(pattern)")} </code>
      {Component.text(" converts patterns like /users/:id into segment arrays")}
      </li>
      <li>
        <code> {Component.text("matchPath(pattern, pathname)")} </code>
      {Component.text(" returns Match(params) or NoMatch")}
      </li>
      <li>
        {Component.text("Parameters returned as Dict.t<string>")}
      </li>
    </ul>
    <h3> {Component.text("Router State")} </h3>
    <ul>
      <li>
        <strong> {Component.text("Location signal:")} </strong>
      {Component.text(" ")}
      <code> {Component.text("Router.location")} </code>
      {Component.text(" contains {pathname, search, hash}")}
      </li>
      <li>
        <strong> {Component.text("History API integration:")} </strong>
      {Component.text(" Listens to popstate events for back/forward buttons")}
      </li>
      <li>
        <strong> {Component.text("Declarative routing:")} </strong>
      {Component.text(" Uses SignalFragment + Computed for reactive rendering")}
      </li>
      <li>
        <strong> {Component.text("Navigation links:")} </strong>
      {Component.text(" Intercepts clicks to prevent page reload")}
      </li>
    </ul>
    <h2> {Component.text("Execution Characteristics")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Push-based:")} </strong>
      {Component.text(" Signals push notifications to observers; computeds eagerly push into their backing signal")}
      </li>
      <li>
        <strong> {Component.text("Auto-tracked:")} </strong>
      {Component.text(" Observers re-track dependencies on every run")}
      </li>
      <li>
        <strong> {Component.text("Synchronous:")} </strong>
      {Component.text(" Updates run synchronously by default")}
      </li>
      <li>
        <strong> {Component.text("Exception safe:")} </strong>
      {Component.text(" Scheduler wrapped in try/catch to ensure tracking state is restored")}
      </li>
    </ul>
    <h2> {Component.text("Relation to TC39 Signals Proposal")} </h2>
    <p>
      {Component.text("Xote's reactive primitives (via rescript-signals) are inspired by the ")}
      <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Component.text("TC39 Signals proposal")} </a>
      {Component.text(":")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Aligned concepts:")} </strong>
      </li>
    </ul>
    <p>
      {Component.text("  - Automatic dependency tracking on read")}
    </p>
    <p>
      {Component.text("  - Observer-based recomputation and re-tracking")}
    </p>
    <p>
      {Component.text("  - Structural equality checks")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("Key differences:")} </strong>
      </li>
    </ul>
    <p>
      {Component.text("  - Computeds are push-based (eager) rather than pull-based (lazy) as in the proposal")}
    </p>
    <p>
      {Component.text("  - Synchronous scheduling rather than microtask-based")}
    </p>
    <p>
      {Component.text("  - Effects can return cleanup callbacks (Some/None pattern)")}
    </p>
    <h2> {Component.text("API Summary")} </h2>
    <h3> {Component.text("Reactive Primitives")} </h3>
    <pre>
      <code class="language-rescript">
        {Component.text(`Signal.make : 'a => t<'a>
Signal.get : t<'a> => 'a
Signal.peek : t<'a> => 'a
Signal.set : (t<'a>, 'a) => unit
Signal.update : (t<'a>, 'a => 'a) => unit

Computed.make : (unit => 'a) => t<'a>
Computed.dispose : t<'a> => unit

Effect.run : (unit => option<unit => unit>) => {dispose: unit => unit}`)}
      </code>
    </pre>
    <h3> {Component.text("Component Helpers")} </h3>
    <pre>
      <code class="language-rescript">
        {Component.text(`Component.text : string => node
Component.textSignal : (unit => string) => node
Component.list : (t<array<'a>>, 'a => node) => node
Component.listKeyed : (t<array<'a>>, 'a => string, 'a => node) => node
Component.mount : (node, Dom.element) => unit
Component.mountById : (node, string) => unit`)}
      </code>
    </pre>
    <h3> {Component.text("Router Helpers")} </h3>
    <pre>
      <code class="language-rescript">
        {Component.text(`Router.init : unit => unit
Router.location : t<{pathname: string, search: string, hash: string}>
Router.push : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.replace : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.routes : array<{pattern: string, render: params => node}> => node
Router.link : (~to: string, ~attrs: array=?, ~children: array=?, unit) => node`)}
      </code>
    </pre>
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Trust auto-disposal:")} </strong>
      {Component.text(" Computeds auto-dispose when subscribers drop to zero")}
      </li>
      <li>
        <strong> {Component.text("Use structural equality:")} </strong>
      {Component.text(" Signal.set only notifies if values differ")}
      </li>
      <li>
        <strong> {Component.text("Prefer JSX:")} </strong>
      {Component.text(" More concise and familiar syntax")}
      </li>
      <li>
        <strong> {Component.text("Keep components small:")} </strong>
      {Component.text(" Each component should do one thing well")}
      </li>
      <li>
        <strong> {Component.text("Use keyed lists:")} </strong>
      {Component.text(" For efficient reconciliation of dynamic lists")}
      </li>
    </ul>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Explore the ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Core Concepts")], ())}
      {Component.text(" for reactive primitives")}
      </li>
      <li>
        {Component.text("Learn about ")}
      {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
      {Component.text(" for building UIs")}
      </li>
      <li>
        {Component.text("Check out ")}
      <a href="https://github.com/pedrobslisboa/rescript-signals" target="_blank"> {Component.text("rescript-signals")} </a>
      {Component.text(" for reactive implementation details")}
      </li>
    </ul>
  </div>
}
