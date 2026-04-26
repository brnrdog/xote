// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/react.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <h2 id="at-a-glance"> {View.text("At a Glance")} </h2>
    <h3 id="overview"> {View.text("Overview")} </h3>
    <table>
      <thead>
        <tr>
          <th> {View.text("Aspect")} </th>
          <th> {View.text("React")} </th>
          <th> {View.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {View.text("Update model")} </strong> </td>
          <td> {View.text("Re-render component trees, then diff")} </td>
          <td> {View.text("Update the specific reactive consumers directly")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("State")} </strong> </td>
          <td> <code> {View.text("useState")} </code>
      {View.text(", ")}
      <code> {View.text("useReducer")} </code>
      {View.text(", external stores")} </td>
          <td> <code> {View.text("Signal")} </code>
      {View.text(", ")}
      <code> {View.text("Computed")} </code>
      {View.text(", ")}
      <code> {View.text("Effect")} </code> </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Effects")} </strong> </td>
          <td> <code> {View.text("useEffect")} </code>
      {View.text(" with explicit dependency arrays")} </td>
          <td> <code> {View.text("Effect.run")} </code>
      {View.text(" with tracked dependencies")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Routing")} </strong> </td>
          <td> {View.text("Third-party packages")} </td>
          <td> {View.text("Built in")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("SSR")} </strong> </td>
          <td> {View.text("Mature ecosystem and frameworks")} </td>
          <td> {View.text("Built-in primitives for SSR, hydration, and state transfer")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Language")} </strong> </td>
          <td> {View.text("JavaScript / TypeScript")} </td>
          <td> {View.text("ReScript")} </td>
        </tr>
      </tbody>
    </table>
    <p>
      {View.text("React and Xote solve many of the same problems, but they optimize for different tradeoffs. React optimizes for ecosystem reach and framework maturity. Xote optimizes for a smaller runtime, explicit fine-grained reactivity, and a tighter built-in surface.")}
    </p>
    <h2 id="runtime-model"> {View.text("Runtime Model")} </h2>
    <h3 id="reactivity-model"> {View.text("Reactivity Model")} </h3>
    <p>
      {View.text("React updates by re-running component functions and diffing the next virtual tree against the previous one. That model is flexible and well understood, but it means the render pass is the default unit of work.")}
    </p>
    <p>
      {View.text("Xote updates at the signal consumer level. When a signal changes, only the effects, computeds, or reactive DOM bindings that read that signal need to run again. The component function itself usually does not.")}
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
      {View.signalText(() => \`Count: \${Signal.get(count)->Int.toString}\`)}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {View.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <h3 id="effects-and-derived-state"> {View.text("Effects and Derived State")} </h3>
    <p>
      {View.text("React's ")}
      <code> {View.text("useEffect")} </code>
      {View.text(" and ")}
      <code> {View.text("useMemo")} </code>
      {View.text(" depend on manually maintained dependency arrays. That is workable, but stale or over-broad dependency lists are a common source of bugs and noise.")}
    </p>
    <p>
      {View.text("Xote tracks dependencies automatically. ")}
      <code> {View.text("Effect.run")} </code>
      {View.text(" subscribes to the signals it reads, and ")}
      <code> {View.text("Computed.make")} </code>
      {View.text(" derives values from the signals it reads.")}
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
  document.title = \`Count: \${Signal.get(count)->Int.toString}\`
  None
})

let doubled = Computed.make(() => Signal.get(count) * 2)`)}
      </code>
    </pre>
    <p>
      {View.text("The tradeoff is that React's hook model is familiar to more teams and supported by more tooling, while Xote's model is smaller and more explicit once you adopt signals.")}
    </p>
    <h3 id="component-lifecycle"> {View.text("Component Lifecycle")} </h3>
    <p>
      {View.text("React components re-run whenever their state or props change. That is why hooks exist: they preserve values across renders and enforce ordering rules.")}
    </p>
    <p>
      {View.text("Xote components usually run once. Signals, computeds, and effects are ordinary values created during that initial execution. Cleanup is handled by effect cleanups and the owner system that disposes reactive resources when DOM nodes are removed.")}
    </p>
    <h3 id="list-rendering"> {View.text("List Rendering")} </h3>
    <p>
      {View.text("React uses keys during virtual DOM reconciliation. Xote prefers ")}
      <code> {View.text("View.eachWithKey")} </code>
      {View.text(", which works directly against DOM anchors and explicit keys.")}
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
    {View.eachWithKey(
      todos,
      todo => todo.id,
      todo => <li> {View.text(todo.text)} </li>,
    )}
  </ul>
}`)}
      </code>
    </pre>
    <p>
      {View.text("In practice, both can preserve item identity. The difference is mostly where the work happens: inside a general-purpose renderer in React, or through a dedicated keyed-list primitive in Xote.")}
    </p>
    <h2 id="platform-surface"> {View.text("Platform Surface")} </h2>
    <h3 id="server-side-rendering"> {View.text("Server-Side Rendering")} </h3>
    <p>
      {View.text("React has the stronger SSR ecosystem. Frameworks like Next.js and Remix add routing, data loading, streaming, server actions, and deployment integrations on top of the core renderer.")}
    </p>
    <p>
      {View.text("Xote gives you lower-level primitives directly: ")}
      <code> {View.text("SSR.renderToString")} </code>
      {View.text(", ")}
      <code> {View.text("SSR.renderDocument")} </code>
      {View.text(", ")}
      <code> {View.text("SSRState")} </code>
      {View.text(", and ")}
      <code> {View.text("Hydration")} </code>
      {View.text(". That is enough for custom SSR pipelines, but it is intentionally not a batteries-included application framework.")}
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
    <h3 id="routing"> {View.text("Routing")} </h3>
    <p>
      {View.text("React relies on external routers such as React Router or TanStack Router. That is not a weakness by itself, but it does mean routing decisions also become ecosystem decisions.")}
    </p>
    <p>
      {View.text("Xote includes a router in the main library. If you want pattern matching, links, imperative navigation, and SSR-aware initialization without another dependency, that is a meaningful simplification.")}
    </p>
    <h3 id="runtime-footprint"> {View.text("Runtime Footprint")} </h3>
    <p>
      {View.text("React's runtime is larger because it carries a general rendering engine and is often paired with more packages. Xote stays smaller because the reactive graph and direct DOM updates remove the need for a general virtual DOM reconciliation path during normal updates.")}
    </p>
    <p>
      {View.text("Bundle size should not be the only decision criterion, but it matters for widgets, embedded apps, and performance-sensitive pages.")}
    </p>
    <h3 id="type-safety"> {View.text("Type Safety")} </h3>
    <p>
      {View.text("React with TypeScript gives strong ergonomics and wide adoption, but the type system is still optional and structurally typed.")}
    </p>
    <p>
      {View.text("Xote inherits ReScript's sounder model. Pattern matching, ")}
      <code> {View.text("option")} </code>
      {View.text(", and exhaustiveness checks reduce a class of runtime mistakes that TypeScript projects still need discipline to avoid.")}
    </p>
    <h3 id="ecosystem"> {View.text("Ecosystem")} </h3>
    <p>
      {View.text("React is the safer choice if your project depends on third-party UI kits, data tooling, or hiring from a very large pool.")}
    </p>
    <p>
      {View.text("Xote is the better fit when you want to own the stack, keep runtime dependencies minimal, and work from a smaller but more integrated API.")}
    </p>
    <h2 id="choosing-between-them"> {View.text("Choosing Between Them")} </h2>
    <h3 id="when-to-choose-react"> {View.text("When to Choose React")} </h3>
    <ul>
      <li>
        {View.text("Reach for React when ecosystem depth is a hard requirement.")}
      </li>
      <li>
        {View.text("Reach for React when the team is already fluent in React and TypeScript.")}
      </li>
      <li>
        {View.text("Reach for React when third-party UI kits or integrations are central to the product.")}
      </li>
      <li>
        {View.text("Reach for React when React Native is part of the broader platform story.")}
      </li>
    </ul>
    <h3 id="when-to-choose-xote"> {View.text("When to Choose Xote")} </h3>
    <ul>
      <li>
        {View.text("Reach for Xote when you want fine-grained updates without a virtual DOM render cycle.")}
      </li>
      <li>
        {View.text("Reach for Xote when built-in routing and SSR primitives reduce project overhead.")}
      </li>
      <li>
        {View.text("Reach for Xote when ReScript's type model is part of the value proposition.")}
      </li>
      <li>
        {View.text("Reach for Xote when the UI is focused enough that a smaller ecosystem is a benefit, not a cost.")}
      </li>
    </ul>
    <h3 id="migration-considerations"> {View.text("Migration Considerations")} </h3>
    <p>
      {View.text("React developers usually adapt to Xote fastest when they stop looking for hook equivalents and instead map responsibilities directly:")}
    </p>
    <ol>
      <li>
        <code> {View.text("useState")} </code>
      {View.text(" becomes ")}
      <code> {View.text("Signal.make")} </code>
      </li>
      <li>
        <code> {View.text("useMemo")} </code>
      {View.text(" becomes ")}
      <code> {View.text("Computed.make")} </code>
      </li>
      <li>
        <code> {View.text("useEffect")} </code>
      {View.text(" becomes ")}
      <code> {View.text("Effect.run")} </code>
      </li>
      <li>
        {View.text("keyed ")}
      <code> {View.text(".map()")} </code>
      {View.text(" rendering becomes ")}
      <code> {View.text("View.eachWithKey")} </code>
      {View.text(" when identity matters")}
      </li>
    </ol>
    <p>
      {View.text("The conceptual shift is from re-rendered components to persistent reactive values.")}
    </p>
    <h3 id="further-reading"> {View.text("Further Reading")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Signals")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/computed", ~children=[View.text("Computeds")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/core-concepts/effects", ~children=[View.text("Effects")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("View")], ())}
      </li>
    </ul>
  </div>
}
