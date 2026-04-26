// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/router/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {Node.text("Xote includes a client-side router built on signals. Route changes become regular reactive updates, so route matching and UI rendering fit the same model as the rest of the library.")}
    </p>

    <h2 id="getting-started-with-routing"> {Node.text("Getting Started")} </h2>
    <h3 id="quick-start"> {Node.text("Quick Start")} </h3>
    <p>
      {Node.text("Initialize the router once, then render routes inside your app.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

Router.init()

let app = () => {
  <div>
    {Router.routes([
      {pattern: "/", render: _ => <HomePage />},
      {pattern: "/users/:id", render: params =>
        switch params->Dict.get("id") {
        | Some(id) => <UserPage id />
        | None => <NotFoundPage />
        }
      },
    ])}
  </div>
}`)}
      </code>
    </pre>

    <h3 id="reading-the-location"> {Node.text("Reading the Current Location")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Router.locationSignal()")} </code>
      {Node.text(" to get the location signal, or ")}
      <code> {Node.text("Router.current()")} </code>
      {Node.text(" when you only need a snapshot.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Effect.run(() => {
  let current = Signal.get(Router.locationSignal())
  Console.log2("Current path:", current.pathname)
  None
})`)}
      </code>
    </pre>
    <p>
      {Node.text("The location record contains ")}
      <code> {Node.text("pathname")} </code>
      {Node.text(", ")}
      <code> {Node.text("search")} </code>
      {Node.text(", and ")}
      <code> {Node.text("hash")} </code>
      {Node.text(".")}
    </p>

    <h3 id="route-patterns"> {Node.text("Route Patterns")} </h3>
    <p>
      {Node.text("Patterns can be static or dynamic. Dynamic segments use ")}
      <code> {Node.text(":name")} </code>
      {Node.text(" and are exposed through the params dictionary.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`{pattern: "/", render: _ => <HomePage />}
{pattern: "/about", render: _ => <AboutPage />}
{pattern: "/users/:id", render: params =>
  switch params->Dict.get("id") {
  | Some(id) => <UserPage id />
  | None => <NotFoundPage />
  }
}`)}
      </code>
    </pre>

    <h3 id="navigation-methods"> {Node.text("Navigation Methods")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Router.push")} </code>
      {Node.text(" to create a new history entry and ")}
      <code> {Node.text("Router.replace")} </code>
      {Node.text(" to replace the current one. Both support optional ")}
      <code> {Node.text("~search")} </code>
      {Node.text(" and ")}
      <code> {Node.text("~hash")} </code>
      {Node.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.push("/users/123", ())
Router.push("/search", ~search="?q=xote", ())
Router.replace("/login", ())`)}
      </code>
    </pre>

    <h3 id="navigation-links"> {Node.text("Navigation Links")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("Router.link")} </code>
      {Node.text(" in the function API or ")}
      <code> {Node.text("Router.Link")} </code>
      {Node.text(" in JSX. Both intercept navigation without reloading the page.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let nav = () => {
  <nav>
    <Router.Link to="/" class="nav-link">
      {View.text("Home")}
    </Router.Link>
    <Router.Link to="/docs" class="nav-link">
      {View.text("Docs")}
    </Router.Link>
  </nav>
}`)}
      </code>
    </pre>

    <h3 id="server-rendering"> {Node.text("Server Rendering")} </h3>
    <p>
      {Node.text("On the server, initialize router state with ")}
      <code> {Node.text("Router.initSSR")} </code>
      {Node.text(" instead of ")}
      <code> {Node.text("Router.init")} </code>
      {Node.text(". That sets the initial location without touching browser APIs.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.initSSR(
  ~pathname="/docs",
  ~search="?tab=signals",
  (),
)`)}
      </code>
    </pre>

    <h2 id="routing-in-practice"> {Node.text("In Practice")} </h2>
    <h3 id="complete-example"> {Node.text("Complete Example")} </h3>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

Router.init()

let nav = () => {
  <nav>
    <Router.Link to="/"> {View.text("Home")} </Router.Link>
    <Router.Link to="/users"> {View.text("Users")} </Router.Link>
  </nav>
}

let app = () => {
  <div>
    <nav />
    {Router.routes([
      {pattern: "/", render: _ => <HomePage />},
      {pattern: "/users", render: _ => <UsersPage />},
      {pattern: "/users/:id", render: params =>
        switch params->Dict.get("id") {
        | Some(id) => <UserPage id />
        | None => <NotFoundPage />
        }
      },
    ])}
  </div>
}`)}
      </code>
    </pre>

    <h2 id="router-working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Initialize the router once at the app boundary, not from leaf components.")}
      </li>
      <li>
        {Node.text("Treat ")}
        <code> {Node.text("Router.locationSignal()")} </code>
        {Node.text(" like shared state. Read it where needed instead of mirroring it elsewhere.")}
      </li>
      <li>
        {Node.text("Prefer ")}
        <code> {Node.text("Router.Link")} </code>
        {Node.text(" for ordinary UI navigation so the intent stays obvious in markup.")}
      </li>
      <li>
        {Node.text("Use ")}
        <code> {Node.text("Router.initSSR")} </code>
        {Node.text(" on the server so routing stays consistent across SSR and hydration.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[Node.text("Pair this with View")], ())}
        {Node.text(" when you want to turn routes into real pages and layouts.")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[Node.text("Read Server-Side Rendering")], ())}
        {Node.text(" if the same routes also need SSR and hydration.")}
      </li>
    </ul>
  </div>
}
