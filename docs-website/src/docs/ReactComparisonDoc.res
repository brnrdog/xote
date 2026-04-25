// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/react.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h2 id="at-a-glance"> {Node.text("At a Glance")} </h2>
    <h3 id="overview"> {Node.text("Overview")} </h3>
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
          <td> <strong> {Node.text("Update model")} </strong> </td>
          <td> {Node.text("Re-render component trees, then diff")} </td>
          <td> {Node.text("Update the specific reactive consumers directly")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("State")} </strong> </td>
          <td> <code> {Node.text("useState")} </code>
      {Node.text(", ")}
      <code> {Node.text("useReducer")} </code>
      {Node.text(", external stores")} </td>
          <td> <code> {Node.text("Signal")} </code>
      {Node.text(", ")}
      <code> {Node.text("Computed")} </code>
      {Node.text(", ")}
      <code> {Node.text("Effect")} </code> </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Effects")} </strong> </td>
          <td> <code> {Node.text("useEffect")} </code>
      {Node.text(" with explicit dependency arrays")} </td>
          <td> <code> {Node.text("Effect.run")} </code>
      {Node.text(" with tracked dependencies")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Routing")} </strong> </td>
          <td> {Node.text("Third-party packages")} </td>
          <td> {Node.text("Built in")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("SSR")} </strong> </td>
          <td> {Node.text("Mature ecosystem and frameworks")} </td>
          <td> {Node.text("Built-in primitives for SSR, hydration, and state transfer")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Language")} </strong> </td>
          <td> {Node.text("JavaScript / TypeScript")} </td>
          <td> {Node.text("ReScript")} </td>
        </tr>
      </tbody>
    </table>
    <p>
      {Node.text("React and Xote solve many of the same problems, but they optimize for different tradeoffs. React optimizes for ecosystem reach and framework maturity. Xote optimizes for a smaller runtime, explicit fine-grained reactivity, and a tighter built-in surface.")}
    </p>
    <h2 id="runtime-model"> {Node.text("Runtime Model")} </h2>
    <h3 id="reactivity-model"> {Node.text("Reactivity Model")} </h3>
    <p>
      {Node.text("React updates by re-running component functions and diffing the next virtual tree against the previous one. That model is flexible and well understood, but it means the render pass is the default unit of work.")}
    </p>
    <p>
      {Node.text("Xote updates at the signal consumer level. When a signal changes, only the effects, computeds, or reactive DOM bindings that read that signal need to run again. The component function itself usually does not.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <h1>Count: {count}</h1>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let counter = () => {
  let count = Signal.make(0)

  <div>
    <h1>
      {Node.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Node.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <h3 id="effects-and-derived-state"> {Node.text("Effects and Derived State")} </h3>
    <p>
      {Node.text("React's ")}
      <code> {Node.text("useEffect")} </code>
      {Node.text(" and ")}
      <code> {Node.text("useMemo")} </code>
      {Node.text(" depend on manually maintained dependency arrays. That is workable, but stale or over-broad dependency lists are a common source of bugs and noise.")}
    </p>
    <p>
      {Node.text("Xote tracks dependencies automatically. ")}
      <code> {Node.text("Effect.run")} </code>
      {Node.text(" subscribes to the signals it reads, and ")}
      <code> {Node.text("Computed.make")} </code>
      {Node.text(" derives values from the signals it reads.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`useEffect(() => {
  document.title = \`Count: \${count}\`;
}, [count]);`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Effect.run(() => {
  document.title = "Count: " ++ Int.toString(Signal.get(count))
  None
})

let doubled = Computed.make(() => Signal.get(count) * 2)`)}
      </code>
    </pre>
    <p>
      {Node.text("The tradeoff is that React's hook model is familiar to more teams and supported by more tooling, while Xote's model is smaller and more explicit once you adopt signals.")}
    </p>
    <h3 id="component-lifecycle"> {Node.text("Component Lifecycle")} </h3>
    <p>
      {Node.text("React components re-run whenever their state or props change. That is why hooks exist: they preserve values across renders and enforce ordering rules.")}
    </p>
    <p>
      {Node.text("Xote components usually run once. Signals, computeds, and effects are ordinary values created during that initial execution. Cleanup is handled by effect cleanups and the owner system that disposes reactive resources when DOM nodes are removed.")}
    </p>
    <h3 id="list-rendering"> {Node.text("List Rendering")} </h3>
    <p>
      {Node.text("React uses keys during virtual DOM reconciliation. Xote uses ")}
      <code> {Node.text("Node.keyedList")} </code>
      {Node.text(", which works directly against DOM anchors and explicit keys.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`function TodoList({ todos }) {
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
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let todoList = () => {
  let todos = Signal.make([{id: "1", text: "Buy milk"}])

  <ul>
    {Node.keyedList(
      todos,
      todo => todo.id,
      todo => <li> {Node.text(todo.text)} </li>,
    )}
  </ul>
}`)}
      </code>
    </pre>
    <p>
      {Node.text("In practice, both can preserve item identity. The difference is mostly where the work happens: inside a general-purpose renderer in React, or through a dedicated keyed-list primitive in Xote.")}
    </p>
    <h2 id="platform-surface"> {Node.text("Platform Surface")} </h2>
    <h3 id="server-side-rendering"> {Node.text("Server-Side Rendering")} </h3>
    <p>
      {Node.text("React has the stronger SSR ecosystem. Frameworks like Next.js and Remix add routing, data loading, streaming, server actions, and deployment integrations on top of the core renderer.")}
    </p>
    <p>
      {Node.text("Xote gives you lower-level primitives directly: ")}
      <code> {Node.text("SSR.renderToString")} </code>
      {Node.text(", ")}
      <code> {Node.text("SSR.renderDocument")} </code>
      {Node.text(", ")}
      <code> {Node.text("SSRState")} </code>
      {Node.text(", and ")}
      <code> {Node.text("Hydration")} </code>
      {Node.text(". That is enough for custom SSR pipelines, but it is intentionally not a batteries-included application framework.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let html = SSR.renderDocument(
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app,
)

Hydration.hydrateById(app, "root")`)}
      </code>
    </pre>
    <h3 id="routing"> {Node.text("Routing")} </h3>
    <p>
      {Node.text("React relies on external routers such as React Router or TanStack Router. That is not a weakness by itself, but it does mean routing decisions also become ecosystem decisions.")}
    </p>
    <p>
      {Node.text("Xote includes a router in the main library. If you want pattern matching, links, imperative navigation, and SSR-aware initialization without another dependency, that is a meaningful simplification.")}
    </p>
    <h3 id="runtime-footprint"> {Node.text("Runtime Footprint")} </h3>
    <p>
      {Node.text("React's runtime is larger because it carries a general rendering engine and is often paired with more packages. Xote stays smaller because the reactive graph and direct DOM updates remove the need for a general virtual DOM reconciliation path during normal updates.")}
    </p>
    <p>
      {Node.text("Bundle size should not be the only decision criterion, but it matters for widgets, embedded apps, and performance-sensitive pages.")}
    </p>
    <h3 id="type-safety"> {Node.text("Type Safety")} </h3>
    <p>
      {Node.text("React with TypeScript gives strong ergonomics and wide adoption, but the type system is still optional and structurally typed.")}
    </p>
    <p>
      {Node.text("Xote inherits ReScript's sounder model. Pattern matching, ")}
      <code> {Node.text("option")} </code>
      {Node.text(", and exhaustiveness checks reduce a class of runtime mistakes that TypeScript projects still need discipline to avoid.")}
    </p>
    <h3 id="ecosystem"> {Node.text("Ecosystem")} </h3>
    <p>
      {Node.text("React is the safer choice if your project depends on third-party UI kits, data tooling, or hiring from a very large pool.")}
    </p>
    <p>
      {Node.text("Xote is the better fit when you want to own the stack, keep runtime dependencies minimal, and work from a smaller but more integrated API.")}
    </p>
    <h2 id="choosing-between-them"> {Node.text("Choosing Between Them")} </h2>
    <h3 id="when-to-choose-react"> {Node.text("When to Choose React")} </h3>
    <ul>
      <li>
        {Node.text("Reach for React when ecosystem depth is a hard requirement.")}
      </li>
      <li>
        {Node.text("Reach for React when the team is already fluent in React and TypeScript.")}
      </li>
      <li>
        {Node.text("Reach for React when third-party UI kits or integrations are central to the product.")}
      </li>
      <li>
        {Node.text("Reach for React when React Native is part of the broader platform story.")}
      </li>
    </ul>
    <h3 id="when-to-choose-xote"> {Node.text("When to Choose Xote")} </h3>
    <ul>
      <li>
        {Node.text("Reach for Xote when you want fine-grained updates without a virtual DOM render cycle.")}
      </li>
      <li>
        {Node.text("Reach for Xote when built-in routing and SSR primitives reduce project overhead.")}
      </li>
      <li>
        {Node.text("Reach for Xote when ReScript's type model is part of the value proposition.")}
      </li>
      <li>
        {Node.text("Reach for Xote when the UI is focused enough that a smaller ecosystem is a benefit, not a cost.")}
      </li>
    </ul>
    <h3 id="migration-considerations"> {Node.text("Migration Considerations")} </h3>
    <p>
      {Node.text("React developers usually adapt to Xote fastest when they stop looking for hook equivalents and instead map responsibilities directly:")}
    </p>
    <ol>
      <li>
        <code> {Node.text("useState")} </code>
      {Node.text(" becomes ")}
      <code> {Node.text("Signal.make")} </code>
      </li>
      <li>
        <code> {Node.text("useMemo")} </code>
      {Node.text(" becomes ")}
      <code> {Node.text("Computed.make")} </code>
      </li>
      <li>
        <code> {Node.text("useEffect")} </code>
      {Node.text(" becomes ")}
      <code> {Node.text("Effect.run")} </code>
      </li>
      <li>
        {Node.text("keyed ")}
      <code> {Node.text(".map()")} </code>
      {Node.text(" rendering becomes ")}
      <code> {Node.text("Node.keyedList")} </code>
      {Node.text(" when identity matters")}
      </li>
    </ol>
    <p>
      {Node.text("The conceptual shift is from re-rendered components to persistent reactive values.")}
    </p>
    <h3 id="further-reading"> {Node.text("Further Reading")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[Node.text("Computeds")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[Node.text("Effects")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      </li>
    </ul>
  </div>
}
