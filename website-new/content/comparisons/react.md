# Comparing Xote with React

This guide compares Xote with React to help you understand the differences in philosophy, API design, and when to choose each framework.

## Philosophy

| Aspect | React | Xote |
|--------|-------|------|
| **Reactivity** | Virtual DOM diffing and reconciliation | Fine-grained reactivity with signals |
| **Updates** | Re-render component trees on state change | Direct DOM updates at the signal level |
| **State** | useState, useReducer hooks | Signal primitives (Signal, Computed, Effect) |
| **Side Effects** | useEffect hook with dependency array | Effect.run with automatic dependency tracking |
| **Ecosystem** | Massive: thousands of libraries and tools | Minimal: focused on core reactivity |
| **Bundle Size** | ~45KB (React + ReactDOM minified) | ~8KB (Xote + rescript-signals minified) |

## Code Comparison: Counter Example

### React Version

```javascript
import { useState } from 'react';

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
}
```

### Xote Version

```rescript
open Xote

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
}
```

## Key Differences

### 1. Reactivity Model

**React:**

- Re-renders entire component on state change
- Virtual DOM diffing determines what changed
- Batches updates automatically
- May re-render child components unnecessarily

**Xote:**

- Updates only the specific DOM nodes that depend on changed signals
- No virtual DOM - direct DOM manipulation
- Synchronous updates by default
- Minimal overhead per update

### 2. Side Effects and Dependencies

**React useEffect:**

```javascript
// React - Manual dependency array
useEffect(() => {
  console.log("Count changed:", count);
}, [count]); // Must manually specify dependencies
```

**Xote Effect:**

```rescript
// Xote - Automatic dependency tracking
Effect.run(() => {
  Console.log2("Count changed:", Signal.get(count))
  None // No dependencies needed - automatically tracked!
})
```

**Key difference:**

- React requires manual dependency arrays - risk of stale closures and bugs
- Xote automatically tracks dependencies during execution - no arrays needed

### 3. Derived State

**React useMemo:**

```javascript
// React - Must specify dependencies
const doubled = useMemo(() => count * 2, [count]);
```

**Xote Computed:**

```rescript
// Xote - Automatic tracking
let doubled = Computed.make(() => Signal.get(count) * 2)
```

### 4. Component Lifecycle

**React:**

- Components are functions that re-execute on every render
- Hooks must follow rules of hooks (order matters)
- useEffect cleanup functions for teardown

**Xote:**

- Components are functions that execute once
- Signals/effects created inside persist
- Effect cleanup via Some(cleanupFn) return values

## Code Comparison: Todo List

### React Version

```javascript
function TodoList() {
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
}
```

### Xote Version

```rescript
let todoList = () => {
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
        let value = %raw(`evt.target.value`)
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
}
```

## When to Choose React

- **Large ecosystem needed:** Need access to thousands of React libraries, UI components, and tools
- **Team experience:** Team is already proficient in React and JavaScript/TypeScript
- **Server-side rendering:** Need Next.js or other mature SSR solutions
- **Mobile apps:** Want to use React Native for cross-platform development
- **Hiring:** Easier to find React developers in the job market

## When to Choose Xote

- **Fine-grained reactivity:** Need precise, efficient updates without virtual DOM overhead
- **Type safety:** Want ReScript's powerful type system and compiler guarantees
- **Small bundle size:** Every kilobyte counts for your use case
- **Learning signals:** Want to explore signal-based reactivity aligned with TC39 proposal
- **Functional programming:** Prefer ReScript's functional approach over JavaScript
- **Minimal dependencies:** Want a focused library without a large ecosystem dependency

## Performance Comparison

### React

**Pros:**

- Highly optimized virtual DOM diffing
- Automatic batching of updates in React 18+
- Concurrent rendering features
- Memo and useMemo for optimization

**Cons:**

- Virtual DOM overhead for all updates
- Re-renders can cascade through component tree
- Requires manual optimization (React.memo, useMemo)
- Larger bundle size

### Xote

**Pros:**

- Direct DOM updates - no virtual DOM overhead
- Fine-grained reactivity - only affected nodes update
- No unnecessary component re-renders
- Smaller bundle size (~5x smaller)

**Cons:**

- List updates replace all children (no diffing/reconciliation)
- Less battle-tested than React
- Smaller community and fewer optimization resources

## Migration Considerations

### From React to Xote

Key concepts that map over:

- `useState` → `Signal.make`
- `useMemo` → `Computed.make`
- `useEffect` → `Effect.run`
- `JSX` → `Xote JSX (similar syntax)`

Challenges:

- Learning ReScript syntax and type system
- Different mental model (signals vs. re-renders)
- No direct equivalent for many React libraries
- Need to rethink component composition patterns

## Conclusion

React and Xote take fundamentally different approaches to reactivity. React's virtual DOM and re-rendering model is mature, well-understood, and backed by a massive ecosystem. Xote's signal-based fine-grained reactivity offers performance benefits and a simpler mental model, but with a smaller ecosystem.

Choose React if you need the ecosystem, tooling, and community. Choose Xote if you value type safety, minimal bundle size, and want to explore signal-based reactivity with ReScript.

## Further Reading

- [Xote Signals Guide](/docs/core-concepts/signals)
- [Xote Components](/docs/components/overview)
- [React Documentation](https://react.dev)
- [TC39 Signals Proposal](https://github.com/tc39/proposal-signals)
