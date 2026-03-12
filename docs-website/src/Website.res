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
                {text: "Reading Values", id: "reading-values", level: 2},
                {text: "Updating Signals", id: "updating-signals", level: 2},
                {text: "Structural Equality", id: "structural-equality", level: 2},
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
            />,
        },
        {
          pattern: "/docs/core-concepts/batching",
          render: _params =>
            <DocsPage
              currentPath="/docs/core-concepts/batching"
              pageTitle="Batching"
              pageLead="Group multiple signal updates to run observers only once."
              content={BatchingDoc.content()}
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

