open Xote

// Import doc content
module IntroDoc = IntroDoc

// Initialize router
Router.init()

// 404 Page component
module NotFoundPage = {
  type props = {}

  let make = (_props: props) => {
    <Layout children={
      <div class="container">
        <h1> {Component.text("404 - Page Not Found")} </h1>
        <p> {Component.text("The page you're looking for doesn't exist.")} </p>
        <a href="/" class="button button-primary"> {Component.text("Go Home")} </a>
      </div>
    } />
  }
}

// Main app component
let app = () => {
  Router.routes([
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
  ])
}

// Mount the app
Component.mountById(app(), "app")
