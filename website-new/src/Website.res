open Xote

// Import doc content
module IntroDoc = IntroDoc

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
