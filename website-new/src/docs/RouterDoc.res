open Xote

let content = () => {
  <div>
    <h1> {Component.text("Router Overview")} </h1>
    <p>
      {Component.text(
        "Xote includes a built-in signal-based router for building single-page applications (SPAs). The router uses the browser's History API and provides both imperative and declarative navigation.",
      )}
    </p>
    <h2> {Component.text("Features")} </h2>
    <ul>
      <li> {Component.text("Signal-based reactive routing")} </li>
      <li> {Component.text("Browser History API integration")} </li>
      <li> {Component.text("Pattern matching with dynamic parameters")} </li>
      <li> {Component.text("Imperative navigation (push/replace)")} </li>
      <li> {Component.text("Declarative routing components")} </li>
      <li> {Component.text("SPA navigation links (no page reload)")} </li>
      <li> {Component.text("Zero dependencies")} </li>
    </ul>
    <h2> {Component.text("Quick Start")} </h2>
    <h3> {Component.text("1. Initialize the Router")} </h3>
    <p>
      {Component.text("Call ")}
      <code> {Component.text("Router.init()")} </code>
      {Component.text(" once at application startup:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

Router.init()`)}
      </code>
    </pre>
    <p>
      {Component.text(
        "This sets the initial location from the browser URL and adds a popstate listener for back/forward button support.",
      )}
    </p>
    <h3> {Component.text("2. Define Routes")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Router.routes()")} </code>
      {Component.text(" to define your application routes:")}
    </p>
    <pre>
      <code>
        {Component.text(`let app = () => {
  <div>
    {Router.routes([
      {
        pattern: "/",
        render: _params => <HomePage />
      },
      {
        pattern: "/about",
        render: _params => <AboutPage />
      },
      {
        pattern: "/users/:id",
        render: params => <UserPage userId={params->Dict.get("id")} />
      },
    ])}
  </div>
}

Component.mountById(app(), "app")`)}
      </code>
    </pre>
    <h3> {Component.text("3. Navigate")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text("Router.push()")} </code>
      {Component.text(" or ")}
      <code> {Component.text("Router.link()")} </code>
      {Component.text(" to navigate:")}
    </p>
    <pre>
      <code>
        {Component.text(`// Imperative navigation
let goToAbout = (_evt: Dom.event) => {
  Router.push("/about", ())
}

// Declarative links
Router.link(
  ~to="/about",
  ~children=[Component.text("About")],
  ()
)`)}
      </code>
    </pre>
    <h2> {Component.text("The Location Signal")} </h2>
    <p>
      <code> {Component.text("Router.location")} </code>
      {Component.text(" is a signal containing the current route information:")}
    </p>
    <pre>
      <code>
        {Component.text(`type location = {
  pathname: string,  // e.g., "/users/123"
  search: string,    // e.g., "?sort=name"
  hash: string,      // e.g., "#section"
}`)}
      </code>
    </pre>
    <p> {Component.text("Read it like any signal:")} </p>
    <pre>
      <code>
        {Component.text(`Effect.run(() => {
  let currentLocation = Signal.get(Router.location)
  Console.log2("Current path:", currentLocation.pathname)
})`)}
      </code>
    </pre>
    <h2> {Component.text("Route Patterns")} </h2>
    <p> {Component.text("Patterns support static segments and dynamic parameters:")} </p>
    <h3> {Component.text("Static Routes")} </h3>
    <pre>
      <code>
        {Component.text(`{pattern: "/", render: _params => <HomePage />}
{pattern: "/about", render: _params => <AboutPage />}
{pattern: "/contact", render: _params => <ContactPage />}`)}
      </code>
    </pre>
    <h3> {Component.text("Dynamic Parameters")} </h3>
    <p>
      {Component.text("Use ")}
      <code> {Component.text(":param")} </code>
      {Component.text(" syntax for dynamic segments:")}
    </p>
    <pre>
      <code>
        {Component.text(`{pattern: "/users/:id", render: params =>
  switch params->Dict.get("id") {
  | Some(id) => <UserPage userId={id} />
  | None => <NotFoundPage />
  }
}

{pattern: "/posts/:postId/comments/:commentId", render: params => {
  let postId = params->Dict.get("postId")
  let commentId = params->Dict.get("commentId")
  <CommentPage postId={postId} commentId={commentId} />
}}`)}
      </code>
    </pre>
    <h2> {Component.text("Navigation Methods")} </h2>
    <h3>
      <code> {Component.text("Router.push()")} </code>
    </h3>
    <p> {Component.text("Navigate to a new route with a new history entry:")} </p>
    <pre>
      <code>
        {Component.text(`Router.push("/users/123", ())

// With query string
Router.push("/search", ~search="?q=xote", ())

// With hash
Router.push("/docs", ~hash="#installation", ())`)}
      </code>
    </pre>
    <h3>
      <code> {Component.text("Router.replace()")} </code>
    </h3>
    <p> {Component.text("Navigate without creating a new history entry:")} </p>
    <pre>
      <code>
        {Component.text(`Router.replace("/login", ())`)}
      </code>
    </pre>
    <p>
      {Component.text(
        "This replaces the current history entry, so clicking the back button will skip this route.",
      )}
    </p>
    <h2> {Component.text("Navigation Links")} </h2>
    <p> {Component.text("Create links that navigate without page reload:")} </p>
    <pre>
      <code>
        {Component.text(`Router.link(
  ~to="/about",
  ~children=[Component.text("About Us")],
  ()
)

// With attributes
Router.link(
  ~to="/users/123",
  ~attrs=[Component.attr("class", "user-link")],
  ~children=[Component.text("View User")],
  ()
)`)}
      </code>
    </pre>
    <h2> {Component.text("Complete Example")} </h2>
    <pre>
      <code>
        {Component.text(`open Xote

// Initialize router
Router.init()

// Page components
let homePage = () => {
  <div>
    <h1> {Component.text("Home")} </h1>
    {Router.link(~to="/about", ~children=[Component.text("About")], ())}
  </div>
}

let aboutPage = () => {
  <div>
    <h1> {Component.text("About")} </h1>
    {Router.link(~to="/", ~children=[Component.text("Home")], ())}
  </div>
}

// Main app
let app = () => {
  <div>
    <nav>
      {Router.link(~to="/", ~children=[Component.text("Home")], ())}
      {Component.text(" | ")}
      {Router.link(~to="/about", ~children=[Component.text("About")], ())}
    </nav>
    <hr />
    {Router.routes([
      {pattern: "/", render: _params => homePage()},
      {pattern: "/about", render: _params => aboutPage()},
    ])}
  </div>
}

Component.mountById(app(), "app")`)}
      </code>
    </pre>
    <h2> {Component.text("How It Works")} </h2>
    <ol>
      <li>
        <strong> {Component.text("Initialization:")} </strong>
        {Component.text(" Router.init() reads the current URL and sets up the location signal")}
      </li>
      <li>
        <strong> {Component.text("History Integration:")} </strong>
        {Component.text(" Listens to popstate events for back/forward navigation")}
      </li>
      <li>
        <strong> {Component.text("Pattern Matching:")} </strong>
        {Component.text(" Routes use simple string-based matching with :param syntax")}
      </li>
      <li>
        <strong> {Component.text("Reactive Rendering:")} </strong>
        {Component.text(" Route components are wrapped in SignalFragment + Computed")}
      </li>
      <li>
        <strong> {Component.text("Link Handling:")} </strong>
        {Component.text(
          " Router.link() intercepts clicks and calls Router.push() instead of following the href",
        )}
      </li>
    </ol>
    <h2> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Initialize once:")} </strong>
        {Component.text(" Call Router.init() at the top level, not in components")}
      </li>
      <li>
        <strong> {Component.text("Order routes carefully:")} </strong>
        {Component.text(" More specific routes should come before generic ones")}
      </li>
      <li>
        <strong> {Component.text("Handle 404s:")} </strong>
        {Component.text(" Add a catch-all route at the end for unmatched paths")}
      </li>
      <li>
        <strong> {Component.text("Use links for navigation:")} </strong>
        {Component.text(" Prefer Router.link() over manual Router.push() calls")}
      </li>
      <li>
        <strong> {Component.text("Extract parameters safely:")} </strong>
        {Component.text(" Use Option methods when accessing route parameters")}
      </li>
    </ul>
    <h2> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Try the ")}
        {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
        {Component.text(" to see routing in action")}
      </li>
      <li>
        {Component.text("Learn about ")}
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Signals")], ())}
        {Component.text(" for reactive state")}
      </li>
      <li>
        {Component.text("Explore ")}
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
        {Component.text(" for building UIs")}
      </li>
    </ul>
  </div>
}
