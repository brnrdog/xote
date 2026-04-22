module DOM = RuntimeDom
module Reactivity = RuntimeOwner

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
  | KeyedList({signal: Signal.t<array<Obj.t>>, keyFn: Obj.t => string, renderItem: Obj.t => node})

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
          let disposer = Effect.runWithDisposer(() => {
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
          let disposer = Effect.runWithDisposer(() => {
            let children = Signal.get(signal)

            /* Dispose existing children */
            let childNodes: array<Dom.element> = %raw(`Array.from(container.childNodes || [])`)
            childNodes->Array.forEach(disposeElement)

            /* Clear existing children */
            let _ = (%raw(`container.innerHTML = ''`): unit)

            /* Render and append new children */
            children->Array.forEach(
              child => {
                let childEl = render(child)
                container->DOM.appendChild(childEl)
              },
            )

            None
          })

          addDisposer(owner, disposer)
        })

        container
      }

    | Element({tag, attrs, events, children}) => {
        let el = DOM.createElementForTag(tag)
        let owner = createOwner()
        setOwner(el, owner)

        runWithOwner(owner, () => {
          let shouldDeferAttrUntilAfterChildren = ((key, _value)) =>
            tag == "select" && key == "value"

          let applyAttr = ((key, value)) => {
            switch value {
            | Static(v) => DOM.setAttrOrProp(el, key, v)
            | SignalValue(signal) => {
                DOM.setAttrOrProp(el, key, Signal.peek(signal))
                let disposer = Effect.runWithDisposer(
                  () => {
                    DOM.setAttrOrProp(el, key, Signal.get(signal))
                    None
                  },
                )
                addDisposer(owner, disposer)
              }
            | Compute(compute) => {
                let disposer = Effect.runWithDisposer(
                  () => {
                    DOM.setAttrOrProp(el, key, compute())
                    None
                  },
                )
                addDisposer(owner, disposer)
              }
            }
          }

          /* Set attributes that do not depend on mounted children */
          attrs->Array.forEach(attr => {
            if !shouldDeferAttrUntilAfterChildren(attr) {
              applyAttr(attr)
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

          /* Some DOM properties need the child tree to exist before the browser can resolve them */
          attrs->Array.forEach(attr => {
            if shouldDeferAttrUntilAfterChildren(attr) {
              applyAttr(attr)
            }
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
              keyedItems
              ->Dict.keysToArray
              ->Array.forEach(key => {
                switch newKeyMap->Dict.get(key) {
                | None => keysToRemove->Array.push(key)->ignore
                | Some(_) => ()
                }
              })

              keysToRemove->Array.forEach(key => {
                switch keyedItems->Dict.get(key) {
                | Some(keyedItem) => {
                    disposeElement(keyedItem.element)
                    let _ = (%raw(`keyedItem.element.remove()`): unit)
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
                | Some(existing) =>
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
                | Some(elem) if elem === endAnchor =>
                  DOM.insertBefore(parent, keyedItem.element, endAnchor)
                | Some(elem) if elem === keyedItem.element => marker := DOM.getNextSibling(elem)
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
                | None => DOM.insertBefore(parent, keyedItem.element, endAnchor)
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
          let disposer = Effect.runWithDisposer(() => {
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

let signalText = (compute: unit => string): node => {
  let signal = Computed.make(compute)
  SignalText(signal)
}

let signalInt = (compute: unit => int): node => {
  let signal = Computed.make(() => compute()->Int.toString)
  SignalText(signal)
}

let signalFloat = (compute: unit => float): node => {
  let signal = Computed.make(() => compute()->Float.toString)
  SignalText(signal)
}

/* Static text nodes with type-specific helpers */
let int = (value: int): node => Text(Int.toString(value))

let float = (value: float): node => Text(Float.toString(value))

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

/* Null representation */
let null = () => text("")

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
