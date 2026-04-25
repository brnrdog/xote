// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/solidjs.md
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
          <th> {Node.text("SolidJS")} </th>
          <th> {Node.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {Node.text("Reactive model")} </strong> </td>
          <td> {Node.text("Fine-grained signals")} </td>
          <td> {Node.text("Fine-grained signals")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Component execution")} </strong> </td>
          <td> {Node.text("Usually once")} </td>
          <td> {Node.text("Usually once")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Routing")} </strong> </td>
          <td> {Node.text("Separate package")} </td>
          <td> {Node.text("Built in")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("SSR")} </strong> </td>
          <td> {Node.text("Strong framework story via SolidStart")} </td>
          <td> {Node.text("Built-in primitives")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Language")} </strong> </td>
          <td> {Node.text("JavaScript / TypeScript")} </td>
          <td> {Node.text("ReScript")} </td>
        </tr>
        <tr>
          <td> <strong> {Node.text("Scope")} </strong> </td>
          <td> {Node.text("Framework plus ecosystem")} </td>
          <td> {Node.text("Smaller integrated UI library")} </td>
        </tr>
      </tbody>
    </table>
    <p>
      {Node.text("SolidJS and Xote are conceptually much closer to each other than either is to React. The real differences are language choice, what is included out of the box, and how explicit the UI bindings are.")}
    </p>
    <h2 id="shared-ground"> {Node.text("Shared Ground")} </h2>
    <h3 id="shared-philosophy"> {Node.text("Shared Philosophy")} </h3>
    <p>
      {Node.text("Both libraries:")}
    </p>
    <ul>
      <li>
        {Node.text("use signals as the foundation")}
      </li>
      <li>
        {Node.text("avoid virtual DOM diffing for ordinary updates")}
      </li>
      <li>
        {Node.text("let components establish reactive structure once")}
      </li>
      <li>
        {Node.text("rely on dependency tracking instead of dependency arrays")}
      </li>
    </ul>
    <p>
      {Node.text("If you already understand SolidJS, Xote's mental model will feel familiar quickly.")}
    </p>
    <h2 id="runtime-model"> {Node.text("Runtime Model")} </h2>
    <h3 id="signals-and-state"> {Node.text("Signals and State")} </h3>
    <p>
      {Node.text("SolidJS uses getter and setter pairs. Xote uses explicit read and write functions against a signal value.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`import { createSignal, createMemo, createEffect } from "solid-js";

const [count, setCount] = createSignal(0);
const doubled = createMemo(() => count() * 2);

createEffect(() => {
  console.log(count());
});`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Effect.run(() => {
  Console.log(Signal.get(count))
  None
})`)}
      </code>
    </pre>
    <p>
      {Node.text("Key differences:")}
    </p>
    <ul>
      <li>
        {Node.text("SolidJS reads via function calls like ")}
      <code> {Node.text("count()")} </code>
      {Node.text(", Xote reads via ")}
      <code> {Node.text("Signal.get(count)")} </code>
      </li>
      <li>
        {Node.text("Xote effects return cleanup directly; SolidJS uses ")}
      <code> {Node.text("onCleanup")} </code>
      </li>
      <li>
        {Node.text("Xote signals use strict equality by default and let you opt into custom equality with ")}
      <code> {Node.text("~equals")} </code>
      </li>
    </ul>
    <h3 id="component-model"> {Node.text("Component Model")} </h3>
    <p>
      {Node.text("Both component models are close: the function runs, the DOM structure is created, and later updates flow through reactive bindings instead of through repeated component renders.")}
    </p>
    <p>
      {Node.text("The main ergonomic difference is that SolidJS can embed reactive expressions directly inside JSX, while Xote makes the reactive boundary explicit with helpers such as ")}
      <code> {Node.text("Node.signalText")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`function Counter() {
  const [count, setCount] = createSignal(0);

  return (
    <div>
      <h1>Count: {count()}</h1>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}`)}
      </code>
    </pre>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let counter = () => {
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
    <h3 id="list-rendering"> {Node.text("List Rendering")} </h3>
    <p>
      {Node.text("SolidJS uses control-flow helpers like ")}
      <code> {Node.text("<For>")} </code>
      {Node.text(" and ")}
      <code> {Node.text("<Index>")} </code>
      {Node.text(". Xote exposes list handling through ")}
      <code> {Node.text("Node.list")} </code>
      {Node.text(" and ")}
      <code> {Node.text("Node.keyedList")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`import { For } from "solid-js";

function TodoList(props) {
  return (
    <ul>
      <For each={props.todos}>
        {todo => <li>{todo.text}</li>}
      </For>
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
      {Node.text("Both approaches preserve identity. Xote asks for the key function explicitly, which keeps the reconciliation contract visible in the code.")}
    </p>
    <h2 id="platform-surface"> {Node.text("Platform Surface")} </h2>
    <h3 id="server-side-rendering"> {Node.text("Server-Side Rendering")} </h3>
    <p>
      {Node.text("SolidJS has the more complete application story through SolidStart. If you want file-based routing, streaming, and framework-level conventions, SolidStart is a major advantage.")}
    </p>
    <p>
      {Node.text("Xote's SSR primitives are smaller and more manual. You render HTML, optionally serialize state with ")}
      <code> {Node.text("SSRState")} </code>
      {Node.text(", and hydrate the result on the client.")}
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
      {Node.text("SolidJS uses ")}
      <code> {Node.text("@solidjs/router")} </code>
      {Node.text(" rather than shipping a router in the core package. Xote includes one. That difference matters more for smaller apps than for large framework-driven apps, but it is still an important scope distinction.")}
    </p>
    <h3 id="runtime-footprint-and-compilation"> {Node.text("Runtime Footprint and Compilation")} </h3>
    <p>
      {Node.text("Both libraries produce small output. The practical difference is in the toolchain:")}
    </p>
    <ul>
      <li>
        {Node.text("SolidJS uses a JSX compiler that turns reactive expressions into direct DOM operations")}
      </li>
      <li>
        {Node.text("Xote relies on the ReScript compiler and generic JSX transform, then uses explicit reactive nodes where needed")}
      </li>
    </ul>
    <p>
      {Node.text("SolidJS feels more implicit in JSX. Xote is more explicit about where reactivity lives.")}
    </p>
    <h3 id="type-safety"> {Node.text("Type Safety")} </h3>
    <p>
      {Node.text("SolidJS with TypeScript is productive and familiar, but still lives in TypeScript's structural and partially unsound model.")}
    </p>
    <p>
      {Node.text("Xote benefits from ReScript's stricter type guarantees. If that matters more to your team than staying in JS/TS syntax, it is a strong reason to prefer Xote.")}
    </p>
    <h3 id="ecosystem"> {Node.text("Ecosystem")} </h3>
    <p>
      {Node.text("SolidJS has a meaningful and growing ecosystem, especially around SolidStart and headless UI work.")}
    </p>
    <p>
      {Node.text("Xote is intentionally smaller. That means fewer ready-made packages, but also fewer architectural decisions outsourced to third-party dependencies.")}
    </p>
    <h2 id="choosing-between-them"> {Node.text("Choosing Between Them")} </h2>
    <h3 id="when-to-choose-solidjs"> {Node.text("When to Choose SolidJS")} </h3>
    <ul>
      <li>
        {Node.text("Reach for SolidJS when you want fine-grained reactivity while staying in JavaScript or TypeScript.")}
      </li>
      <li>
        {Node.text("Reach for SolidJS when the stronger ecosystem and framework story matter immediately.")}
      </li>
      <li>
        {Node.text("Reach for SolidJS when SolidStart and its conventions are part of the expected stack.")}
      </li>
    </ul>
    <h3 id="when-to-choose-xote"> {Node.text("When to Choose Xote")} </h3>
    <ul>
      <li>
        {Node.text("Reach for Xote when a smaller integrated API is more valuable than broader ecosystem depth.")}
      </li>
      <li>
        {Node.text("Reach for Xote when ReScript's type system and compilation model are part of the appeal.")}
      </li>
      <li>
        {Node.text("Reach for Xote when you prefer explicit reactive bindings over more automatic JSX transforms.")}
      </li>
    </ul>
    <h3 id="migration-considerations"> {Node.text("Migration Considerations")} </h3>
    <p>
      {Node.text("SolidJS developers typically need to adapt in three places:")}
    </p>
    <ol>
      <li>
        {Node.text("signal reads move from function calls to ")}
      <code> {Node.text("Signal.get")} </code>
      </li>
      <li>
        {Node.text("reactive JSX expressions often become ")}
      <code> {Node.text("Node.signalText")} </code>
      {Node.text(" or other explicit reactive nodes")}
      </li>
      <li>
        {Node.text("routing and SSR move from the Solid ecosystem to Xote's built-in modules")}
      </li>
    </ol>
    <p>
      {Node.text("The underlying mental model stays largely the same.")}
    </p>
    <h3 id="further-reading"> {Node.text("Further Reading")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[Node.text("Router")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[Node.text("Server-Side Rendering")], ())}
      </li>
    </ul>
  </div>
}
