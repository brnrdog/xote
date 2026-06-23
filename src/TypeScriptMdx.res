@genType
type children = Obj.t

@genType
type components = dict<Obj.t => TypeScriptView.node>

@genType
type props = {components?: components}

@genType
type document = props => TypeScriptView.node

@genType
let component = (make: 'props => TypeScriptView.node): (Obj.t => TypeScriptView.node) =>
  props => make(Obj.magic(props))

@genType
let components = (entries: array<(string, Obj.t => TypeScriptView.node)>): components =>
  Obj.magic(Dict.fromArray(entries))

@genType
let render = (document: document, ~components: option<components>=?): TypeScriptView.node =>
  Obj.magic(Mdx.render(Obj.magic(document), ~components=Obj.magic(components), ()))

@genType
let childrenToNodes = (children: children): array<TypeScriptView.node> =>
  Obj.magic(Mdx.childrenToNodes(Obj.magic(children)))

@genType
let childrenToText = (children: children): string => Mdx.childrenToText(children)
