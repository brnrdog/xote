open Signals

/* Source for an attribute value - supports static strings, signals, or computed values */
type attrValue =
  | Static(string)
  | SignalValue(Signal.t<string>)
  | Compute(unit => string)

/* Helpers to build attribute entries */
let attr = (key: string, value: string): (string, attrValue) => (key, Static(value))
let signalAttr = (key: string, signal: Signal.t<string>): (string, attrValue) => (
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
      attrs: array<(string, attrValue)>,
      events: array<(string, Dom.event => unit)>,
      children: array<node>,
    })
  | Text(string)
  | SignalText(Signal.t<string>)
  | Fragment(array<node>)
  | SignalFragment(Signal.t<array<node>>)

/* Create a text node */
let text = (content: string): node => Text(content)

/* Create a reactive text node from a computed function */
let textSignal = (compute: unit => string): node => {
  let signal = Computed.make(compute)
  SignalText(signal)
}

/* Create a fragment (multiple children without wrapper) */
let fragment = (children: array<node>): node => Fragment(children)

/* Create a reactive fragment from a signal */
let signalFragment = (signal: Signal.t<array<node>>): node => SignalFragment(signal)

/* Create a reactive list from a signal and render function */
let list = (signal: Signal.t<array<'a>>, renderItem: 'a => node): node => {
  let nodesSignal = Computed.make(() => {
    Signal.get(signal)->Array.map(renderItem)
  })
  SignalFragment(nodesSignal)
}

/* Create an element */
let element = (
  tag: string,
  ~attrs: array<(string, attrValue)>=[]->Array.map(x => x),
  ~events: array<(string, Dom.event => unit)>=[]->Array.map(x => x),
  ~children: array<node>=[]->Array.map(x => x),
  (),
): node => Element({tag, attrs, events, children})

/* Helper to create common elements */
let div = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("div", ~attrs?, ~events?, ~children?, ())
let span = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("span", ~attrs?, ~events?, ~children?, ())
let button = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("button", ~attrs?, ~events?, ~children?, ())
let input = (~attrs=?, ~events=?, ()) => element("input", ~attrs?, ~events?, ())
let h1 = (~attrs=?, ~events=?, ~children=?, ()) => element("h1", ~attrs?, ~events?, ~children?, ())
let h2 = (~attrs=?, ~events=?, ~children=?, ()) => element("h2", ~attrs?, ~events?, ~children?, ())
let h3 = (~attrs=?, ~events=?, ~children=?, ()) => element("h3", ~attrs?, ~events?, ~children?, ())
let p = (~attrs=?, ~events=?, ~children=?, ()) => element("p", ~attrs?, ~events?, ~children?, ())
let ul = (~attrs=?, ~events=?, ~children=?, ()) => element("ul", ~attrs?, ~events?, ~children?, ())
let li = (~attrs=?, ~events=?, ~children=?, ()) => element("li", ~attrs?, ~events?, ~children?, ())
let a = (~attrs=?, ~events=?, ~children=?, ()) => element("a", ~attrs?, ~events?, ~children?, ())

/* External bindings for DOM manipulation */
@val @scope("document") external createElement: string => Dom.element = "createElement"
@val @scope("document")
external createElementNS: (string, string) => Dom.element = "createElementNS"
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
@set external setValue: (Dom.element, string) => unit = "value"

/* Disposer management for reactive nodes */
type disposerList = array<Effect.disposer>

@set external setDisposers: (Dom.element, disposerList) => unit = "__xote_disposers"
@get external getDisposers: Dom.element => Nullable.t<disposerList> = "__xote_disposers"

/* Helper to add a disposer to an element */
let addDisposer = (el: Dom.element, disposer: Effect.disposer): unit => {
  let existing = getDisposers(el)->Nullable.toOption->Option.getOr([])
  setDisposers(el, Array.concat(existing, [disposer]))
}

/* Recursively dispose an element and all its children */
let rec disposeElement = (el: Dom.element): unit => {
  /* Dispose this element's observers */
  switch getDisposers(el)->Nullable.toOption {
  | Some(disposers) => {
      disposers->Array.forEach(d => d.dispose())
      setDisposers(el, []) /* Clear the disposers array */
    }
  | None => ()
  }

  /* Dispose all children recursively */
  let children: array<Dom.element> = %raw(`Array.from(el.childNodes || [])`)
  children->Array.forEach(disposeElement)
}

/* Render a virtual node to a real DOM element */
let rec render = (node: node): Dom.element => {
  switch node {
  | Text(content) => createTextNode(content)
  | SignalText(signal) => {
      let el = createTextNode(Signal.peek(signal))

      /* Set up effect to update text when signal changes */
      let disposer = Effect.run(() => {
        let content = Signal.get(signal)
        el->setTextContent(content)
        None
      })

      addDisposer(el, disposer)
      el
    }
  | Element({tag, attrs, events, children}) => {
      let el = switch tag {
      | "svg"
      | "path"
      | "circle"
      | "rect"
      | "line"
      | "polyline"
      | "polygon"
      | "ellipse"
      | "g"
      | "defs"
      | "use"
      | "symbol"
      | "marker"
      | "clipPath"
      | "mask"
      | "pattern"
      | "linearGradient"
      | "radialGradient"
      | "stop"
      | "text"
      | "tspan"
      | "textPath" =>
        createElementNS("http://www.w3.org/2000/svg", tag)
      | _ => createElement(tag)
      }

      /* Set attributes - handle static, signal, and computed values */
      attrs->Array.forEach(((key, source)) => {
        switch source {
        | Static(value) =>
          /* Static attribute - set once */
          if key == "value" && tag == "input" {
            el->setValue(value)
          } else {
            el->setAttribute(key, value)
          }
        | SignalValue(s) => /* Signal attribute - set initial value and subscribe to changes */
          if key == "value" && tag == "input" {
            el->setValue(Signal.peek(s))
            let disposer = Effect.run(() => {
              let v = Signal.get(s)
              el->setValue(v)
              None
            })
            addDisposer(el, disposer)
          } else {
            el->setAttribute(key, Signal.peek(s))
            let disposer = Effect.run(() => {
              let v = Signal.get(s)
              el->setAttribute(key, v)
              None
            })
            addDisposer(el, disposer)
          }
        | Compute(f) => {
            /* Computed attribute - create computed signal and subscribe */
            let computedSignal = Computed.make(() => f())
            if key == "value" && tag == "input" {
              el->setValue(Signal.peek(computedSignal))
              let disposer = Effect.run(() => {
                let v = Signal.get(computedSignal)
                el->setValue(v)
                None
              })
              addDisposer(el, disposer)
            } else {
              el->setAttribute(key, Signal.peek(computedSignal))
              let disposer = Effect.run(() => {
                let v = Signal.get(computedSignal)
                el->setAttribute(key, v)
                None
              })
              addDisposer(el, disposer)
            }
          }
        }
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
      let disposer = Effect.run(() => {
        let children = Signal.get(signal)
        /* Dispose existing children before clearing DOM */
        let childNodes: array<Dom.element> = %raw(`Array.from(container.childNodes || [])`)
        childNodes->Array.forEach(disposeElement)
        /* Clear existing children */
        %raw(`container.innerHTML = ''`)
        /* Render and append new children */
        children->Array.forEach(child => {
          let childEl = render(child)
          container->appendChild(childEl)
        })
        None
      })

      addDisposer(container, disposer)
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
