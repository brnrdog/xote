# Technical Overview

This document describes the architecture of Xote, a lightweight UI library for ReScript that combines fine-grained reactivity with a minimal component system.

> **Note:** Xote v3.0+ uses rescript-signals for all reactive primitives (Signal, Computed, Effect). This overview focuses on Xote-specific features: Components, Router, and JSX support.

## Architecture Overview

### Module Structure

Xote is organized into focused modules:

- **Reactive Primitives (from rescript-signals):**
  - `Signal` - Reactive state cells
  - `Computed` - Derived values that auto-update
  - `Effect` - Side effects that re-run on changes

- **Xote Modules:**
  - `Xote__Component` - Component system and virtual DOM
  - `Xote__JSX` - Generic JSX v4 implementation
  - `Xote__Router` - Signal-based routing
  - `Xote__Route` - Route matching utilities
  - `Xote.res` - Public API surface

## Reactivity Model

All reactive behavior is provided by [rescript-signals](https://github.com/pedrobslisboa/rescript-signals):

- **Dependency Tracking:** When an observer (effect or computed) runs, any Signal.get calls register the signal as a dependency
- **Scheduling:** When Signal.set is called, all dependent observers are scheduled and run synchronously
- **Push-based Computeds:** Computeds eagerly recompute when dependencies change and push results to their backing signal
- **Structural Equality:** Signals use structural equality (==) to check if values have changed, preventing unnecessary updates

## Component System

### Virtual Node Types

Xote uses several node types to represent UI elements:

- **Element:** Standard DOM elements (div, button, input, etc.)
- **Text:** Static text nodes
- **SignalText:** Reactive text that updates when signals change
- **Fragment:** Groups multiple nodes without a wrapper element
- **SignalFragment:** Reactive fragment that re-renders when a signal changes

### Rendering Behavior

- **SignalText:** Creates a DOM text node and sets up an effect that updates textContent when the signal changes
- **SignalFragment:** Uses a container element with display: contents and replaces all children when the signal changes (no diffing)
- **Lists:** Implemented as a computed signal + SignalFragment, so the entire list rerenders on any array change
- **Reactive attributes:** Set up effects that update the DOM attribute when the signal/computed value changes

## JSX Support

Xote supports ReScript's generic JSX v4 for declarative component syntax:

```json
{
  "jsx": {
    "version": 4,
    "module": "Xote__JSX"
  }
}
```

**Features:**

- Lowercase tags for HTML elements
- Props support for common attributes and events
- Children passed via JSX syntax
- Component functions called with props objects

## Router Architecture

### Route Matching

Pattern-based string matching with :param syntax:

- `parsePattern(pattern)` converts patterns like /users/:id into segment arrays
- `matchPath(pattern, pathname)` returns Match(params) or NoMatch
- Parameters returned as Dict.t<string>

### Router State

- **Location signal:** `Router.location` contains {pathname, search, hash}
- **History API integration:** Listens to popstate events for back/forward buttons
- **Declarative routing:** Uses SignalFragment + Computed for reactive rendering
- **Navigation links:** Intercepts clicks to prevent page reload

## Execution Characteristics

- **Push-based:** Signals push notifications to observers; computeds eagerly push into their backing signal
- **Auto-tracked:** Observers re-track dependencies on every run
- **Synchronous:** Updates run synchronously by default
- **Exception safe:** Scheduler wrapped in try/catch to ensure tracking state is restored

## Relation to TC39 Signals Proposal

Xote's reactive primitives (via rescript-signals) are inspired by the [TC39 Signals proposal](https://github.com/tc39/proposal-signals):

- **Aligned concepts:**
  - Automatic dependency tracking on read
  - Observer-based recomputation and re-tracking
  - Structural equality checks

- **Key differences:**
  - Computeds are push-based (eager) rather than pull-based (lazy) as in the proposal
  - Synchronous scheduling rather than microtask-based
  - Effects can return cleanup callbacks (Some/None pattern)

## API Summary

### Reactive Primitives

```rescript
Signal.make : 'a => t<'a>
Signal.get : t<'a> => 'a
Signal.peek : t<'a> => 'a
Signal.set : (t<'a>, 'a) => unit
Signal.update : (t<'a>, 'a => 'a) => unit

Computed.make : (unit => 'a) => t<'a>
Computed.dispose : t<'a> => unit

Effect.run : (unit => option<unit => unit>) => {dispose: unit => unit}
```

### Component Helpers

```rescript
Component.text : string => node
Component.textSignal : (unit => string) => node
Component.list : (t<array<'a>>, 'a => node) => node
Component.listKeyed : (t<array<'a>>, 'a => string, 'a => node) => node
Component.mount : (node, Dom.element) => unit
Component.mountById : (node, string) => unit
```

### Router Helpers

```rescript
Router.init : unit => unit
Router.location : t<{pathname: string, search: string, hash: string}>
Router.push : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.replace : (string, ~search: string=?, ~hash: string=?, unit) => unit
Router.routes : array<{pattern: string, render: params => node}> => node
Router.link : (~to: string, ~attrs: array=?, ~children: array=?, unit) => node
```

## Best Practices

- **Trust auto-disposal:** Computeds auto-dispose when subscribers drop to zero
- **Use structural equality:** Signal.set only notifies if values differ
- **Prefer JSX:** More concise and familiar syntax
- **Keep components small:** Each component should do one thing well
- **Use keyed lists:** For efficient reconciliation of dynamic lists

## Next Steps

- Explore the [Core Concepts](/docs/core-concepts/signals) for reactive primitives
- Learn about [Components](/docs/components/overview) for building UIs
- Check out [rescript-signals](https://github.com/pedrobslisboa/rescript-signals) for reactive implementation details
