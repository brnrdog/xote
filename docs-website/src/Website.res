open Xote

// Import doc content
module IntroDoc = IntroDoc
module SignalsDoc = SignalsDoc
module ComputedDoc = ComputedDoc
module EffectsDoc = EffectsDoc
module BatchingDoc = BatchingDoc
module ComponentsDoc = ComponentsDoc
module RouterDoc = RouterDoc
module ApiSignalsDoc = ApiSignalsDoc
module ReactComparisonDoc = ReactComparisonDoc
module TechnicalOverviewDoc = TechnicalOverviewDoc
module SSRDoc = SSRDoc

// Import demo content
module CounterDemo = CounterDemo
module TodoDemo = TodoDemo
module ColorMixerDemo = ColorMixerDemo
module ReactionGameDemo = ReactionGameDemo
module SolitaireDemo = SolitaireDemo
module MatchGameDemo = MatchGameDemo
module SnakeGameDemo = SnakeGameDemo

// 404 Page component
module NotFoundPage = {
  type props = {}

  let make = (_props: props) => {
    <Layout
      children={
        <div class="not-found">
          <h1> {Component.text("404")} </h1>
          <p> {Component.text("The page you're looking for doesn't exist.")} </p>
          {Router.link(
            ~to="/",
            ~attrs=[Component.attr("class", "btn btn-primary")],
            ~children=[Component.text("Go Home")],
            (),
          )}
        </div>
      }
    />
  }
}

// Main app
module App = {
  type props = {}

  let make = (_props: props) => {
    Router.routes(
      [
        {
          pattern: "/",
          render: _params => <HomePage />,
        },
        {
          pattern: "/demos",
          render: _params => <DemosPage />,
        },
        {
          pattern: "/docs",
          render: _params =>
            <DocsPage
              currentPath="/docs"
              pageTitle="Introduction"
              pageLead="Get started with Xote, a lightweight reactive UI library for ReScript."
              content={IntroDoc.content()}
              tocItems=[
                {text: "What is Xote?", id: "what-is-xote", level: 2},
                {text: "Quick Example", id: "quick-example", level: 2},
                {text: "Using JSX Syntax", id: "using-jsx-syntax", level: 3},
                {text: "Core Concepts", id: "core-concepts", level: 2},
                {text: "Installation", id: "installation", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
                {text: "Philosophy", id: "philosophy", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/",
          render: _params =>
            <DocsPage
              currentPath="/docs"
              pageTitle="Introduction"
              pageLead="Get started with Xote, a lightweight reactive UI library for ReScript."
              content={IntroDoc.content()}
              tocItems=[
                {text: "What is Xote?", id: "what-is-xote", level: 2},
                {text: "Quick Example", id: "quick-example", level: 2},
                {text: "Using JSX Syntax", id: "using-jsx-syntax", level: 3},
                {text: "Core Concepts", id: "core-concepts", level: 2},
                {text: "Installation", id: "installation", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
                {text: "Philosophy", id: "philosophy", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/core-concepts/signals",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/signals"
              pageTitle="Signals"
              pageLead="Reactive state cells that form the foundation of Xote's reactivity model."
              content={SignalsDoc.content()}
              tocItems=[
                {text: "Creating Signals", id: "creating-signals", level: 2},
                {text: "Reading Signal Values", id: "reading-signal-values", level: 2},
                {text: "Signal.get()", id: "signal-get", level: 3},
                {text: "Signal.peek()", id: "signal-peek", level: 3},
                {text: "Updating Signals", id: "updating-signals", level: 2},
                {text: "Signal.set()", id: "signal-set", level: 3},
                {text: "Signal.update()", id: "signal-update", level: 3},
                {text: "Important Behaviors", id: "important-behaviors", level: 2},
                {text: "Example: Counter", id: "example-counter", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/core-concepts/computed",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/computed"
              pageTitle="Computed"
              pageLead="Derived signals that automatically recompute when their dependencies change."
              content={ComputedDoc.content()}
              tocItems=[
                {text: "Creating Computed Values", id: "creating-computed-values", level: 2},
                {text: "How Computed Values Work", id: "how-computed-values-work", level: 2},
                {text: "Reading Computed Values", id: "reading-computed-values", level: 2},
                {text: "Automatic Disposal", id: "automatic-disposal", level: 2},
                {text: "Chaining Computed Values", id: "chaining-computed-values", level: 2},
                {text: "Computed vs Manual Updates", id: "computed-vs-manual-updates", level: 2},
                {text: "Dynamic Dependencies", id: "dynamic-dependencies", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Important Notes", id: "important-notes", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/core-concepts/effects",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/effects"
              pageTitle="Effects"
              pageLead="Side effects that run when their dependencies change, with automatic cleanup."
              content={EffectsDoc.content()}
              tocItems=[
                {text: "Creating Effects", id: "creating-effects", level: 2},
                {text: "How Effects Work", id: "how-effects-work", level: 2},
                {text: "Cleanup Callbacks", id: "cleanup-callbacks", level: 2},
                {text: "Common Use Cases", id: "common-use-cases", level: 2},
                {text: "Disposing Effects", id: "disposing-effects", level: 2},
                {text: "Dynamic Dependencies", id: "dynamic-dependencies", level: 2},
                {text: "Avoiding Dependencies", id: "avoiding-dependencies", level: 2},
                {text: "Example: Auto-save", id: "example-auto-save", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Effects vs Computed", id: "effects-vs-computed", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/advanced/ssr",
          render: _params =>
            <DocsPage
              currentPath="/docs/advanced/ssr"
              pageTitle="Server-Side Rendering"
              pageLead="Render components on the server and hydrate on the client with seamless state transfer."
              content={SSRDoc.content()}
              tocItems=[
                {text: "Overview", id: "overview", level: 2},
                {text: "Environment Detection", id: "environment-detection", level: 2},
                {text: "Rendering to HTML", id: "rendering-to-html", level: 2},
                {text: "Full Document Rendering", id: "full-document-rendering", level: 3},
                {text: "State Transfer", id: "state-transfer", level: 2},
                {text: "Creating Synced State", id: "creating-synced-state", level: 3},
                {text: "Built-in Codecs", id: "built-in-codecs", level: 3},
                {text: "Syncing Existing Signals", id: "syncing-existing-signals", level: 3},
                {text: "Generating the State Script", id: "generating-the-state-script", level: 3},
                {text: "Client-Side Hydration", id: "hydration", level: 2},
                {text: "Complete Example", id: "complete-example", level: 2},
                {text: "Hydration Markers", id: "hydration-markers", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/advanced/batching",
          render: _params =>
            <DocsPage
              currentPath="/docs/advanced/batching"
              pageTitle="Batching"
              pageLead="Group multiple signal updates to run observers only once."
              content={BatchingDoc.content()}
              tocItems=[
                {text: "Why Batch?", id: "why-batch", level: 2},
                {text: "Using Signal.batch()", id: "using-signal-batch", level: 2},
                {text: "How Batching Works", id: "how-batching-works", level: 2},
                {text: "Example: Form Updates", id: "example-form-updates", level: 2},
                {text: "Nested Batches", id: "nested-batches", level: 2},
                {text: "Returning Values from Batches", id: "returning-values-from-batches", level: 2},
                {text: "When to Use Batching", id: "when-to-use-batching", level: 2},
                {text: "Example: Animation", id: "example-animation", level: 2},
                {text: "Performance Considerations", id: "performance-considerations", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Example: Shopping Cart", id: "example-shopping-cart", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/components/overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/components/overview"
              pageTitle="Components"
              pageLead="The Xote component system for building reactive user interfaces."
              content={ComponentsDoc.content()}
              tocItems=[
                {text: "What are Components?", id: "what-are-components", level: 2},
                {text: "JSX Configuration", id: "jsx-configuration", level: 2},
                {text: "Text Nodes", id: "text-nodes", level: 2},
                {text: "Attributes", id: "attributes", level: 2},
                {text: "Event Handlers", id: "event-handlers", level: 2},
                {text: "Lists", id: "lists", level: 2},
                {text: "Mounting to the DOM", id: "mounting-to-the-dom", level: 2},
                {text: "Example: Counter Component", id: "example-counter-component", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/router/overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/router/overview"
              pageTitle="Router"
              pageLead="Signal-based client-side router with pattern matching and dynamic routes."
              content={RouterDoc.content()}
              tocItems=[
                {text: "Features", id: "features", level: 2},
                {text: "Quick Start", id: "quick-start", level: 2},
                {text: "The Location Signal", id: "the-location-signal", level: 2},
                {text: "Route Patterns", id: "route-patterns", level: 2},
                {text: "Navigation Methods", id: "navigation-methods", level: 2},
                {text: "Navigation Links", id: "navigation-links", level: 2},
                {text: "Complete Example", id: "complete-example", level: 2},
                {text: "How It Works", id: "how-it-works", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/api/signals",
          render: _params =>
            <DocsPage
              currentPath="/docs/api/signals"
              pageTitle="Signals API"
              pageLead="Complete API reference for Signal, Computed, and Effect."
              content={ApiSignalsDoc.content()}
              tocItems=[
                {text: "Type", id: "type", level: 2},
                {text: "Functions", id: "functions", level: 2},
                {text: "make", id: "make", level: 3},
                {text: "get", id: "get", level: 3},
                {text: "peek", id: "peek", level: 3},
                {text: "set", id: "set", level: 3},
                {text: "update", id: "update", level: 3},
                {text: "batch", id: "batch", level: 3},
                {text: "untrack", id: "untrack", level: 3},
                {text: "Examples", id: "examples", level: 2},
                {text: "Notes", id: "notes", level: 2},
                {text: "See Also", id: "see-also", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/comparisons/react",
          render: _params =>
            <DocsPage
              currentPath="/docs/comparisons/react"
              pageTitle="React Comparison"
              pageLead="How Xote's reactivity model compares to React's component model."
              content={ReactComparisonDoc.content()}
              tocItems=[
                {text: "Philosophy", id: "philosophy", level: 2},
                {text: "Code Comparison: Counter", id: "code-comparison-counter-example", level: 2},
                {text: "Key Differences", id: "key-differences", level: 2},
                {text: "Code Comparison: Todo List", id: "code-comparison-todo-list", level: 2},
                {text: "When to Choose React", id: "when-to-choose-react", level: 2},
                {text: "When to Choose Xote", id: "when-to-choose-xote", level: 2},
                {text: "Performance Comparison", id: "performance-comparison", level: 2},
                {text: "Migration Considerations", id: "migration-considerations", level: 2},
                {text: "Conclusion", id: "conclusion", level: 2},
                {text: "Further Reading", id: "further-reading", level: 2},
              ]
            />,
        },
        {
          pattern: "/docs/technical-overview",
          render: _params =>
            <DocsPage
              currentPath="/docs/technical-overview"
              pageTitle="Technical Overview"
              pageLead="Deep dive into Xote's architecture, scheduling, and reactivity internals."
              content={TechnicalOverviewDoc.content()}
              tocItems=[
                {text: "Architecture Overview", id: "architecture-overview", level: 2},
                {text: "Reactivity Model", id: "reactivity-model", level: 2},
                {text: "Component System", id: "component-system", level: 2},
                {text: "JSX Support", id: "jsx-support", level: 2},
                {text: "Router Architecture", id: "router-architecture", level: 2},
                {text: "Execution Characteristics", id: "execution-characteristics", level: 2},
                {text: "TC39 Signals Proposal", id: "relation-to-tc39-signals-proposal", level: 2},
                {text: "API Summary", id: "api-summary", level: 2},
                {text: "Best Practices", id: "best-practices", level: 2},
                {text: "Next Steps", id: "next-steps", level: 2},
              ]
            />,
        },
        // Demo routes
        {
          pattern: "/docs/demos/counter",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/counter"
              demoTitle="Counter"
              demoLead="Simple reactive counter with signals and event handlers."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/CounterDemo.res"
              content={CounterDemo.content()}
            />,
        },
        {
          pattern: "/docs/demos/todo",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/todo"
              demoTitle="Todo List"
              demoLead="Complete todo app with filters, computed values, and reactive lists."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/TodoDemo.res"
              content={TodoDemo.content()}
            />,
        },
        {
          pattern: "/docs/demos/color-mixer",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/color-mixer"
              demoTitle="Color Mixer"
              demoLead="RGB color mixing with live preview, format conversions, and palette variations."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/ColorMixerDemo.res"
              content={ColorMixerDemo.content()}
            />,
        },
        {
          pattern: "/docs/demos/reaction-game",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/reaction-game"
              demoTitle="Reaction Game"
              demoLead="Reflex testing game with timers, statistics, and computed averages."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/ReactionGameDemo.res"
              content={ReactionGameDemo.content()}
            />,
        },
        {
          pattern: "/docs/demos/solitaire",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/solitaire"
              demoTitle="Solitaire"
              demoLead="Classic Klondike Solitaire with click-to-move gameplay and win detection."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/SolitaireDemo.res"
              content={SolitaireDemo.content()}
            />,
        },
        {
          pattern: "/docs/demos/memory-match",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/memory-match"
              demoTitle="Memory Match"
              demoLead="2-player memory matching game with 10 progressive levels and score tracking."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/MatchGameDemo.res"
              content={MatchGameDemo.content()}
            />,
        },
        {
          pattern: "/docs/demos/snake",
          render: _params =>
            <DemoPage
              currentPath="/docs/demos/snake"
              demoTitle="Snake Game"
              demoLead="Classic snake game with 10 challenging levels, obstacles, and increasing difficulty."
              sourceUrl="https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/SnakeGameDemo.res"
              content={SnakeGameDemo.content()}
            />,
        },
        {
          pattern: "*",
          render: _params => <NotFoundPage />,
        },
      ],
    )
  }
}

