@genType
type location = {
  pathname: string,
  search: string,
  hash: string,
}

@genType
type routeConfig = {
  pattern: string,
  render: TypeScriptRoute.params => TypeScriptView.node,
}

@genType
let init = (~basePath: option<string>=?): unit => {
  Router.init(~basePath?, ())
}

@genType
let initSSR = (
  ~basePath: option<string>=?,
  ~pathname: option<string>=?,
  ~search: option<string>=?,
  ~hash: option<string>=?,
): unit => {
  Router.initSSR(~basePath?, ~pathname?, ~search?, ~hash?, ())
}

@genType
let location = (): TypeScriptSignal.t<location> => Obj.magic(Router.location())

@genType
let push = (pathname: string, ~search: option<string>=?, ~hash: option<string>=?): unit => {
  Router.push(pathname, ~search?, ~hash?, ())
}

@genType
let replace = (pathname: string, ~search: option<string>=?, ~hash: option<string>=?): unit => {
  Router.replace(pathname, ~search?, ~hash?, ())
}

@genType
let route = (
  pattern: string,
  render: TypeScriptRoute.params => TypeScriptView.node,
): TypeScriptView.node =>
  Obj.magic(Router.route(pattern, params => Obj.magic(render(Obj.magic(params)))))

@genType
let routes = (configs: array<routeConfig>): TypeScriptView.node =>
  Obj.magic(Router.routes(Obj.magic(configs)))

@genType
let link = (
  to: string,
  ~attrs: array<(string, TypeScriptView.attrValue)>=[],
  ~children: array<TypeScriptView.node>=[],
): TypeScriptView.node =>
  Obj.magic(Router.link(~to, ~attrs=Obj.magic(attrs), ~children=Obj.magic(children), ()))

@genType
let normalizeBasePath = Router.normalizeBasePath

@genType
let stripBasePath = Router.stripBasePath

@genType
let addBasePath = Router.addBasePath
