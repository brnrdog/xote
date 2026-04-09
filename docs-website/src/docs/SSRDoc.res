let content = () => {
  <div>
    <h2 id="overview"> {Node.text("Overview")} </h2>
    <p>
      {Node.text("Xote provides full server-side rendering (SSR) with client-side hydration. You can render your components to HTML on the server, transfer state to the client, and hydrate the server-rendered DOM without re-rendering.")}
    </p>
    <p>
      {Node.text("The SSR system is built on three core modules:")}
    </p>
    <ul>
      <li>
        <strong> {Node.text("SSR")} </strong>
        {Node.text(" \u2014 renders components to HTML strings")}
      </li>
      <li>
        <strong> {Node.text("SSRState")} </strong>
        {Node.text(" \u2014 serializes and restores state between server and client")}
      </li>
      <li>
        <strong> {Node.text("Hydration")} </strong>
        {Node.text(" \u2014 walks server-rendered DOM and attaches reactivity")}
      </li>
    </ul>
    <h2 id="environment-detection"> {Node.text("Environment Detection")} </h2>
    <p>
      {Node.text("The ")}
      <code> {Node.text("SSRContext")} </code>
      {Node.text(" module provides runtime detection of the current environment:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

// Boolean checks
let isServer = SSRContext.isServer
let isClient = SSRContext.isClient

// Conditional execution
SSRContext.onServer(() => {
  Console.log("Running on the server")
})

SSRContext.onClient(() => {
  Console.log("Running in the browser")
})

// Environment branching
let greeting = SSRContext.match(
  ~server=() => "Rendered on server",
  ~client=() => "Running in browser",
)`)}
      </code>
    </pre>
    <p>
      {Node.text("This is useful for code that should only run in one environment, like DOM APIs on the client or file system access on the server.")}
    </p>
    <h2 id="rendering-to-html"> {Node.text("Rendering to HTML")} </h2>
    <p>
      {Node.text("The ")}
      <code> {Node.text("SSR")} </code>
      {Node.text(" module renders Xote components to HTML strings:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

let app = () => {
  <div>
    <h1> {Node.text("Hello from the server!")} </h1>
    <p> {Node.text("This was rendered as HTML.")} </p>
  </div>
}

// Basic render to string
let html = SSR.renderToString(app)

// With a root element ID for hydration
let html = SSR.renderToStringWithRoot(app, ~rootId="root")`)}
      </code>
    </pre>
    <h3 id="full-document-rendering"> {Node.text("Full Document Rendering")} </h3>
    <p>
      {Node.text("For a complete HTML document with head, scripts, and styles:")}
    </p>
    <pre>
      <code>
        {Node.text(`let html = SSR.renderDocument(
  ~head=\`
    <title>My App</title>
    <meta name="description" content="My Xote app" />
  \`,
  ~scripts=["./client.mjs"],
  ~styles=["./styles.css"],
  ~stateScript=SSRState.generateScript(),
  app,
)`)}
      </code>
    </pre>
    <p>
      {Node.text("The rendered HTML includes comment-based hydration markers (")}
      <code> {Node.text("<!--$-->")} </code>
      {Node.text(", ")}
      <code> {Node.text("<!--#-->")} </code>
      {Node.text(") that the hydration walker uses to attach reactivity without re-rendering.")}
    </p>
    <h2 id="state-transfer"> {Node.text("State Transfer")} </h2>
    <p>
      {Node.text("The ")}
      <code> {Node.text("SSRState")} </code>
      {Node.text(" module handles serializing state on the server and restoring it on the client. It uses a type-safe ")}
      <code> {Node.text("Codec")} </code>
      {Node.text(" system for encoding and decoding values.")}
    </p>
    <h3 id="creating-synced-state"> {Node.text("Creating Synced State")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

// SSRState.make creates a signal and registers it for sync
let count = SSRState.make("count", 0, SSRState.Codec.int)
let name = SSRState.make("name", "Alice", SSRState.Codec.string)

// On the server: the signal is created with the initial value,
// and registered for serialization.
// On the client: the signal is restored from the server-serialized
// value embedded in the HTML.`)}
      </code>
    </pre>
    <h3 id="built-in-codecs"> {Node.text("Built-in Codecs")} </h3>
    <p>
      {Node.text("SSRState.Codec provides codecs for common types:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("Codec.int")} </code>
        {Node.text(", ")}
        <code> {Node.text("Codec.float")} </code>
        {Node.text(", ")}
        <code> {Node.text("Codec.string")} </code>
        {Node.text(", ")}
        <code> {Node.text("Codec.bool")} </code>
      </li>
      <li>
        <code> {Node.text("Codec.array(itemCodec)")} </code>
        {Node.text(" \u2014 arrays of any codec type")}
      </li>
      <li>
        <code> {Node.text("Codec.option(itemCodec)")} </code>
        {Node.text(" \u2014 optional values")}
      </li>
      <li>
        <code> {Node.text("Codec.tuple2(a, b)")} </code>
        {Node.text(", ")}
        <code> {Node.text("Codec.tuple3(a, b, c)")} </code>
        {Node.text(" \u2014 tuples")}
      </li>
      <li>
        <code> {Node.text("Codec.dict(valueCodec)")} </code>
        {Node.text(" \u2014 dictionaries")}
      </li>
    </ul>
    <pre>
      <code>
        {Node.text(`// Array of strings
let items = SSRState.make(
  "items",
  ["Apple", "Banana"],
  SSRState.Codec.array(SSRState.Codec.string),
)

// Optional value
let selected = SSRState.make(
  "selected",
  None,
  SSRState.Codec.option(SSRState.Codec.int),
)

// Tuple
let position = SSRState.make(
  "pos",
  (0, 0),
  SSRState.Codec.tuple2(SSRState.Codec.int, SSRState.Codec.int),
)`)}
      </code>
    </pre>
    <h3 id="syncing-existing-signals"> {Node.text("Syncing Existing Signals")} </h3>
    <p>
      {Node.text("If you already have a signal, use ")}
      <code> {Node.text("SSRState.sync")} </code>
      {Node.text(" to register it:")}
    </p>
    <pre>
      <code>
        {Node.text(`let count = Signal.make(0)

// Register the signal for server/client sync
SSRState.sync("count", count, SSRState.Codec.int)`)}
      </code>
    </pre>
    <h3 id="generating-the-state-script"> {Node.text("Generating the State Script")} </h3>
    <p>
      {Node.text("On the server, call ")}
      <code> {Node.text("SSRState.generateScript()")} </code>
      {Node.text(" to produce a ")}
      <code> {Node.text("<script>")} </code>
      {Node.text(" tag that embeds the serialized state in the HTML. Pass it to ")}
      <code> {Node.text("SSR.renderDocument")} </code>
      {Node.text(" via the ")}
      <code> {Node.text("~stateScript")} </code>
      {Node.text(" parameter.")}
    </p>
    <h2 id="hydration"> {Node.text("Client-Side Hydration")} </h2>
    <p>
      {Node.text("Hydration walks the server-rendered DOM and attaches reactive effects, event listeners, and keyed list reconciliation \u2014 without re-rendering:")}
    </p>
    <pre>
      <code>
        {Node.text(`open Xote

// Hydrate by container element ID
Hydration.hydrateById(app, "root", ~options={
  onHydrated: () => Console.log("Hydration complete!"),
})

// Or hydrate with a DOM element reference
Hydration.hydrate(app, containerElement)`)}
      </code>
    </pre>
    <p>
      {Node.text("After hydration, the app becomes fully interactive. Subsequent updates use standard client-side rendering.")}
    </p>
    <h2 id="complete-example"> {Node.text("Complete Example")} </h2>
    <p>
      {Node.text("Here is a full SSR setup with a shared component, server entry, and client entry.")}
    </p>
    <h3 id="shared-component"> {Node.text("Shared Component (App.res)")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

let makeAppState = () => {
  let count = SSRState.make("count", 0, SSRState.Codec.int)
  let items = SSRState.make(
    "items",
    ["Apple", "Banana", "Cherry"],
    SSRState.Codec.array(SSRState.Codec.string),
  )
  let inputValue = Signal.make("")
  (count, items, inputValue)
}

let app = (count, items, inputValue) => () => {
  let increment = (_: Dom.event) =>
    Signal.update(count, n => n + 1)
  let decrement = (_: Dom.event) =>
    Signal.update(count, n => n - 1)

  <div>
    <h1> {Node.text("SSR Demo")} </h1>
    <p>
      {Node.text("Count: ")}
      {Node.signalText(() =>
        Signal.get(count)->Int.toString
      )}
    </p>
    <button onClick={decrement}>
      {Node.text("-")}
    </button>
    <button onClick={increment}>
      {Node.text("+")}
    </button>
    <ul>
      {Node.list(items, item =>
        <li> {Node.text(item)} </li>
      )}
    </ul>
  </div>
}`)}
      </code>
    </pre>
    <h3 id="server-entry"> {Node.text("Server Entry (server.res)")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

let (count, items, inputValue) = App.makeAppState()
let appComponent = App.app(count, items, inputValue)

let html = SSR.renderDocument(
  ~head=\`<title>My App</title>\`,
  ~scripts=["./client.res.mjs"],
  ~stateScript=SSRState.generateScript(),
  appComponent,
)

Console.log(html)`)}
      </code>
    </pre>
    <h3 id="client-entry"> {Node.text("Client Entry (client.res)")} </h3>
    <pre>
      <code>
        {Node.text(`open Xote

let (count, items, inputValue) = App.makeAppState()
let appComponent = App.app(count, items, inputValue)

let _ = Hydration.hydrateById(appComponent, "root", ~options={
  onHydrated: () => Console.log("Hydration complete!"),
})`)}
      </code>
    </pre>
    <div class="info-box">
      <p>
        <strong> {Node.text("Note:")} </strong>
        {Node.text(" The shared component uses ")}
        <code> {Node.text("SSRState.make")} </code>
        {Node.text(" so the same code works on both server and client. On the server, signals are created with initial values and registered for serialization. On the client, they are automatically restored from the serialized state.")}
      </p>
    </div>
    <h2 id="hydration-markers"> {Node.text("How Hydration Markers Work")} </h2>
    <p>
      {Node.text("During SSR, Xote inserts HTML comment nodes to mark reactive boundaries:")}
    </p>
    <ul>
      <li>
        <code> {Node.text("<!--$-->")} </code>
        {Node.text(" \u2014 signal text boundary")}
      </li>
      <li>
        <code> {Node.text("<!--#-->")} </code>
        {Node.text(" \u2014 signal fragment boundary")}
      </li>
      <li>
        <code> {Node.text("<!--kl-->")} </code>
        {Node.text(" \u2014 keyed list start")}
      </li>
      <li>
        <code> {Node.text("<!--k:KEY-->")} </code>
        {Node.text(" \u2014 keyed list item with key")}
      </li>
      <li>
        <code> {Node.text("<!--lc-->")} </code>
        {Node.text(" \u2014 lazy component boundary")}
      </li>
    </ul>
    <p>
      {Node.text("The hydration walker reads these markers to know where to attach effects, event listeners, and reconciliation logic. This avoids re-rendering the DOM from scratch.")}
    </p>
    <h2 id="best-practices"> {Node.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Node.text("Use SSRState.make for shared state:")} </strong>
        {Node.text(" It handles both creation and sync in one call")}
      </li>
      <li>
        <strong> {Node.text("Guard client-only code:")} </strong>
        {Node.text(" Use ")}
        <code> {Node.text("SSRContext.onClient")} </code>
        {Node.text(" for DOM APIs, timers, and browser features")}
      </li>
      <li>
        <strong> {Node.text("Keep components isomorphic:")} </strong>
        {Node.text(" The same component function should work on both server and client")}
      </li>
      <li>
        <strong> {Node.text("Don't sync ephemeral state:")} </strong>
        {Node.text(" Input values and UI state that resets on page load don't need SSRState")}
      </li>
      <li>
        <strong> {Node.text("Match component trees:")} </strong>
        {Node.text(" The client must render the same component tree as the server for hydration to succeed")}
      </li>
    </ul>
    <h2 id="next-steps"> {Node.text("Next Steps")} </h2>
    <ul>
      <li>
        {Node.text("Learn about ")}
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Node.text("Signals")], ())}
        {Node.text(" \u2014 the reactive primitives behind SSR state")}
      </li>
      <li>
        {Node.text("Explore ")}
        {Router.link(~to="/docs/components/overview", ~children=[Node.text("Components")], ())}
        {Node.text(" \u2014 building the component tree")}
      </li>
      <li>
        {Node.text("See the ")}
        {Router.link(~to="/docs/technical-overview", ~children=[Node.text("Technical Overview")], ())}
        {Node.text(" for architecture details")}
      </li>
    </ul>
  </div>
}
