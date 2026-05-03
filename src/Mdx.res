type children = Obj.t

type components = dict<Obj.t => View.node>

type props = {components?: components}

type document = props => View.node

let component = (make: 'props => View.node): (Obj.t => View.node) =>
  props => make(Obj.magic(props))

let components = (entries: array<(string, Obj.t => View.node)>): components => Dict.fromArray(entries)

let render = (document: document, ~components=?, ()): View.node =>
  switch components {
  | Some(components) => document({components: components})
  | None => document({})
  }

@val @scope("Array") external isArray: 'a => bool = "isArray"
@val external toString: 'a => string = "String"

let isEmptyChild = (value: 'a): bool => {
  ignore(value)
  %raw(`value === null || value === undefined || typeof value === "boolean"`)
}

let isXoteNode = (value: 'a): bool => {
  ignore(value)
  %raw(`value && typeof value === "object" && (
    value.TAG === "Element" ||
    value.TAG === "Text" ||
    value.TAG === "SignalText" ||
    value.TAG === "Fragment" ||
    value.TAG === "SignalFragment" ||
    value.TAG === "Keyed" ||
    value.TAG === "LazyComponent" ||
    value.TAG === "KeyedList"
  )`)
}

let rec nodeToText = (node: View.node): string =>
  switch node {
  | Text(text) => text
  | Fragment(children) => children->Array.map(nodeToText)->Array.join("")
  | _ => ""
  }

let rec childrenToNodes = (children: children): array<View.node> => {
  if isEmptyChild(children) {
    []
  } else if isArray(children) {
    let result = []
    let childrenArray: array<children> = Obj.magic(children)
    childrenArray->Array.forEach(child => {
      childrenToNodes(child)->Array.forEach(node => result->Array.push(node)->ignore)
    })
    result
  } else if isXoteNode(children) {
    [Obj.magic(children)]
  } else {
    [View.text(toString(children))]
  }
}

let rec childrenToText = (children: children): string => {
  if isEmptyChild(children) {
    ""
  } else if isArray(children) {
    let childrenArray: array<children> = Obj.magic(children)
    childrenArray->Array.map(childrenToText)->Array.join("")
  } else if isXoteNode(children) {
    nodeToText(Obj.magic(children))
  } else {
    toString(children)
  }
}
