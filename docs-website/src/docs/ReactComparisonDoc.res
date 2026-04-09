// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/react.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h1> {Node.text("Comparing Xote with React")} </h1>
    <p>
      {Node.text("This guide provides a detailed comparison between Xote and React, covering their fundamental approaches to building web applications, their feature sets, and when each is the better choice.")}
    </p>
    <h2 id="overview"> {Node.text("Overview")} </h2>
    <table>
      <thead>
        <tr>
          <th> {Node.text("Aspect")} </th>
          <th> {Node.text("React")} </th>
          <th> {Node.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {Node.text("Reactivity")} </strong> </td>
          <td> {Node.text("Virtual DOM diffing and reconciliation")} </td>
          <td> {Node.text("Fine-grained reactivity with signals")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Updates")} </strong> </td>
          <td> {Node.text("Re-renders component trees on state change")} </td>
          <td> {Node.text("Direct DOM updates at the signal level")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("State")} </strong> </td>
          <td> {Node.text("useState, useReducer hooks")} </td>
          <td> {Node.text("Signal primitives (Signal, Computed, Effect)")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Side Effects")} </strong> </td>
          <td> {Node.text("useEffect with manual dependency arrays")} </td>
          <td> {Node.text("Effect.run with automatic dependency tracking")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("SSR")} </strong> </td>
          <td> {Node.text("Built-in (renderToString, Server Components)")} </td>
          <td> {Node.text("Built-in (renderToString, hydration, state transfer)")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Routing")} </strong> </td>
          <td> {Node.text("Third-party (React Router, TanStack Router)")} </td>
          <td> {Node.text("Built-in signal-based router")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("List Rendering")} </strong> </td>
          <td> {Node.text("Key-based reconciliation via VDOM diffing")} </td>
          <td> {Node.text("KeyedList with 3-phase DOM reconciliation")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Language")} </strong> </td>
          <td> {Node.text("JavaScript / TypeScript")} </td>
          <td> {Node.text("ReScript (compiles to JavaScript)")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Bundle Size")} </strong> </td>
          <td> {Node.text("~44KB min (react + react-dom)")} </td>
          <td> {Node.text("~6KB min (xote + rescript-signals)")} </td>
        </tr>
      </tbody>
    </table>
    <h2 id="reactivity-model"> {Node.text("Reactivity Model")} </h2>
    <p>
      <strong> {Node.text("React")} </strong>
      {Node.text(" re-renders entire component subtrees when state changes. Every ")}
      <code> {Node.text("useState")} </code>
      {Node.text(" setter triggers a re-render of the component and all its children. React then diffs the new virtual DOM against the previous one to determine the minimal DOM operations. This works well but means components can re-execute their entire body unnecessarily. Optimizations like ")}
      <code> {Node.text("React.memo")} </code>
      {Node.text(", ")}
      <code> {Node.text("useMemo")} </code>
      {Node.text(", and ")}
      <code> {Node.text("useCallback")} </code>
      {Node.text(" exist to mitigate this, but they add complexity and are easy to get wrong.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" uses fine-grained reactivity based on signals. When a signal changes, only the specific DOM nodes or effects that read that signal are updated. There is no virtual DOM and no diffing. Components execute once to set up their reactive graph, and from that point, updates flow directly to the DOM. This means there is no need for memoization APIs -- updates are surgical by default.")}
    </p>
    <h3 id="counter-example"> {Node.text("Counter Example")} </h3>
    <p>
      <strong> {Node.text("React:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`import { useState } from 'react';

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
      <strong> {Node.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

let counter = () => {
  let count = Signal.make(0)

  // This function body executes once.
  // Only the text node updates when count changes.
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
    <h2 id="side-effects-and-dependencies"> {Node.text("Side Effects and Dependencies")} </h2>
    <p>
      {Node.text("One of the most common sources of bugs in React is the ")}
      <code> {Node.text("useEffect")} </code>
      {Node.text(" dependency array. Forgetting a dependency leads to stale closures; including too many causes infinite loops. Lint rules help, but they cannot catch all cases.")}
    </p>
    <p>
      {Node.text("Xote effects track dependencies automatically. Any signal read during effect execution becomes a dependency. When dependencies change, the effect re-runs. There is no array to maintain.")}
    </p>
    <p>
      <strong> {Node.text("React:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`// Must manually list every dependency
useEffect(() => {
  document.title = \`Count: \${count}\`;
}, [count]); // Forget count here and the title never updates`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Xote:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`// Dependencies tracked automatically
Effect.run(() => {
  document.title = "Count: " ++ Int.toString(Signal.get(count))
  None
})`)}
      </code>
    </pre>
    <p>
      <strong> {Node.text("Derived state")} </strong>
      {Node.text(" follows the same pattern. React's ")}
      <code> {Node.text("useMemo")} </code>
      {Node.text(" requires a dependency array. Xote's ")}
      <code> {Node.text("Computed.make")} </code>
      {Node.text(" tracks dependencies automatically and is lazy -- it only recomputes when read.")}
    </p>
    <pre>
      <code>
        {Node.text(`// Recomputes only when count changes, and only when someone reads it
let doubled = Computed.make(() => Signal.get(count) * 2)`)}
      </code>
    </pre>
    <h2 id="component-lifecycle"> {Node.text("Component Lifecycle")} </h2>
    <p>
      {Node.text("In React, components are functions that re-execute on every render. Hooks must follow strict ordering rules, and cleanup requires returning a function from ")}
      <code> {Node.text("useEffect")} </code>
      {Node.text(".")}
    </p>
    <p>
      {Node.text("In Xote, component functions execute once. Signals, effects, and computed values are created during that single execution. Cleanup is handled by the ")}
      <strong> {Node.text("owner system")} </strong>
      {Node.text(" -- each DOM element tracks its reactive resources, and when the element is removed from the DOM, all associated effects and computeds are disposed automatically.")}
    </p>
    <p>
      <strong> {Node.text("React:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Component functions re-execute on every render")}
      </li>
      <li>
        {Node.text("Hooks must follow the rules of hooks (no conditionals, fixed order)")}
      </li>
      <li>
        {Node.text("Cleanup via useEffect return functions")}
      </li>
      <li>
        {Node.text("Must use useRef to persist values across renders")}
      </li>
    </ul>
    <p>
      <strong> {Node.text("Xote:")} </strong>
    </p>
    <ul>
      <li>
        {Node.text("Component functions execute once")}
      </li>
      <li>
        {Node.text("No hook rules -- signals and effects can be created anywhere")}
      </li>
      <li>
        {Node.text("Cleanup via Effect return values and automatic owner-based disposal")}
      </li>
      <li>
        {Node.text("All values naturally persist (they are just local variables)")}
      </li>
    </ul>
    <h2 id="list-rendering"> {Node.text("List Rendering")} </h2>
    <p>
      <strong> {Node.text("React")} </strong>
      {Node.text(" uses key-based reconciliation during its virtual DOM diff. When a list changes, React matches elements by key and determines insertions, deletions, and moves. This works well but happens as part of the full VDOM reconciliation pass.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" provides ")}
      <code> {Node.text("keyedList")} </code>
      {Node.text(" with a dedicated 3-phase reconciliation algorithm that operates directly on the DOM:")}
    </p>
    <ol>
      <li>
        <strong> {Node.text("Remove")} </strong>
      {Node.text(" items no longer in the list")}
      </li>
      <li>
        <strong> {Node.text("Build new order")} </strong>
      {Node.text(" reusing existing DOM elements for unchanged keys")}
      </li>
      <li>
        <strong> {Node.text("Reconcile DOM")} </strong>
      {Node.text(" by inserting, moving, and replacing elements")}
      </li>
    </ol>
    <p>
      {Node.text("This preserves DOM element identity across updates -- an important property for elements with focus state, animations, or internal state.")}
    </p>
    <p>
      <strong> {Node.text("React:")} </strong>
    </p>
    <pre>
      <code>
        {Node.text(`function TodoList({ todos }) {
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
      <strong> {Node.text("Xote:")} </strong>
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
    <h2 id="server-side-rendering"> {Node.text("Server-Side Rendering")} </h2>
    <p>
      <strong> {Node.text("React")} </strong>
      {Node.text(" has mature SSR support through ")}
      <code> {Node.text("renderToString")} </code>
      {Node.text(", streaming with ")}
      <code> {Node.text("renderToPipeableStream")} </code>
      {Node.text(", and the newer Server Components architecture (via frameworks like Next.js). React's SSR ecosystem is extensive and battle-tested.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" provides built-in SSR with a focused feature set:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("\`SSR.renderToString\`")} </strong>
      {Node.text(" renders components to HTML strings")}
      </li>
      <li>
        <strong> {Node.text("\`SSR.renderDocument\`")} </strong>
      {Node.text(" generates full HTML documents with head, scripts, and styles")}
      </li>
      <li>
        <strong> {Node.text("Hydration markers")} </strong>
      {Node.text(" (HTML comments) mark reactive boundaries so the client can attach reactivity without re-rendering")}
      </li>
      <li>
        <strong> {Node.text("\`SSRState\`")} </strong>
      {Node.text(" handles state transfer between server and client with a type-safe codec system")}
      </li>
      <li>
        <strong> {Node.text("\`Hydration.hydrate\`")} </strong>
      {Node.text(" walks server-rendered DOM and attaches signals, effects, and event listeners")}
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
      {Node.text("React's SSR ecosystem is more mature and offers features like streaming and Server Components. Xote's SSR is simpler and more lightweight, handling the core use case of server rendering with client hydration and state transfer without requiring a framework.")}
    </p>
    <h2 id="routing"> {Node.text("Routing")} </h2>
    <p>
      <strong> {Node.text("React")} </strong>
      {Node.text(" does not include a router. You need a third-party library like React Router or TanStack Router. These are excellent but add to your dependency count and bundle size.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" includes a signal-based router out of the box:")}
    </p>
    <ul>
      <li>
        {Node.text("Pattern matching with dynamic segments (")}
      <code> {Node.text("/users/:id")} </code>
      {Node.text(")")}
      </li>
      <li>
        {Node.text("Imperative navigation (")}
      <code> {Node.text("Router.push")} </code>
      {Node.text(", ")}
      <code> {Node.text("Router.replace")} </code>
      {Node.text(")")}
      </li>
      <li>
        {Node.text("A ")}
      <code> {Node.text("Router.Link")} </code>
      {Node.text(" JSX component for declarative navigation")}
      </li>
      <li>
        {Node.text("Base path support for sub-app routing")}
      </li>
      <li>
        {Node.text("Scroll position restoration on back/forward navigation")}
      </li>
      <li>
        {Node.text("SSR-compatible initialization (")}
      <code> {Node.text("Router.initSSR")} </code>
      {Node.text(")")}
      </li>
      <li>
        {Node.text("Global singleton state via ")}
      <code> {Node.text("Symbol.for()")} </code>
      {Node.text(" so multiple bundles share the same router")}
      </li>
    </ul>
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
      {Node.text("Having routing built in means one less dependency to manage, and the router integrates naturally with the signal system -- route changes trigger reactive updates like any other signal change.")}
    </p>
    <h2 id="bundle-size-and-runtime-footprint"> {Node.text("Bundle Size and Runtime Footprint")} </h2>
    <p>
      {Node.text("This is one of the most significant practical differences. React's runtime (react + react-dom) is approximately ")}
      <strong> {Node.text("44KB minified")} </strong>
      {Node.text(" (about 14KB gzipped). Add a router and you are looking at another 10-20KB.")}
    </p>
    <p>
      {Node.text("Xote's entire runtime including the signals library is approximately ")}
      <strong> {Node.text("6KB minified")} </strong>
      {Node.text(". The built-in router and SSR modules are included in that figure.")}
    </p>
    <p>
      {Node.text("This difference comes from two factors:")}
    </p>
    <ol>
      <li>
        <strong> {Node.text("No virtual DOM")} </strong>
      {Node.text(": Xote does not need a diffing/reconciliation engine for general updates. The signal graph handles targeted updates directly.")}
      </li>
      <li>
        <strong> {Node.text("ReScript's zero-cost JSX")} </strong>
      {Node.text(": ReScript's JSX compiles to direct function calls with no runtime JSX transformer. There is no ")}
      <code> {Node.text("React.createElement")} </code>
      {Node.text(" equivalent that builds intermediate objects. The compiled output is lean JavaScript that directly constructs the component tree.")}
      </li>
    </ol>
    <p>
      {Node.text("For applications where initial load time matters -- mobile web, embedded widgets, progressive web apps, or performance-constrained environments -- this difference is substantial.")}
    </p>
    <h2 id="type-safety"> {Node.text("Type Safety")} </h2>
    <p>
      <strong> {Node.text("React")} </strong>
      {Node.text(" with TypeScript provides good type safety, but it is opt-in and structural. Generic component patterns, higher-order components, and complex hooks often require manual type annotations. Runtime type errors are still possible.")}
    </p>
    <p>
      <strong> {Node.text("Xote")} </strong>
      {Node.text(" uses ReScript, which has a sound type system with full type inference. Types are checked at compile time and cover the entire codebase. The compiler guarantees that if your code compiles, types are correct -- there are no runtime type errors from type mismatches. Pattern matching is exhaustive, and the absence of ")}
      <code> {Node.text("null")} </code>
      {Node.text("/")}
      <code> {Node.text("undefined")} </code>
      {Node.text(" exceptions (replaced by the ")}
      <code> {Node.text("option")} </code>
      {Node.text(" type) eliminates an entire class of bugs.")}
    </p>
    <h2 id="ecosystem"> {Node.text("Ecosystem")} </h2>
    <p>
      {Node.text("This is where React has a clear advantage. React has thousands of UI component libraries, state management solutions, form libraries, data fetching tools, animation frameworks, and more. The community is enormous, and finding help, tutorials, and examples is straightforward.")}
    </p>
    <p>
      {Node.text("Xote's ecosystem is minimal by design. It provides the core building blocks -- reactivity, components, routing, and SSR -- and leaves the rest to the application. This means less choice paralysis but also fewer off-the-shelf solutions.")}
    </p>
    <h2 id="when-to-choose-react"> {Node.text("When to Choose React")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Large ecosystem needed:")} </strong>
      {Node.text(" Your project relies on third-party React component libraries or integrations")}
      </li>
      <li>
        <strong> {Node.text("Team experience:")} </strong>
      {Node.text(" Your team is already proficient with React and JavaScript/TypeScript")}
      </li>
      <li>
        <strong> {Node.text("Mobile apps:")} </strong>
      {Node.text(" You want to use React Native for cross-platform development")}
      </li>
      <li>
        <strong> {Node.text("Hiring:")} </strong>
      {Node.text(" Finding React developers is easier in the current job market")}
      </li>
      <li>
        <strong> {Node.text("Mature SSR frameworks:")} </strong>
      {Node.text(" You need Next.js, Remix, or similar full-stack frameworks with advanced features like Server Components and streaming")}
      </li>
    </ul>
    <h2 id="when-to-choose-xote"> {Node.text("When to Choose Xote")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Performance-sensitive applications:")} </strong>
      {Node.text(" You need minimal bundle size and fast initial load times")}
      </li>
      <li>
        <strong> {Node.text("Fine-grained reactivity:")} </strong>
      {Node.text(" You want precise, efficient updates without virtual DOM overhead or memoization boilerplate")}
      </li>
      <li>
        <strong> {Node.text("Full-stack type safety:")} </strong>
      {Node.text(" You value a sound type system that catches errors at compile time")}
      </li>
      <li>
        <strong> {Node.text("Built-in essentials:")} </strong>
      {Node.text(" You prefer having routing, SSR, and hydration included without additional dependencies")}
      </li>
      <li>
        <strong> {Node.text("Signal-based architecture:")} </strong>
      {Node.text(" You want to build with a reactivity model aligned with the TC39 Signals proposal")}
      </li>
      <li>
        <strong> {Node.text("Minimal dependency footprint:")} </strong>
      {Node.text(" You want a focused library with a single runtime dependency")}
      </li>
    </ul>
    <h2 id="migration-considerations"> {Node.text("Migration Considerations")} </h2>
    <p>
      {Node.text("If you are coming from React, here is how core concepts map:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("useState")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Signal.make")} </code>
      </li>
      <li>
        <code> {Node.text("useMemo")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Computed.make")} </code>
      {Node.text(" (no dependency array needed)")}
      </li>
      <li>
        <code> {Node.text("useEffect")} </code>
      {Node.text(" -> ")}
      <code> {Node.text("Effect.run")} </code>
      {Node.text(" (no dependency array needed)")}
      </li>
      <li>
        <code> {Node.text("useRef")} </code>
      {Node.text(" -> Just use a ")}
      <code> {Node.text("ref()")} </code>
      {Node.text(" or a local ")}
      <code> {Node.text("let")} </code>
      {Node.text(" binding (components execute once)")}
      </li>
      <li>
        <code> {Node.text("React.memo")} </code>
      {Node.text(" -> Not needed (fine-grained updates by default)")}
      </li>
      <li>
        <code> {Node.text("useCallback")} </code>
      {Node.text(" -> Not needed (no re-renders to cause reference changes)")}
      </li>
      <li>
        <code> {Node.text("JSX")} </code>
      {Node.text(" -> ReScript JSX (very similar syntax)")}
      </li>
      <li>
        <code> {Node.text("React Router")} </code>
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
      {Node.text("The main learning curve is ReScript itself -- its syntax, type system, and functional programming patterns. The reactivity model is arguably simpler than React's hooks system once you understand signals.")}
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
        <a href="https://react.dev" target="_blank"> {Node.text("React Documentation")} </a>
      </li>
      <li>
        <a href="https://github.com/tc39/proposal-signals" target="_blank"> {Node.text("TC39 Signals Proposal")} </a>
      </li>
    </ul>
  </div>
}
