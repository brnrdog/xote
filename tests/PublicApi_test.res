open! Zekr

let suite = Zekr.suite(
  "Public API",
  [
    test("keeps documented modules and core entry points usable", () => {
      let name = Signal.make("xote")
      let greeting = Computed.make(() => "hello " ++ Signal.get(name))

      Effect.run(() => {
        ignore(Signal.get(greeting))
        None
      })

      let prop = ReactiveProp.reactive(name)
      let node: Node.node = Html.div(
        ~attrs=[Node.attr("class", "app")],
        ~children=[Node.text(ReactiveProp.get(prop))],
        (),
      )

      let _jsxElement: XoteJSX.element = XoteJSX.null()
      let _routeResult = Route.match("/users/:id", "/users/1")
      let _routeConfig: Router.routeConfig = {pattern: "/", render: _params => Node.null()}
      let _locationSignal: unit => Signal.t<Router.location> = Router.location
      let _renderOptions: SSR.renderOptions = {}
      let _hydrateOptions: Hydration.hydrateOptions = {}
      let _codec: SSRState.Codec.t<string> = SSRState.Codec.string
      let _isServer = SSRContext.isServer
      let html = SSR.renderToString(() => node)

      combineResults([
        assertEqual(Signal.peek(greeting), "hello xote"),
        assertEqual(html, `<div class="app">xote</div>`),
      ])
    }),
  ],
)
