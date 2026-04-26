// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/comparisons/solidjs.md
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
          <th> {View.text("SolidJS")} </th>
          <th> {View.text("Xote")} </th>
        </tr>
      </thead>
      <tbody>
        <tr>
          <td> <strong> {View.text("Reactive model")} </strong> </td>
          <td> {View.text("Fine-grained signals")} </td>
          <td> {View.text("Fine-grained signals")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Component execution")} </strong> </td>
          <td> {View.text("Usually once")} </td>
          <td> {View.text("Usually once")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Routing")} </strong> </td>
          <td> {View.text("Separate package")} </td>
          <td> {View.text("Built in")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("SSR")} </strong> </td>
          <td> {View.text("Strong framework story via SolidStart")} </td>
          <td> {View.text("Built-in primitives")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Language")} </strong> </td>
          <td> {View.text("JavaScript / TypeScript")} </td>
          <td> {View.text("ReScript")} </td>
        </tr>
        <tr>
          <td> <strong> {View.text("Scope")} </strong> </td>
          <td> {View.text("Framework plus ecosystem")} </td>
          <td> {View.text("Smaller integrated UI library")} </td>
        </tr>
      </tbody>
    </table>
    <p>
      {View.text("SolidJS and Xote are conceptually much closer to each other than either is to React. The real differences are language choice, what is included out of the box, and how explicit the UI bindings are.")}
    </p>
    <h2 id="shared-ground"> {View.text("Shared Ground")} </h2>
    <h3 id="shared-philosophy"> {View.text("Shared Philosophy")} </h3>
    <p>
      {View.text("Both libraries:")}
    </p>
    <ul>
      <li>
        {View.text("use signals as the foundation")}
      </li>
      <li>
        {View.text("avoid virtual DOM diffing for ordinary updates")}
      </li>
      <li>
        {View.text("let components establish reactive structure once")}
      </li>
      <li>
        {View.text("rely on dependency tracking instead of dependency arrays")}
      </li>
    </ul>
    <p>
      {View.text("If you already understand SolidJS, Xote's mental model will feel familiar quickly.")}
    </p>
    <h2 id="runtime-model"> {View.text("Runtime Model")} </h2>
    <h3 id="signals-and-state"> {View.text("Signals and State")} </h3>
    <p>
      {View.text("SolidJS uses getter and setter pairs. Xote uses explicit read and write functions against a signal value.")}
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
      {View.text("Key differences:")}
    </p>
    <ul>
      <li>
        {View.text("SolidJS reads via function calls like ")}
      <code> {View.text("count()")} </code>
      {View.text(", Xote reads via ")}
      <code> {View.text("Signal.get(count)")} </code>
      </li>
      <li>
        {View.text("Xote effects return cleanup directly; SolidJS uses ")}
      <code> {View.text("onCleanup")} </code>
      </li>
      <li>
        {View.text("Xote signals use strict equality by default and let you opt into custom equality with ")}
      <code> {View.text("~equals")} </code>
      </li>
    </ul>
    <h3 id="component-model"> {View.text("Component Model")} </h3>
    <p>
      {View.text("Both component models are close: the function runs, the DOM structure is created, and later updates flow through reactive bindings instead of through repeated component renders.")}
    </p>
    <p>
      {View.text("The main ergonomic difference is that SolidJS can embed reactive expressions directly inside JSX, while Xote makes the reactive boundary explicit with helpers such as ")}
      <code> {View.text("View.signalText")} </code>
      {View.text(".")}
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
      {View.signalText(() => \`Count: \${Signal.get(count)->Int.toString}\`)}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {View.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <h3 id="list-rendering"> {View.text("List Rendering")} </h3>
    <p>
      {View.text("SolidJS uses control-flow helpers like ")}
      <code> {View.text("<For>")} </code>
      {View.text(" and ")}
      <code> {View.text("<Index>")} </code>
      {View.text(". Xote exposes list handling through ")}
      <code> {View.text("View.each")} </code>
      {View.text(" and ")}
      <code> {View.text("View.eachWithKey")} </code>
      {View.text(".")}
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
      {View.text("Both approaches preserve identity. Xote asks for the key function explicitly, which keeps the reconciliation contract visible in the code.")}
    </p>
    <h2 id="platform-surface"> {View.text("Platform Surface")} </h2>
    <h3 id="server-side-rendering"> {View.text("Server-Side Rendering")} </h3>
    <p>
      {View.text("SolidJS has the more complete application story through SolidStart. If you want file-based routing, streaming, and framework-level conventions, SolidStart is a major advantage.")}
    </p>
    <p>
      {View.text("Xote's SSR primitives are smaller and more manual. You render HTML, optionally serialize state with ")}
      <code> {View.text("SSRState")} </code>
      {View.text(", and hydrate the result on the client.")}
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
      {View.text("SolidJS uses ")}
      <code> {View.text("@solidjs/router")} </code>
      {View.text(" rather than shipping a router in the core package. Xote includes one. That difference matters more for smaller apps than for large framework-driven apps, but it is still an important scope distinction.")}
    </p>
    <h3 id="runtime-footprint-and-compilation"> {View.text("Runtime Footprint and Compilation")} </h3>
    <p>
      {View.text("Both libraries produce small output. The practical difference is in the toolchain:")}
    </p>
    <ul>
      <li>
        {View.text("SolidJS uses a JSX compiler that turns reactive expressions into direct DOM operations")}
      </li>
      <li>
        {View.text("Xote relies on the ReScript compiler and generic JSX transform, then uses explicit reactive nodes where needed")}
      </li>
    </ul>
    <p>
      {View.text("SolidJS feels more implicit in JSX. Xote is more explicit about where reactivity lives.")}
    </p>
    <h3 id="type-safety"> {View.text("Type Safety")} </h3>
    <p>
      {View.text("SolidJS with TypeScript is productive and familiar, but still lives in TypeScript's structural and partially unsound model.")}
    </p>
    <p>
      {View.text("Xote benefits from ReScript's stricter type guarantees. If that matters more to your team than staying in JS/TS syntax, it is a strong reason to prefer Xote.")}
    </p>
    <h3 id="ecosystem"> {View.text("Ecosystem")} </h3>
    <p>
      {View.text("SolidJS has a meaningful and growing ecosystem, especially around SolidStart and headless UI work.")}
    </p>
    <p>
      {View.text("Xote is intentionally smaller. That means fewer ready-made packages, but also fewer architectural decisions outsourced to third-party dependencies.")}
    </p>
    <h2 id="choosing-between-them"> {View.text("Choosing Between Them")} </h2>
    <h3 id="when-to-choose-solidjs"> {View.text("When to Choose SolidJS")} </h3>
    <ul>
      <li>
        {View.text("Reach for SolidJS when you want fine-grained reactivity while staying in JavaScript or TypeScript.")}
      </li>
      <li>
        {View.text("Reach for SolidJS when the stronger ecosystem and framework story matter immediately.")}
      </li>
      <li>
        {View.text("Reach for SolidJS when SolidStart and its conventions are part of the expected stack.")}
      </li>
    </ul>
    <h3 id="when-to-choose-xote"> {View.text("When to Choose Xote")} </h3>
    <ul>
      <li>
        {View.text("Reach for Xote when a smaller integrated API is more valuable than broader ecosystem depth.")}
      </li>
      <li>
        {View.text("Reach for Xote when ReScript's type system and compilation model are part of the appeal.")}
      </li>
      <li>
        {View.text("Reach for Xote when you prefer explicit reactive bindings over more automatic JSX transforms.")}
      </li>
    </ul>
    <h3 id="migration-considerations"> {View.text("Migration Considerations")} </h3>
    <p>
      {View.text("SolidJS developers typically need to adapt in three places:")}
    </p>
    <ol>
      <li>
        {View.text("signal reads move from function calls to ")}
      <code> {View.text("Signal.get")} </code>
      </li>
      <li>
        {View.text("reactive JSX expressions often become ")}
      <code> {View.text("View.signalText")} </code>
      {View.text(" or other explicit reactive nodes")}
      </li>
      <li>
        {View.text("routing and SSR move from the Solid ecosystem to Xote's built-in modules")}
      </li>
    </ol>
    <p>
      {View.text("The underlying mental model stays largely the same.")}
    </p>
    <h3 id="further-reading"> {View.text("Further Reading")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[View.text("Signals")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("View")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[View.text("Router")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[View.text("Server-Side Rendering")], ())}
      </li>
    </ul>
  </div>
}
