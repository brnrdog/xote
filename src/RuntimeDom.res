module Core = RescriptCore

let svgNamespace = "http://www.w3.org/2000/svg"

let svgTags = [
  "svg",
  "path",
  "circle",
  "ellipse",
  "line",
  "polygon",
  "polyline",
  "rect",
  "g",
  "defs",
  "clipPath",
  "mask",
  "pattern",
  "marker",
  "symbol",
  "use",
  "text",
  "tspan",
  "image",
  "foreignObject",
  "linearGradient",
  "radialGradient",
  "stop",
  "filter",
  "feBlend",
  "feColorMatrix",
  "feComposite",
  "feFlood",
  "feGaussianBlur",
  "feMerge",
  "feMergeNode",
  "feOffset",
  "animate",
  "animateTransform",
  "desc",
  "title",
  "metadata",
]

let svgTagSet: Dict.t<bool> = {
  let d = Dict.make()
  svgTags->Array.forEach(tag => d->Dict.set(tag, true))
  d
}

let isSvgTag = (tag: string): bool => svgTagSet->Dict.get(tag)->Option.isSome

@val @scope("document") external createElement: string => Dom.element = "createElement"
@val @scope("document")
external createElementNS: (string, string) => Dom.element = "createElementNS"
@val @scope("document") external createTextNode: string => Dom.element = "createTextNode"
@val @scope("document")
external createDocumentFragment: unit => Dom.element = "createDocumentFragment"
@val @scope("document") external createComment: string => Dom.element = "createComment"
@val @scope("document")
external getElementById: string => Nullable.t<Dom.element> = "getElementById"

@get external getNextSibling: Dom.element => Nullable.t<Dom.element> = "nextSibling"
@get external getFirstChild: Dom.element => Nullable.t<Dom.element> = "firstChild"
@get external getParentNode: Dom.element => Nullable.t<Dom.element> = "parentNode"
@get external childNodes: Dom.element => Array.arrayLike<Dom.element> = "childNodes"

let childNodesToArray = (el: Dom.element): array<Dom.element> => {
  el->childNodes->Core.Array.fromArrayLike
}

@send
external addEventListener: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external remove: Dom.element => unit = "remove"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external removeAttribute: (Dom.element, string) => unit = "removeAttribute"
@send external replaceChild: (Dom.element, Dom.element, Dom.element) => unit = "replaceChild"
@send external insertBefore: (Dom.element, Dom.element, Dom.element) => unit = "insertBefore"
@set external setTextContent: (Dom.element, string) => unit = "textContent"
@set external setInnerHTML: (Dom.element, string) => unit = "innerHTML"
@set external setValue: (Dom.element, string) => unit = "value"
@set external setChecked: (Dom.element, bool) => unit = "checked"
@set external setDisabled: (Dom.element, bool) => unit = "disabled"

let createElementForTag = (tag: string): Dom.element =>
  isSvgTag(tag) ? createElementNS(svgNamespace, tag) : createElement(tag)

let setAttrOrProp = (el: Dom.element, key: string, value: string): unit => {
  switch key {
  | "value" => setValue(el, value)
  | "checked" => setChecked(el, value == "true")
  | "disabled" => setDisabled(el, value == "true")
  | _ if RuntimeAttr.isBoolean(key) =>
    if RuntimeAttr.shouldRenderBoolean(value) {
      setAttribute(el, key, "")
    } else {
      removeAttribute(el, key)
    }
  | _ => setAttribute(el, key, value)
  }
}
