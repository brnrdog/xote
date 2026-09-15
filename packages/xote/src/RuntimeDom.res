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

let isDocumentFragment: Dom.element => bool = %raw(`function (node) {
  return node != null && node.nodeType === 11
}`)

let childNodesToArray = (el: Dom.element): array<Dom.element> => {
  ignore(el)
  %raw(`Array.from(el.childNodes || [])`)
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

/* Element creation, and the two places a non-DOM host needs a say.

 `createXoteElement` and `createXoteGroup` are the whole host seam: a document
 that implements them decides what a tag means and how a reactive region is
 grouped, and one that does not gets the browser behaviour below, unchanged.
 Both are one `typeof` per element created, which is nothing next to creating
 one. */
let hostCreateElement: string => Nullable.t<Dom.element> = %raw(`function (tag) {
  return typeof document.createXoteElement === "function" ? document.createXoteElement(tag) : null
}`)

let hostCreateGroup: unit => Nullable.t<Dom.element> = %raw(`function () {
  return typeof document.createXoteGroup === "function" ? document.createXoteGroup() : null
}`)

/* The SVG table is the reason the first hook exists. `text`, `image`, `line`,
 `mask`, `filter` and `use` are SVG on the web and perfectly ordinary view names
 elsewhere, so "which namespace is this tag in" is a question only a DOM can
 answer — and it should not be answered in shared code on everyone's behalf. */
let createElementForTag = (tag: string): Dom.element =>
  switch hostCreateElement(tag)->Nullable.toOption {
  | Some(element) => element
  | None => isSvgTag(tag) ? createElementNS(svgNamespace, tag) : createElement(tag)
  }

/* The container a reactive region renders its children into.

 On the web that is a `<div style="display: contents">` — a grouping box the
 browser erases at layout time. Nothing else has such an escape, so a host that
 implements `createXoteGroup` is handed the concept directly instead of having
 to recognise one of these by its tag name. */
let createGroup = (): Dom.element =>
  switch hostCreateGroup()->Nullable.toOption {
  | Some(element) => element
  | None => {
      let element = createElement("div")
      setAttribute(element, "style", "display: contents")
      element
    }
  }

/* Assign a value the renderer never inspects. An opaque attribute is a host
 property, not an HTML attribute, so none of the presence-or-string rules in
 `setAttrOrProp` apply to it. */
let setOpaqueProp: (Dom.element, string, Nullable.t<Obj.t>) => unit = %raw(`function (element, key, value) {
  if (value === null || value === undefined) {
    if (typeof element.removeAttribute === "function") element.removeAttribute(key)
    return
  }
  element.setAttribute(key, value)
}`)

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
