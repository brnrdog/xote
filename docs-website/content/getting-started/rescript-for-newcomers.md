ReScript is the language Xote is built for. If you are coming from JavaScript or TypeScript, the quickest way to get productive is to understand that ReScript keeps the JavaScript runtime model, but gives you stricter types, better data modeling, and a compiler that pushes you toward explicit code.

## What ReScript Is

ReScript is a statically typed language that compiles to readable JavaScript. It is designed for the JavaScript ecosystem rather than against it, so you still use npm packages, browser APIs, Node APIs, bundlers, and regular JavaScript interop when you need to.

For Xote users, that matters because the code you write stays close to the platform. Signals, DOM events, and server rendering are still JavaScript work. ReScript mainly improves how safely and clearly you express that work.

## Why It Matters

ReScript removes a lot of the background noise that tends to accumulate in large UI codebases.

- Type inference means you rarely annotate obvious types.
- `option` replaces a large class of `null` and `undefined` mistakes.
- `switch` with pattern matching makes branching on data shape clearer.
- Exhaustiveness checks catch missing cases at compile time.
- Modules map cleanly to files, which keeps code organization simple.

### The Practical Payoff

The language is valuable when your UI grows beyond a few components. Refactors are safer, data modeling is more deliberate, and impossible states are harder to represent by accident.

That does not mean every file looks radically different from JavaScript. Most of the time, ReScript feels like a cleaner way to write functions, records, and modules for code that still runs as JavaScript in the browser or on the server.

## ReScript in Existing JS or TS Projects

You do not need to rewrite a whole codebase to use ReScript. It works well as an incremental addition inside an existing JavaScript or TypeScript project.

- A JavaScript or TypeScript app can import modules or libraries compiled from ReScript.
- A ReScript file can target the same runtime, bundler, and npm package graph as the rest of your app.
- That makes it practical to introduce ReScript one feature, component, or library at a time.

This is useful for Xote too. You can build a library in ReScript and consume it from JavaScript or TypeScript, or add ReScript-powered UI to a broader JS or TS codebase without changing the whole stack at once.

## Syntax You Will See Often

### let Bindings and Functions

Most values are declared with `let`. Functions are also regular values.

```rescript
let name = "Ada"
let count = 1

let greet = person => `Hello, ${person}`
let add = (a, b) => a + b
```

Two things stand out quickly:

- Template strings use backticks and `${...}` for interpolation
- Function calls use parentheses, but a single-argument anonymous function often reads like `value => ...`

### Records and Variants

Records are good for structured data. Variants are good for modeling a fixed set of states.

```rescript
type user = {
  name: string,
  admin: bool,
}

type status =
  | Idle
  | Saving
  | Failed(string)

let currentUser = {name: "Ada", admin: true}
let currentStatus = Saving
```

Variants are one of the biggest upgrades from typical JavaScript data modeling. They make state machines and async UI states much easier to express safely.

### switch and Pattern Matching

`switch` is one of the most useful parts of the language. You use it for branching, destructuring, and exhaustiveness checking.

```rescript
let statusLabel = status =>
  switch status {
  | Idle => "Ready"
  | Saving => "Saving..."
  | Failed(message) => `Failed: ${message}`
  }
```

When you add a new variant case later, the compiler tells you every `switch` that now needs updating.

### options Instead of null

ReScript uses `option<'a>` for values that may be missing.

```rescript
let maybeName: option<string> = Some("Ada")
let missingName: option<string> = None

let displayName = name =>
  switch name {
  | Some(value) => value
  | None => "Anonymous"
  }
```

That pattern shows up often when working with DOM lookups, optional props, and server data.

### Modules and Files

Each file becomes a module. If you have a file named `Counter.res`, its values are available under `Counter`.

```rescript
/* Counter.res */
let initial = 0
let increment = count => count + 1

/* App.res */
let next = Counter.increment(Counter.initial)
```

This is one of the reasons ReScript codebases stay readable as they grow. Namespacing is simple and built into the file model.

## Xote-Flavored ReScript Patterns

### Event Handlers

A DOM event handler is usually just a small function that updates a signal.

```rescript
open Xote

let count = Signal.make(0)

let increment = (_evt: Dom.event) => {
  Signal.update(count, n => n + 1)
}
```

The `_evt` name means the argument exists, but the function does not need to read it.

### Local State with Signals

Signals are ordinary values, so local state does not need a special hook API.

```rescript
open Xote

module Counter = {
  @jsx.component
  let make = () => {
    let count = Signal.make(0)

    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {Node.signalText(() => `Count: ${Signal.get(count)->Int.toString}`)}
    </button>
  }
}
```

The component sets up its state once. Later updates happen through the reactive graph, not by re-running the whole component as the default update mechanism.

### JSX Components

A Xote component is usually a module with a `make` function marked with `@jsx.component`.

```rescript
open Xote

module Greeting = {
  @jsx.component
  let make = (~name: string, ~highlight=false) => {
    <h1 class={highlight ? "hero" : "plain"}>
      {Node.text(`Hello, ${name}`)}
    </h1>
  }
}
```

Labeled arguments such as `~name` become component props. Optional props often use defaults like `~highlight=false`.

## Official Docs

The official ReScript docs are the right place for the full language reference and deeper syntax coverage.

### Recommended Deep Dives

- [Introduction](https://rescript-lang.org/docs/manual/v12.0.0/introduction)
- [Overview](https://rescript-lang.org/docs/manual/overview)
- [Pattern Matching / Destructuring](https://rescript-lang.org/docs/manual/pattern-matching-destructuring/)
- [Modules](https://rescript-lang.org/docs/manual/module/)
- [API Reference](https://rescript-lang.org/docs/manual/api/)

Once this page feels familiar, the best next step inside Xote's docs is [Signals](/docs/core-concepts/signals), then [Components](/docs/components/overview).
