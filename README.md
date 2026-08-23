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
  <a href="https://bundlejs.com/?q=xote"><img src="https://img.shields.io/bundlejs/size/xote?label=gzipped" alt="Bundle size (gzip)" /></a>
</p>

Xote is a lightweight [ReScript](https://rescript-lang.org/) library that combines fine-grained reactivity and a declarative component system for building user interfaces for the web.

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
  "ppx-flags": ["xote/ppx/ppx"],
  "compiler-flags": ["-open Xote"]
}
```

The compiler flag `-open Xote` is optional, it makes the Xote modules available unqualified inside your source files.

The `ppx-flags` line enables the `@xote.component` annotation, which is the recommended way to write components in xote, though you can also use `@jsx.component` with explicit  and `<View.Text>`/`<View.Int>` primitives. 

### Quick Example

```rescript
module App = {
  @xote.component
  let make = () => {
    // Create reactive state
    let count = Signal.make(0)

    // Create a derived state
    let doubled = Computed.make(() => Signal.get(count) * 2)

    // Logs every time count changes
    Effect.run(() => {
      Console.log2("Count is ", Signal.get(count))
      
      None // Optional clean up function
    })

    // Build the UI with JSX — signal reads inline, only the leaves re-run
    <div>
      <h1> {"Counter"} </h1>
      <p> {`Count: ${Signal.get(count)}`} </p>
      <p> {`Doubled: ${Signal.get(doubled)}`} </p>
      <button onClick={(_evt: Dom.event) => Signal.update(count, n => n + 1)}>
        {"Increment"}
      </button>
    </div>
  }
}

// Mount to the DOM
View.mountById(<App />, "app")
```

When `count` changes, only the two text leaves that read it update. The elements are built once and keep their DOM identity.

Since in ReScript each file is its own module, you can define a reusable component by exporting a `make` function from that file. The file name becomes the component name: `Counter.res` gives you `<Counter />`.

The `@xote.component` annotation derives a props type from the function's labeled arguments (exactly like ReScript's `@jsx.component`) and fine-grains the returned JSX automatically for you.

Here's an example of a reusable component with properties:

```res
// Greeting.res
@xote.component
let make = (~name: string, ~greeting: string="Hello") => {
  <p> {`${greeting}, ${name}!`} </p>
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

All reactive primitives feature automatic dependency tracking. No manual subscriptions needed. Its API and behavior were designed to be close to the [TC39 proposal](https://github.com/tc39/proposal-signals) for Signals in Standard JavaScript.

### View System

On top of the reactive primitives with signals, Xote provides a declarative view system:

- **JSX Support**: Build user interface using JSX in a declarative and familiar manner
- **MDX Support**: Consume and generate components from MDX files
- **Reactive DOM Nodes**: Fine-grained reactivity that updates DOM nodes directly, no virtual DOM required
- **Built-in Router**: Client-side routing with pattern matching and a reactive location state
- **Automatic Cleanup**: Effect disposal and memory management built into the component lifecycle
- **Server-side Rendering**: pre-render your pages on the server with full hydration (experimental)

### Views and Attributes

`View` creates UI nodes. It is the official application-facing module for DOM rendering:

```rescript
let className = Signal.make("card")

<div class={MaybeSignal.reactive(className)}>
  {"Status: "}
  {Signal.get(className)}
</div>
```

#### Bare children

Under `@xote.component`, any `{…}` child works directly in element position. The annotation wraps it in the runtime helper `View.child`, which coerces it at runtime:

```rescript
<div>
  {"Count: "}            // static text
  {Signal.get(count)}    // reactive text leaf, re-runs on its own
  {View.text("node")}    // already a node, passes through
  {someOption}           // None renders nothing
</div>
```

An eager signal read becomes a reactive leaf; a static scalar becomes static text; a value that is already a node passes through; `null`/`undefined` render nothing; an array is coerced element-wise.

The explicit value primitives are still there for code that does not use the PPX, and when you want the stronger `int`/`float` typing:

```rescript
// equivalent, without the annotation
<div>
  <View.Text> "Count: " </View.Text>
  <View.Int> {count} </View.Int>
</div>
```

Built-in attributes take a plain value, a signal, or a `unit => 'a` function, so
a signal can be passed straight through without wrapping it.

#### Keep signal reads visible

`@xote.component` decides what to make reactive by *reading your source*. It
follows `Signal.get` and `MaybeSignal.get`, aliases (`let g = Signal.get`,
`module S = Signal`, `open Signal`), local helpers that read a signal, and
helpers in a module in the same file. It cannot follow a call into **another
module** — nothing in `Store.waitingCount(store)` says "signal" — so that leaf is
compiled as a plain value and renders its first result forever:

```rescript
<p> {Store.waitingCount(store)} </p>   // ⚠️ one-shot: never updates
<p> {() => Store.waitingCount(store)} </p>   // ✅ reactive
```

The same applies to a read hoisted into a `let` (`let n = Signal.get(count)`,
then `{n}`): reactivity follows the expression written in JSX position. In both
cases the fix is a thunk — `() => …`, and the PPX never double-wraps one you
wrote yourself.

When using `@xote.component`, a runtime check is performed to ensure the component
body does not read a signal through a call the PPX cannot resolve. So you can apply the fix describe above in those cases.

```
[Xote] Queue.res:42:19: this value reads a signal through a call
@xote.component cannot see … Wrap it in a thunk (`{() => ...}`).
```

For more information, read: [`ppx/README.md`](ppx/README.md#hidden-reads).

For rendering collections in JSX, prefer `View.For`. Add `by` when items have stable identity and should reconcile by key:

```rescript
type todo = {id: string, title: string}

let todos = Signal.make([
  {id: "1", title: "Write docs"},
  {id: "2", title: "Ship release"},
])

<View.For
  each={MaybeSignal.reactive(todos)}
  by={todo => todo.id}
  render={todo => <li> {todo.title} </li>}
/>
```

The other view components take static or reactive values through `MaybeSignal.t`, and their render callbacks are fine-grained too:

```rescript
<View.For
  each={MaybeSignal.static(["Draft", "Review", "Ship"])}
  render={label => <span> {label} </span>}
/>

<View.Show when_={MaybeSignal.reactive(isReady)} fallback={<p> {"Loading"} </p>}>
  <p> {"Ready"} </p>
</View.Show>

<View.Maybe
  value={MaybeSignal.reactive(selectedTodo)}
  fallback={<p> {"No selection"} </p>}
  render={todo => <p> {todo.title} </p>}
/>

<View.Value
  value={MaybeSignal.reactive(count)}
  render={count => <p> {"Count: "} {count} </p>}
/>
```

### Auto-tracked Blocks

When a block of UI depends on several signals at once, `View.tracked` lets you read them inline — every signal read while the body runs subscribes the block automatically, and the block re-renders when any of them changes:

```rescript
let loggedIn = Signal.make(false)
let name = Signal.make("Ada")

{View.tracked(() =>
  if Signal.get(loggedIn) {
    <p> {`Hello, ${Signal.get(name)}`} </p>
  } else {
    <p> {"Please log in"} </p>
  }
)}
```

Dependencies are re-discovered on every run, so conditional reads work: above, `name` is only tracked while `loggedIn` is true. The tradeoff is granularity. A tracked block replaces its children wholesale (no diffing) when a dependency changes, so keep tracked blocks small and prefer `View.For` with `by` for lists.

Under `@xote.component` you rarely write `View.tracked` yourself: an `if`/`switch` in child position is wrapped in it automatically, tracking only the condition — reactive leaves inside the branches stay fine-grained:

```rescript
let loggedIn = Signal.make(false)
let name = Signal.make("Ada")

switch(Signal.get(loggedIn)) {
| true => <p> {`Hello, ${Signal.get(name)}`} </p>
| false => <p> {"Please log in"} </p>
}
```

### Static or Reactive Props

`MaybeSignal` is how a value says whether it is plain or reactive. There is one
rule for when you need it:

| Where | What it accepts |
|---|---|
| Built-in HTML/SVG attributes, `View.Text`/`Int`/`Float`/`Bool` | anything — a plain value, a `Signal.t`, a `unit => 'a` function, or a `MaybeSignal.t`. No wrapper needed. |
| Props with a declared type — `View.Show`, `View.For`, `View.Maybe`, `View.Value`, and the components you write | a `MaybeSignal.t`, so the wrapper is how the caller says which one they are passing. |

```rescript
module Button {
  @xote.component
  let make = (~disabled: MaybeSignal.t<bool>=MaybeSignal.static(false), ~children) => {
    <button disabled={disabled}> {children} </button>
  }
}

let disabledState = Signal.make(false);

<Button disabled={MaybeSignal.reactive(disabled)}>
  {Signal.get(disabledState) ? "Disabled" : "Enabled"}
</Button>

<Button disabled={MaybeSignal.static(false)}>
  {"Always disabled"}
</Button>
```

`MaybeSignal.t<'a>` is `Reactive(Signal.t<'a>) | Static('a)`. Build one with
`MaybeSignal.static`, `MaybeSignal.reactive`, or `MaybeSignal.computed(fn)` for a
derived value. Read it with `MaybeSignal.get` (tracked) or `MaybeSignal.peek`
(untracked), and transform it with `MaybeSignal.map`, which preserves staticness.

`MaybeSignal.ofUnknown` is the coercion the JSX runtime applies to untyped props;
reach for it only when adapting untyped input of your own.

> **Deprecated:** the old `Prop` module is a deprecated alias of `MaybeSignal`.
> `Prop.t` is a type alias of `MaybeSignal.t`, so migrating is a rename:
> `Prop.static` → `MaybeSignal.static`, `Prop.signal` and `Prop.reactive` →
> `MaybeSignal.reactive`, `Prop.get` → `MaybeSignal.get`.

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
  <Router.Link to="/"> {"Home"} </Router.Link>
  <Router.Link to="/about" class="nav-link"> {"About"} </Router.Link>
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

## Benchmarks

The [`benchmarks/`](benchmarks) directory runs the same keyed-list table application in Xote, React, Vue, and SolidJS. Identical DOM, identical data, each written the way its own library recommends. Median of 15 iterations, Chromium 141 on a 4-core Xeon; lower is better, fastest in bold. These are ratios from one machine, and re-runs move individual numbers by 10-25%, so only the large gaps mean anything.

| | Xote | React | Vue | Solid |
| --- | ---: | ---: | ---: | ---: |
| **Updating an existing list** | | | | |
| Update every 10th row (ms) | 6.3 | 11.7 | 7.4 | **5.4** |
| Select a row (ms) | 1.0 | 5.8 | 1.9 | **0.8** |
| Swap two rows (ms) | 7.3 | 64.8 | 7.8 | **6.3** |
| **Building and tearing down** | | | | |
| Create 1,000 rows (ms) | 88.7 | 62.1 | 59.2 | **52.5** |
| Create 10,000 rows (ms) | 918.9 | 947.3 | 705.8 | **660.4** |
| Clear 10,000 rows (ms) | 108.9 | 96.4 | 75.3 | **62.0** |
| **Startup, size, memory** | | | | |
| Time to first render (ms) | 24.4 | 41.8 | 28.5 | **22.8** |
| App bundle, gzipped (KB) | 8.4 | 59.9 | 24.9 | **4.7** |
| Heap at 10,000 rows (MB) | 40.5 | 20.2 | 19.0 | **12.3** |

Full results, methodology, and the DOM-operation profile behind these numbers are in [`benchmarks/README.md`](benchmarks/README.md) and [`benchmarks/results/RESULTS.md`](benchmarks/results/RESULTS.md). Per-framework detail lives in the [React](https://xote.dev/docs/comparisons/react) and [SolidJS](https://xote.dev/docs/comparisons/solidjs) comparison pages.

## Releasing

Releases are automated with semantic-release and published to npm. See [docs/RELEASING.md](docs/RELEASING.md) for the stable and beta channels and the release flow.

## License

LGPL v3
