module Signal = Xote__Signal
module Effect = Xote__Effect
module Core = Xote__Core
module Computed = Xote__Computed

/* Source for a reactive attribute value */
type attrValue =
  | SignalValue(Core.t<string>)
  | Compute(unit => string)

/* Helpers to build reactive attribute entries */
let signalAttr = (key: string, signal: Core.t<string>): (string, attrValue) => (
  key,
  SignalValue(signal),
)
let computedAttr = (key: string, compute: unit => string): (string, attrValue) => (
  key,
  Compute(compute),
)

/* Type representing a virtual node */
type rec node =
  | Element({
      tag: string,
      attrs: array<(string, string)>,
      /* Attributes whose values are driven by signals or computed getters */
      signalAttrs: array<(string, attrValue)>,
      events: array<(string, Dom.event => unit)>,
      children: array<node>,
    })
  | Text(string)
  | SignalText(Core.t<string>)
  | Fragment(array<node>)
  | SignalFragment(Core.t<array<node>>)

/* Create a text node */
let text = (content: string): node => Text(content)

/* Create a reactive text node from a signal */
let textSignal = (signal: Core.t<string>): node => SignalText(signal)

let textSignalComputed = (signal: Core.t<string>): node => {
  let computed = Computed.make(() => Signal.get(signal))
  SignalText(computed)
}

/* Create a fragment (multiple children without wrapper) */
let fragment = (children: array<node>): node => Fragment(children)

/* Create a reactive fragment from a signal */
let signalFragment = (signal: Core.t<array<node>>): node => SignalFragment(signal)

/* Create a reactive list from a signal and render function */
let list = (signal: Core.t<array<'a>>, renderItem: 'a => node): node => {
  let nodesSignal = Computed.make(() => {
    Signal.get(signal)->Array.map(renderItem)
  })
  SignalFragment(nodesSignal)
}

/* Create an element */
let element = (
  tag: string,
  ~attrs: array<(string, string)>=[]->Array.map(x => x),
  ~signalAttrs: array<(string, attrValue)>=[]->Array.map(x => x),
  ~events: array<(string, Dom.event => unit)>=[]->Array.map(x => x),
  ~children: array<node>=[]->Array.map(x => x),
  (),
): node => Element({tag, attrs, signalAttrs, events, children})

/* Helper to create common elements */
let div = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("div", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let span = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("span", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let button = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("button", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let input = (~attrs=?, ~signalAttrs=?, ~events=?, ()) =>
  element("input", ~attrs?, ~signalAttrs?, ~events?, ())
let h1 = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("h1", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let h2 = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("h2", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let h3 = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("h3", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let p = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("p", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let ul = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("ul", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let li = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("li", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())
let a = (~attrs=?, ~signalAttrs=?, ~events=?, ~children=?, ()) =>
  element("a", ~attrs?, ~signalAttrs?, ~events?, ~children?, ())

/* External bindings for DOM manipulation */
@val @scope("document") external createElement: string => Dom.element = "createElement"
@val @scope("document") external createTextNode: string => Dom.element = "createTextNode"
@val @scope("document")
external createDocumentFragment: unit => Dom.element = "createDocumentFragment"
@val @scope("document")
external getElementById: string => Nullable.t<Dom.element> = "getElementById"

@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@send
external addEventListener: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@set external setTextContent: (Dom.element, string) => unit = "textContent"

/* Render a virtual node to a real DOM element */
let rec render = (node: node): Dom.element => {
  switch node {
  | Text(content) => createTextNode(content)
  | SignalText(signal) => {
      let el = createTextNode(Signal.peek(signal))

      /* Set up effect to update text when signal changes */
      let _ = Effect.run(() => {
        let content = Signal.get(signal)
        el->setTextContent(content)
      })

      el
    }
  | Element({tag, attrs, signalAttrs, events, children}) => {
      let el = createElement(tag)

      /* Set attributes */
      attrs->Array.forEach(((key, value)) => {
        el->setAttribute(key, value)
      })

      /* Set reactive attributes */
      signalAttrs->Array.forEach(((key, source)) => {
        let sig = switch source {
        | SignalValue(s) => s
        | Compute(f) => Computed.make(() => f())
        }
        /* initial */
        el->setAttribute(key, Signal.peek(sig))
        /* subscribe */
        let _ = Effect.run(() => {
          let v = Signal.get(sig)
          el->setAttribute(key, v)
        })
      })

      /* Attach event listeners */
      events->Array.forEach(((eventName, handler)) => {
        el->addEventListener(eventName, handler)
      })

      /* Append children */
      children->Array.forEach(child => {
        let childEl = render(child)
        el->appendChild(childEl)
      })

      el
    }
  | Fragment(children) => {
      let fragment = createDocumentFragment()
      children->Array.forEach(child => {
        let childEl = render(child)
        fragment->appendChild(childEl)
      })
      fragment
    }
  | SignalFragment(signal) => {
      /* Create a container element to hold the dynamic children */
      let container = createElement("div")
      setAttribute(container, "data-signal-fragment", "true")
      setAttribute(container, "style", "display: contents")

      /* Set up effect to update children when signal changes */
      let _ = Effect.run(() => {
        let children = Signal.get(signal)
        /* Clear existing children */
        %raw(`container.innerHTML = ''`)
        /* Render and append new children */
        children->Array.forEach(child => {
          let childEl = render(child)
          container->appendChild(childEl)
        })
      })

      container
    }
  }
}

/* Mount a node to a container element */
let mount = (node: node, container: Dom.element): unit => {
  let el = render(node)
  container->appendChild(el)
}

/* Mount a node to a container by ID */
let mountById = (node: node, containerId: string): unit => {
  switch getElementById(containerId)->Nullable.toOption {
  | Some(container) => mount(node, container)
  | None => Console.error("Container element not found: " ++ containerId)
  }
}
