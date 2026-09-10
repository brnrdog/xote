/* Everything a downstream package is allowed to rely on.

   This file must keep compiling: it is the positive half of the boundary
   guarantee. Anything removed from a `.resi` shows up here as a build failure. */

/* ---------------------------------------------------------------- reactivity */

let count = Xote.Signal.make(0, ~name="count")
let doubled = Xote.Computed.make(() => Xote.Signal.get(count) * 2, ~name="doubled")

let () = Xote.Effect.run(() => {
  ignore(Xote.Signal.get(doubled))
  None
})

let disposer = Xote.Effect.runWithDisposer(() => None)
let () = disposer.dispose()

let () = Xote.Signal.batch(() => {
  Xote.Signal.set(count, 1)
  Xote.Signal.update(count, n => n + 1)
})

let peeked = Xote.Signal.peek(count)
let untracked = Xote.Signal.untrack(() => Xote.Signal.get(count))
let () = Xote.Computed.dispose(doubled)

/* ---------------------------------------------------------------------- view */

let label = Xote.Signal.make("hello")

let node = Xote.Html.div(
  ~attrs=[
    Xote.View.attr("class", "app"),
    Xote.View.signalAttr("title", label),
    Xote.View.computedAttr("data-count", () => Xote.Signal.get(count)->Int.toString),
    Xote.View.optionalAttr("data-open", Some("")),
    Xote.View.optionalSignalAttr("data-label", Xote.Computed.make(() => Some("x"))),
    Xote.View.optionalComputedAttr("data-empty", () => None),
    Xote.View.Attr.string("id", "root"),
    Xote.View.Attr.optional("data-flag", None),
    Xote.View.Attr.optionalSignal("data-name", Xote.Computed.make(() => None)),
    Xote.View.Attr.optionalCompute("data-other", () => Some("y")),
  ],
  ~events=[("click", _evt => Xote.Signal.update(count, n => n + 1))],
  ~children=[
    Xote.View.text("static"),
    Xote.View.signalText(() => Xote.Signal.get(label)),
    Xote.View.signalInt(() => Xote.Signal.get(count)),
    Xote.View.signalFloat(() => 1.5),
    Xote.View.int(1),
    Xote.View.float(1.5),
    Xote.View.bool(true),
    Xote.View.null(),
    Xote.View.empty(),
    Xote.View.element("span", ~children=[Xote.View.text("via element")], ()),
  ],
  (),
)

let items = Xote.Signal.make([1, 2, 3])
let plainList = Xote.View.each(items, item => Xote.View.int(item))
let keyedList = Xote.View.eachWithKey(
  items,
  item => Int.toString(item),
  item => Xote.View.int(item),
)
let group = Xote.View.fragment([node, plainList, keyedList])

let nodes = Xote.Signal.make([Xote.View.text("a")])
let reactiveGroup = Xote.View.signalFragment(nodes)

/* `tracked`, `child` and `probe` are what `@xote.component` emits into consumer
   code, so sealing any of them would break every annotated component. */
let trackedBlock = Xote.View.tracked(() => Xote.View.int(Xote.Signal.get(count)))
let coercedChild = Xote.View.child("bare")
let coercedSignalChild = Xote.View.child(label)
let probedLeaf: int = Xote.View.probe("DocumentedApi.res:1:1", () => Xote.Signal.get(count))

/* `node` is a public variant: consumers may pattern-match on it */
let describe = (node: Xote.View.node): string =>
  switch node {
  | Text(_) => "text"
  | Element(_) => "element"
  | Fragment(_) => "fragment"
  | SignalText(_) => "signal-text"
  | SignalFragment(_) => "signal-fragment"
  | Keyed(_) => "keyed"
  | LazyComponent(_) => "lazy"
  | KeyedList(_) => "keyed-list"
  }

let describeAttr = (attr: Xote.View.attrValue): string =>
  switch attr {
  | Static(_) => "static"
  | SignalValue(_) => "signal"
  | Compute(_) => "compute"
  | OptionalStatic(_) => "optional-static"
  | OptionalSignalValue(_) => "optional-signal"
  | OptionalCompute(_) => "optional-compute"
  }

/* -------------------------------------------------------------- maybe-signal */

let staticValue = Xote.MaybeSignal.static("a")
let reactiveValue = Xote.MaybeSignal.reactive(label)
let computedValue = Xote.MaybeSignal.computed(() => Xote.Signal.get(label) ++ "!")
let read = Xote.MaybeSignal.get(staticValue)
let peekedValue = Xote.MaybeSignal.peek(reactiveValue)
let reactiveFlag = Xote.MaybeSignal.isReactive(reactiveValue)
let staticFlag = Xote.MaybeSignal.isStatic(staticValue)
let mapped = Xote.MaybeSignal.map(reactiveValue, String.length)
let asSignal = Xote.MaybeSignal.toSignal(staticValue)
let coerced: Xote.MaybeSignal.t<string> = Xote.MaybeSignal.ofUnknown("raw")

let describeMaybeSignal = (value: Xote.MaybeSignal.t<string>): string =>
  switch value {
  | Static(_) => "static"
  | Reactive(_) => "reactive"
  }

/* ------------------------------------------------------------ JSX components */

let jsxTree =
  <div class="wrapper" attrs=[("aria-valuenow", "3"), ("data-state", "open")]>
    <Xote.View.Show when_={Xote.MaybeSignal.static(true)} fallback={Xote.View.text("no")}>
      {Xote.View.text("yes")}
    </Xote.View.Show>
    <Xote.View.For each={Xote.MaybeSignal.reactive(items)} render={item => Xote.View.int(item)} />
    <Xote.View.KeyedFor
      each={Xote.MaybeSignal.reactive(items)}
      by={item => Int.toString(item)}
      render={item => Xote.View.int(item)}
    />
    <Xote.View.Maybe value={Xote.MaybeSignal.static(Some(1))} render={value => Xote.View.int(value)} />
    <Xote.View.Value value={Xote.MaybeSignal.static(1)} render={value => Xote.View.int(value)} />
    <Xote.View.Text value="text" />
    <Xote.View.Int value=1 />
    <Xote.View.Float value=1.5 />
    <Xote.View.Bool value=true />
  </div>

let jsxElement: Xote.XoteJSX.element = Xote.XoteJSX.null()
let jsxArray = Xote.XoteJSX.array([Xote.View.text("a")])

/* --------------------------------------------------------------------- route */

let routeResult = Xote.Route.match("/users/:id", "/users/1")
let routeParams: option<Xote.Route.params> = switch routeResult {
| Match(params) => Some(params)
| NoMatch => None
}

/* -------------------------------------------------------------------- router */

let () = Xote.Router.initSSR(~basePath="/app", ~pathname="/", ())
let location: unit => Xote.Signal.t<Xote.Router.location> = Xote.Router.location
let singleRoute = Xote.Router.route("/", _params => Xote.View.text("home"))
let routeConfig: Xote.Router.routeConfig = {pattern: "/", render: _params => Xote.View.null()}
let allRoutes = Xote.Router.routes([routeConfig])
let anchor = Xote.Router.link(~to="/about", ~children=[Xote.View.text("about")], ())
let jsxAnchor =
  <Xote.Router.Link to="/about" class="nav" attrs=[("aria-current", "page")]>
    {Xote.View.text("about")}
  </Xote.Router.Link>

/* ----------------------------------------------------------------------- ssr */

let renderOptions: Xote.SSR.renderOptions = {}
let html = Xote.SSR.renderToString(() => group, ~options=renderOptions)
let rooted = Xote.SSR.renderToStringWithRoot(() => group, ~rootId="root")
let hydrationScript = Xote.SSR.generateHydrationScript()
let document = Xote.SSR.renderDocument(~scripts=["/client.js"], () => group)

let isServer = Xote.SSRContext.isServer
let isClient = Xote.SSRContext.isClient
let onServer = Xote.SSRContext.onServer(() => 1)
let onClient = Xote.SSRContext.onClient(() => 1)
let branched = Xote.SSRContext.match(~server=() => 1, ~client=() => 2)

let codec: Xote.SSRState.Codec.t<string> = Xote.SSRState.Codec.string
let pairCodec = Xote.SSRState.Codec.tuple2(Xote.SSRState.Codec.int, Xote.SSRState.Codec.float)
let listCodec = Xote.SSRState.Codec.array(Xote.SSRState.Codec.bool)
let maybeCodec = Xote.SSRState.Codec.option(Xote.SSRState.Codec.string)
let dictCodec = Xote.SSRState.Codec.dict(Xote.SSRState.Codec.string)
let tripleCodec = Xote.SSRState.Codec.tuple3(
  Xote.SSRState.Codec.int,
  Xote.SSRState.Codec.int,
  Xote.SSRState.Codec.int,
)
let customCodec = Xote.SSRState.Codec.make(~encode=JSON.Encode.string, ~decode=JSON.Decode.string)
let syncedSignal = Xote.SSRState.signal("name", "xote", codec)
let () = Xote.SSRState.sync("name", syncedSignal, codec)
let () = Xote.SSRState.register("name", syncedSignal, codec)
let () = Xote.SSRState.restore("name", syncedSignal, codec)
let clientState = Xote.SSRState.getClientState()
let stateScript = Xote.SSRState.generateScript()
let () = Xote.SSRState.clear()

/* --------------------------------------------------------------- hydration */

let hydrateOptions: Xote.Hydration.hydrateOptions = {}
let hydrate: (unit => Xote.View.node, Dom.element) => unit = (component, container) =>
  Xote.Hydration.hydrate(component, container, ~options=hydrateOptions)
let hydrateById: (unit => Xote.View.node) => unit = component =>
  Xote.Hydration.hydrateById(component, "root")

/* --------------------------------------------------------------------- mdx */

let mdxDocument: Xote.Mdx.document = _props => Xote.View.text("mdx")
let mdxComponents = Xote.Mdx.components([
  ("Example", Xote.Mdx.component((_props: Obj.t) => Xote.View.text("component"))),
])
let mdxNode = Xote.Mdx.render(mdxDocument, ~components=mdxComponents, ())
let mdxChildren: Xote.Mdx.children = Obj.magic("text")
let mdxNodes = Xote.Mdx.childrenToNodes(mdxChildren)
let mdxText = Xote.Mdx.childrenToText(mdxChildren)

/* --------------------------------------------------------------- mounting */

let mount: Dom.element => unit = container => Xote.View.mount(group, container)
let mountById = () => Xote.View.mountById(group, "root")
