open Xote

// Import modules to ensure they are included in the bundle
module Website = Website

// Render function called by the SSR server for each request
let render = (url: string) => {
  // Initialize router for server-side rendering with the requested URL
  Router.initSSR(~basePath="/xote", ~pathname=url, ())

  // Render the app to an HTML string
  SSR.renderToString(() => <Website.App />)
}
