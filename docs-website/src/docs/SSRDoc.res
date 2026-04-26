let content = () => {
  <div>
    <h2 id="rendering-model"> {Node.text("Rendering Model")} </h2>
    <h3 id="overview"> {Node.text("Overview")} </h3>
    <p>
      {Node.text("Xote's SSR story is built from three modules that line up with the render flow:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("SSR")} </strong>
        {Node.text(" - render nodes to HTML")}
      </li>
      <li>
        <strong> {Node.text("SSRState")} </strong>
        {Node.text(" - serialize state on the server and restore it on the client")}
      </li>
      <li>
        <strong> {Node.text("Hydration")} </strong>
        {Node.text(" - attach reactivity and event handlers to existing DOM")}
      </li>
    </ul>
    <p>
      {Node.text("The key idea is that the client should not re-render what the server already produced. Hydration walks the server HTML, reconnects reactive boundaries, and continues from there.")}
    </p>

    <h3 id="render-on-the-server"> {Node.text("Render on the Server")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("SSR.renderToString")} </code>
      {Node.text(" for fragments and ")}
      <code> {Node.text("SSR.renderToStringWithRoot")} </code>
      {Node.text(" when you want a hydration root.")}
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
    <h3 id="full-document-rendering"> {Node.text("Full Document Rendering")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("SSR.renderDocument")} </code>
      {Node.text(" when the server is responsible for the whole HTML document.")}
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

    <h3 id="environment-detection"> {Node.text("Environment Detection")} </h3>
    <p>
      {Node.text("Use ")}
      <code> {Node.text("SSRContext")} </code>
      {Node.text(" when code needs to branch between server and client behavior.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let greeting = SSRContext.match(
  ~server=() => "Rendered on the server",
  ~client=() => "Rendered on the client",
)`)}
      </code>
    </pre>

    <h2 id="state-and-hydration"> {Node.text("State and Hydration")} </h2>
    <h3 id="state-transfer"> {Node.text("State Transfer")} </h3>
    <p>
      {Node.text("If the server and client must start from the same state, create or register signals with ")}
      <code> {Node.text("SSRState")} </code>
      {Node.text(".")}
    </p>
    <h4 id="creating-synced-state"> {Node.text("Creating Synced State")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let count = SSRState.signal("count", 0, SSRState.Codec.int)
let name = SSRState.signal("name", "Ada", SSRState.Codec.string)`)}
      </code>
    </pre>
    <h4 id="syncing-existing-signals"> {Node.text("Syncing Existing Signals")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`let draft = Signal.make("")
SSRState.syncSignal("draft", draft, SSRState.Codec.string)`)}
      </code>
    </pre>
    <h4 id="built-in-codecs"> {Node.text("Built-in Codecs")} </h4>
    <p>
      {Node.text("Use the built-in codecs for primitives and common containers, or create your own with ")}
      <code> {Node.text("SSRState.Codec.make")} </code>
      {Node.text(".")}
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
      {Node.text("On long-lived servers that render more than one request, call ")}
      <code> {Node.text("SSRState.clear()")} </code>
      {Node.text(" between renders to reset the registry.")}
    </p>

    <h3 id="hydration"> {Node.text("Client-Side Hydration")} </h3>
    <p>
      {Node.text("Hydration connects the client runtime to server-rendered DOM without replacing it.")}
    </p>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Hydration.hydrateById(app, "root", ~options={
  onHydrated: () => Console.log("hydrated"),
})`)}
      </code>
    </pre>

    <h2 id="ssr-in-practice"> {Node.text("In Practice")} </h2>
    <h3 id="complete-example"> {Node.text("Complete Example")} </h3>
    <p>
      {Node.text("A typical setup shares the same component between server and client.")}
    </p>
    <h4 id="shared-component"> {Node.text("Shared Component")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`open Xote

let count = SSRState.signal("count", 0, SSRState.Codec.int)

let app = () => {
  <div>
    <h1>
      {View.computedText(() => "Count: " ++ Int.toString(Signal.get(count)))}
    </h1>
    <button onClick={_ => Signal.update(count, n => n + 1)}>
      {View.text("Increment")}
    </button>
  </div>
}`)}
      </code>
    </pre>
    <h4 id="server-entry"> {Node.text("Server Entry")} </h4>
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
    <h4 id="client-entry"> {Node.text("Client Entry")} </h4>
    <pre class="docs-code-pre">
      <code>
        {SyntaxHighlight.highlight(`Router.init()
Hydration.hydrateById(app, "root")`)}
      </code>
    </pre>

    <h3 id="hydration-markers"> {Node.text("Hydration Markers")} </h3>
    <p>
      {Node.text("Xote inserts HTML comments around reactive boundaries during SSR. The client uses those markers to find reactive view text, fragments, keyed lists, and lazy components while hydrating.")}
    </p>

    <h2 id="ssr-working-style"> {Node.text("Working Style")} </h2>
    <h3 id="best-practices"> {Node.text("Best Practices")} </h3>
    <ul>
      <li>
        {Node.text("Render the same component tree on the server and the client so hydration can attach cleanly.")}
      </li>
      <li>
        {Node.text("Initialize the router for the right environment: ")}
        <code> {Node.text("initSSR")} </code>
        {Node.text(" on the server, ")}
        <code> {Node.text("init")} </code>
        {Node.text(" on the client.")}
      </li>
      <li>
        {Node.text("Clear ")}
        <code> {Node.text("SSRState")} </code>
        {Node.text(" between server renders, especially in custom or long-lived processes.")}
      </li>
      <li>
        {Node.text("Choose codecs deliberately because they define the contract between serialized output and restored client state.")}
      </li>
    </ul>

    <h3 id="next-steps"> {Node.text("Next Steps")} </h3>
    <ul>
      <li>
        {Router.link(~to="/docs/router/overview", ~children=[Node.text("Read Router")], ())}
        {Node.text(" if these pages also depend on route state.")}
      </li>
      <li>
        {Router.link(~to="/docs/technical-overview", ~children=[Node.text("Read the Technical Overview")], ())}
        {Node.text(" if you want the internal model behind hydration and runtime ownership.")}
      </li>
    </ul>
  </div>
}
