// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/router/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
    <h1> {Node.text("Router Overview")} </h1>
    <p>
      {Node.text("Xote includes a built-in signal-based router for building single-page applications (SPAs). The router uses the browser's History API and provides both imperative and declarative navigation.")}
    </p>
    <h2 id="features"> {Node.text("Features")} </h2>
    <ul>
      <li>
        {Node.text("Signal-based reactive routing")}
      </li>
      <li>
        {Node.text("Browser History API integration")}
      </li>
      <li>
        {Node.text("Pattern matching with dynamic parameters")}
      </li>
      <li>
        {Node.text("Imperative navigation (push/replace)")}
      </li>
      <li>
        {Node.text("Declarative routing components")}
      </li>
      <li>
        {Node.text("SPA navigation links (no page reload)")}
      </li>
      <li>
        {Node.text("Zero dependencies")}
      </li>
    </ul>
    <h2 id="quick-start"> {Node.text("Quick Start")} </h2>
    <h3 id="initialize-the-router"> {Node.text("1. Initialize the Router")} </h3>
    <p>
      {Node.text("Call ")}
      <code> {Node.text("Router.init()")} </code>
      {Node.text(" once at application startup:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

Router.init()`)}
      </code>
    </pre>
    <p>
      {Node.text("This sets the initial location from the browser URL and adds a popstate listener for back/forward button support.")}
    </p>
    <h3 id="define-routes"> {Node.text("2. Define Routes")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Router.routes()")} </code>
      {Node.text(" to define your application routes:")}
    </p>
    <pre>
      <code>
        {Node.text(`let app = () => {
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

Node.mountById(app(), "app")`)}
      </code>
    </pre>
    <h3 id="navigate"> {Node.text("3. Navigate")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Router.push()")} </code>
      {Node.text(" or ")}
      <code> {Node.text("Router.link()")} </code>
      {Node.text(" to navigate:")}
    </p>
    <pre>
      <code>
        {Node.text(`// Imperative navigation
let goToAbout = (_evt: Dom.event) => {
  Router.push("/about", ())
}

// Declarative links
Router.link(
  ~to="/about",
  ~children=[Node.text("About")],
  ()
)`)}
      </code>
    </pre>
    <h2 id="the-location-signal"> {Node.text("The Location Signal")} </h2>
    <p>
      <code> {Node.text("Router.location")} </code>
      {Node.text(" is a signal containing the current route information:")}
    </p>
    <pre>
      <code>
        {Node.text(`type location = {
  pathname: string,  // e.g., "/users/123"
  search: string,    // e.g., "?sort=name"
  hash: string,      // e.g., "#section"
}`)}
      </code>
    </pre>
    <p>
      {Node.text("Read it like any signal:")}
    </p>
    <pre>
      <code>
        {Node.text(`Effect.run(() => {
  let currentLocation = Signal.get(Router.location)
  Console.log2("Current path:", currentLocation.pathname)
})`)}
      </code>
    </pre>
    <h2 id="route-patterns"> {Node.text("Route Patterns")} </h2>
    <p>
      {Node.text("Patterns support static segments and dynamic parameters:")}
    </p>
    <h3 id="static-routes"> {Node.text("Static Routes")} </h3>
    <pre>
      <code>
        {Node.text(`{pattern: "/", render: _params => <HomePage />}
{pattern: "/about", render: _params => <AboutPage />}
{pattern: "/contact", render: _params => <ContactPage />}`)}
      </code>
    </pre>
    <h3 id="dynamic-parameters"> {Node.text("Dynamic Parameters")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text(":param")} </code>
      {Node.text(" syntax for dynamic segments:")}
    </p>
    <pre>
      <code>
        {Node.text(`{pattern: "/users/:id", render: params =>
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
    <h2 id="navigation-methods"> {Node.text("Navigation Methods")} </h2>
    <h3 id="routerpush"> <code> {Node.text("Router.push()")} </code> </h3>
    <p>
      {Node.text("Navigate to a new route with a new history entry:")}
    </p>
    <pre>
      <code>
        {Node.text(`Router.push("/users/123", ())

// With query string
Router.push("/search", ~search="?q=xote", ())

// With hash
Router.push("/docs", ~hash="#installation", ())`)}
      </code>
    </pre>
    <h3 id="routerreplace"> <code> {Node.text("Router.replace()")} </code> </h3>
    <p>
      {Node.text("Navigate without creating a new history entry:")}
    </p>
    <pre>
      <code>
        {Node.text(`Router.replace("/login", ())`)}
      </code>
    </pre>
    <p>
      {Node.text("This replaces the current history entry, so clicking the back button will skip this route.")}
    </p>
    <h2 id="navigation-links"> {Node.text("Navigation Links")} </h2>
    <p>
      {Node.text("Create links that navigate without page reload:")}
    </p>
    <pre>
      <code>
        {Node.text(`Router.link(
  ~to="/about",
  ~children=[Node.text("About Us")],
  ()
)

// With attributes
Router.link(
  ~to="/users/123",
  ~attrs=[Node.attr("class", "user-link")],
  ~children=[Node.text("View User")],
  ()
)`)}
      </code>
    </pre>
    <h2 id="complete-example"> {Node.text("Complete Example")} </h2>
    <pre>
      <code>
        {Node.text(`open Xote

// Initialize router
Router.init()

// Page components
let homePage = () => {
  <div>
    <h1> {Node.text("Home")} </h1>
    {Router.link(~to="/about", ~children=[Node.text("About")], ())}
  </div>
}

let aboutPage = () => {
  <div>
    <h1> {Node.text("About")} </h1>
    {Router.link(~to="/", ~children=[Node.text("Home")], ())}
  </div>
}

// Main app
let app = () => {
  <div>
    <nav>
      {Router.link(~to="/", ~children=[Node.text("Home")], ())}
      {Node.text(" | ")}
      {Router.link(~to="/about", ~children=[Node.text("About")], ())}
    </nav>
    <hr />
    {Router.routes([
      {pattern: "/", render: _params => homePage()},
      {pattern: "/about", render: _params => aboutPage()},
    ])}
  </div>
}

Node.mountById(app(), "app")`)}
      </code>
    </pre>
    <h2 id="how-it-works"> {Node.text("How It Works")} </h2>
    <ol>
      <li>
        <strong> {Node.text("Initialization:")} </strong>
      {Node.text(" Router.init() reads the current URL and sets up the location signal")}
      </li>
      <li>
        <strong> {Node.text("History Integration:")} </strong>
      {Node.text(" Listens to popstate events for back/forward navigation")}
      </li>
      <li>
        <strong> {Node.text("Pattern Matching:")} </strong>
      {Node.text(" Routes use simple string-based matching with :param syntax")}
      </li>
      <li>
        <strong> {Node.text("Reactive Rendering:")} </strong>
      {Node.text(" Route components are wrapped in SignalFragment + Computed")}
      </li>
      <li>
        <strong> {Node.text("Link Handling:")} </strong>
      {Node.text(" Router.link() intercepts clicks and calls Router.push() instead of following the href")}
      </li>
    </ol>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Initialize once:")} </strong>
      {Node.text(" Call Router.init() at the top level, not in components")}
      </li>
      <li>
        <strong> {Node.text("Order routes carefully:")} </strong>
      {Node.text(" More specific routes should come before generic ones")}
      </li>
      <li>
        <strong> {Node.text("Handle 404s:")} </strong>
      {Node.text(" Add a catch-all route at the end for unmatched paths")}
      </li>
      <li>
        <strong> {Node.text("Use links for navigation:")} </strong>
      {Node.text(" Prefer Router.link() over manual Router.push() calls")}
      </li>
      <li>
        <strong> {Node.text("Extract parameters safely:")} </strong>
      {Node.text(" Use Option methods when accessing route parameters")}
      </li>
    </ul>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Try the ")}
      {Router.link(~to="/demos", ~children=[Node.text("Demos")], ())}
      {Node.text(" to see routing in action")}
      </li>
      <li>
        {Node.text("Learn about ")}
      {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
      {Node.text(" for reactive state")}
      </li>
      <li>
        {Node.text("Explore ")}
      {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
      {Node.text(" for building UIs")}
      </li>
    </ul>
  </div>
}
