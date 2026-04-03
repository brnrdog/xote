// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/solidjs.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Comparing Xote with SolidJS")} </h1>
    <p>
      {Component.text("This guide compares Xote and SolidJS -- two frameworks that share a signal-based reactivity model but differ in language, ecosystem, and scope.")}
    </p>
    <h2 id="overview"> {Component.text("Overview")} </h2>
    <table>
      <thead>
        <tr>
          <th> {Component.text("Aspect")} </th>
          <th> {Component.text("SolidJS")} </th>
          <th> {Component.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {Component.text("Reactivity")} </strong> </td>
          <td> {Component.text("Fine-grained signals (createSignal, createEffect)")} </td>
          <td> {Component.text("Fine-grained signals (Signal.make, Effect.run)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Updates")} </strong> </td>
          <td> {Component.text("Direct DOM updates, no virtual DOM")} </td>
          <td> {Component.text("Direct DOM updates, no virtual DOM")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Components")} </strong> </td>
          <td> {Component.text("Functions that run once, JSX compiles away")} </td>
          <td> {Component.text("Functions that run once, JSX compiles away")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Language")} </strong> </td>
          <td> {Component.text("JavaScript / TypeScript")} </td>
          <td> {Component.text("ReScript (compiles to JavaScript)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("SSR")} </strong> </td>
          <td> {Component.text("SolidStart framework")} </td>
          <td> {Component.text("Built-in (renderToString, hydration, state transfer)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Routing")} </strong> </td>
          <td> {Component.text("Separate package (@solidjs/router)")} </td>
          <td> {Component.text("Built-in signal-based router")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("List Rendering")} </strong> </td>
          <td> <code> {Component.text("<For>")} </code>
      {Component.text(" / ")}
      <code> {Component.text("<Index>")} </code>
      {Component.text(" components")} </td>
          <td> {Component.text("keyedList with 3-phase DOM reconciliation")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Ecosystem")} </strong> </td>
          <td> {Component.text("Growing: UI libraries, SolidStart, community packages")} </td>
          <td> {Component.text("Minimal: focused core with built-in essentials")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Bundle Size")} </strong> </td>
          <td> {Component.text("~7KB min (solid-js)")} </td>
          <td> {Component.text("~6KB min (xote + rescript-signals)")} </td>
        </tr>
      </tbody>
    </table>
    <h2 id="shared-philosophy"> {Component.text("Shared Philosophy")} </h2>
    <p>
      {Component.text("Xote and SolidJS are closer to each other than either is to React. Both frameworks:")}
    </p>
    <ul>
      <li>
        {Component.text("Use ")}
      <strong> {Component.text("fine-grained reactivity")} </strong>
      {Component.text(" with signals as the core primitive")}
      </li>
      <li>
        {Component.text("Execute component functions ")}
      <strong> {Component.text("once")} </strong>
      {Component.text(" (not on every update)")}
      </li>
      <li>
        {Component.text("Update the DOM ")}
      <strong> {Component.text("directly")} </strong>
      {Component.text(" without a virtual DOM diffing step")}
      </li>
      <li>
        {Component.text("Compile JSX away at build time into efficient DOM operations")}
      </li>
      <li>
        {Component.text("Track dependencies ")}
      <strong> {Component.text("automatically")} </strong>
      {Component.text(" (no dependency arrays)")}
      </li>
      <li>
        {Component.text("Achieve ")}
      <strong> {Component.text("small bundle sizes")} </strong>
      {Component.text(" by avoiding a reconciliation runtime")}
      </li>
    </ul>
    <p>
      {Component.text("If you are familiar with SolidJS, many Xote concepts will feel natural. The differences lie in language choice, API surface, and what is included out of the box.")}
    </p>
    <h2 id="signals-and-state"> {Component.text("Signals and State")} </h2>
    <p>
      {Component.text("Both frameworks use signals as their core reactive primitive. The APIs are similar but not identical.")}
    </p>
    <p>
      <strong> {Component.text("SolidJS:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`import { createSignal, createEffect, createMemo } from "solid-js";

const [count, setCount] = createSignal(0);
const doubled = createMemo(() => count() * 2);

createEffect(() => {
  console.log("Count:", count());
});`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))
  None
})`)}
      </code>
    </pre>
    <p>
      {Component.text("Key differences:")}
    </p>
    <ul>
      <li>
        {Component.text("SolidJS uses a ")}
      <strong> {Component.text("getter/setter tuple")} </strong>
      {Component.text(" (")}
      <code> {Component.text("count()")} </code>
      {Component.text(" to read, ")}
      <code> {Component.text("setCount()")} </code>
      {Component.text(" to write). Xote uses ")}
      <strong> {Component.text("explicit functions")} </strong>
      {Component.text(" (")}
      <code> {Component.text("Signal.get(count)")} </code>
      {Component.text(" to read, ")}
      <code> {Component.text("Signal.set(count, value)")} </code>
      {Component.text(" to write).")}
      </li>
      <li>
        {Component.text("SolidJS effects do not return cleanup. Cleanup is handled via ")}
      <code> {Component.text("onCleanup")} </code>
      {Component.text(". Xote effects return ")}
      <code> {Component.text("Some(cleanupFn)")} </code>
      {Component.text(" or ")}
      <code> {Component.text("None")} </code>
      {Component.text(".")}
      </li>
      <li>
        {Component.text("Xote signals use ")}
      <strong> {Component.text("structural equality")} </strong>
      {Component.text(" by default -- setting a signal to a structurally equal value does not trigger updates. SolidJS uses referential equality by default but supports custom comparators via ")}
      <code> {Component.text("equals")} </code>
      {Component.text(".")}
      </li>
    </ul>
    <h2 id="component-model"> {Component.text("Component Model")} </h2>
    <p>
      {Component.text("Both frameworks share the same model: components run once. In both, the component function sets up the reactive graph and returns a DOM tree. After that, only the reactive bindings update.")}
    </p>
    <p>
      <strong> {Component.text("SolidJS:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`function Counter() {
  const [count, setCount] = createSignal(0);

  // Runs once. Only the text node with count() updates.
  return (
    <div>
      <h1>Count: {count()}</h1>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  );
}`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`let counter = () => {
  let count = Signal.make(0)

  // Runs once. Only the text node with Signal.get(count) updates.
  <div>
    <h1>
      {Component.textSignal(() =>
        "Count: " ++ Int.toString(Signal.get(count))
      )}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Component.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <p>
      {Component.text("The main difference is that SolidJS embeds reactive expressions directly in JSX (")}
      <code> {Component.text("{count()}")} </code>
      {Component.text("), while Xote uses explicit reactive text nodes (")}
      <code> {Component.text("Component.textSignal")} </code>
      {Component.text("). SolidJS's compiler transforms the JSX to wrap signal reads in effects automatically. Xote's approach is more explicit -- you decide which parts are reactive.")}
    </p>
    <h2 id="list-rendering"> {Component.text("List Rendering")} </h2>
    <p>
      {Component.text("This is an area where the two frameworks take different approaches.")}
    </p>
    <p>
      <strong> {Component.text("SolidJS")} </strong>
      {Component.text(" provides built-in components ")}
      <code> {Component.text("<For>")} </code>
      {Component.text(" (keyed by item reference) and ")}
      <code> {Component.text("<Index>")} </code>
      {Component.text(" (keyed by index):")}
    </p>
    <pre>
      <code>
        {Component.text(`import { For } from "solid-js";

function TodoList() {
  const [todos, setTodos] = createSignal([
    { id: "1", text: "Buy milk" }
  ]);

  return (
    <ul>
      <For each={todos()} fallback={<p>No todos</p>}>
        {(todo) => <li>{todo.text}</li>}
      </For>
    </ul>
  );
}`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" provides ")}
      <code> {Component.text("keyedList")} </code>
      {Component.text(" with a dedicated 3-phase reconciliation algorithm:")}
    </p>
    <pre>
      <code>
        {Component.text(`let todoList = () => {
  let todos = Signal.make([{id: "1", text: "Buy milk"}])

  <ul>
    {Component.keyedList(
      todos,
      todo => todo.id,
      todo => <li> {Component.text(todo.text)} </li>
    )}
  </ul>
}`)}
      </code>
    </pre>
    <p>
      {Component.text("Both approaches preserve DOM element identity across updates. SolidJS's ")}
      <code> {Component.text("<For>")} </code>
      {Component.text(" derives keys from item references, while Xote's ")}
      <code> {Component.text("keyedList")} </code>
      {Component.text(" takes an explicit key function. Xote's 3-phase algorithm (remove, build order, reconcile DOM) operates directly on DOM nodes using comment-based anchors.")}
    </p>
    <h2 id="server-side-rendering"> {Component.text("Server-Side Rendering")} </h2>
    <p>
      <strong> {Component.text("SolidJS")} </strong>
      {Component.text(" provides SSR through SolidStart, its meta-framework. SolidStart handles routing, data loading, streaming SSR, and deployment. Lower-level SSR is available via ")}
      <code> {Component.text("solid-js/web")} </code>
      {Component.text(" (")}
      <code> {Component.text("renderToString")} </code>
      {Component.text(", ")}
      <code> {Component.text("renderToStream")} </code>
      {Component.text("), but most users go through SolidStart.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" provides SSR as a built-in module without requiring a framework:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("SSR.renderToString")} </code>
      {Component.text(" and ")}
      <code> {Component.text("SSR.renderDocument")} </code>
      {Component.text(" for server rendering")}
      </li>
      <li>
        {Component.text("Comment-based hydration markers for reactive boundaries")}
      </li>
      <li>
        <code> {Component.text("SSRState")} </code>
      {Component.text(" with a type-safe codec system for server-to-client state transfer")}
      </li>
      <li>
        <code> {Component.text("Hydration.hydrate")} </code>
      {Component.text(" to attach reactivity to server-rendered DOM")}
      </li>
    </ul>
    <pre>
      <code>
        {Component.text(`// Server
let html = SSR.renderDocument(
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app
)

// Client
Hydration.hydrateById(app, "root")`)}
      </code>
    </pre>
    <p>
      {Component.text("SolidStart is more feature-rich (file-based routing, API routes, streaming, deployment adapters). Xote's SSR is more minimal -- it handles rendering, hydration, and state transfer without prescribing an application framework.")}
    </p>
    <h2 id="routing"> {Component.text("Routing")} </h2>
    <p>
      <strong> {Component.text("SolidJS")} </strong>
      {Component.text(" uses ")}
      <code> {Component.text("@solidjs/router")} </code>
      {Component.text(", a separate package:")}
    </p>
    <pre>
      <code>
        {Component.text(`import { Router, Route } from "@solidjs/router";

function App() {
  return (
    <Router>
      <Route path="/" component={Home} />
      <Route path="/users/:id" component={UserPage} />
    </Router>
  );
}`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" includes a signal-based router:")}
    </p>
    <pre>
      <code>
        {Component.text(`Router.init()

let nav = () => {
  <nav>
    <Router.Link to="/" class="nav-link">
      {Component.text("Home")}
    </Router.Link>
    <Router.Link to="/users" class="nav-link">
      {Component.text("Users")}
    </Router.Link>
  </nav>
}

let app = () => {
  <div>
    <nav />
    {Router.routes([
      {pattern: "/", render: _ => <HomePage />},
      {pattern: "/users/:id", render: params =>
        <UserPage id={params->Dict.getUnsafe("id")} />
      },
    ])}
  </div>
}`)}
      </code>
    </pre>
    <p>
      {Component.text("Both routers support dynamic segments, navigation, and links. SolidJS's router is more feature-rich (nested routing, data loading, lazy routes). Xote's router is simpler but integrated -- it uses the same signal system, supports SSR initialization, and uses ")}
      <code> {Component.text("Symbol.for()")} </code>
      {Component.text(" to share state across bundles.")}
    </p>
    <h2 id="bundle-size-and-compilation"> {Component.text("Bundle Size and Compilation")} </h2>
    <p>
      {Component.text("Both frameworks produce small bundles compared to virtual DOM frameworks. SolidJS is approximately ")}
      <strong> {Component.text("7KB minified")} </strong>
      {Component.text(" (solid-js core). Xote is approximately ")}
      <strong> {Component.text("6KB minified")} </strong>
      {Component.text(" (xote + rescript-signals), including its built-in router and SSR modules.")}
    </p>
    <p>
      {Component.text("The compilation models differ:")}
    </p>
    <p>
      <strong> {Component.text("SolidJS")} </strong>
      {Component.text(" uses a custom Babel plugin that transforms JSX into fine-grained DOM operations. The compiler detects signal reads in JSX and wraps them in effects automatically. The output is vanilla JavaScript with direct DOM API calls.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" uses the ReScript compiler, which transforms JSX into direct function calls via its generic JSX v4 transform. ReScript compiles to clean, readable JavaScript with zero runtime overhead from the language itself. There is no JSX runtime, no ")}
      <code> {Component.text("createElement")} </code>
      {Component.text(" calls -- just direct function invocations that construct the component tree.")}
    </p>
    <p>
      {Component.text("The practical result is similar: both produce small, efficient bundles with no framework overhead in the compiled output.")}
    </p>
    <h2 id="type-safety"> {Component.text("Type Safety")} </h2>
    <p>
      <strong> {Component.text("SolidJS")} </strong>
      {Component.text(" with TypeScript provides good type safety with full JSX type checking. TypeScript's structural type system works well with SolidJS's API, and the community maintains solid type definitions. However, TypeScript is opt-in and unsound -- runtime type errors are still possible.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" uses ReScript, which has a ")}
      <strong> {Component.text("sound type system")} </strong>
      {Component.text(" with full type inference. If the code compiles, types are guaranteed correct at runtime. Pattern matching is exhaustive, ")}
      <code> {Component.text("null")} </code>
      {Component.text("/")}
      <code> {Component.text("undefined")} </code>
      {Component.text(" are replaced by the ")}
      <code> {Component.text("option")} </code>
      {Component.text(" type, and the compiler catches errors that TypeScript cannot. The tradeoff is that ReScript is a different language from JavaScript, with its own syntax and ecosystem.")}
    </p>
    <h2 id="ecosystem"> {Component.text("Ecosystem")} </h2>
    <p>
      <strong> {Component.text("SolidJS")} </strong>
      {Component.text(" has a growing ecosystem with UI component libraries (SUID, Kobalte, Corvu), SolidStart for full-stack applications, and a community of plugins and integrations. It is smaller than React's ecosystem but significantly larger than Xote's.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" is minimal by design. It provides reactivity, components, routing, SSR, and hydration in a single package with one runtime dependency. There are no third-party component libraries or community packages. This is appropriate for projects that want full control over their stack.")}
    </p>
    <h2 id="when-to-choose-solidjs"> {Component.text("When to Choose SolidJS")} </h2>
    <ul>
      <li>
        <strong> {Component.text("JavaScript/TypeScript team:")} </strong>
      {Component.text(" Your team prefers staying in the JS/TS ecosystem")}
      </li>
      <li>
        <strong> {Component.text("Growing ecosystem:")} </strong>
      {Component.text(" You want access to UI component libraries and community packages")}
      </li>
      <li>
        <strong> {Component.text("SolidStart:")} </strong>
      {Component.text(" You need a full-stack framework with file-based routing, data loading, and deployment adapters")}
      </li>
      <li>
        <strong> {Component.text("Familiar syntax:")} </strong>
      {Component.text(" SolidJS's API is closer to React, easing migration")}
      </li>
      <li>
        <strong> {Component.text("Community support:")} </strong>
      {Component.text(" Larger community for help, tutorials, and examples")}
      </li>
    </ul>
    <h2 id="when-to-choose-xote"> {Component.text("When to Choose Xote")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Sound type safety:")} </strong>
      {Component.text(" You want compile-time guarantees that eliminate runtime type errors")}
      </li>
      <li>
        <strong> {Component.text("Built-in essentials:")} </strong>
      {Component.text(" You prefer routing, SSR, and hydration included without additional packages")}
      </li>
      <li>
        <strong> {Component.text("Minimal dependencies:")} </strong>
      {Component.text(" You want a single runtime dependency and full control over your stack")}
      </li>
      <li>
        <strong> {Component.text("ReScript ecosystem:")} </strong>
      {Component.text(" You are already using or interested in ReScript")}
      </li>
      <li>
        <strong> {Component.text("Explicit reactivity:")} </strong>
      {Component.text(" You prefer marking reactive boundaries explicitly rather than relying on compiler magic")}
      </li>
      <li>
        <strong> {Component.text("Smallest possible bundle:")} </strong>
      {Component.text(" Every kilobyte matters and you want routing + SSR included in ~6KB")}
      </li>
    </ul>
    <h2 id="migration-considerations"> {Component.text("Migration Considerations")} </h2>
    <p>
      {Component.text("If you are coming from SolidJS, the mental model transfers well:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("createSignal")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Signal.make")} </code>
      {Component.text(" (read with ")}
      <code> {Component.text("Signal.get")} </code>
      {Component.text(" instead of calling the getter)")}
      </li>
      <li>
        <code> {Component.text("createMemo")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Computed.make")} </code>
      </li>
      <li>
        <code> {Component.text("createEffect")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Effect.run")} </code>
      {Component.text(" (return ")}
      <code> {Component.text("Some(cleanupFn)")} </code>
      {Component.text(" or ")}
      <code> {Component.text("None")} </code>
      {Component.text(")")}
      </li>
      <li>
        <code> {Component.text("onCleanup")} </code>
      {Component.text(" -> Return ")}
      <code> {Component.text("Some(cleanupFn)")} </code>
      {Component.text(" from ")}
      <code> {Component.text("Effect.run")} </code>
      </li>
      <li>
        <code> {Component.text("<For>")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Component.keyedList")} </code>
      </li>
      <li>
        <code> {Component.text("<Show>")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Component.textSignal")} </code>
      {Component.text(" or ")}
      <code> {Component.text("SignalFragment")} </code>
      {Component.text(" with conditional logic")}
      </li>
      <li>
        <code> {Component.text("<A>")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("<Router.Link>")} </code>
      </li>
      <li>
        <code> {Component.text("@solidjs/router")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Router")} </code>
      {Component.text(" module (built-in)")}
      </li>
      <li>
        <code> {Component.text("renderToString")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("SSR.renderToString")} </code>
      </li>
    </ul>
    <p>
      {Component.text("The main learning curve is ReScript itself. The reactivity concepts are nearly identical -- both frameworks use signals with automatic dependency tracking and components that execute once.")}
    </p>
    <h2 id="further-reading"> {Component.text("Further Reading")} </h2>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Xote Signals Guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Xote Components")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[Component.text("Router Overview")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[Component.text("Server-Side Rendering")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/comparisons/react", ~children=[Component.text("React Comparison")], ())}
      </li>
      <li>
        <a href="https://docs.solidjs.com" target="_blank"> {Component.text("SolidJS Documentation")} </a>
      </li>
      <li>
        <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Component.text("TC39 Signals Proposal")} </a>
      </li>
    </ul>
  </div>
}
