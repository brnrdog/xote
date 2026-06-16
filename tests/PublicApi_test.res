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

      let prop = Prop.signal(name)
      let node: View.node = Html.div(
        ~attrs=[View.Attr.string("class", "app")],
        ~children=[View.text(Prop.get(prop))],
        (),
      )
      let emptyView: View.node = View.empty()

      let _jsxElement: XoteJSX.element = XoteJSX.null()
      let _routeResult = Route.matchPathname("/users/:id", "/users/1")
      let _routeConfig: Router.routeConfig = {pattern: "/", render: _params => View.null()}
      let _location: unit => Signal.t<Router.location> = Router.location
      let _renderOptions: SSR.renderOptions = {}
      let _hydrateOptions: Hydration.hydrateOptions = {}
      let _codec: SSRState.Codec.t<string> = SSRState.Codec.string
      let _ssrSignal = SSRState.signal("public-api-name", "xote", SSRState.Codec.string)
      let _isServer = SSRContext.isServer
      let mdxDoc: Mdx.document = _props => View.text("mdx")
      let _mdxComponents = Mdx.components([
        ("Example", Mdx.component((_props: Obj.t) => View.text("component"))),
      ])
      let html = SSR.renderToString(() => View.fragment([node, emptyView]))
      let mdxHtml = SSR.renderToString(() => Mdx.render(mdxDoc, ()))

      combineResults([
        assertEqual(Signal.peek(greeting), "hello xote"),
        assertEqual(html, `<div class="app">xote</div>`),
        assertEqual(mdxHtml, "mdx"),
      ])
    }),
  ],
)
