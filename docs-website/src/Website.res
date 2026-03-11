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

// Initialize router
Router.init(~basePath="/xote", ())

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
        {
          pattern: "*",
          render: _params => <NotFoundPage />,
        },
      ],
    )
  }
}

// Mount the app
Component.mountById(<App />, "app")
