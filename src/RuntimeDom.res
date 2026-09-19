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

let isDocumentFragment: Dom.element => bool = %raw(`function (node) {
  return node != null && node.nodeType === 11
}`)

@send
external addEventListener: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external remove: Dom.element => unit = "remove"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send external removeAttribute: (Dom.element, string) => unit = "removeAttribute"
@send external replaceChild: (Dom.element, Dom.element, Dom.element) => unit = "replaceChild"
@send external insertBefore: (Dom.element, Dom.element, Dom.element) => unit = "insertBefore"
@set external setTextContent: (Dom.element, string) => unit = "textContent"

/* Write text into a node that holds only text: a text node's own data, or an
   element whose single child is the text node written before. Updating that
   node's data keeps it; `textContent` would drop it and make a new one on
   every write. An element with no text yet, or with anything else in it, gets
   `textContent`. */
let writeText: (Dom.element, string) => unit = %raw(`function (node, value) {
  const first = node.firstChild
  if (first !== null && first.nodeType === 3 && first.nextSibling === null) {
    first.data = value
  } else {
    node.textContent = value
  }
}`)
@set external setValue: (Dom.element, string) => unit = "value"
@set external setChecked: (Dom.element, bool) => unit = "checked"
@set external setDisabled: (Dom.element, bool) => unit = "disabled"

let createElementForTag = (tag: string): Dom.element =>
  isSvgTag(tag) ? createElementNS(svgNamespace, tag) : createElement(tag)

let removeAttrOrProp = (el: Dom.element, key: string): unit => {
  switch key {
  | "value" => setValue(el, "")
  | "checked" => setChecked(el, false)
  | "disabled" => setDisabled(el, false)
  | _ => removeAttribute(el, key)
  }
}

/* The value is nullable: `null`/`undefined` (a `None` coming out of an optional
 attribute, or an untyped JSX value that resolved to nothing) removes the
 attribute instead of writing the string "undefined". That is what
 presence-based selectors such as `[data-open]` need — an attribute that is
 always present, even as `""`, is always matched. */
let setAttrOrProp = (el: Dom.element, key: string, value: Nullable.t<string>): unit => {
  switch value->Nullable.toOption {
  | None => removeAttrOrProp(el, key)
  | Some(value) =>
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
}
