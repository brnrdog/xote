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
Router.init()

// 404 Page component
module NotFoundPage = {
  type props = {}

  let make = (_props: props) => {
    <Layout
      children={<div class="container">
        <h1> {Component.text("404 - Page Not Found")} </h1>
        <p> {Component.text("The page you're looking for doesn't exist.")} </p>
        {Router.link(~to="/", ~attrs=[Component.attr("class", "button button-primary")], ~children=[Component.text("Go Home")], ())}
      </div>}
    />
  }
}

// Main app - use routes directly as the root node
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
          render: _params => <DocsPage currentPath="/docs" content={IntroDoc.content()} />,
        },
        {
          pattern: "/docs/",
          render: _params => <DocsPage currentPath="/docs" content={IntroDoc.content()} />,
        },
        {
          pattern: "/docs/core-concepts/signals",
          render: _params => <DocsPage currentPath="/docs/core-concepts/signals" content={SignalsDoc.content()} />,
        },
        {
          pattern: "/docs/core-concepts/computed",
          render: _params => <DocsPage currentPath="/docs/core-concepts/computed" content={ComputedDoc.content()} />,
        },
        {
          pattern: "/docs/core-concepts/effects",
          render: _params => <DocsPage currentPath="/docs/core-concepts/effects" content={EffectsDoc.content()} />,
        },
        {
          pattern: "/docs/core-concepts/batching",
          render: _params => <DocsPage currentPath="/docs/core-concepts/batching" content={BatchingDoc.content()} />,
        },
        {
          pattern: "/docs/components/overview",
          render: _params => <DocsPage currentPath="/docs/components/overview" content={ComponentsDoc.content()} />,
        },
        {
          pattern: "/docs/router/overview",
          render: _params => <DocsPage currentPath="/docs/router/overview" content={RouterDoc.content()} />,
        },
        {
          pattern: "/docs/api/signals",
          render: _params => <DocsPage currentPath="/docs/api/signals" content={ApiSignalsDoc.content()} />,
        },
        {
          pattern: "/docs/comparisons/react",
          render: _params => <DocsPage currentPath="/docs/comparisons/react" content={ReactComparisonDoc.content()} />,
        },
        {
          pattern: "/docs/technical-overview",
          render: _params => <DocsPage currentPath="/docs/technical-overview" content={TechnicalOverviewDoc.content()} />,
        },
        {
          pattern: "*",
          render: _params => <NotFoundPage />,
        },
      ],
      ~baseUrl="/xote",
    )
  }
}
// Mount the app
Component.mountById(<App />, "app")
