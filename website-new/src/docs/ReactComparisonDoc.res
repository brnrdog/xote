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
      {Component.text("This guide compares Xote with React to help you understand the differences in philosophy, API design, and when to choose each framework.")}
    </p>
    <h2> {Component.text("Philosophy")} </h2>
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
          <td> {Component.text("Re-render component trees on state change")} </td>
          <td> {Component.text("Direct DOM updates at the signal level")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("State")} </strong> </td>
          <td> {Component.text("useState, useReducer hooks")} </td>
          <td> {Component.text("Signal primitives (Signal, Computed, Effect)")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Side Effects")} </strong> </td>
          <td> {Component.text("useEffect hook with dependency array")} </td>
          <td> {Component.text("Effect.run with automatic dependency tracking")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Ecosystem")} </strong> </td>
          <td> {Component.text("Massive: thousands of libraries and tools")} </td>
          <td> {Component.text("Minimal: focused on core reactivity")} </td>
        </tr>
        <tr>
          <td> <strong> {Component.text("Bundle Size")} </strong> </td>
          <td> {Component.text("~45KB (React + ReactDOM minified)")} </td>
          <td> {Component.text("~8KB (Xote + rescript-signals minified)")} </td>
        </tr>
      </tbody>
    </table>
    <h2> {Component.text("Code Comparison: Counter Example")} </h2>
    <h3> {Component.text("React Version")} </h3>
    <pre>
      <code class="language-javascript">
        {Component.text(`import { useState } from 'react';

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <h1>Count: {count}</h1>
      <button onClick={() => setCount(count + 1)}>
        Increment
      </button>
    </div>
  );
}`)}
      </code>
    </pre>
    <h3> {Component.text("Xote Version")} </h3>
    <pre>
      <code class="language-rescript">
        {Component.text(`open Xote

let counter = () => {
  let count = Signal.make(0)

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
    <h2> {Component.text("Key Differences")} </h2>
    <h3> {Component.text("1. Reactivity Model")} </h3>
    <p>
      <strong> {Component.text("React:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Re-renders entire component on state change")}
      </li>
      <li>
        {Component.text("Virtual DOM diffing determines what changed")}
      </li>
      <li>
        {Component.text("Batches updates automatically")}
      </li>
      <li>
        {Component.text("May re-render child components unnecessarily")}
      </li>
    </ul>
    <p>
      <strong> {Component.text("Xote:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Updates only the specific DOM nodes that depend on changed signals")}
      </li>
      <li>
        {Component.text("No virtual DOM - direct DOM manipulation")}
      </li>
      <li>
        {Component.text("Synchronous updates by default")}
      </li>
      <li>
        {Component.text("Minimal overhead per update")}
      </li>
    </ul>
    <h3> {Component.text("2. Side Effects and Dependencies")} </h3>
    <p>
      <strong> {Component.text("React useEffect:")} </strong>
    </p>
    <pre>
      <code class="language-javascript">
        {Component.text(`// React - Manual dependency array
useEffect(() => {
  console.log("Count changed:", count);
}, [count]); // Must manually specify dependencies`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote Effect:")} </strong>
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`// Xote - Automatic dependency tracking
Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
  None // No dependencies needed - automatically tracked!
})`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Key difference:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("React requires manual dependency arrays - risk of stale closures and bugs")}
      </li>
      <li>
        {Component.text("Xote automatically tracks dependencies during execution - no arrays needed")}
      </li>
    </ul>
    <h3> {Component.text("3. Derived State")} </h3>
    <p>
      <strong> {Component.text("React useMemo:")} </strong>
    </p>
    <pre>
      <code class="language-javascript">
        {Component.text(`// React - Must specify dependencies
const doubled = useMemo(() => count * 2, [count]);`)}
      </code>
    </pre>
    <p>
      <strong> {Component.text("Xote Computed:")} </strong>
    </p>
    <pre>
      <code class="language-rescript">
        {Component.text(`// Xote - Automatic tracking
let doubled = Computed.make(() => Signal.get(count) * 2)`)}
      </code>
    </pre>
    <h3> {Component.text("4. Component Lifecycle")} </h3>
    <p>
      <strong> {Component.text("React:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Components are functions that re-execute on every render")}
      </li>
      <li>
        {Component.text("Hooks must follow rules of hooks (order matters)")}
      </li>
      <li>
        {Component.text("useEffect cleanup functions for teardown")}
      </li>
    </ul>
    <p>
      <strong> {Component.text("Xote:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Components are functions that execute once")}
      </li>
      <li>
        {Component.text("Signals/effects created inside persist")}
      </li>
      <li>
        {Component.text("Effect cleanup via Some(cleanupFn) return values")}
      </li>
    </ul>
    <h2> {Component.text("Code Comparison: Todo List")} </h2>
    <h3> {Component.text("React Version")} </h3>
    <pre>
      <code class="language-javascript">
        {Component.text(`function TodoList() {
  const [todos, setTodos] = useState([]);
  const [input, setInput] = useState("");

  const addTodo = () => {
    setTodos([...todos, input]);
    setInput("");
  };

  return (
    <div>
      <input
        value={input}
        onChange={(e) => setInput(e.target.value)}
      />
      <button onClick={addTodo}>Add</button>
      <ul>
        {todos.map((todo, i) => (
          <li key={i}>{todo}</li>
        ))}
      </ul>
    </div>
  );
}`)}
      </code>
    </pre>
    <h3> {Component.text("Xote Version")} </h3>
    <pre>
      <code class="language-rescript">
        {Component.text(`let todoList = () => {
  let todos = Signal.make([])
  let input = Signal.make("")

  let addTodo = _ => {
    Signal.update(todos, arr => Array.concat(arr, [Signal.peek(input)]))
    Signal.set(input, "")
  }

  <div>
    <input
      value={Signal.peek(input)}
      onInput={evt => {
        let value = %raw(\`evt.target.value\`)
        Signal.set(input, value)
      }}
    />
    <button onClick={addTodo}>
      {Component.text("Add")}
    </button>
    <ul>
      {Component.list(todos, todo =>
        <li> {Component.text(todo)} </li>
      )}
    </ul>
  </div>
}`)}
      </code>
    </pre>
    <h2> {Component.text("When to Choose React")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Large ecosystem needed:")} </strong>
      {Component.text(" Need access to thousands of React libraries, UI components, and tools")}
      </li>
      <li>
        <strong> {Component.text("Team experience:")} </strong>
      {Component.text(" Team is already proficient in React and JavaScript/TypeScript")}
      </li>
      <li>
        <strong> {Component.text("Server-side rendering:")} </strong>
      {Component.text(" Need Next.js or other mature SSR solutions")}
      </li>
      <li>
        <strong> {Component.text("Mobile apps:")} </strong>
      {Component.text(" Want to use React Native for cross-platform development")}
      </li>
      <li>
        <strong> {Component.text("Hiring:")} </strong>
      {Component.text(" Easier to find React developers in the job market")}
      </li>
    </ul>
    <h2> {Component.text("When to Choose Xote")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Fine-grained reactivity:")} </strong>
      {Component.text(" Need precise, efficient updates without virtual DOM overhead")}
      </li>
      <li>
        <strong> {Component.text("Type safety:")} </strong>
      {Component.text(" Want ReScript's powerful type system and compiler guarantees")}
      </li>
      <li>
        <strong> {Component.text("Small bundle size:")} </strong>
      {Component.text(" Every kilobyte counts for your use case")}
      </li>
      <li>
        <strong> {Component.text("Learning signals:")} </strong>
      {Component.text(" Want to explore signal-based reactivity aligned with TC39 proposal")}
      </li>
      <li>
        <strong> {Component.text("Functional programming:")} </strong>
      {Component.text(" Prefer ReScript's functional approach over JavaScript")}
      </li>
      <li>
        <strong> {Component.text("Minimal dependencies:")} </strong>
      {Component.text(" Want a focused library without a large ecosystem dependency")}
      </li>
    </ul>
    <h2> {Component.text("Performance Comparison")} </h2>
    <h3> {Component.text("React")} </h3>
    <p>
      <strong> {Component.text("Pros:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Highly optimized virtual DOM diffing")}
      </li>
      <li>
        {Component.text("Automatic batching of updates in React 18+")}
      </li>
      <li>
        {Component.text("Concurrent rendering features")}
      </li>
      <li>
        {Component.text("Memo and useMemo for optimization")}
      </li>
    </ul>
    <p>
      <strong> {Component.text("Cons:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Virtual DOM overhead for all updates")}
      </li>
      <li>
        {Component.text("Re-renders can cascade through component tree")}
      </li>
      <li>
        {Component.text("Requires manual optimization (React.memo, useMemo)")}
      </li>
      <li>
        {Component.text("Larger bundle size")}
      </li>
    </ul>
    <h3> {Component.text("Xote")} </h3>
    <p>
      <strong> {Component.text("Pros:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("Direct DOM updates - no virtual DOM overhead")}
      </li>
      <li>
        {Component.text("Fine-grained reactivity - only affected nodes update")}
      </li>
      <li>
        {Component.text("No unnecessary component re-renders")}
      </li>
      <li>
        {Component.text("Smaller bundle size (~5x smaller)")}
      </li>
    </ul>
    <p>
      <strong> {Component.text("Cons:")} </strong>
    </p>
    <ul>
      <li>
        {Component.text("List updates replace all children (no diffing/reconciliation)")}
      </li>
      <li>
        {Component.text("Less battle-tested than React")}
      </li>
      <li>
        {Component.text("Smaller community and fewer optimization resources")}
      </li>
    </ul>
    <h2> {Component.text("Migration Considerations")} </h2>
    <h3> {Component.text("From React to Xote")} </h3>
    <p>
      {Component.text("Key concepts that map over:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("useState")} </code>
      {Component.text(" → ")}
      <code> {Component.text("Signal.make")} </code>
      </li>
      <li>
        <code> {Component.text("useMemo")} </code>
      {Component.text(" → ")}
      <code> {Component.text("Computed.make")} </code>
      </li>
      <li>
        <code> {Component.text("useEffect")} </code>
      {Component.text(" → ")}
      <code> {Component.text("Effect.run")} </code>
      </li>
      <li>
        <code> {Component.text("JSX")} </code>
      {Component.text(" → ")}
      <code> {Component.text("Xote JSX (similar syntax)")} </code>
      </li>
    </ul>
    <p>
      {Component.text("Challenges:")}
    </p>
    <ul>
      <li>
        {Component.text("Learning ReScript syntax and type system")}
      </li>
      <li>
        {Component.text("Different mental model (signals vs. re-renders)")}
      </li>
      <li>
        {Component.text("No direct equivalent for many React libraries")}
      </li>
      <li>
        {Component.text("Need to rethink component composition patterns")}
      </li>
    </ul>
    <h2> {Component.text("Conclusion")} </h2>
    <p>
      {Component.text("React and Xote take fundamentally different approaches to reactivity. React's virtual DOM and re-rendering model is mature, well-understood, and backed by a massive ecosystem. Xote's signal-based fine-grained reactivity offers performance benefits and a simpler mental model, but with a smaller ecosystem.")}
    </p>
    <p>
      {Component.text("Choose React if you need the ecosystem, tooling, and community. Choose Xote if you value type safety, minimal bundle size, and want to explore signal-based reactivity with ReScript.")}
    </p>
    <h2> {Component.text("Further Reading")} </h2>
    <ul>
      <li>
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Xote Signals Guide")], ())}
      </li>
      <li>
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Xote Components")], ())}
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
