<p>
  <a href="https://xote.dev/">
    <picture>
      <source media="(prefers-color-scheme: dark)" srcset="docs/banner.svg">
      <source media="(prefers-color-scheme: light)" srcset="docs/banner-light.svg">
      <img src="docs/banner.svg" alt="xote - Fine-grained reactivity for ReScript" width="400" />
    </picture>
  </a>
</p>

<p>
  <a href="https://www.npmjs.com/package/xote"><img src="https://img.shields.io/npm/v/xote" alt="NPM Version" /></a>
  <a href="https://bundlephobia.com/package/xote"><img src="https://badgen.net/bundlephobia/min/xote" alt="Bundle size" /></a>
  <a href="https://bundlephobia.com/package/xote"><img src="https://badgen.net/bundlephobia/minzip/xote" alt="Bundle size (gzip)" /></a>
</p>

xote is a lightweight [ReScript](https://rescript-lang.org/) library that combines fine-grained reactivity and a declarative component system for building user interfaces for the web.

## Getting Started

### Installation

```bash
npm install xote
```

Then, add it to your ReScript project's `rescript.json`. You'll need to declare `xote` as a dependency and configure JSX to use Xote's transform:

```json
{
  "dependencies": ["xote"],
  "jsx": {
    "version": 4,
    "module": "XoteJSX"
  },
  "compiler-flags": ["-open Xote"]
}
```

The compiler flag `-open Xote` is optional, it makes the Xote modules available unqualified inside your source files.

This README uses the application-facing names for public code:

- `View` is the module for building and mounting DOM nodes.
- `Prop` is the static-or-reactive prop module.
- `View.Text`, `View.Int`, `View.For`, `View.Show`, `View.Attr.*`, `Router.location`, and `SSRState.signal` are the building blocks used throughout these examples.

### Quick Example

```rescript
module App = {
  @jsx.component
  let make = () => {
    // Create reactive state
    let count = Signal.make(0)

    // Create a derived state
    let doubled = Computed.make(() => Signal.get(count) * 2)

    // Logs every time count changes:
    Effect.run(() => {
      Console.log2("Count is ", Signal.get(count))
      
      None // Optional clean up function
    })

    // Build the UI with JSX
    <div>
      <h1> <View.Text> "Counter" </View.Text> </h1>
      <p>
        <View.Text> "Count: " </View.Text>
        <View.Int> {count} </View.Int>
      </p>
      <p>
        <View.Text> "Doubled: " </View.Text>
        <View.Int> {doubled} </View.Int>
      </p>
      <button onClick={(_evt: Dom.event) => Signal.update(count, n => n + 1)}>
        <View.Text> "Increment" </View.Text>
      </button>
    </div>
  }
}

// Mount to the DOM
View.mountById(<App />, "app")
```

Since in ReScript each file is its own module, you can define a reusable component by exporting a `make` function from that file. The file name becomes the component name: `Counter.res` gives you `<Counter />`. 

The `@jsx.component` attribute instructs the compiler to derive a props type from the function's labeled arguments, enabling JSX usage without boilerplate. 

Here's an example of a reusable component with properties:

```res
// Greeting.res
@jsx.component
let make = (~name: string, ~greeting: string="Hello") => {
  <p>
    <View.Text> {`${greeting}, ${name}!`} </View.Text>
  </p>
}

// Usage from another file:
<Greeting name="World" /> // <p>Hello, World!</p>
<Greeting name="Universe" greeting="Hey" /> // <p>Hey, Universe!</p>
```

## Core Concepts

Xote focuses on clarity, control, and performance. The goal is to offer precise, fine-grained updates and predictable behavior with a minimal set of abstractions, while leveraging the robust type system from ReScript. 

### Reactive Primitives

Xote uses **[rescript-signals](https://github.com/brnrdog/rescript-signals)** for its reactive primitives:

- **Signal**: Reactive state container - `Signal.make(value)`
- **Computed**: Derived reactive value that updates automatically - `Computed.make(() => ...)`
- **Effect**: Side-effect functions that re-run when dependencies change - `Effect.run(() => ...)`

All reactive primitives feature automatic dependency tracking. No manual subscriptions needed.

### View System

On top of the reactive primitives with signals, Xote provides a declarative view system:

- **JSX Support**: Build user interface using JSX in a declarative and familiar manner
- **Reactive DOM Nodes**: Fine-grained reactivity that updates DOM nodes directly, no virtual DOM required
- **Built-in Router**: Client-side routing with pattern matching and a reactive location state
- **Automatic Cleanup**: Effect disposal and memory management built into the component lifecycle
- **Server-side Rendering**: pre-render your pages on the server with full hydration (experimental)

### Views and Attributes

`View` creates UI nodes. It is the official application-facing module for DOM rendering:

```rescript
let className = Signal.make("card")

<div class={Prop.signal(className)}>
  <View.Text> "Status: " </View.Text>
  <View.Text> {className} </View.Text>
</div>
```

For rendering collections in JSX, prefer `View.For`. Add `by` when items have stable identity and should reconcile by key:

```rescript
type todo = {id: string, title: string}

let todos = Signal.make([
  {id: "1", title: "Write docs"},
  {id: "2", title: "Ship release"},
])

<View.For
  each={Prop.signal(todos)}
  by={todo => todo.id}
  render={todo => <li> <View.Text> {todo.title} </View.Text> </li>}
/>
```

`View` also provides component primitives for static or reactive values. Their children can be raw values, signals, `Prop.t` values, or functions.

```rescript
<View.For
  each={Prop.static(["Draft", "Review", "Ship"])}
  render={label => <span> <View.Text> {label} </View.Text> </span>}
/>

<ul>
  <View.For
    each={Prop.signal(todos)}
    by={todo => todo.id}
    render={todo => <li> <View.Text> {todo.title} </View.Text> </li>}
  />
</ul>

<View.Show when_={Prop.signal(isReady)} fallback={<p> <View.Text> "Loading" </View.Text> </p>}>
  <p> <View.Text> "Ready" </View.Text> </p>
</View.Show>

<View.Maybe
  value={Prop.signal(selectedTodo)}
  fallback={<p> <View.Text> "No selection" </View.Text> </p>}
  render={todo => <p> <View.Text> {todo.title} </View.Text> </p>}
/>

<View.Value
  value={Prop.signal(count)}
  render={count =>
    <p>
      <View.Text> "Count: " </View.Text>
      <View.Int> {count} </View.Int>
    </p>
  }
/>

<p>
  <View.Text> "Count: " </View.Text>
  <View.Int> {count} </View.Int>
  <View.Text> ", ready: " </View.Text>
  <View.Bool> {isReady} </View.Bool>
</p>
```

### Auto-tracked Blocks

When a block of UI depends on several signals at once, `View.tracked` lets you read them inline — every signal read while the body runs subscribes the block automatically, and the block re-renders when any of them changes:

```rescript
let loggedIn = Signal.make(false)
let name = Signal.make("Ada")

{View.tracked(() =>
  if Signal.get(loggedIn) {
    <p> <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text> </p>
  } else {
    <p> <View.Text> "Please log in" </View.Text> </p>
  }
)}
```

Dependencies are re-discovered on every run, so conditional reads work: above, `name` is only tracked while `loggedIn` is true. The tradeoff is granularity — a tracked block replaces its children wholesale (no diffing) when a dependency changes, so keep tracked blocks small and prefer `View.For` with `by` for lists.

### Static or Reactive Props

Use `Prop` when a component prop can accept either a static value or a signal:

```rescript
@jsx.component
let make = (~className: Prop.t<string>=Prop.static("badge"), ~children) => {
  <span class={className}> {children} </span>
}

let tone = Signal.make("badge badge-info")

<Badge className={Prop.signal(tone)}>
  <View.Text> "Live" </View.Text>
</Badge>
```

`Prop` is the module for static-or-reactive props.

### Router and SSR State

Initialize the router once at your app entry, then describe your screens with
the `Router.routes` component. Each route matches a pattern and receives the
parsed params:

```rescript
Router.init(())

let app = () =>
  Router.routes([
    {pattern: "/", render: _ => <Home />},
    {pattern: "/about", render: _ => <About />},
    {
      pattern: "/users/:id",
      render: params =>
        <UserPage id={params->Dict.get("id")->Option.getOr("")} />,
    },
  ])
```

Use the `Router.Link` component for client-side navigation without a full page
reload:

```rescript
<nav>
  <Router.Link to="/"> <View.Text> "Home" </View.Text> </Router.Link>
  <Router.Link to="/about" class="nav-link"> <View.Text> "About" </View.Text> </Router.Link>
</nav>
```

For server/client state transfer, prefer `SSRState.signal` when creating a synced signal:

```rescript
let count = SSRState.signal("count", 0, SSRState.Codec.int)
```

### JavaScript Interop

Xote is built for ReScript first, but the compiled package can also be used from JavaScript. Import the focused client entry and build nodes with `View` or `Html` helpers:

```js
import { Signal, Computed, Effect, View } from "xote/client";

const count = Signal.make(0);
const doubled = Computed.make(() => Signal.get(count) * 2);

Effect.run(() => {
  console.log("Count:", Signal.get(count));
});

const app = View.element("div", [], [], [
  View.element("h1", [], [], [View.text("Counter")]),
  View.element("p", [], [], [
    View.text("Count: "),
    View.signalText(() => String(Signal.get(count))),
  ]),
  View.element("p", [], [], [
    View.text("Doubled: "),
    View.signalText(() => String(Signal.get(doubled))),
  ]),
  View.element(
    "button",
    [],
    [["click", () => Signal.update(count, n => n + 1)]],
    [View.text("Increment")],
  ),
]);

View.mountById(app, "app");
```

Use `xote/client` for browser UI, `xote/router` for routing, `xote/ssr` for server rendering, `xote/hydration` for hydrating server-rendered pages, and `xote/mdx` for MDX integration.

Check the [website](https://brnrdog.github.io/xote/) for more comprehensive documentations about Xote and Signals.

## Releasing

Releases are automated with semantic-release and published to npm. See [docs/RELEASING.md](docs/RELEASING.md) for the stable and beta channels and the release flow.

## License

LGPL v3 
