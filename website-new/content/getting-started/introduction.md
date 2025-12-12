# Getting Started

Welcome to Xote (pronounced [ˈʃɔtʃi]) - a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.

## What is Xote?

Xote provides a declarative component system and signal-based router built on top of [rescript-signals](https://github.com/brnrdog/rescript-signals). It focuses on:

- Fine-grained reactivity: Direct DOM updates without a virtual DOM
- Automatic dependency tracking: No manual subscription management (powered by rescript-signals)
- Lightweight: Minimal runtime footprint
- Type-safe: Leverages ReScript's powerful type system
- JSX Support: Declarative component syntax with full ReScript type safety

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

When you click the button, the counter updates reactively - only the text node displaying the count is updated, not the entire component tree.

## Core Concepts

Xote re-exports reactive primitives from rescript-signals and adds UI features:

### Reactive Primitives (from rescript-signals)

- [Signals](/docs/core-concepts/signals): Reactive state containers that notify dependents when they change
- [Computed Values](/docs/core-concepts/computed): Derived values that automatically update when their dependencies change
- [Effects](/docs/core-concepts/effects): Side effects that re-run when dependencies change

### Xote Features

- [Components](/docs/components/overview): Declarative UI builder with JSX support and fine-grained DOM updates
- Router: Signal-based SPA navigation with pattern matching

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

Xote focuses on clarity, control, and performance. The goal is to offer precise, fine-grained updates and predictable behavior without a virtual DOM.

By building on [rescript-signals](https://github.com/pedrobslisboa/rescript-signals) (which implements the [TC39 Signals proposal](https://github.com/tc39/proposal-signals)), Xote ensures your reactive code aligns with emerging JavaScript standards while providing ReScript-specific UI features.
