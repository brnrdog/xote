open Xote

let content = () => {
  <div>
    <h2 id="overview"> {Component.text("Overview")} </h2>
    <p>
      {Component.text("Xote provides full server-side rendering (SSR) with client-side hydration. You can render your components to HTML on the server, transfer state to the client, and hydrate the server-rendered DOM without re-rendering.")}
    </p>
    <p>
      {Component.text("The SSR system is built on three core modules:")}
    </p>
    <ul>
      <li>
        <strong> {Component.text("SSR")} </strong>
        {Component.text(" \u2014 renders components to HTML strings")}
      </li>
      <li>
        <strong> {Component.text("SSRState")} </strong>
        {Component.text(" \u2014 serializes and restores state between server and client")}
      </li>
      <li>
        <strong> {Component.text("Hydration")} </strong>
        {Component.text(" \u2014 walks server-rendered DOM and attaches reactivity")}
      </li>
    </ul>
    <h2 id="environment-detection"> {Component.text("Environment Detection")} </h2>
    <p>
      {Component.text("The ")}
      <code> {Component.text("SSRContext")} </code>
      {Component.text(" module provides runtime detection of the current environment:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

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
      {Component.text("This is useful for code that should only run in one environment, like DOM APIs on the client or file system access on the server.")}
    </p>
    <h2 id="rendering-to-html"> {Component.text("Rendering to HTML")} </h2>
    <p>
      {Component.text("The ")}
      <code> {Component.text("SSR")} </code>
      {Component.text(" module renders Xote components to HTML strings:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

let app = () => {
  <div>
    <h1> {Component.text("Hello from the server!")} </h1>
    <p> {Component.text("This was rendered as HTML.")} </p>
  </div>
}

// Basic render to string
let html = SSR.renderToString(app)

// With a root element ID for hydration
let html = SSR.renderToStringWithRoot(app, ~rootId="root")`)}
      </code>
    </pre>
    <h3 id="full-document-rendering"> {Component.text("Full Document Rendering")} </h3>
    <p>
      {Component.text("For a complete HTML document with head, scripts, and styles:")}
    </p>
    <pre>
      <code>
        {Component.text(`let html = SSR.renderDocument(
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
      {Component.text("The rendered HTML includes comment-based hydration markers (")}
      <code> {Component.text("<!--$-->")} </code>
      {Component.text(", ")}
      <code> {Component.text("<!--#-->")} </code>
      {Component.text(") that the hydration walker uses to attach reactivity without re-rendering.")}
    </p>
    <h2 id="state-transfer"> {Component.text("State Transfer")} </h2>
    <p>
      {Component.text("The ")}
      <code> {Component.text("SSRState")} </code>
      {Component.text(" module handles serializing state on the server and restoring it on the client. It uses a type-safe ")}
      <code> {Component.text("Codec")} </code>
      {Component.text(" system for encoding and decoding values.")}
    </p>
    <h3 id="creating-synced-state"> {Component.text("Creating Synced State")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

// SSRState.make creates a signal and registers it for sync
let count = SSRState.make("count", 0, SSRState.Codec.int)
let name = SSRState.make("name", "Alice", SSRState.Codec.string)

// On the server: the signal is created with the initial value,
// and registered for serialization.
// On the client: the signal is restored from the server-serialized
// value embedded in the HTML.`)}
      </code>
    </pre>
    <h3 id="built-in-codecs"> {Component.text("Built-in Codecs")} </h3>
    <p>
      {Component.text("SSRState.Codec provides codecs for common types:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("Codec.int")} </code>
        {Component.text(", ")}
        <code> {Component.text("Codec.float")} </code>
        {Component.text(", ")}
        <code> {Component.text("Codec.string")} </code>
        {Component.text(", ")}
        <code> {Component.text("Codec.bool")} </code>
      </li>
      <li>
        <code> {Component.text("Codec.array(itemCodec)")} </code>
        {Component.text(" \u2014 arrays of any codec type")}
      </li>
      <li>
        <code> {Component.text("Codec.option(itemCodec)")} </code>
        {Component.text(" \u2014 optional values")}
      </li>
      <li>
        <code> {Component.text("Codec.tuple2(a, b)")} </code>
        {Component.text(", ")}
        <code> {Component.text("Codec.tuple3(a, b, c)")} </code>
        {Component.text(" \u2014 tuples")}
      </li>
      <li>
        <code> {Component.text("Codec.dict(valueCodec)")} </code>
        {Component.text(" \u2014 dictionaries")}
      </li>
    </ul>
    <pre>
      <code>
        {Component.text(`// Array of strings
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
    <h3 id="syncing-existing-signals"> {Component.text("Syncing Existing Signals")} </h3>
    <p>
      {Component.text("If you already have a signal, use ")}
      <code> {Component.text("SSRState.sync")} </code>
      {Component.text(" to register it:")}
    </p>
    <pre>
      <code>
        {Component.text(`let count = Signal.make(0)

// Register the signal for server/client sync
SSRState.sync("count", count, SSRState.Codec.int)`)}
      </code>
    </pre>
    <h3 id="generating-the-state-script"> {Component.text("Generating the State Script")} </h3>
    <p>
      {Component.text("On the server, call ")}
      <code> {Component.text("SSRState.generateScript()")} </code>
      {Component.text(" to produce a ")}
      <code> {Component.text("<script>")} </code>
      {Component.text(" tag that embeds the serialized state in the HTML. Pass it to ")}
      <code> {Component.text("SSR.renderDocument")} </code>
      {Component.text(" via the ")}
      <code> {Component.text("~stateScript")} </code>
      {Component.text(" parameter.")}
    </p>
    <h2 id="hydration"> {Component.text("Client-Side Hydration")} </h2>
    <p>
      {Component.text("Hydration walks the server-rendered DOM and attaches reactive effects, event listeners, and keyed list reconciliation \u2014 without re-rendering:")}
    </p>
    <pre>
      <code>
        {Component.text(`open Xote

// Hydrate by container element ID
Hydration.hydrateById(app, "root", ~options={
  onHydrated: () => Console.log("Hydration complete!"),
})

// Or hydrate with a DOM element reference
Hydration.hydrate(app, containerElement)`)}
      </code>
    </pre>
    <p>
      {Component.text("After hydration, the app becomes fully interactive. Subsequent updates use standard client-side rendering.")}
    </p>
    <h2 id="complete-example"> {Component.text("Complete Example")} </h2>
    <p>
      {Component.text("Here is a full SSR setup with a shared component, server entry, and client entry.")}
    </p>
    <h3 id="shared-component"> {Component.text("Shared Component (App.res)")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

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
    <h1> {Component.text("SSR Demo")} </h1>
    <p>
      {Component.text("Count: ")}
      {Component.textSignal(() =>
        Signal.get(count)->Int.toString
      )}
    </p>
    <button onClick={decrement}>
      {Component.text("-")}
    </button>
    <button onClick={increment}>
      {Component.text("+")}
    </button>
    <ul>
      {Component.list(items, item =>
        <li> {Component.text(item)} </li>
      )}
    </ul>
  </div>
}`)}
      </code>
    </pre>
    <h3 id="server-entry"> {Component.text("Server Entry (server.res)")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

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
    <h3 id="client-entry"> {Component.text("Client Entry (client.res)")} </h3>
    <pre>
      <code>
        {Component.text(`open Xote

let (count, items, inputValue) = App.makeAppState()
let appComponent = App.app(count, items, inputValue)

let _ = Hydration.hydrateById(appComponent, "root", ~options={
  onHydrated: () => Console.log("Hydration complete!"),
})`)}
      </code>
    </pre>
    <div class="info-box">
      <p>
        <strong> {Component.text("Note:")} </strong>
        {Component.text(" The shared component uses ")}
        <code> {Component.text("SSRState.make")} </code>
        {Component.text(" so the same code works on both server and client. On the server, signals are created with initial values and registered for serialization. On the client, they are automatically restored from the serialized state.")}
      </p>
    </div>
    <h2 id="hydration-markers"> {Component.text("How Hydration Markers Work")} </h2>
    <p>
      {Component.text("During SSR, Xote inserts HTML comment nodes to mark reactive boundaries:")}
    </p>
    <ul>
      <li>
        <code> {Component.text("<!--$-->")} </code>
        {Component.text(" \u2014 signal text boundary")}
      </li>
      <li>
        <code> {Component.text("<!--#-->")} </code>
        {Component.text(" \u2014 signal fragment boundary")}
      </li>
      <li>
        <code> {Component.text("<!--kl-->")} </code>
        {Component.text(" \u2014 keyed list start")}
      </li>
      <li>
        <code> {Component.text("<!--k:KEY-->")} </code>
        {Component.text(" \u2014 keyed list item with key")}
      </li>
      <li>
        <code> {Component.text("<!--lc-->")} </code>
        {Component.text(" \u2014 lazy component boundary")}
      </li>
    </ul>
    <p>
      {Component.text("The hydration walker reads these markers to know where to attach effects, event listeners, and reconciliation logic. This avoids re-rendering the DOM from scratch.")}
    </p>
    <h2 id="best-practices"> {Component.text("Best Practices")} </h2>
    <ul>
      <li>
        <strong> {Component.text("Use SSRState.make for shared state:")} </strong>
        {Component.text(" It handles both creation and sync in one call")}
      </li>
      <li>
        <strong> {Component.text("Guard client-only code:")} </strong>
        {Component.text(" Use ")}
        <code> {Component.text("SSRContext.onClient")} </code>
        {Component.text(" for DOM APIs, timers, and browser features")}
      </li>
      <li>
        <strong> {Component.text("Keep components isomorphic:")} </strong>
        {Component.text(" The same component function should work on both server and client")}
      </li>
      <li>
        <strong> {Component.text("Don't sync ephemeral state:")} </strong>
        {Component.text(" Input values and UI state that resets on page load don't need SSRState")}
      </li>
      <li>
        <strong> {Component.text("Match component trees:")} </strong>
        {Component.text(" The client must render the same component tree as the server for hydration to succeed")}
      </li>
    </ul>
    <h2 id="next-steps"> {Component.text("Next Steps")} </h2>
    <ul>
      <li>
        {Component.text("Learn about ")}
        {Router.link(~to="/docs/core-concepts/signals", ~children=[Component.text("Signals")], ())}
        {Component.text(" \u2014 the reactive primitives behind SSR state")}
      </li>
      <li>
        {Component.text("Explore ")}
        {Router.link(~to="/docs/components/overview", ~children=[Component.text("Components")], ())}
        {Component.text(" \u2014 building the component tree")}
      </li>
      <li>
        {Component.text("See the ")}
        {Router.link(~to="/docs/technical-overview", ~children=[Component.text("Technical Overview")], ())}
        {Component.text(" for architecture details")}
      </li>
    </ul>
  </div>
}
