// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/react.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Component.text("Comparing Xote with React")} </h1>
    <p>
      {Component.text("This guide provides a detailed comparison between Xote and React, covering their fundamental approaches to building web applications, their feature sets, and when each is the better choice.")}
    </p>
    <h2 id="overview"> {Component.text("Overview")} </h2>
    <table>
      <thead>
        <tr>
          <th> {Component.text("Aspect")} </th>
          <th> {Component.text("React")} </th>
          <th> {Component.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {Component.text("Reactivity")} </strong> </td>
          <td> {Component.text("Virtual DOM diffing and reconciliation")} </td>
          <td> {Component.text("Fine-grained reactivity with signals")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Updates")} </strong> </td>
          <td> {Component.text("Re-renders component trees on state change")} </td>
          <td> {Component.text("Direct DOM updates at the signal level")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("State")} </strong> </td>
          <td> {Component.text("useState, useReducer hooks")} </td>
          <td> {Component.text("Signal primitives (Signal, Computed, Effect)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Side Effects")} </strong> </td>
          <td> {Component.text("useEffect with manual dependency arrays")} </td>
          <td> {Component.text("Effect.run with automatic dependency tracking")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("SSR")} </strong> </td>
          <td> {Component.text("Built-in (renderToString, Server Components)")} </td>
          <td> {Component.text("Built-in (renderToString, hydration, state transfer)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Routing")} </strong> </td>
          <td> {Component.text("Third-party (React Router, TanStack Router)")} </td>
          <td> {Component.text("Built-in signal-based router")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("List Rendering")} </strong> </td>
          <td> {Component.text("Key-based reconciliation via VDOM diffing")} </td>
          <td> {Component.text("KeyedList with 3-phase DOM reconciliation")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Language")} </strong> </td>
          <td> {Component.text("JavaScript / TypeScript")} </td>
          <td> {Component.text("ReScript (compiles to JavaScript)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Bundle Size")} </strong> </td>
          <td> {Component.text("~44KB min (react + react-dom)")} </td>
          <td> {Component.text("~6KB min (xote + rescript-signals)")} </td>
        </tr>
      </tbody>
    </table>
    <h2 id="reactivity-model"> {Component.text("Reactivity Model")} </h2>
    <p>
      <strong> {Component.text("React")} </strong>
      {Component.text(" re-renders entire component subtrees when state changes. Every ")}
      <code> {Component.text("useState")} </code>
      {Component.text(" setter triggers a re-render of the component and all its children. React then diffs the new virtual DOM against the previous one to determine the minimal DOM operations. This works well but means components can re-execute their entire body unnecessarily. Optimizations like ")}
      <code> {Component.text("React.memo")} </code>
      {Component.text(", ")}
      <code> {Component.text("useMemo")} </code>
      {Component.text(", and ")}
      <code> {Component.text("useCallback")} </code>
      {Component.text(" exist to mitigate this, but they add complexity and are easy to get wrong.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" uses fine-grained reactivity based on signals. When a signal changes, only the specific DOM nodes or effects that read that signal are updated. There is no virtual DOM and no diffing. Components execute once to set up their reactive graph, and from that point, updates flow directly to the DOM. This means there is no need for memoization APIs -- updates are surgical by default.")}
    </p>
    <h3 id="counter-example"> {Component.text("Counter Example")} </h3>
    <p>
      <strong> {Component.text("React:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  // This entire function body re-executes on every click
  return (
    <div>
      <h1>Count: {count}</h1>
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
        {Component.text(`open Xote

let counter = () => {
  let count = Signal.make(0)

  // This function body executes once.
  // Only the text node updates when count changes.
  <div>
    <h1>
      {Component.signalText(() =>
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
    <h2 id="side-effects-and-dependencies"> {Component.text("Side Effects and Dependencies")} </h2>
    <p>
      {Component.text("One of the most common sources of bugs in React is the ")}
      <code> {Component.text("useEffect")} </code>
      {Component.text(" dependency array. Forgetting a dependency leads to stale closures; including too many causes infinite loops. Lint rules help, but they cannot catch all cases.")}
    </p>
    <p>
      {Component.text("Xote effects track dependencies automatically. Any signal read during effect execution becomes a dependency. When dependencies change, the effect re-runs. There is no array to maintain.")}
    </p>
    <p>
      <strong> {Component.text("React:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`// Must manually list every dependency
useEffect(() => {
  document.title = \`Count: \${count}\`;
}, [count]); // Forget count here and the title never updates`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`// Dependencies tracked automatically
Effect.run(() => {
  document.title = "Count: " ++ Int.toString(Signal.get(count))
  None
})`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Derived state")} </strong>
      {Component.text(" follows the same pattern. React's ")}
      <code> {Component.text("useMemo")} </code>
      {Component.text(" requires a dependency array. Xote's ")}
      <code> {Component.text("Computed.make")} </code>
      {Component.text(" tracks dependencies automatically and is lazy -- it only recomputes when read.")}
    </p>
    <pre>
      <code>
        {Component.text(`// Recomputes only when count changes, and only when someone reads it
let doubled = Computed.make(() => Signal.get(count) * 2)`)}
      </code>
    </pre>
    <h2 id="component-lifecycle"> {Component.text("Component Lifecycle")} </h2>
    <p>
      {Component.text("In React, components are functions that re-execute on every render. Hooks must follow strict ordering rules, and cleanup requires returning a function from ")}
      <code> {Component.text("useEffect")} </code>
      {Component.text(".")}
    </p>
    <p>
      {Component.text("In Xote, component functions execute once. Signals, effects, and computed values are created during that single execution. Cleanup is handled by the ")}
      <strong> {Component.text("owner system")} </strong>
      {Component.text(" -- each DOM element tracks its reactive resources, and when the element is removed from the DOM, all associated effects and computeds are disposed automatically.")}
    </p>
    <p>
      <strong> {Component.text("React:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Component functions re-execute on every render")}
      </li>
      <li>
        {Component.text("Hooks must follow the rules of hooks (no conditionals, fixed order)")}
      </li>
      <li>
        {Component.text("Cleanup via useEffect return functions")}
      </li>
      <li>
        {Component.text("Must use useRef to persist values across renders")}
      </li>
    </ul>
    <p>
      <strong> {Component.text("Xote:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Component functions execute once")}
      </li>
      <li>
        {Component.text("No hook rules -- signals and effects can be created anywhere")}
      </li>
      <li>
        {Component.text("Cleanup via Effect return values and automatic owner-based disposal")}
      </li>
      <li>
        {Component.text("All values naturally persist (they are just local variables)")}
      </li>
    </ul>
    <h2 id="list-rendering"> {Component.text("List Rendering")} </h2>
    <p>
      <strong> {Component.text("React")} </strong>
      {Component.text(" uses key-based reconciliation during its virtual DOM diff. When a list changes, React matches elements by key and determines insertions, deletions, and moves. This works well but happens as part of the full VDOM reconciliation pass.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" provides ")}
      <code> {Component.text("keyedList")} </code>
      {Component.text(" with a dedicated 3-phase reconciliation algorithm that operates directly on the DOM:")}
    </p>
    <ol>
      <li>
        <strong> {Component.text("Remove")} </strong>
      {Component.text(" items no longer in the list")}
      </li>
      <li>
        <strong> {Component.text("Build new order")} </strong>
      {Component.text(" reusing existing DOM elements for unchanged keys")}
      </li>
      <li>
        <strong> {Component.text("Reconcile DOM")} </strong>
      {Component.text(" by inserting, moving, and replacing elements")}
      </li>
    </ol>
    <p>
      {Component.text("This preserves DOM element identity across updates -- an important property for elements with focus state, animations, or internal state.")}
    </p>
    <p>
      <strong> {Component.text("React:")} </strong>
    </p>
    <pre>
      <code>
        {Component.text(`function TodoList({ todos }) {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote:")} </strong>
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
    <h2 id="server-side-rendering"> {Component.text("Server-Side Rendering")} </h2>
    <p>
      <strong> {Component.text("React")} </strong>
      {Component.text(" has mature SSR support through ")}
      <code> {Component.text("renderToString")} </code>
      {Component.text(", streaming with ")}
      <code> {Component.text("renderToPipeableStream")} </code>
      {Component.text(", and the newer Server Components architecture (via frameworks like Next.js). React's SSR ecosystem is extensive and battle-tested.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" provides built-in SSR with a focused feature set:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("\`SSR.renderToString\`")} </strong>
      {Component.text(" renders components to HTML strings")}
      </li>
      <li>
        <strong> {Component.text("\`SSR.renderDocument\`")} </strong>
      {Component.text(" generates full HTML documents with head, scripts, and styles")}
      </li>
      <li>
        <strong> {Component.text("Hydration markers")} </strong>
      {Component.text(" (HTML comments) mark reactive boundaries so the client can attach reactivity without re-rendering")}
      </li>
      <li>
        <strong> {Component.text("\`SSRState\`")} </strong>
      {Component.text(" handles state transfer between server and client with a type-safe codec system")}
      </li>
      <li>
        <strong> {Component.text("\`Hydration.hydrate\`")} </strong>
      {Component.text(" walks server-rendered DOM and attaches signals, effects, and event listeners")}
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
      {Component.text("React's SSR ecosystem is more mature and offers features like streaming and Server Components. Xote's SSR is simpler and more lightweight, handling the core use case of server rendering with client hydration and state transfer without requiring a framework.")}
    </p>
    <h2 id="routing"> {Component.text("Routing")} </h2>
    <p>
      <strong> {Component.text("React")} </strong>
      {Component.text(" does not include a router. You need a third-party library like React Router or TanStack Router. These are excellent but add to your dependency count and bundle size.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" includes a signal-based router out of the box:")}
    </p>
    <ul>
      <li>
        {Component.text("Pattern matching with dynamic segments (")}
      <code> {Component.text("/users/:id")} </code>
      {Component.text(")")}
      </li>
      <li>
        {Component.text("Imperative navigation (")}
      <code> {Component.text("Router.push")} </code>
      {Component.text(", ")}
      <code> {Component.text("Router.replace")} </code>
      {Component.text(")")}
      </li>
      <li>
        {Component.text("A ")}
      <code> {Component.text("Router.Link")} </code>
      {Component.text(" JSX component for declarative navigation")}
      </li>
      <li>
        {Component.text("Base path support for sub-app routing")}
      </li>
      <li>
        {Component.text("Scroll position restoration on back/forward navigation")}
      </li>
      <li>
        {Component.text("SSR-compatible initialization (")}
      <code> {Component.text("Router.initSSR")} </code>
      {Component.text(")")}
      </li>
      <li>
        {Component.text("Global singleton state via ")}
      <code> {Component.text("Symbol.for()")} </code>
      {Component.text(" so multiple bundles share the same router")}
      </li>
    </ul>
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
      {Component.text("Having routing built in means one less dependency to manage, and the router integrates naturally with the signal system -- route changes trigger reactive updates like any other signal change.")}
    </p>
    <h2 id="bundle-size-and-runtime-footprint"> {Component.text("Bundle Size and Runtime Footprint")} </h2>
    <p>
      {Component.text("This is one of the most significant practical differences. React's runtime (react + react-dom) is approximately ")}
      <strong> {Component.text("44KB minified")} </strong>
      {Component.text(" (about 14KB gzipped). Add a router and you are looking at another 10-20KB.")}
    </p>
    <p>
      {Component.text("Xote's entire runtime including the signals library is approximately ")}
      <strong> {Component.text("6KB minified")} </strong>
      {Component.text(". The built-in router and SSR modules are included in that figure.")}
    </p>
    <p>
      {Component.text("This difference comes from two factors:")}
    </p>
    <ol>
      <li>
        <strong> {Component.text("No virtual DOM")} </strong>
      {Component.text(": Xote does not need a diffing/reconciliation engine for general updates. The signal graph handles targeted updates directly.")}
      </li>
      <li>
        <strong> {Component.text("ReScript's zero-cost JSX")} </strong>
      {Component.text(": ReScript's JSX compiles to direct function calls with no runtime JSX transformer. There is no ")}
      <code> {Component.text("React.createElement")} </code>
      {Component.text(" equivalent that builds intermediate objects. The compiled output is lean JavaScript that directly constructs the component tree.")}
      </li>
    </ol>
    <p>
      {Component.text("For applications where initial load time matters -- mobile web, embedded widgets, progressive web apps, or performance-constrained environments -- this difference is substantial.")}
    </p>
    <h2 id="type-safety"> {Component.text("Type Safety")} </h2>
    <p>
      <strong> {Component.text("React")} </strong>
      {Component.text(" with TypeScript provides good type safety, but it is opt-in and structural. Generic component patterns, higher-order components, and complex hooks often require manual type annotations. Runtime type errors are still possible.")}
    </p>
    <p>
      <strong> {Component.text("Xote")} </strong>
      {Component.text(" uses ReScript, which has a sound type system with full type inference. Types are checked at compile time and cover the entire codebase. The compiler guarantees that if your code compiles, types are correct -- there are no runtime type errors from type mismatches. Pattern matching is exhaustive, and the absence of ")}
      <code> {Component.text("null")} </code>
      {Component.text("/")}
      <code> {Component.text("undefined")} </code>
      {Component.text(" exceptions (replaced by the ")}
      <code> {Component.text("option")} </code>
      {Component.text(" type) eliminates an entire class of bugs.")}
    </p>
    <h2 id="ecosystem"> {Component.text("Ecosystem")} </h2>
    <p>
      {Component.text("This is where React has a clear advantage. React has thousands of UI component libraries, state management solutions, form libraries, data fetching tools, animation frameworks, and more. The community is enormous, and finding help, tutorials, and examples is straightforward.")}
    </p>
    <p>
      {Component.text("Xote's ecosystem is minimal by design. It provides the core building blocks -- reactivity, components, routing, and SSR -- and leaves the rest to the application. This means less choice paralysis but also fewer off-the-shelf solutions.")}
    </p>
    <h2 id="when-to-choose-react"> {Component.text("When to Choose React")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Large ecosystem needed:")} </strong>
      {Component.text(" Your project relies on third-party React component libraries or integrations")}
      </li>
      <li>
        <strong> {Component.text("Team experience:")} </strong>
      {Component.text(" Your team is already proficient with React and JavaScript/TypeScript")}
      </li>
      <li>
        <strong> {Component.text("Mobile apps:")} </strong>
      {Component.text(" You want to use React Native for cross-platform development")}
      </li>
      <li>
        <strong> {Component.text("Hiring:")} </strong>
      {Component.text(" Finding React developers is easier in the current job market")}
      </li>
      <li>
        <strong> {Component.text("Mature SSR frameworks:")} </strong>
      {Component.text(" You need Next.js, Remix, or similar full-stack frameworks with advanced features like Server Components and streaming")}
      </li>
    </ul>
    <h2 id="when-to-choose-xote"> {Component.text("When to Choose Xote")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Performance-sensitive applications:")} </strong>
      {Component.text(" You need minimal bundle size and fast initial load times")}
      </li>
      <li>
        <strong> {Component.text("Fine-grained reactivity:")} </strong>
      {Component.text(" You want precise, efficient updates without virtual DOM overhead or memoization boilerplate")}
      </li>
      <li>
        <strong> {Component.text("Full-stack type safety:")} </strong>
      {Component.text(" You value a sound type system that catches errors at compile time")}
      </li>
      <li>
        <strong> {Component.text("Built-in essentials:")} </strong>
      {Component.text(" You prefer having routing, SSR, and hydration included without additional dependencies")}
      </li>
      <li>
        <strong> {Component.text("Signal-based architecture:")} </strong>
      {Component.text(" You want to build with a reactivity model aligned with the TC39 Signals proposal")}
      </li>
      <li>
        <strong> {Component.text("Minimal dependency footprint:")} </strong>
      {Component.text(" You want a focused library with a single runtime dependency")}
      </li>
    </ul>
    <h2 id="migration-considerations"> {Component.text("Migration Considerations")} </h2>
    <p>
      {Component.text("If you are coming from React, here is how core concepts map:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("useState")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Signal.make")} </code>
      </li>
      <li>
        <code> {Component.text("useMemo")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Computed.make")} </code>
      {Component.text(" (no dependency array needed)")}
      </li>
      <li>
        <code> {Component.text("useEffect")} </code>
      {Component.text(" -> ")}
      <code> {Component.text("Effect.run")} </code>
      {Component.text(" (no dependency array needed)")}
      </li>
      <li>
        <code> {Component.text("useRef")} </code>
      {Component.text(" -> Just use a ")}
      <code> {Component.text("ref()")} </code>
      {Component.text(" or a local ")}
      <code> {Component.text("let")} </code>
      {Component.text(" binding (components execute once)")}
      </li>
      <li>
        <code> {Component.text("React.memo")} </code>
      {Component.text(" -> Not needed (fine-grained updates by default)")}
      </li>
      <li>
        <code> {Component.text("useCallback")} </code>
      {Component.text(" -> Not needed (no re-renders to cause reference changes)")}
      </li>
      <li>
        <code> {Component.text("JSX")} </code>
      {Component.text(" -> ReScript JSX (very similar syntax)")}
      </li>
      <li>
        <code> {Component.text("React Router")} </code>
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
      {Component.text("The main learning curve is ReScript itself -- its syntax, type system, and functional programming patterns. The reactivity model is arguably simpler than React's hooks system once you understand signals.")}
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
        <a href="https://react.dev" target="_blank"> {Component.text("React Documentation")} </a>
      </li>
      <li>
        <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Component.text("TC39 Signals Proposal")} </a>
      </li>
    </ul>
  </div>
}
