# Comparing Xote with React

This guide provides a detailed comparison between Xote and React, covering their fundamental approaches to building web applications, their feature sets, and when each is the better choice.

## Overview

| Aspect | React | Xote |
| --- | --- | --- |
| **Reactivity** | Virtual DOM diffing and reconciliation | Fine-grained reactivity with signals |
| **Updates** | Re-renders component trees on state change | Direct DOM updates at the signal level |
| **State** | useState, useReducer hooks | Signal primitives (Signal, Computed, Effect) |
| **Side Effects** | useEffect with manual dependency arrays | Effect.run with automatic dependency tracking |
| **SSR** | Built-in (renderToString, Server Components) | Built-in (renderToString, hydration, state transfer) |
| **Routing** | Third-party (React Router, TanStack Router) | Built-in signal-based router |
| **List Rendering** | Key-based reconciliation via VDOM diffing | KeyedList with 3-phase DOM reconciliation |
| **Language** | JavaScript / TypeScript | ReScript (compiles to JavaScript) |
| **Bundle Size** | ~44KB min (react + react-dom) | ~6KB min (xote + rescript-signals) |

## Reactivity Model

**React** re-renders entire component subtrees when state changes. Every `useState` setter triggers a re-render of the component and all its children. React then diffs the new virtual DOM against the previous one to determine the minimal DOM operations. This works well but means components can re-execute their entire body unnecessarily. Optimizations like `React.memo`, `useMemo`, and `useCallback` exist to mitigate this, but they add complexity and are easy to get wrong.

**Xote** uses fine-grained reactivity based on signals. When a signal changes, only the specific DOM nodes or effects that read that signal are updated. There is no virtual DOM and no diffing. Components execute once to set up their reactive graph, and from that point, updates flow directly to the DOM. This means there is no need for memoization APIs -- updates are surgical by default.

### Counter Example

**React:**

```jsx
import { useState } from 'react';

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
}
```

**Xote:**

```rescript
open Xote

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
}
```

## Side Effects and Dependencies

One of the most common sources of bugs in React is the `useEffect` dependency array. Forgetting a dependency leads to stale closures; including too many causes infinite loops. Lint rules help, but they cannot catch all cases.

Xote effects track dependencies automatically. Any signal read during effect execution becomes a dependency. When dependencies change, the effect re-runs. There is no array to maintain.

**React:**

```jsx
// Must manually list every dependency
useEffect(() => {
  document.title = `Count: ${count}`;
}, [count]); // Forget count here and the title never updates
```

**Xote:**

```rescript
// Dependencies tracked automatically
Effect.run(() => {
  document.title = "Count: " ++ Int.toString(Signal.get(count))
  None
})
```

**Derived state** follows the same pattern. React's `useMemo` requires a dependency array. Xote's `Computed.make` tracks dependencies automatically and is lazy -- it only recomputes when read.

```rescript
// Recomputes only when count changes, and only when someone reads it
let doubled = Computed.make(() => Signal.get(count) * 2)
```

## Component Lifecycle

In React, components are functions that re-execute on every render. Hooks must follow strict ordering rules, and cleanup requires returning a function from `useEffect`.

In Xote, component functions execute once. Signals, effects, and computed values are created during that single execution. Cleanup is handled by the **owner system** -- each DOM element tracks its reactive resources, and when the element is removed from the DOM, all associated effects and computeds are disposed automatically.

**React:**

- Component functions re-execute on every render
- Hooks must follow the rules of hooks (no conditionals, fixed order)
- Cleanup via useEffect return functions
- Must use useRef to persist values across renders

**Xote:**

- Component functions execute once
- No hook rules -- signals and effects can be created anywhere
- Cleanup via Effect return values and automatic owner-based disposal
- All values naturally persist (they are just local variables)

## List Rendering

**React** uses key-based reconciliation during its virtual DOM diff. When a list changes, React matches elements by key and determines insertions, deletions, and moves. This works well but happens as part of the full VDOM reconciliation pass.

**Xote** provides `keyedList` with a dedicated 3-phase reconciliation algorithm that operates directly on the DOM:

1. **Remove** items no longer in the list
2. **Build new order** reusing existing DOM elements for unchanged keys
3. **Reconcile DOM** by inserting, moving, and replacing elements

This preserves DOM element identity across updates -- an important property for elements with focus state, animations, or internal state.

**React:**

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

**Xote:**

```rescript
let todoList = () => {
  let todos = Signal.make([{id: "1", text: "Buy milk"}])

  <ul>
    {Component.keyedList(
      todos,
      todo => todo.id,
      todo => <li> {Component.text(todo.text)} </li>
    )}
  </ul>
}
```

## Server-Side Rendering

**React** has mature SSR support through `renderToString`, streaming with `renderToPipeableStream`, and the newer Server Components architecture (via frameworks like Next.js). React's SSR ecosystem is extensive and battle-tested.

**Xote** provides built-in SSR with a focused feature set:

- **`SSR.renderToString`** renders components to HTML strings
- **`SSR.renderDocument`** generates full HTML documents with head, scripts, and styles
- **Hydration markers** (HTML comments) mark reactive boundaries so the client can attach reactivity without re-rendering
- **`SSRState`** handles state transfer between server and client with a type-safe codec system
- **`Hydration.hydrate`** walks server-rendered DOM and attaches signals, effects, and event listeners

```rescript
// Server
let html = SSR.renderDocument(
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app
)

// Client
Hydration.hydrateById(app, "root")
```

React's SSR ecosystem is more mature and offers features like streaming and Server Components. Xote's SSR is simpler and more lightweight, handling the core use case of server rendering with client hydration and state transfer without requiring a framework.

## Routing

**React** does not include a router. You need a third-party library like React Router or TanStack Router. These are excellent but add to your dependency count and bundle size.

**Xote** includes a signal-based router out of the box:

- Pattern matching with dynamic segments (`/users/:id`)
- Imperative navigation (`Router.push`, `Router.replace`)
- A `Router.Link` JSX component for declarative navigation
- Base path support for sub-app routing
- Scroll position restoration on back/forward navigation
- SSR-compatible initialization (`Router.initSSR`)
- Global singleton state via `Symbol.for()` so multiple bundles share the same router

```rescript
Router.init()

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
}
```

Having routing built in means one less dependency to manage, and the router integrates naturally with the signal system -- route changes trigger reactive updates like any other signal change.

## Bundle Size and Runtime Footprint

This is one of the most significant practical differences. React's runtime (react + react-dom) is approximately **44KB minified** (about 14KB gzipped). Add a router and you are looking at another 10-20KB.

Xote's entire runtime including the signals library is approximately **6KB minified**. The built-in router and SSR modules are included in that figure.

This difference comes from two factors:

1. **No virtual DOM**: Xote does not need a diffing/reconciliation engine for general updates. The signal graph handles targeted updates directly.
2. **ReScript's zero-cost JSX**: ReScript's JSX compiles to direct function calls with no runtime JSX transformer. There is no `React.createElement` equivalent that builds intermediate objects. The compiled output is lean JavaScript that directly constructs the component tree.

For applications where initial load time matters -- mobile web, embedded widgets, progressive web apps, or performance-constrained environments -- this difference is substantial.

## Type Safety

**React** with TypeScript provides good type safety, but it is opt-in and structural. Generic component patterns, higher-order components, and complex hooks often require manual type annotations. Runtime type errors are still possible.

**Xote** uses ReScript, which has a sound type system with full type inference. Types are checked at compile time and cover the entire codebase. The compiler guarantees that if your code compiles, types are correct -- there are no runtime type errors from type mismatches. Pattern matching is exhaustive, and the absence of `null`/`undefined` exceptions (replaced by the `option` type) eliminates an entire class of bugs.

## Ecosystem

This is where React has a clear advantage. React has thousands of UI component libraries, state management solutions, form libraries, data fetching tools, animation frameworks, and more. The community is enormous, and finding help, tutorials, and examples is straightforward.

Xote's ecosystem is minimal by design. It provides the core building blocks -- reactivity, components, routing, and SSR -- and leaves the rest to the application. This means less choice paralysis but also fewer off-the-shelf solutions.

## When to Choose React

- **Large ecosystem needed:** Your project relies on third-party React component libraries or integrations
- **Team experience:** Your team is already proficient with React and JavaScript/TypeScript
- **Mobile apps:** You want to use React Native for cross-platform development
- **Hiring:** Finding React developers is easier in the current job market
- **Mature SSR frameworks:** You need Next.js, Remix, or similar full-stack frameworks with advanced features like Server Components and streaming

## When to Choose Xote

- **Performance-sensitive applications:** You need minimal bundle size and fast initial load times
- **Fine-grained reactivity:** You want precise, efficient updates without virtual DOM overhead or memoization boilerplate
- **Full-stack type safety:** You value a sound type system that catches errors at compile time
- **Built-in essentials:** You prefer having routing, SSR, and hydration included without additional dependencies
- **Signal-based architecture:** You want to build with a reactivity model aligned with the TC39 Signals proposal
- **Minimal dependency footprint:** You want a focused library with a single runtime dependency

## Migration Considerations

If you are coming from React, here is how core concepts map:

- `useState` -> `Signal.make`
- `useMemo` -> `Computed.make` (no dependency array needed)
- `useEffect` -> `Effect.run` (no dependency array needed)
- `useRef` -> Just use a `ref()` or a local `let` binding (components execute once)
- `React.memo` -> Not needed (fine-grained updates by default)
- `useCallback` -> Not needed (no re-renders to cause reference changes)
- `JSX` -> ReScript JSX (very similar syntax)
- `React Router` -> `Router` module (built-in)
- `renderToString` -> `SSR.renderToString`

The main learning curve is ReScript itself -- its syntax, type system, and functional programming patterns. The reactivity model is arguably simpler than React's hooks system once you understand signals.

## Further Reading

- [Xote Signals Guide](/docs/core-concepts/signals)
- [Xote Components](/docs/components/overview)
- [Router Overview](/docs/router/overview)
- [Server-Side Rendering](/docs/advanced/ssr)
- [React Documentation](https://react.dev)
- [TC39 Signals Proposal](https://github.com/tc39/proposal-signals)
