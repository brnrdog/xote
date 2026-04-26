# [xote](https://brnrdog.github.io/xote/)
![NPM Version](https://img.shields.io/npm/v/xote)
![npm bundle size](https://badgen.net/bundlephobia/min/xote)
![npm bundle size](https://badgen.net/bundlephobia/minzip/xote)

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

This README uses the application-facing names introduced for public code:

- `View` is the official module for building and mounting DOM nodes.
- `Node` is a deprecated compatibility alias for `View` and will be removed in a future release.
- `Prop` is the official static-or-reactive prop module.
- `ReactiveProp` is a deprecated compatibility alias for `Prop`.
- `View.signalText`, `View.each`, `View.eachWithKey`, `View.Attr.*`, `Router.location`, and `SSRState.signal` are preferred in examples, while the deprecated `Node.signalText`, `Node.list`, `Node.keyedList`, `Node.attr`, `ReactiveProp.*`, and `SSRState.make` names remain supported.

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
      <h1> {View.text("Counter")} </h1>
      <p>
        {View.signalText(() => "Count: " ++ Signal.get(count)->Int.toString)}
      </p>
      <p>
        {View.signalText(() => "Doubled: " ++ Signal.get(doubled)->Int.toString)}
      </p>
      <button onClick={(_evt: Dom.event) => Signal.update(count, n => n + 1)}>
        {View.text("Increment")}
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
    {View.text(greeting ++ ", " ++ name ++ "!")}
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

Html.div(
  ~attrs=[View.Attr.signal("class", className)],
  ~children=[
    View.text("Status: "),
    View.signalText(() => Signal.get(className)),
  ],
  (),
)
```

For rendering collections, prefer `View.each` for simple lists and `View.eachWithKey` when items have stable identity:

```rescript
type todo = {id: string, title: string}

let todos = Signal.make([
  {id: "1", title: "Write docs"},
  {id: "2", title: "Ship release"},
])

View.eachWithKey(
  todos,
  todo => todo.id,
  todo => <li> {View.text(todo.title)} </li>,
)
```

### Static or Reactive Props

Use `Prop` when a component prop can accept either a static value or a signal:

```rescript
@jsx.component
let make = (~className: Prop.t<string>=Prop.static("badge"), ~children) => {
  <span class={className}> {children} </span>
}

let tone = Signal.make("badge badge-info")

<Badge className={Prop.signal(tone)}>
  {View.text("Live")}
</Badge>
```

`Prop` is the source module for static-or-reactive props. `ReactiveProp` remains available as a deprecated compatibility alias.

### Router and SSR State

Router state is signal-based. Read the shared location signal directly with `Router.location()`:

```rescript
Router.init(())

let pathname = View.signalText(() => {
  let location = Signal.get(Router.location())
  "Current path: " ++ location.pathname
})
```

For server/client state transfer, prefer `SSRState.signal` when creating a synced signal:

```rescript
let count = SSRState.signal("count", 0, SSRState.Codec.int)
```

Check the [website](https://brnrdog.github.io/xote/) for more comprehensive documentations about Xote and Signals.

## License

LGPL v3 
