let content = () => {
  <div>
    <h2 id="rendering-model"> {View.text("Rendering Model")} </h2>
    <h3 id="overview"> {View.text("Overview")} </h3>
    <p>
      {View.text("Xote's SSR story is built from three modules that line up with the render flow:")}
    </p>
    <ul>
      <li>
        <strong> {View.text("SSR")} </strong>
        {View.text(" - render nodes to HTML")}
      </li>
      <li>
        <strong> {View.text("SSRState")} </strong>
        {View.text(" - serialize state on the server and restore it on the client")}
      </li>
      <li>
        <strong> {View.text("Hydration")} </strong>
        {View.text(" - attach reactivity and event handlers to existing DOM")}
      </li>
    </ul>
    <p>
      {View.text("The key idea is that the client should not re-render what the server already produced. Hydration walks the server HTML, reconnects reactive boundaries, and continues from there.")}
    </p>

    <h3 id="render-on-the-server"> {View.text("Render on the Server")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("SSR.renderToString")} </code>
      {View.text(" for fragments and ")}
      <code> {View.text("SSR.renderToStringWithRoot")} </code>
      {View.text(" when you want a hydration root.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let app = () => {
  <div>
    <h1> {View.text("Hello from the server")} </h1>
  </div>
}

let html = SSR.renderToStringWithRoot(app, ~rootId="root")`)}
      </code>
    </pre>
    <h3 id="full-document-rendering"> {View.text("Full Document Rendering")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("SSR.renderDocument")} </code>
      {View.text(" when the server is responsible for the whole HTML document.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let html = SSR.renderDocument(
  ~head="<title>Xote App</title>",
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app,
)`)}
      </code>
    </pre>

    <h3 id="environment-detection"> {View.text("Environment Detection")} </h3>
    <p>
      {View.text("Use ")}
      <code> {View.text("SSRContext")} </code>
      {View.text(" when code needs to branch between server and client behavior.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let greeting = SSRContext.match(
  ~server=() => "Rendered on the server",
  ~client=() => "Rendered on the client",
)`)}
      </code>
    </pre>

    <h2 id="state-and-hydration"> {View.text("State and Hydration")} </h2>
    <h3 id="state-transfer"> {View.text("State Transfer")} </h3>
    <p>
      {View.text("If the server and client must start from the same state, create or register signals with ")}
      <code> {View.text("SSRState")} </code>
      {View.text(".")}
    </p>
    <h4 id="creating-synced-state"> {View.text("Creating Synced State")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = SSRState.signal("count", 0, SSRState.Codec.int)
let name = SSRState.signal("name", "Ada", SSRState.Codec.string)`)}
      </code>
    </pre>
    <h4 id="syncing-existing-signals"> {View.text("Syncing Existing Signals")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let draft = Signal.make("")
SSRState.syncSignal("draft", draft, SSRState.Codec.string)`)}
      </code>
    </pre>
    <h4 id="built-in-codecs"> {View.text("Built-in Codecs")} </h4>
    <p>
      {View.text("Use the built-in codecs for primitives and common containers, or create your own with ")}
      <code> {View.text("SSRState.Codec.make")} </code>
      {View.text(".")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`SSRState.Codec.int
SSRState.Codec.string
SSRState.Codec.bool
SSRState.Codec.array(SSRState.Codec.string)
SSRState.Codec.option(SSRState.Codec.int)
SSRState.Codec.tuple2(SSRState.Codec.int, SSRState.Codec.string)`)}
      </code>
    </pre>
    <p>
      {View.text("On long-lived servers that render more than one request, call ")}
      <code> {View.text("SSRState.clear()")} </code>
      {View.text(" between renders to reset the registry.")}
    </p>

    <h3 id="hydration"> {View.text("Client-Side Hydration")} </h3>
    <p>
      {View.text("Hydration connects the client runtime to server-rendered DOM without replacing it.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Hydration.hydrateById(app, "root", ~options={
  onHydrated: () => Console.log("hydrated"),
})`)}
      </code>
    </pre>

    <h2 id="ssr-in-practice"> {View.text("In Practice")} </h2>
    <h3 id="complete-example"> {View.text("Complete Example")} </h3>
    <p>
      {View.text("A typical setup shares the same component between server and client.")}
    </p>
    <h4 id="shared-component"> {View.text("Shared Component")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = SSRState.signal("count", 0, SSRState.Codec.int)

let app = () => {
  <div>
    <h1>
      {View.signalText(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {View.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <h4 id="server-entry"> {View.text("Server Entry")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.initSSR(~pathname="/", ())

let html = SSR.renderDocument(
  ~scripts=["/client.js"],
  ~stateScript=SSRState.generateScript(),
  app,
)`)}
      </code>
    </pre>
    <h4 id="client-entry"> {View.text("Client Entry")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.init()
Hydration.hydrateById(app, "root")`)}
      </code>
    </pre>

    <h3 id="hydration-markers"> {View.text("Hydration Markers")} </h3>
    <p>
      {View.text("Xote inserts HTML comments around reactive boundaries during SSR. The client uses those markers to find reactive view text, fragments, keyed lists, and lazy components while hydrating.")}
    </p>

    <h2 id="ssr-working-style"> {View.text("Working Style")} </h2>
    <h3 id="best-practices"> {View.text("Best Practices")} </h3>
    <ul>
      <li>
        {View.text("Render the same component tree on the server and the client so hydration can attach cleanly.")}
      </li>
      <li>
        {View.text("Initialize the router for the right environment: ")}
        <code> {View.text("initSSR")} </code>
        {View.text(" on the server, ")}
        <code> {View.text("init")} </code>
        {View.text(" on the client.")}
      </li>
      <li>
        {View.text("Clear ")}
        <code> {View.text("SSRState")} </code>
        {View.text(" between server renders, especially in custom or long-lived processes.")}
      </li>
      <li>
        {View.text("Choose codecs deliberately because they define the contract between serialized output and restored client state.")}
      </li>
    </ul>

    <h3 id="next-steps"> {View.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[View.text("Read Router")], ())}
        {View.text(" if these pages also depend on route state.")}
      </li>
      <li>
        {Router.link(~to="/docs/technical-overview", ~children=[View.text("Read the Technical Overview")], ())}
        {View.text(" if you want the internal model behind hydration and runtime ownership.")}
      </li>
    </ul>
  </div>
}
