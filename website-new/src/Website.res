open Xote

// Import doc content
module IntroDoc = IntroDoc

// Initialize router
Router.init()

// Main app component
let app = () => {
  Router.routes([
    {
      pattern: "/",
      render: _params => HomePage.make(),
    },
    {
      pattern: "/demos",
      render: _params => DemosPage.make(),
    },
    {
      pattern: "/docs",
      render: _params => DocsPage.make(~currentPath="/docs", ~content=IntroDoc.content()),
    },
    {
      pattern: "/docs/",
      render: _params => DocsPage.make(~currentPath="/docs", ~content=IntroDoc.content()),
    },
    {
      pattern: "*",
      render: _params =>
        Layout.make(~children={
          <div class="container">
            <h1> {Component.text("404 - Page Not Found")} </h1>
            <p> {Component.text("The page you're looking for doesn't exist.")} </p>
            <a href="/" class="button button-primary"> {Component.text("Go Home")} </a>
          </div>
        }),
    },
  ])
}

// Mount the app
Component.mountById(app(), "app")
