---
sidebar_position: 1
slug: /
---

# Getting Started

Welcome to **Xote** (pronounced [ˈʃɔtʃi]) - a lightweight, zero-dependency UI library for ReScript with fine-grained reactivity based on the [TC39 Signals proposal](https://github.com/tc39/proposal-signals).

## What is Xote?

Xote brings reactive programming to ReScript with minimal abstractions and no runtime dependencies. It focuses on:

- **Zero dependencies**: Pure ReScript implementation
- **Lightweight**: Efficient runtime with minimal overhead
- **Fine-grained reactivity**: Direct DOM updates without a virtual DOM
- **Automatic dependency tracking**: No manual subscription management
- **Type-safe**: Leverages ReScript's powerful type system

## Quick Example

Here's a simple counter application to get you started:

### Using JSX Syntax

```rescript
open Xote

// Create reactive state
let count = Signal.make(0)

// Event handler
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

// Build the UI
let app = () => {
  <div>
    <h1> {Component.text("Counter")} </h1>
    <p>
      {Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </p>
    <button onClick={increment}>
      {Component.text("Increment")}
    </button>
  </div>
}

// Mount to the DOM
Component.mountById(app(), "app")
```

### Using Function API

```rescript
open Xote

let count = Signal.make(0)
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)

let app = Component.div(
  ~children=[
    Component.h1(~children=[Component.text("Counter")], ()),
    Component.p(~children=[
      Component.textSignal(() => "Count: " ++ Int.toString(Signal.get(count)))
    ], ()),
    Component.button(
      ~events=[("click", increment)],
      ~children=[Component.text("Increment")],
      ()
    )
  ],
  ()
)

Component.mountById(app, "app")
```

When you click the button, the counter updates reactively - only the text node displaying the count is updated, not the entire component tree.

## Core Concepts

Xote is built on four fundamental primitives:

- **[Signals](/docs/core-concepts/signals)**: Reactive state containers that notify dependents when they change
- **[Computed Values](/docs/core-concepts/computed)**: Derived values that automatically update when their dependencies change
- **[Effects](/docs/core-concepts/effects)**: Side effects that re-run when dependencies change
- **[Components](/docs/components/overview)**: Declarative UI builders using ReScript functions

## Installation

Get started with Xote in your ReScript project:

```bash
npm install xote
# or
yarn add xote
# or
pnpm add xote
```

Then add it to your `rescript.json`:

```json
{
  "bs-dependencies": ["xote"]
}
```

## Next Steps

- Learn about [Signals](/docs/core-concepts/signals) - the foundation of reactive state
- Explore [Components](/docs/components/overview) - building UIs with Xote
- Check out the [Demos](/demos) to see Xote in action
- Read the [API Reference](/docs/api/signals) for detailed documentation

## Philosophy

Xote focuses on **clarity, control, and performance**. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM. By aligning with the TC39 Signals proposal, Xote ensures your code will feel familiar as JavaScript evolves to include native reactivity primitives.
