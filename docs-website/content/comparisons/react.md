## At a Glance

### Overview

| Aspect | React | Xote |
| --- | --- | --- |
| **Update model** | Re-render component trees, then diff | Update the specific reactive consumers directly |
| **State** | `useState`, `useReducer`, external stores | `Signal`, `Computed`, `Effect` |
| **Effects** | `useEffect` with explicit dependency arrays | `Effect.run` with tracked dependencies |
| **Routing** | Third-party packages | Built in |
| **SSR** | Mature ecosystem and frameworks | Built-in primitives for SSR, hydration, and state transfer |
| **Language** | JavaScript / TypeScript | ReScript |

React and Xote solve many of the same problems, but they optimize for different tradeoffs. React optimizes for ecosystem reach and framework maturity. Xote optimizes for a smaller runtime, explicit fine-grained reactivity, and a tighter built-in surface.

## Runtime Model

### Reactivity Model

React updates by re-running component functions and diffing the next virtual tree against the previous one. That model is flexible and well understood, but it means the render pass is the default unit of work.

Xote updates at the signal consumer level. When a signal changes, only the effects, computeds, or reactive DOM bindings that read that signal need to run again. The component function itself usually does not.

```jsx
import { useState } from "react";

function Counter() {
  const [count, setCount] = useState(0);

  return (
    <div>
      <h1>Count: {count}</h1>
      <button onClick={() => setCount(c => c + 1)}>Increment</button>
    </div>
  );
}
```

```rescript
open Xote

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
}
```

### Effects and Derived State

React's `useEffect` and `useMemo` depend on manually maintained dependency arrays. That is workable, but stale or over-broad dependency lists are a common source of bugs and noise.

Xote tracks dependencies automatically. `Effect.run` subscribes to the signals it reads, and `Computed.make` derives values from the signals it reads.

```jsx
useEffect(() => {
  document.title = `Count: ${count}`;
}, [count]);
```

```rescript
Effect.run(() => {
  document.title = "Count: " ++ Int.toString(Signal.get(count))
  None
})

let doubled = Computed.make(() => Signal.get(count) * 2)
```

The tradeoff is that React's hook model is familiar to more teams and supported by more tooling, while Xote's model is smaller and more explicit once you adopt signals.

### Component Lifecycle

React components re-run whenever their state or props change. That is why hooks exist: they preserve values across renders and enforce ordering rules.

Xote components usually run once. Signals, computeds, and effects are ordinary values created during that initial execution. Cleanup is handled by effect cleanups and the owner system that disposes reactive resources when DOM nodes are removed.

### List Rendering

React uses keys during virtual DOM reconciliation. Xote uses `Node.keyedList`, which works directly against DOM anchors and explicit keys.

```jsx
function TodoList({ todos }) {
  return (
    <ul>
      {todos.map(todo => (
        <li key={todo.id}>{todo.text}</li>
      ))}
    </ul>
  );
}
```

```rescript
let todoList = () => {
  let todos = Signal.make([{id: "1", text: "Buy milk"}])

  <ul>
    {Node.keyedList(
      todos,
      todo => todo.id,
      todo => <li> {Node.text(todo.text)} </li>,
    )}
  </ul>
}
```

In practice, both can preserve item identity. The difference is mostly where the work happens: inside a general-purpose renderer in React, or through a dedicated keyed-list primitive in Xote.

## Platform Surface

### Server-Side Rendering

React has the stronger SSR ecosystem. Frameworks like Next.js and Remix add routing, data loading, streaming, server actions, and deployment integrations on top of the core renderer.

Xote gives you lower-level primitives directly: `SSR.renderToString`, `SSR.renderDocument`, `SSRState`, and `Hydration`. That is enough for custom SSR pipelines, but it is intentionally not a batteries-included application framework.

```rescript
let html = SSR.renderDocument(
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app,
)

Hydration.hydrateById(app, "root")
```

### Routing

React relies on external routers such as React Router or TanStack Router. That is not a weakness by itself, but it does mean routing decisions also become ecosystem decisions.

Xote includes a router in the main library. If you want pattern matching, links, imperative navigation, and SSR-aware initialization without another dependency, that is a meaningful simplification.

### Runtime Footprint

React's runtime is larger because it carries a general rendering engine and is often paired with more packages. Xote stays smaller because the reactive graph and direct DOM updates remove the need for a general virtual DOM reconciliation path during normal updates.

Bundle size should not be the only decision criterion, but it matters for widgets, embedded apps, and performance-sensitive pages.

### Type Safety

React with TypeScript gives strong ergonomics and wide adoption, but the type system is still optional and structurally typed.

Xote inherits ReScript's sounder model. Pattern matching, `option`, and exhaustiveness checks reduce a class of runtime mistakes that TypeScript projects still need discipline to avoid.

### Ecosystem

React is the safer choice if your project depends on third-party UI kits, data tooling, or hiring from a very large pool.

Xote is the better fit when you want to own the stack, keep runtime dependencies minimal, and work from a smaller but more integrated API.

## Choosing Between Them

### When to Choose React

- Reach for React when ecosystem depth is a hard requirement.
- Reach for React when the team is already fluent in React and TypeScript.
- Reach for React when third-party UI kits or integrations are central to the product.
- Reach for React when React Native is part of the broader platform story.

### When to Choose Xote

- Reach for Xote when you want fine-grained updates without a virtual DOM render cycle.
- Reach for Xote when built-in routing and SSR primitives reduce project overhead.
- Reach for Xote when ReScript's type model is part of the value proposition.
- Reach for Xote when the UI is focused enough that a smaller ecosystem is a benefit, not a cost.

### Migration Considerations

React developers usually adapt to Xote fastest when they stop looking for hook equivalents and instead map responsibilities directly:

1. `useState` becomes `Signal.make`
2. `useMemo` becomes `Computed.make`
3. `useEffect` becomes `Effect.run`
4. keyed `.map()` rendering becomes `Node.keyedList` when identity matters

The conceptual shift is from re-rendered components to persistent reactive values.

### Further Reading

- [Signals](/docs/core-concepts/signals)
- [Computeds](/docs/core-concepts/computed)
- [Effects](/docs/core-concepts/effects)
- [Components](/docs/components/overview)
