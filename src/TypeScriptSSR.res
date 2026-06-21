@genType
type renderOptions = {
  nonce?: string,
  renderId?: string,
}

@genType
let renderNodeToString = (node: TypeScriptView.node): string =>
  SSR.renderNodeToString(Obj.magic(node))

@genType
let renderToString = (
  component: unit => TypeScriptView.node,
  ~options: option<renderOptions>=?,
): string =>
  switch options {
  | Some(options) => SSR.renderToString(() => Obj.magic(component()), ~options=Obj.magic(options))
  | None => SSR.renderToString(() => Obj.magic(component()))
  }

@genType
let renderToStringWithRoot = (
  component: unit => TypeScriptView.node,
  ~rootId: option<string>=?,
  ~options: option<renderOptions>=?,
): string =>
  switch options {
  | Some(options) =>
    SSR.renderToStringWithRoot(
      () => Obj.magic(component()),
      ~rootId?,
      ~options=Obj.magic(options),
    )
  | None => SSR.renderToStringWithRoot(() => Obj.magic(component()), ~rootId?)
  }

@genType
let generateHydrationScript = (~nonce: option<string>=?): string =>
  SSR.generateHydrationScript(~nonce?)

@genType
let renderDocument = (
  component: unit => TypeScriptView.node,
  ~head: option<string>=?,
  ~bodyAttrs: option<string>=?,
  ~scripts: option<array<string>>=?,
  ~styles: option<array<string>>=?,
  ~stateScript: option<string>=?,
  ~nonce: option<string>=?,
): string =>
  SSR.renderDocument(
    ~head?,
    ~bodyAttrs?,
    ~scripts?,
    ~styles?,
    ~stateScript?,
    ~nonce?,
    () => Obj.magic(component()),
  )
