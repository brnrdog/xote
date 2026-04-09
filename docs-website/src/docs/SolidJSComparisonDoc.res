// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/solidjs.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Comparing Xote with SolidJS")} </h1>
    <p>
      {Node.text("This guide compares Xote and SolidJS -- two frameworks that share a signal-based reactivity model but differ in language, ecosystem, and scope.")}
    </p>
    <h2 id="overview"> {Node.text("Overview")} </h2>
    <table>
      <thead>
        <tr>
          <th> {Node.text("Aspect")} </th>
          <th> {Node.text("SolidJS")} </th>
          <th> {Node.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {Node.text("Reactivity")} </strong> </td>
          <td> {Node.text("Fine-grained signals (createSignal, createEffect)")} </td>
          <td> {Node.text("Fine-grained signals (Signal.make, Effect.run)")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Updates")} </strong> </td>
          <td> {Node.text("Direct DOM updates, no virtual DOM")} </td>
          <td> {Node.text("Direct DOM updates, no virtual DOM")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Components")} </strong> </td>
          <td> {Node.text("Functions that run once, JSX compiles away")} </td>
          <td> {Node.text("Functions that run once, JSX compiles away")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Language")} </strong> </td>
          <td> {Node.text("JavaScript / TypeScript")} </td>
          <td> {Node.text("ReScript (compiles to JavaScript)")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("SSR")} </strong> </td>
          <td> {Node.text("SolidStart framework")} </td>
          <td> {Node.text("Built-in (renderToString, hydration, state transfer)")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Routing")} </strong> </td>
          <td> {Node.text("Separate package (@solidjs/router)")} </td>
          <td> {Node.text("Built-in signal-based router")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("List Rendering")} </strong> </td>
          <td> <code> {Node.text("<For>")} </code>
      {Node.text(" / ")}
      <code> {Node.text("<Index>")} </code>
      {Node.text(" components")} </td>
          <td> {Node.text("keyedList with 3-phase DOM reconciliation")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Ecosystem")} </strong> </td>
          <td> {Node.text("Growing: UI libraries, SolidStart, community packages")} </td>
          <td> {Node.text("Minimal: focused core with built-in essentials")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Bundle Size")} </strong> </td>
          <td> {Node.text("~7KB min (solid-js)")} </td>
          <td> {Node.text("~6KB min (xote + rescript-signals)")} </td>
        </tr>
      </tbody>
    </table>
    <h2 id="shared-philosophy"> {Node.text("Shared Philosophy")} </h2>
    <p>
      {Node.text("Xote and SolidJS are closer to each other than either is to React. Both frameworks:")}
    </p>
    <ul>
      <li>
        {Node.text("Use ")}
      <strong> {Node.text("fine-grained reactivity")} </strong>
      {Node.text(" with signals as the core primitive")}
      </li>
      <li>
        {Node.text("Execute component functions ")}
      <strong> {Node.text("once")} </strong>
      {Node.text(" (not on every update)")}
      </li>
      <li>
        {Node.text("Update the DOM ")}
      <strong> {Node.text("directly")} </strong>
      {Node.text(" without a virtual DOM diffing step")}
      </li>
      <li>
        {Node.text("Compile JSX away at build time into efficient DOM operations")}
      </li>
      <li>
        {Node.text("Track dependencies ")}
      <strong> {Node.text("automatically")} </strong>
      {Node.text(" (no dependency arrays)")}
      </li>
      <li>
        {Node.text("Achieve ")}
      <strong> {Node.text("small bundle sizes")} </strong>
      {Node.text(" by avoiding a reconciliation runtime")}
      </li>
    </ul>
    <p>
      {Node.text("If you are familiar with SolidJS, many Xote concepts will feel natural. The differences lie in language choice, API surface, and what is included out of the box.")}
    </p>
    <h2 id="signals-and-state"> {Node.text("Signals and State")} </h2>
    <p>
      {Node.text("Both frameworks use signals as their core reactive primitive. The APIs are similar but not identical.")}
    </p>
    <p>
      <strong> {Node.text("SolidJS:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`import { createSignal, createEffect, createMemo } from "solid-js";

const [count, setCount] = createSignal(0);
const doubled = createMemo(() => count() * 2);

createEffect(() => {
  console.log("Count:", count());
});`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))
  None
})`)}
      </code>
    </pre>
    <p>
      {Node.text("Key differences:")}
    </p>
    <ul>
      <li>
        {Node.text("SolidJS uses a ")}
      <strong> {Node.text("getter/setter tuple")} </strong>
      {Node.text(" (")}
      <code> {Node.text("count()")} </code>
      {Node.text(" to read, ")}
      <code> {Node.text("setCount()")} </code>
      {Node.text(" to write). Xote uses ")}
      <strong> {Node.text("explicit functions")} </strong>
      {Node.text(" (")}
      <code> {Node.text("Signal.get(count)")} </code>
      {Node.text(" to read, ")}
      <code> {Node.text("Signal.set(count, value)")} </code>
      {Node.text(" to write).")}
      </li>
      <li>
        {Node.text("SolidJS effects do not return cleanup. Cleanup is handled via ")}
      <code> {Node.text("onCleanup")} </code>
      {Node.text(". Xote effects return ")}
      <code> {Node.text("Some(cleanupFn)")} </code>
      {Node.text(" or ")}
      <code> {Node.text("None")} </code>
      {Node.text(", and use ")}
      <code> {Node.text("Effect.run")} </code>
      {Node.text(" (returns unit) or ")}
      <code> {Node.text("Effect.runWithDisposer")} </code>
      {Node.text(" (returns a disposer for manual cleanup).")}
      </li>
      <li>
        {Node.text("Xote signals use ")}
      <strong> {Node.text("structural equality")} </strong>
      {Node.text(" by default -- setting a signal to a structurally equal value does not trigger updates. SolidJS uses referential equality by default but supports custom comparators via ")}
      <code> {Node.text("equals")} </code>
      {Node.text(".")}
      </li>
    </ul>
    <h2 id="component-model"> {Node.text("Component Model")} </h2>
    <p>
      {Node.text("Both frameworks share the same model: components run once. In both, the component function sets up the reactive graph and returns a DOM tree. After that, only the reactive bindings update.")}
    </p>
    <p>
      <strong> {Node.text("SolidJS:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`function Counter() {
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
      <strong> {Node.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`let counter = () => {
  let count = Signal.make(0)

  // Runs once. Only the text node with Signal.get(count) updates.
  <div>
    <h1>
      {Node.signalText(() =>
        "Count: " ++ Int.toString(Signal.get(count))
      )}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Node.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <p>
      {Node.text("The main difference is that SolidJS embeds reactive expressions directly in JSX (")}
      <code> {Node.text("{count()}")} </code>
      {Node.text("), while Xote uses explicit reactive text nodes (")}
      <code> {Node.text("Node.signalText")} </code>
      {Node.text("). SolidJS's compiler transforms the JSX to wrap signal reads in effects automatically. Xote's approach is more explicit -- you decide which parts are reactive.")}
    </p>
    <h2 id="list-rendering"> {Node.text("List Rendering")} </h2>
    <p>
      {Node.text("This is an area where the two frameworks take different approaches.")}
    </p>
    <p>
      <strong> {Node.text("SolidJS")} </strong>
      {Node.text(" provides built-in components ")}
      <code> {Node.text("<For>")} </code>
      {Node.text(" (keyed by item reference) and ")}
      <code> {Node.text("<Index>")} </code>
      {Node.text(" (keyed by index):")}
    </p>
    <pre>
      <code>
        {Node.text(`import { For } from "solid-js";

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
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" provides ")}
      <code> {Node.text("keyedList")} </code>
      {Node.text(" with a dedicated 3-phase reconciliation algorithm:")}
    </p>
    <pre>
      <code>
        {Node.text(`let todoList = () => {
  let todos = Signal.make([{id: "1", text: "Buy milk"}])

  <ul>
    {Node.keyedList(
      todos,
      todo => todo.id,
      todo => <li> {Node.text(todo.text)} </li>
    )}
  </ul>
}`)}
      </code>
    </pre>
    <p>
      {Node.text("Both approaches preserve DOM element identity across updates. SolidJS's ")}
      <code> {Node.text("<For>")} </code>
      {Node.text(" derives keys from item references, while Xote's ")}
      <code> {Node.text("keyedList")} </code>
      {Node.text(" takes an explicit key function. Xote's 3-phase algorithm (remove, build order, reconcile DOM) operates directly on DOM nodes using comment-based anchors.")}
    </p>
    <h2 id="server-side-rendering"> {Node.text("Server-Side Rendering")} </h2>
    <p>
      <strong> {Node.text("SolidJS")} </strong>
      {Node.text(" provides SSR through SolidStart, its meta-framework. SolidStart handles routing, data loading, streaming SSR, and deployment. Lower-level SSR is available via ")}
      <code> {Node.text("solid-js/web")} </code>
      {Node.text(" (")}
      <code> {Node.text("renderToString")} </code>
      {Node.text(", ")}
      <code> {Node.text("renderToStream")} </code>
      {Node.text("), but most users go through SolidStart.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" provides SSR as a built-in module without requiring a framework:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("SSR.renderToString")} </code>
      {Node.text(" and ")}
      <code> {Node.text("SSR.renderDocument")} </code>
      {Node.text(" for server rendering")}
      </li>
      <li>
        {Node.text("Comment-based hydration markers for reactive boundaries")}
      </li>
      <li>
        <code> {Node.text("SSRState")} </code>
      {Node.text(" with a type-safe codec system for server-to-client state transfer")}
      </li>
      <li>
        <code> {Node.text("Hydration.hydrate")} </code>
      {Node.text(" to attach reactivity to server-rendered DOM")}
      </li>
    </ul>
    <pre>
      <code>
        {Node.text(`// Server
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
      {Node.text("SolidStart is more feature-rich (file-based routing, API routes, streaming, deployment adapters). Xote's SSR is more minimal -- it handles rendering, hydration, and state transfer without prescribing an application framework.")}
    </p>
    <h2 id="routing"> {Node.text("Routing")} </h2>
    <p>
      <strong> {Node.text("SolidJS")} </strong>
      {Node.text(" uses ")}
      <code> {Node.text("@solidjs/router")} </code>
      {Node.text(", a separate package:")}
    </p>
    <pre>
      <code>
        {Node.text(`import { Router, Route } from "@solidjs/router";

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
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" includes a signal-based router:")}
    </p>
    <pre>
      <code>
        {Node.text(`Router.init()

let nav = () => {
  <nav>
    <Router.Link to="/" class="nav-link">
      {Node.text("Home")}
    </Router.Link>
    <Router.Link to="/users" class="nav-link">
      {Node.text("Users")}
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
      {Node.text("Both routers support dynamic segments, navigation, and links. SolidJS's router is more feature-rich (nested routing, data loading, lazy routes). Xote's router is simpler but integrated -- it uses the same signal system, supports SSR initialization, and uses ")}
      <code> {Node.text("Symbol.for()")} </code>
      {Node.text(" to share state across bundles.")}
    </p>
    <h2 id="bundle-size-and-compilation"> {Node.text("Bundle Size and Compilation")} </h2>
    <p>
      {Node.text("Both frameworks produce small bundles compared to virtual DOM frameworks. SolidJS is approximately ")}
      <strong> {Node.text("7KB minified")} </strong>
      {Node.text(" (solid-js core). Xote is approximately ")}
      <strong> {Node.text("6KB minified")} </strong>
      {Node.text(" (xote + rescript-signals), including its built-in router and SSR modules.")}
    </p>
    <p>
      {Node.text("The compilation models differ:")}
    </p>
    <p>
      <strong> {Node.text("SolidJS")} </strong>
      {Node.text(" uses a custom Babel plugin that transforms JSX into fine-grained DOM operations. The compiler detects signal reads in JSX and wraps them in effects automatically. The output is vanilla JavaScript with direct DOM API calls.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" uses the ReScript compiler, which transforms JSX into direct function calls via its generic JSX v4 transform. ReScript compiles to clean, readable JavaScript with zero runtime overhead from the language itself. There is no JSX runtime, no ")}
      <code> {Node.text("createElement")} </code>
      {Node.text(" calls -- just direct function invocations that construct the component tree.")}
    </p>
    <p>
      {Node.text("The practical result is similar: both produce small, efficient bundles with no framework overhead in the compiled output.")}
    </p>
    <h2 id="type-safety"> {Node.text("Type Safety")} </h2>
    <p>
      <strong> {Node.text("SolidJS")} </strong>
      {Node.text(" with TypeScript provides good type safety with full JSX type checking. TypeScript's structural type system works well with SolidJS's API, and the community maintains solid type definitions. However, TypeScript is opt-in and unsound -- runtime type errors are still possible.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" uses ReScript, which has a ")}
      <strong> {Node.text("sound type system")} </strong>
      {Node.text(" with full type inference. If the code compiles, types are guaranteed correct at runtime. Pattern matching is exhaustive, ")}
      <code> {Node.text("null")} </code>
      {Node.text("/")}
      <code> {Node.text("undefined")} </code>
      {Node.text(" are replaced by the ")}
      <code> {Node.text("option")} </code>
      {Node.text(" type, and the compiler catches errors that TypeScript cannot. The tradeoff is that ReScript is a different language from JavaScript, with its own syntax and ecosystem.")}
    </p>
    <h2 id="ecosystem"> {Node.text("Ecosystem")} </h2>
    <p>
      <strong> {Node.text("SolidJS")} </strong>
      {Node.text(" has a growing ecosystem with UI component libraries (SUID, Kobalte, Corvu), SolidStart for full-stack applications, and a community of plugins and integrations. It is smaller than React's ecosystem but significantly larger than Xote's.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" is minimal by design. It provides reactivity, components, routing, SSR, and hydration in a single package with one runtime dependency. There are no third-party component libraries or community packages. This is appropriate for projects that want full control over their stack.")}
    </p>
    <h2 id="when-to-choose-solidjs"> {Node.text("When to Choose SolidJS")} </h2>
    <ul>
      <li>
        <strong> {Node.text("JavaScript/TypeScript team:")} </strong>
      {Node.text(" Your team prefers staying in the JS/TS ecosystem")}
      </li>
      <li>
        <strong> {Node.text("Growing ecosystem:")} </strong>
      {Node.text(" You want access to UI component libraries and community packages")}
      </li>
      <li>
        <strong> {Node.text("SolidStart:")} </strong>
      {Node.text(" You need a full-stack framework with file-based routing, data loading, and deployment adapters")}
      </li>
      <li>
        <strong> {Node.text("Familiar syntax:")} </strong>
      {Node.text(" SolidJS's API is closer to React, easing migration")}
      </li>
      <li>
        <strong> {Node.text("Community support:")} </strong>
      {Node.text(" Larger community for help, tutorials, and examples")}
      </li>
    </ul>
    <h2 id="when-to-choose-xote"> {Node.text("When to Choose Xote")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Sound type safety:")} </strong>
      {Node.text(" You want compile-time guarantees that eliminate runtime type errors")}
      </li>
      <li>
        <strong> {Node.text("Built-in essentials:")} </strong>
      {Node.text(" You prefer routing, SSR, and hydration included without additional packages")}
      </li>
      <li>
        <strong> {Node.text("Minimal dependencies:")} </strong>
      {Node.text(" You want a single runtime dependency and full control over your stack")}
      </li>
      <li>
        <strong> {Node.text("ReScript ecosystem:")} </strong>
      {Node.text(" You are already using or interested in ReScript")}
      </li>
      <li>
        <strong> {Node.text("Explicit reactivity:")} </strong>
      {Node.text(" You prefer marking reactive boundaries explicitly rather than relying on compiler magic")}
      </li>
      <li>
        <strong> {Node.text("Smallest possible bundle:")} </strong>
      {Node.text(" Every kilobyte matters and you want routing + SSR included in ~6KB")}
      </li>
    </ul>
    <h2 id="migration-considerations"> {Node.text("Migration Considerations")} </h2>
    <p>
      {Node.text("If you are coming from SolidJS, the mental model transfers well:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("createSignal")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Signal.make")} </code>
      {Node.text(" (read with ")}
      <code> {Node.text("Signal.get")} </code>
      {Node.text(" instead of calling the getter)")}
      </li>
      <li>
        <code> {Node.text("createMemo")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Computed.make")} </code>
      </li>
      <li>
        <code> {Node.text("createEffect")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Effect.run")} </code>
      {Node.text(" (return ")}
      <code> {Node.text("Some(cleanupFn)")} </code>
      {Node.text(" or ")}
      <code> {Node.text("None")} </code>
      {Node.text("; use ")}
      <code> {Node.text("Effect.runWithDisposer")} </code>
      {Node.text(" if you need the disposer)")}
      </li>
      <li>
        <code> {Node.text("onCleanup")} </code>
      {Node.text(" -> Return ")}
      <code> {Node.text("Some(cleanupFn)")} </code>
      {Node.text(" from the effect")}
      </li>
      <li>
        <code> {Node.text("<For>")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Node.keyedList")} </code>
      </li>
      <li>
        <code> {Node.text("<Show>")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Node.signalText")} </code>
      {Node.text(" or ")}
      <code> {Node.text("SignalFragment")} </code>
      {Node.text(" with conditional logic")}
      </li>
      <li>
        <code> {Node.text("<A>")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("<Router.Link>")} </code>
      </li>
      <li>
        <code> {Node.text("@solidjs/router")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Router")} </code>
      {Node.text(" module (built-in)")}
      </li>
      <li>
        <code> {Node.text("renderToString")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("SSR.renderToString")} </code>
      </li>
    </ul>
    <p>
      {Node.text("The main learning curve is ReScript itself. The reactivity concepts are nearly identical -- both frameworks use signals with automatic dependency tracking and components that execute once.")}
    </p>
    <h2 id="further-reading"> {Node.text("Further Reading")} </h2>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Xote Signals Guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Node.text("Xote Components")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[Node.text("Router Overview")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[Node.text("Server-Side Rendering")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/comparisons/react", ~children=[Node.text("React Comparison")], ())}
      </li>
      <li>
        <a href="https://docs.solidjs.com" target="_blank"> {Node.text("SolidJS Documentation")} </a>
      </li>
      <li>
        <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Node.text("TC39 Signals Proposal")} </a>
      </li>
    </ul>
  </div>
}
