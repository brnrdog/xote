open Signals

/* ============================================================================
 * DOM Bindings
 * ============================================================================ */

module DOM = {
  /* Creation */
  @val @scope("document") external createElement: string => Dom.element = "createElement"
  @val @scope("document")
  external createElementNS: (string, string) => Dom.element = "createElementNS"
  @val @scope("document") external createTextNode: string => Dom.element = "createTextNode"
  @val @scope("document")
  external createDocumentFragment: unit => Dom.element = "createDocumentFragment"
  @val @scope("document") external createComment: string => Dom.element = "createComment"
  @val @scope("document")
  external getElementById: string => Nullable.t<Dom.element> = "getElementById"

  /* Accessors */
  @get external getNextSibling: Dom.element => Nullable.t<Dom.element> = "nextSibling"
  @get external getParentNode: Dom.element => Nullable.t<Dom.element> = "parentNode"

  /* Mutations */
  @send
  external addEventListener: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
  @send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
  @send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
  @send external replaceChild: (Dom.element, Dom.element, Dom.element) => unit = "replaceChild"
  @send external insertBefore: (Dom.element, Dom.element, Dom.element) => unit = "insertBefore"
  @set external setTextContent: (Dom.element, string) => unit = "textContent"
  @set external setValue: (Dom.element, string) => unit = "value"
}

/* ============================================================================
 * Reactivity / Owner System
 * ============================================================================ */

module Reactivity = {
  /* Owner tracks reactive state for a component scope */
  type owner = {
    disposers: array<Effect.disposer>,
    mutable computeds: array<Obj.t>,
  }

  /* Global owner stack */
  let currentOwner: ref<option<owner>> = ref(None)

  /* Create a new owner */
  let createOwner = (): owner => {
    disposers: [],
    computeds: [],
  }

  /* Run function with owner context */
  let runWithOwner = (owner: owner, fn: unit => 'a): 'a => {
    let previousOwner = currentOwner.contents
    currentOwner := Some(owner)
    let result = fn()
    currentOwner := previousOwner
    result
  }

  /* Add disposer to owner */
  let addDisposer = (owner: owner, disposer: Effect.disposer): unit => {
    owner.disposers->Array.push(disposer)->ignore
  }

  /* Dispose owner and all its reactive state */
  let disposeOwner = (owner: owner): unit => {
    /* Dispose all effects */
    owner.disposers->Array.forEach(disposer => disposer.dispose())

    /* Dispose all computeds */
    owner.computeds->Array.forEach(computed => {
      let c: Signal.t<Obj.t> = Obj.magic(computed)
      Computed.dispose(c)
    })
  }

  /* Owner storage on DOM elements */
  let setOwner = (element: Dom.element, owner: owner): unit => {
    %raw(`element["__xote_owner__"] = owner`)
  }

  let getOwner = (element: Dom.element): option<owner> => {
    let owner: Nullable.t<owner> = %raw(`element["__xote_owner__"]`)
    owner->Nullable.toOption
  }
}

/* ============================================================================
 * Type Definitions
 * ============================================================================ */

/* Attribute value source */
type attrValue =
  | Static(string)
  | SignalValue(Signal.t<string>)
  | Compute(unit => string)

/* Virtual node types */
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
  | LazyComponent(unit => node)
  | KeyedList({
      signal: Signal.t<array<Obj.t>>,
      keyFn: Obj.t => string,
      renderItem: Obj.t => node,
    })

/* ============================================================================
 * Attribute Helpers
 * ============================================================================ */

module Attributes = {
  let static = (key: string, value: string): (string, attrValue) => (key, Static(value))

  let signal = (key: string, signal: Signal.t<string>): (string, attrValue) => (
    key,
    SignalValue(signal),
  )

  let computed = (key: string, compute: unit => string): (string, attrValue) => (
    key,
    Compute(compute),
  )
}

/* Public API for attributes */
let attr = Attributes.static
let signalAttr = Attributes.signal
let computedAttr = Attributes.computed

/* ============================================================================
 * Rendering
 * ============================================================================ */

module Render = {
  open Reactivity

  /* Type for tracking keyed list items */
  type keyedItem<'a> = {
    key: string,
    item: 'a,
    element: Dom.element,
  }

  /* Dispose an element and its reactive state */
  let rec disposeElement = (el: Dom.element): unit => {
    /* Dispose the owner if it exists */
    switch getOwner(el) {
    | Some(owner) => disposeOwner(owner)
    | None => ()
    }

    /* Recursively dispose children */
    let childNodes: array<Dom.element> = %raw(`Array.from(el.childNodes || [])`)
    childNodes->Array.forEach(disposeElement)
  }

  /* Render a virtual node to a DOM element */
  let rec render = (node: node): Dom.element => {
    switch node {
    | Text(content) => DOM.createTextNode(content)

    | SignalText(signal) => {
        let textNode = DOM.createTextNode(Signal.peek(signal))
        let owner = createOwner()
        setOwner(textNode, owner)

        runWithOwner(owner, () => {
          let disposer = Effect.run(() => {
            DOM.setTextContent(textNode, Signal.get(signal))
            None
          })
          addDisposer(owner, disposer)
        })

        textNode
      }

    | Fragment(children) => {
        let fragment = DOM.createDocumentFragment()
        children->Array.forEach(child => {
          let childEl = render(child)
          fragment->DOM.appendChild(childEl)
        })
        fragment
      }

    | SignalFragment(signal) => {
        let owner = createOwner()
        let container = DOM.createElement("div")
        DOM.setAttribute(container, "style", "display: contents")
        setOwner(container, owner)

        runWithOwner(owner, () => {
          let disposer = Effect.run(() => {
            let children = Signal.get(signal)

            /* Dispose existing children */
            let childNodes: array<Dom.element> = %raw(`Array.from(container.childNodes || [])`)
            childNodes->Array.forEach(disposeElement)

            /* Clear existing children */
            %raw(`container.innerHTML = ''`)

            /* Render and append new children */
            children->Array.forEach(child => {
              let childEl = render(child)
              container->DOM.appendChild(childEl)
            })

            None
          })

          addDisposer(owner, disposer)
        })

        container
      }

    | Element({tag, attrs, events, children}) => {
        let el = DOM.createElement(tag)
        let owner = createOwner()
        setOwner(el, owner)

        runWithOwner(owner, () => {
          /* Set attributes */
          attrs->Array.forEach(((key, value)) => {
            switch value {
            | Static(v) => DOM.setAttribute(el, key, v)
            | SignalValue(signal) => {
                DOM.setAttribute(el, key, Signal.peek(signal))
                let disposer = Effect.run(() => {
                  DOM.setAttribute(el, key, Signal.get(signal))
                  None
                })
                addDisposer(owner, disposer)
              }
            | Compute(compute) => {
                DOM.setAttribute(el, key, compute())
                let disposer = Effect.run(() => {
                  DOM.setAttribute(el, key, compute())
                  None
                })
                addDisposer(owner, disposer)
              }
            }
          })

          /* Attach event listeners */
          events->Array.forEach(((eventName, handler)) => {
            el->DOM.addEventListener(eventName, handler)
          })

          /* Append children */
          children->Array.forEach(child => {
            let childEl = render(child)
            el->DOM.appendChild(childEl)
          })
        })

        el
      }

    | LazyComponent(fn) => {
        let owner = createOwner()
        let childNode = runWithOwner(owner, fn)
        let el = render(childNode)
        setOwner(el, owner)
        el
      }

    | KeyedList({signal, keyFn, renderItem}) => {
        let owner = createOwner()
        let startAnchor = DOM.createComment(" keyed-list-start ")
        let endAnchor = DOM.createComment(" keyed-list-end ")

        setOwner(startAnchor, owner)

        let keyedItems: Dict.t<keyedItem<Obj.t>> = Dict.make()

        /* Reconciliation logic */
        let reconcile = (): unit => {
          let parentOpt = DOM.getParentNode(endAnchor)->Nullable.toOption

          switch parentOpt {
          | None => ()
          | Some(parent) => {
              let newItems = Signal.get(signal)

              let newKeyMap: Dict.t<Obj.t> = Dict.make()
              newItems->Array.forEach(item => {
                newKeyMap->Dict.set(keyFn(item), item)
              })

              /* Phase 1: Remove */
              let keysToRemove = []
              keyedItems->Dict.keysToArray->Array.forEach(key => {
                switch newKeyMap->Dict.get(key) {
                | None => keysToRemove->Array.push(key)->ignore
                | Some(_) => ()
                }
              })

              keysToRemove->Array.forEach(key => {
                switch keyedItems->Dict.get(key) {
                | Some(keyedItem) => {
                    disposeElement(keyedItem.element)
                    %raw(`keyedItem.element.remove()`)
                    keyedItems->Dict.delete(key)->ignore
                  }
                | None => ()
                }
              })

              /* Phase 2: Build new order */
              let newOrder: array<keyedItem<Obj.t>> = []
              let elementsToReplace: Dict.t<bool> = Dict.make()

              newItems->Array.forEach(item => {
                let key = keyFn(item)

                switch keyedItems->Dict.get(key) {
                | Some(existing) => {
                    if existing.item !== item {
                      elementsToReplace->Dict.set(key, true)
                      let node = renderItem(item)
                      let element = render(node)
                      let keyedItem = {key, item, element}
                      newOrder->Array.push(keyedItem)->ignore
                      keyedItems->Dict.set(key, keyedItem)
                    } else {
                      newOrder->Array.push(existing)->ignore
                    }
                  }
                | None => {
                    let node = renderItem(item)
                    let element = render(node)
                    let keyedItem = {key, item, element}
                    newOrder->Array.push(keyedItem)->ignore
                    keyedItems->Dict.set(key, keyedItem)
                  }
                }
              })

              /* Phase 3: Reconcile DOM */
              let marker = ref(DOM.getNextSibling(startAnchor))

              newOrder->Array.forEach(keyedItem => {
                let currentElement = marker.contents

                switch currentElement->Nullable.toOption {
                | Some(elem) when elem === endAnchor => {
                    DOM.insertBefore(parent, keyedItem.element, endAnchor)
                  }
                | Some(elem) when elem === keyedItem.element => {
                    marker := DOM.getNextSibling(elem)
                  }
                | Some(elem) => {
                    let needsReplacement =
                      elementsToReplace->Dict.get(keyedItem.key)->Option.getOr(false)

                    if needsReplacement {
                      disposeElement(elem)
                      DOM.replaceChild(parent, keyedItem.element, elem)
                      marker := DOM.getNextSibling(keyedItem.element)
                    } else {
                      DOM.insertBefore(parent, keyedItem.element, elem)
                      marker := DOM.getNextSibling(keyedItem.element)
                    }
                  }
                | None => {
                    DOM.insertBefore(parent, keyedItem.element, endAnchor)
                  }
                }
              })
            }
          }
        }

        /* Initial render */
        let fragment = DOM.createDocumentFragment()
        fragment->DOM.appendChild(startAnchor)

        let initialItems = Signal.peek(signal)
        initialItems->Array.forEach(item => {
          let key = keyFn(item)
          let node = renderItem(item)
          let element = render(node)
          let keyedItem = {key, item, element}
          keyedItems->Dict.set(key, keyedItem)
          fragment->DOM.appendChild(element)
        })

        fragment->DOM.appendChild(endAnchor)

        runWithOwner(owner, () => {
          let disposer = Effect.run(() => {
            reconcile()
            None
          })
          addDisposer(owner, disposer)
        })

        fragment
      }
    }
  }
}

/* ============================================================================
 * Public API
 * ============================================================================ */

/* Text nodes */
let text = (content: string): node => Text(content)

let textSignal = (compute: unit => string): node => {
  let signal = Computed.make(compute)
  SignalText(signal)
}

/* Fragments */
let fragment = (children: array<node>): node => Fragment(children)

let signalFragment = (signal: Signal.t<array<node>>): node => SignalFragment(signal)

/* Lists */
let list = (signal: Signal.t<array<'a>>, renderItem: 'a => node): node => {
  let nodesSignal = Computed.make(() => {
    Signal.get(signal)->Array.map(renderItem)
  })
  SignalFragment(nodesSignal)
}

let keyedList = (
  signal: Signal.t<array<'a>>,
  keyFn: 'a => string,
  renderItem: 'a => node,
): node => {
  KeyedList({
    signal: Obj.magic(signal),
    keyFn: Obj.magic(keyFn),
    renderItem: Obj.magic(renderItem),
  })
}

/* Element constructor */
let element = (
  tag: string,
  ~attrs: array<(string, attrValue)>=[]->Array.map(x => x),
  ~events: array<(string, Dom.event => unit)>=[]->Array.map(x => x),
  ~children: array<node>=[]->Array.map(x => x),
  (),
): node => Element({tag, attrs, events, children})

/* Common elements */
let div = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("div", ~attrs?, ~events?, ~children?, ())
let span = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("span", ~attrs?, ~events?, ~children?, ())
let button = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("button", ~attrs?, ~events?, ~children?, ())
let input = (~attrs=?, ~events=?, ()) => element("input", ~attrs?, ~events?, ())
let h1 = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("h1", ~attrs?, ~events?, ~children?, ())
let h2 = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("h2", ~attrs?, ~events?, ~children?, ())
let h3 = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("h3", ~attrs?, ~events?, ~children?, ())
let p = (~attrs=?, ~events=?, ~children=?, ()) => element("p", ~attrs?, ~events?, ~children?, ())
let ul = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("ul", ~attrs?, ~events?, ~children?, ())
let li = (~attrs=?, ~events=?, ~children=?, ()) =>
  element("li", ~attrs?, ~events?, ~children?, ())
let a = (~attrs=?, ~events=?, ~children=?, ()) => element("a", ~attrs?, ~events?, ~children?, ())

/* Mounting */
let mount = (node: node, container: Dom.element): unit => {
  let el = Render.render(node)
  container->DOM.appendChild(el)
}

let mountById = (node: node, containerId: string): unit => {
  switch DOM.getElementById(containerId)->Nullable.toOption {
  | Some(container) => mount(node, container)
  | None => Console.error("Container element not found: " ++ containerId)
  }
}

/* Re-export for backwards compatibility */
let createOwner = Reactivity.createOwner
let runWithOwner = Reactivity.runWithOwner
let addDisposer = Reactivity.addDisposer
let disposeOwner = Reactivity.disposeOwner
let setOwner = Reactivity.setOwner
let getOwner = Reactivity.getOwner
let render = Render.render
let disposeElement = Render.disposeElement
