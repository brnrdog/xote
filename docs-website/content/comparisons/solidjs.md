# Comparing Xote with SolidJS

This guide compares Xote and SolidJS -- two frameworks that share a signal-based reactivity model but differ in language, ecosystem, and scope.

## Overview

| Aspect | SolidJS | Xote |
| --- | --- | --- |
| **Reactivity** | Fine-grained signals (createSignal, createEffect) | Fine-grained signals (Signal.make, Effect.run) |
| **Updates** | Direct DOM updates, no virtual DOM | Direct DOM updates, no virtual DOM |
| **Components** | Functions that run once, JSX compiles away | Functions that run once, JSX compiles away |
| **Language** | JavaScript / TypeScript | ReScript (compiles to JavaScript) |
| **SSR** | SolidStart framework | Built-in (renderToString, hydration, state transfer) |
| **Routing** | Separate package (@solidjs/router) | Built-in signal-based router |
| **List Rendering** | `<For>` / `<Index>` components | keyedList with 3-phase DOM reconciliation |
| **Ecosystem** | Growing: UI libraries, SolidStart, community packages | Minimal: focused core with built-in essentials |
| **Bundle Size** | ~7KB min (solid-js) | ~6KB min (xote + rescript-signals) |

## Shared Philosophy

Xote and SolidJS are closer to each other than either is to React. Both frameworks:

- Use **fine-grained reactivity** with signals as the core primitive
- Execute component functions **once** (not on every update)
- Update the DOM **directly** without a virtual DOM diffing step
- Compile JSX away at build time into efficient DOM operations
- Track dependencies **automatically** (no dependency arrays)
- Achieve **small bundle sizes** by avoiding a reconciliation runtime

If you are familiar with SolidJS, many Xote concepts will feel natural. The differences lie in language choice, API surface, and what is included out of the box.

## Signals and State

Both frameworks use signals as their core reactive primitive. The APIs are similar but not identical.

**SolidJS:**

```jsx
import { createSignal, createEffect, createMemo } from "solid-js";

const [count, setCount] = createSignal(0);
const doubled = createMemo(() => count() * 2);

createEffect(() => {
  console.log("Count:", count());
});
```

**Xote:**

```rescript
open Xote

let count = Signal.make(0)
let doubled = Computed.make(() => Signal.get(count) * 2)

Effect.run(() => {
  Console.log2("Count:", Signal.get(count))
  None
})
```

Key differences:

- SolidJS uses a **getter/setter tuple** (`count()` to read, `setCount()` to write). Xote uses **explicit functions** (`Signal.get(count)` to read, `Signal.set(count, value)` to write).
- SolidJS effects do not return cleanup. Cleanup is handled via `onCleanup`. Xote effects return `Some(cleanupFn)` or `None`, and use `Effect.run` (returns unit) or `Effect.runWithDisposer` (returns a disposer for manual cleanup).
- Xote signals use **structural equality** by default -- setting a signal to a structurally equal value does not trigger updates. SolidJS uses referential equality by default but supports custom comparators via `equals`.

## Component Model

Both frameworks share the same model: components run once. In both, the component function sets up the reactive graph and returns a DOM tree. After that, only the reactive bindings update.

**SolidJS:**

```jsx
function Counter() {
  const [count, setCount] = createSignal(0);

  // Runs once. Only the text node with count() updates.
  return (
    <div>
      <h1>Count: {count()}</h1>
      <button onClick={() => setCount(c => c + 1)}>
        Increment
      </button>
    </div>
  );
}
```

**Xote:**

```rescript
let counter = () => {
  let count = Signal.make(0)

  // Runs once. Only the text node with Signal.get(count) updates.
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

The main difference is that SolidJS embeds reactive expressions directly in JSX (`{count()}`), while Xote uses explicit reactive text nodes (`Component.signalText`). SolidJS's compiler transforms the JSX to wrap signal reads in effects automatically. Xote's approach is more explicit -- you decide which parts are reactive.

## List Rendering

This is an area where the two frameworks take different approaches.

**SolidJS** provides built-in components `<For>` (keyed by item reference) and `<Index>` (keyed by index):

```jsx
import { For } from "solid-js";

function TodoList() {
  const [todos, setTodos] = createSignal([
    { id: "1", text: "Buy milk" }
  ]);

  return (
    <ul>
      <For each={todos()} fallback={<p>No todos</p>}>
        {(todo) => <li>{todo.text}</li>}
      </For>
    </ul>
  );
}
```

**Xote** provides `keyedList` with a dedicated 3-phase reconciliation algorithm:

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

Both approaches preserve DOM element identity across updates. SolidJS's `<For>` derives keys from item references, while Xote's `keyedList` takes an explicit key function. Xote's 3-phase algorithm (remove, build order, reconcile DOM) operates directly on DOM nodes using comment-based anchors.

## Server-Side Rendering

**SolidJS** provides SSR through SolidStart, its meta-framework. SolidStart handles routing, data loading, streaming SSR, and deployment. Lower-level SSR is available via `solid-js/web` (`renderToString`, `renderToStream`), but most users go through SolidStart.

**Xote** provides SSR as a built-in module without requiring a framework:

- `SSR.renderToString` and `SSR.renderDocument` for server rendering
- Comment-based hydration markers for reactive boundaries
- `SSRState` with a type-safe codec system for server-to-client state transfer
- `Hydration.hydrate` to attach reactivity to server-rendered DOM

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

SolidStart is more feature-rich (file-based routing, API routes, streaming, deployment adapters). Xote's SSR is more minimal -- it handles rendering, hydration, and state transfer without prescribing an application framework.

## Routing

**SolidJS** uses `@solidjs/router`, a separate package:

```jsx
import { Router, Route } from "@solidjs/router";

function App() {
  return (
    <Router>
      <Route path="/" component={Home} />
      <Route path="/users/:id" component={UserPage} />
    </Router>
  );
}
```

**Xote** includes a signal-based router:

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

Both routers support dynamic segments, navigation, and links. SolidJS's router is more feature-rich (nested routing, data loading, lazy routes). Xote's router is simpler but integrated -- it uses the same signal system, supports SSR initialization, and uses `Symbol.for()` to share state across bundles.

## Bundle Size and Compilation

Both frameworks produce small bundles compared to virtual DOM frameworks. SolidJS is approximately **7KB minified** (solid-js core). Xote is approximately **6KB minified** (xote + rescript-signals), including its built-in router and SSR modules.

The compilation models differ:

**SolidJS** uses a custom Babel plugin that transforms JSX into fine-grained DOM operations. The compiler detects signal reads in JSX and wraps them in effects automatically. The output is vanilla JavaScript with direct DOM API calls.

**Xote** uses the ReScript compiler, which transforms JSX into direct function calls via its generic JSX v4 transform. ReScript compiles to clean, readable JavaScript with zero runtime overhead from the language itself. There is no JSX runtime, no `createElement` calls -- just direct function invocations that construct the component tree.

The practical result is similar: both produce small, efficient bundles with no framework overhead in the compiled output.

## Type Safety

**SolidJS** with TypeScript provides good type safety with full JSX type checking. TypeScript's structural type system works well with SolidJS's API, and the community maintains solid type definitions. However, TypeScript is opt-in and unsound -- runtime type errors are still possible.

**Xote** uses ReScript, which has a **sound type system** with full type inference. If the code compiles, types are guaranteed correct at runtime. Pattern matching is exhaustive, `null`/`undefined` are replaced by the `option` type, and the compiler catches errors that TypeScript cannot. The tradeoff is that ReScript is a different language from JavaScript, with its own syntax and ecosystem.

## Ecosystem

**SolidJS** has a growing ecosystem with UI component libraries (SUID, Kobalte, Corvu), SolidStart for full-stack applications, and a community of plugins and integrations. It is smaller than React's ecosystem but significantly larger than Xote's.

**Xote** is minimal by design. It provides reactivity, components, routing, SSR, and hydration in a single package with one runtime dependency. There are no third-party component libraries or community packages. This is appropriate for projects that want full control over their stack.

## When to Choose SolidJS

- **JavaScript/TypeScript team:** Your team prefers staying in the JS/TS ecosystem
- **Growing ecosystem:** You want access to UI component libraries and community packages
- **SolidStart:** You need a full-stack framework with file-based routing, data loading, and deployment adapters
- **Familiar syntax:** SolidJS's API is closer to React, easing migration
- **Community support:** Larger community for help, tutorials, and examples

## When to Choose Xote

- **Sound type safety:** You want compile-time guarantees that eliminate runtime type errors
- **Built-in essentials:** You prefer routing, SSR, and hydration included without additional packages
- **Minimal dependencies:** You want a single runtime dependency and full control over your stack
- **ReScript ecosystem:** You are already using or interested in ReScript
- **Explicit reactivity:** You prefer marking reactive boundaries explicitly rather than relying on compiler magic
- **Smallest possible bundle:** Every kilobyte matters and you want routing + SSR included in ~6KB

## Migration Considerations

If you are coming from SolidJS, the mental model transfers well:

- `createSignal` -> `Signal.make` (read with `Signal.get` instead of calling the getter)
- `createMemo` -> `Computed.make`
- `createEffect` -> `Effect.run` (return `Some(cleanupFn)` or `None`; use `Effect.runWithDisposer` if you need the disposer)
- `onCleanup` -> Return `Some(cleanupFn)` from the effect
- `<For>` -> `Component.keyedList`
- `<Show>` -> `Component.signalText` or `SignalFragment` with conditional logic
- `<A>` -> `<Router.Link>`
- `@solidjs/router` -> `Router` module (built-in)
- `renderToString` -> `SSR.renderToString`

The main learning curve is ReScript itself. The reactivity concepts are nearly identical -- both frameworks use signals with automatic dependency tracking and components that execute once.

## Further Reading

- [Xote Signals Guide](/docs/core-concepts/signals)
- [Xote Components](/docs/components/overview)
- [Router Overview](/docs/router/overview)
- [Server-Side Rendering](/docs/advanced/ssr)
- [React Comparison](/docs/comparisons/react)
- [SolidJS Documentation](https://docs.solidjs.com)
- [TC39 Signals Proposal](https://github.com/tc39/proposal-signals)
