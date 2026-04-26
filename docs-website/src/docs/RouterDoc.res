// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../content/router/overview.md
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

let content = () => {
  <div>
    <p>
      {View.text("Xote includes a client-side router built on signals. Route changes become regular reactive updates, so route matching and UI rendering fit the same model as the rest of the library.")}
    </p>

    <h2 id="getting-started-with-routing"> {View.text("Getting Started")} </h2>
    <h3 id="quick-start"> {View.text("Quick Start")} </h3>
    <p>
      {View.text("Initialize the router once, then render routes inside your app.")}
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

    <h3 id="reading-the-location"> {View.text("Reading the Current Location")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("Router.location()")} </code>
      {View.text(" to access the shared location signal. Read it with ")}
      <code> {View.text("Signal.get")} </code>
      {View.text(" wherever you need the current snapshot.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Effect.run(() => {
  let current = Signal.get(Router.location())
  Console.log2("Current path:", current.pathname)
  None
})`)}
      </code>
    </pre>
    <p>
      {View.text("The location record contains ")}
      <code> {View.text("pathname")} </code>
      {View.text(", ")}
      <code> {View.text("search")} </code>
      {View.text(", and ")}
      <code> {View.text("hash")} </code>
      {View.text(".")}
    </p>

    <h3 id="route-patterns"> {View.text("Route Patterns")} </h3>
    <p>
      {View.text("Patterns can be static or dynamic. Dynamic segments use ")}
      <code> {View.text(":name")} </code>
      {View.text(" and are exposed through the params dictionary.")}
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

    <h3 id="navigation-methods"> {View.text("Navigation Methods")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("Router.push")} </code>
      {View.text(" to create a new history entry and ")}
      <code> {View.text("Router.replace")} </code>
      {View.text(" to replace the current one. Both support optional ")}
      <code> {View.text("~search")} </code>
      {View.text(" and ")}
      <code> {View.text("~hash")} </code>
      {View.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.push("/users/123", ())
Router.push("/search", ~search="?q=xote", ())
Router.replace("/login", ())`)}
      </code>
    </pre>

    <h3 id="navigation-links"> {View.text("Navigation Links")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("Router.link")} </code>
      {View.text(" in the function API or ")}
      <code> {View.text("Router.Link")} </code>
      {View.text(" in JSX. Both intercept navigation without reloading the page.")}
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

    <h3 id="server-rendering"> {View.text("Server Rendering")} </h3>
    <p>
      {View.text("On the server, initialize router state with ")}
      <code> {View.text("Router.initSSR")} </code>
      {View.text(" instead of ")}
      <code> {View.text("Router.init")} </code>
      {View.text(". That sets the initial location without touching browser APIs.")}
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

    <h2 id="routing-in-practice"> {View.text("In Practice")} </h2>
    <h3 id="complete-example"> {View.text("Complete Example")} </h3>
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

    <h2 id="router-working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Initialize the router once at the app boundary, not from leaf components.")}
      </li>
      <li>
        {View.text("Treat ")}
        <code> {View.text("Router.location()")} </code>
        {View.text(" like shared state. Read it where needed instead of mirroring it elsewhere.")}
      </li>
      <li>
        {View.text("Prefer ")}
        <code> {View.text("Router.Link")} </code>
        {View.text(" for ordinary UI navigation so the intent stays obvious in markup.")}
      </li>
      <li>
        {View.text("Use ")}
        <code> {View.text("Router.initSSR")} </code>
        {View.text(" on the server so routing stays consistent across SSR and hydration.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/view/overview", ~children=[View.text("Pair this with View")], ())}
        {View.text(" when you want to turn routes into real pages and layouts.")}
      </li>
      <li>
        {Router.link(~to="/docs/advanced/ssr", ~children=[View.text("Read Server-Side Rendering")], ())}
        {View.text(" if the same routes also need SSR and hydration.")}
      </li>
    </ul>
  </div>
}
