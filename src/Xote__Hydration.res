open Signals

module Component = Xote__Component
module DOM = Xote__Component.DOM
module Reactivity = Xote__Component.Reactivity

/* ============================================================================
 * Hydration Options
 * ============================================================================ */

type hydrateOptions = {
  renderId?: string,
  onHydrated?: unit => unit,
}

/* ============================================================================
 * DOM Walker - Utilities for traversing server-rendered DOM
 * ============================================================================ */

module DOMWalker = {
  /* Node types */
  let elementNode = 1
  let textNode = 3
  let commentNode = 8

  /* Get node type */
  @get external nodeType: Dom.element => int = "nodeType"

  /* Get node value (for comments/text) */
  @get external nodeValue: Dom.element => Nullable.t<string> = "nodeValue"

  /* Get child nodes as array */
  let getChildNodes = (el: Dom.element): array<Dom.element> => {
    %raw(`Array.from(el.childNodes || [])`)
  }

  /* Get first child */
  @get external firstChild: Dom.element => Nullable.t<Dom.element> = "firstChild"

  /* Get next sibling */
  @get external nextSibling: Dom.element => Nullable.t<Dom.element> = "nextSibling"

  /* Check if node is a comment with specific content */
  let isMarker = (node: Dom.element, marker: string): bool => {
    if nodeType(node) == commentNode {
      switch nodeValue(node)->Nullable.toOption {
      | Some(value) => value == marker
      | None => false
      }
    } else {
      false
    }
  }

  /* Check if node is a comment starting with prefix */
  let isMarkerPrefix = (node: Dom.element, prefix: string): bool => {
    if nodeType(node) == commentNode {
      switch nodeValue(node)->Nullable.toOption {
      | Some(value) => String.startsWith(value, prefix)
      | None => false
      }
    } else {
      false
    }
  }

  /* Extract key from keyed item marker <!--k:KEY--> */
  let extractKey = (node: Dom.element): option<string> => {
    if nodeType(node) == commentNode {
      switch nodeValue(node)->Nullable.toOption {
      | Some(value) if String.startsWith(value, "k:") => Some(String.slice(value, ~start=2))
      | _ => None
      }
    } else {
      None
    }
  }

  /* Walker state for iterating through children */
  type t = {
    mutable current: option<Dom.element>,
    parent: Dom.element,
  }

  /* Create a walker starting at first child */
  let make = (parent: Dom.element): t => {
    {
      current: firstChild(parent)->Nullable.toOption,
      parent,
    }
  }

  /* Get current node without advancing */
  let peek = (walker: t): option<Dom.element> => walker.current

  /* Advance to next sibling */
  let next = (walker: t): option<Dom.element> => {
    let current = walker.current
    switch current {
    | Some(node) => walker.current = nextSibling(node)->Nullable.toOption
    | None => ()
    }
    current
  }

  /* Skip until we find a marker */
  let skipUntilMarker = (walker: t, marker: string): option<Dom.element> => {
    let rec loop = () => {
      switch walker.current {
      | Some(node) if isMarker(node, marker) => {
          let _ = next(walker) // consume the marker
          Some(node)
        }
      | Some(_) => {
          let _ = next(walker)
          loop()
        }
      | None => None
      }
    }
    loop()
  }

  /* Collect nodes until we hit a marker */
  let collectUntilMarker = (walker: t, marker: string): array<Dom.element> => {
    let nodes = []
    let rec loop = () => {
      switch walker.current {
      | Some(node) if isMarker(node, marker) => {
          let _ = next(walker) // consume the marker
        }
      | Some(node) => {
          nodes->Array.push(node)->ignore
          let _ = next(walker)
          loop()
        }
      | None => ()
      }
    }
    loop()
    nodes
  }
}

/* ============================================================================
 * Hydration Error Handling
 * ============================================================================ */

exception HydrationMismatch(string)

let logHydrationWarning = (msg: string): unit => {
  Console.warn(`[Xote Hydration] ${msg}`)
}

/* ============================================================================
 * Core Hydration Logic
 * ============================================================================ */

/* Hydrate a single node, attaching reactivity to existing DOM */
let rec hydrateNode = (node: Component.node, domNode: Dom.element): unit => {
  switch node {
  | Component.Text(_content) => /* Static text - nothing to hydrate, DOM already has the content */
    ()

  | Component.SignalText(signal) => {
      /*
       * Server rendered: <!--$-->text<!--/$-->
       * We need to find the text node between markers and attach an effect
       */
      let owner = Reactivity.createOwner()
      Reactivity.setOwner(domNode, owner)

      Reactivity.runWithOwner(owner, () => {
        let disposer = Effect.run(() => {
          DOM.setTextContent(domNode, Signal.get(signal))
          None
        })
        Reactivity.addDisposer(owner, disposer)
      })
    }

  | Component.Fragment(children) => {
      /* Fragment children are directly in the parent - hydrate each */
      let walker = DOMWalker.make(domNode)
      children->Array.forEach(child => {
        hydrateNodeWithWalker(child, walker)
      })
    }

  | Component.SignalFragment(signal) => {
      /*
       * Server rendered: <!--#-->...children...<!--/#-->
       * We need to replace the content when the signal changes
       */
      let owner = Reactivity.createOwner()
      Reactivity.setOwner(domNode, owner)

      Reactivity.runWithOwner(owner, () => {
        let disposer = Effect.run(() => {
          let children = Signal.get(signal)

          /* Clear existing children */
          let childNodes: array<Dom.element> = %raw(`Array.from(domNode.childNodes || [])`)
          childNodes->Array.forEach(
            child => {
              Reactivity.disposeOwner(
                Reactivity.getOwner(child)->Option.getOr(Reactivity.createOwner()),
              )
            },
          )
          let _ = (%raw(`domNode.innerHTML = ''`): unit)

          /* Render and append new children */
          children->Array.forEach(
            child => {
              let childEl = Component.Render.render(child)
              domNode->DOM.appendChild(childEl)
            },
          )

          None
        })
        Reactivity.addDisposer(owner, disposer)
      })
    }

  | Component.Element({attrs, events, children}) => {
      let owner = Reactivity.createOwner()
      Reactivity.setOwner(domNode, owner)

      Reactivity.runWithOwner(owner, () => {
        /* Hydrate reactive attributes */
        attrs->Array.forEach(((key, value)) => {
          switch value {
          | Component.Static(_) => () /* Already rendered, nothing to do */
          | Component.SignalValue(signal) => {
              let disposer = Effect.run(
                () => {
                  DOM.setAttrOrProp(domNode, key, Signal.get(signal))
                  None
                },
              )
              Reactivity.addDisposer(owner, disposer)
            }
          | Component.Compute(compute) => {
              let disposer = Effect.run(
                () => {
                  DOM.setAttrOrProp(domNode, key, compute())
                  None
                },
              )
              Reactivity.addDisposer(owner, disposer)
            }
          }
        })

        /* Attach event listeners (not in SSR HTML) */
        events->Array.forEach(((eventName, handler)) => {
          domNode->DOM.addEventListener(eventName, handler)
        })

        /* Hydrate children */
        let walker = DOMWalker.make(domNode)
        children->Array.forEach(child => {
          hydrateNodeWithWalker(child, walker)
        })
      })
    }

  | Component.LazyComponent(fn) => {
      /* Execute lazy component and hydrate its result */
      let owner = Reactivity.createOwner()
      let childNode = Reactivity.runWithOwner(owner, fn)
      Reactivity.setOwner(domNode, owner)
      hydrateNode(childNode, domNode)
    }

  | Component.KeyedList({signal, keyFn, renderItem}) => {
      /*
       * Server rendered: <!--kl--><!--k:key1-->item1<!--/k--><!--k:key2-->item2<!--/k--><!--/kl-->
       * We need to set up the reconciliation effect
       */
      let owner = Reactivity.createOwner()
      Reactivity.setOwner(domNode, owner)

      /* Build initial key -> element map from existing DOM */
      let keyedItems: Dict.t<Component.Render.keyedItem<Obj.t>> = Dict.make()
      let walker = DOMWalker.make(domNode)

      /* Skip to list start marker */
      let _ = DOMWalker.skipUntilMarker(walker, "kl")

      /* Parse existing keyed items */
      let rec parseKeyedItems = () => {
        switch DOMWalker.peek(walker) {
        | Some(node) if DOMWalker.isMarkerPrefix(node, "k:") => {
            let key = DOMWalker.extractKey(node)->Option.getOr("")
            let _ = DOMWalker.next(walker) // consume start marker

            /* Collect item elements until end marker */
            let itemElements = DOMWalker.collectUntilMarker(walker, "/k")

            /* Get the first actual element (skip text nodes) */
            switch itemElements->Array.find(el => DOMWalker.nodeType(el) == DOMWalker.elementNode) {
            | Some(element) => {
                let items = Signal.peek(signal)
                let item =
                  items->Array.find(i => keyFn(i) == key)->Option.getOr(Obj.magic(Dict.make()))
                keyedItems->Dict.set(key, {key, item, element})
              }
            | None => ()
            }

            parseKeyedItems()
          }
        | Some(node) if DOMWalker.isMarker(node, "/kl") => {
            let _ = DOMWalker.next(walker) // consume end marker
          }
        | _ => ()
        }
      }
      parseKeyedItems()

      /* Set up reconciliation effect (reuses existing render logic) */
      Reactivity.runWithOwner(owner, () => {
        let startAnchor = DOM.createComment(" keyed-list-start ")
        let endAnchor = DOM.createComment(" keyed-list-end ")

        /* Insert anchors */
        switch DOMWalker.firstChild(domNode)->Nullable.toOption {
        | Some(firstChild) => DOM.insertBefore(domNode, startAnchor, firstChild)
        | None => DOM.appendChild(domNode, startAnchor)
        }
        DOM.appendChild(domNode, endAnchor)

        let reconcile = (): unit => {
          let newItems = Signal.get(signal)

          let newKeyMap: Dict.t<Obj.t> = Dict.make()
          newItems->Array.forEach(item => {
            newKeyMap->Dict.set(keyFn(item), item)
          })

          /* Remove items not in new list */
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
                Component.Render.disposeElement(keyedItem.element)
                let _ = (%raw(`keyedItem.element.remove()`): unit)
                keyedItems->Dict.delete(key)->ignore
              }
            | None => ()
            }
          })

          /* Build new order */
          let newOrder: array<Component.Render.keyedItem<Obj.t>> = []
          let elementsToReplace: Dict.t<bool> = Dict.make()

          newItems->Array.forEach(item => {
            let key = keyFn(item)

            switch keyedItems->Dict.get(key) {
            | Some(existing) =>
              if existing.item !== item {
                elementsToReplace->Dict.set(key, true)
                let node = renderItem(item)
                let element = Component.Render.render(node)
                let keyedItem: Component.Render.keyedItem<Obj.t> = {key, item, element}
                newOrder->Array.push(keyedItem)->ignore
                keyedItems->Dict.set(key, keyedItem)
              } else {
                newOrder->Array.push(existing)->ignore
              }
            | None => {
                let node = renderItem(item)
                let element = Component.Render.render(node)
                let keyedItem: Component.Render.keyedItem<Obj.t> = {key, item, element}
                newOrder->Array.push(keyedItem)->ignore
                keyedItems->Dict.set(key, keyedItem)
              }
            }
          })

          /* Reconcile DOM */
          let marker = ref(DOM.getNextSibling(startAnchor))

          newOrder->Array.forEach(keyedItem => {
            let currentElement = marker.contents

            switch currentElement->Nullable.toOption {
            | Some(elem) if elem === endAnchor =>
              DOM.insertBefore(domNode, keyedItem.element, endAnchor)
            | Some(elem) if elem === keyedItem.element => marker := DOM.getNextSibling(elem)
            | Some(elem) => {
                let needsReplacement =
                  elementsToReplace->Dict.get(keyedItem.key)->Option.getOr(false)

                if needsReplacement {
                  Component.Render.disposeElement(elem)
                  DOM.replaceChild(domNode, keyedItem.element, elem)
                  marker := DOM.getNextSibling(keyedItem.element)
                } else {
                  DOM.insertBefore(domNode, keyedItem.element, elem)
                  marker := DOM.getNextSibling(keyedItem.element)
                }
              }
            | None => DOM.insertBefore(domNode, keyedItem.element, endAnchor)
            }
          })
        }

        let disposer = Effect.run(() => {
          reconcile()
          None
        })
        Reactivity.addDisposer(owner, disposer)
      })
    }
  }
}

/* Hydrate using a walker (for traversing children) */
and hydrateNodeWithWalker = (node: Component.node, walker: DOMWalker.t): unit => {
  switch node {
  | Component.Text(_) => {
      /* Skip text node in DOM */
      let _ = DOMWalker.next(walker)
    }

  | Component.SignalText(signal) => {
      /* Find the marker, then hydrate the text node */
      let _ = DOMWalker.skipUntilMarker(walker, "$")

      /* Get the text node */
      switch DOMWalker.next(walker) {
      | Some(textNode) => {
          let owner = Reactivity.createOwner()
          Reactivity.setOwner(textNode, owner)

          Reactivity.runWithOwner(owner, () => {
            let disposer = Effect.run(() => {
              DOM.setTextContent(textNode, Signal.get(signal))
              None
            })
            Reactivity.addDisposer(owner, disposer)
          })

          /* Skip end marker */
          let _ = DOMWalker.skipUntilMarker(walker, "/$")
        }
      | None => logHydrationWarning("Missing text node for SignalText")
      }
    }

  | Component.Fragment(children) =>
    /* Fragment children are inline - hydrate each */
    children->Array.forEach(child => {
      hydrateNodeWithWalker(child, walker)
    })

  | Component.SignalFragment(signal) => {
      /* Find the container (div with display:contents in SSR, markers in comments) */
      let _ = DOMWalker.skipUntilMarker(walker, "#")

      /* Collect all nodes until end marker - these become the container's content */
      let contentNodes = DOMWalker.collectUntilMarker(walker, "/#")

      /* Create a container div to hold the signal fragment */
      let container = DOM.createElement("div")
      DOM.setAttribute(container, "style", "display: contents")

      /* Get parent before moving nodes (we need it for insertion) */
      let parent: option<Dom.element> = switch contentNodes->Array.get(0) {
      | Some(firstNode) => %raw(`firstNode.parentNode`)
      | None => None
      }

      /* Move content nodes into container */
      contentNodes->Array.forEach(node => {
        container->DOM.appendChild(node)
      })

      /* Insert container where the markers were */
      switch (parent, DOMWalker.peek(walker)) {
      | (Some(p), Some(nextNode)) => DOM.insertBefore(p, container, nextNode)
      | (Some(p), None) => DOM.appendChild(p, container)
      | (None, _) => () /* No content nodes, nothing to do */
      }

      /* Set up reactivity */
      let owner = Reactivity.createOwner()
      Reactivity.setOwner(container, owner)

      Reactivity.runWithOwner(owner, () => {
        let disposer = Effect.run(() => {
          let children = Signal.get(signal)

          /* Clear and re-render */
          let childNodes: array<Dom.element> = %raw(`Array.from(container.childNodes || [])`)
          childNodes->Array.forEach(Component.Render.disposeElement)
          let _ = (%raw(`container.innerHTML = ''`): unit)

          children->Array.forEach(
            child => {
              let childEl = Component.Render.render(child)
              container->DOM.appendChild(childEl)
            },
          )

          None
        })
        Reactivity.addDisposer(owner, disposer)
      })
    }

  | Component.Element({attrs, events, children}) =>
    switch DOMWalker.next(walker) {
    | Some(domNode) => {
        let owner = Reactivity.createOwner()
        Reactivity.setOwner(domNode, owner)

        Reactivity.runWithOwner(owner, () => {
          /* Hydrate reactive attributes */
          attrs->Array.forEach(((key, value)) => {
            switch value {
            | Component.Static(_) => ()
            | Component.SignalValue(signal) => {
                let disposer = Effect.run(
                  () => {
                    DOM.setAttrOrProp(domNode, key, Signal.get(signal))
                    None
                  },
                )
                Reactivity.addDisposer(owner, disposer)
              }
            | Component.Compute(compute) => {
                let disposer = Effect.run(
                  () => {
                    DOM.setAttrOrProp(domNode, key, compute())
                    None
                  },
                )
                Reactivity.addDisposer(owner, disposer)
              }
            }
          })

          /* Attach event listeners */
          events->Array.forEach(((eventName, handler)) => {
            domNode->DOM.addEventListener(eventName, handler)
          })

          /* Hydrate children */
          let childWalker = DOMWalker.make(domNode)
          children->Array.forEach(child => {
            hydrateNodeWithWalker(child, childWalker)
          })
        })
      }
    | None => logHydrationWarning("Missing DOM element for Element node")
    }

  | Component.LazyComponent(fn) => {
      /* Skip the lazy component markers and hydrate the content */
      let _ = DOMWalker.skipUntilMarker(walker, "lc")

      let childNode = fn()
      hydrateNodeWithWalker(childNode, walker)

      let _ = DOMWalker.skipUntilMarker(walker, "/lc")
    }

  | Component.KeyedList({signal, keyFn, renderItem}) => {
      /* Find the keyed list in the DOM */
      let _ = DOMWalker.skipUntilMarker(walker, "kl")

      /* Parse existing keyed items from DOM */
      let keyedItems: Dict.t<Component.Render.keyedItem<Obj.t>> = Dict.make()

      let rec parseKeyedItems = () => {
        switch DOMWalker.peek(walker) {
        | Some(node) if DOMWalker.isMarkerPrefix(node, "k:") => {
            let key = DOMWalker.extractKey(node)->Option.getOr("")
            let _ = DOMWalker.next(walker)

            let itemElements = DOMWalker.collectUntilMarker(walker, "/k")

            switch itemElements->Array.find(el => DOMWalker.nodeType(el) == DOMWalker.elementNode) {
            | Some(element) => {
                let items = Signal.peek(signal)
                let item =
                  items->Array.find(i => keyFn(i) == key)->Option.getOr(Obj.magic(Dict.make()))
                keyedItems->Dict.set(key, {key, item, element})
              }
            | None => ()
            }

            parseKeyedItems()
          }
        | Some(node) if DOMWalker.isMarker(node, "/kl") => {
            let _ = DOMWalker.next(walker)
          }
        | _ => ()
        }
      }
      parseKeyedItems()

      /* Note: Full keyed list reconciliation would require more complex handling */
      /* For now, the initial items are hydrated, future updates use full render */
    }
  }
}

/* ============================================================================
 * Public API
 * ============================================================================ */

/* Hydrate a server-rendered component */
let hydrate = (
  component: unit => Component.node,
  container: Dom.element,
  ~options: hydrateOptions={},
): unit => {
  let _ = options.renderId

  /* Execute the component to get the virtual node tree */
  let node = component()

  /* Find the actual content (skip root markers if present) */
  let walker = DOMWalker.make(container)

  /* Check for root marker */
  switch DOMWalker.peek(walker) {
  | Some(firstNode) if DOMWalker.isMarkerPrefix(firstNode, "xote-root:") => {
      let _ = DOMWalker.next(walker) // skip root marker
      hydrateNodeWithWalker(node, walker)
    }
  | _ =>
    /* No root marker, hydrate directly */
    hydrateNodeWithWalker(node, walker)
  }

  /* Mark as hydrated */
  let _ = %raw(`window.__XOTE_HYDRATED__ = true`)

  /* Call onHydrated callback if provided */
  switch options.onHydrated {
  | Some(callback) => callback()
  | None => ()
  }
}

/* Hydrate by element ID */
let hydrateById = (
  component: unit => Component.node,
  containerId: string,
  ~options: hydrateOptions={},
): unit => {
  switch DOM.getElementById(containerId)->Nullable.toOption {
  | Some(container) => hydrate(component, container, ~options)
  | None => Console.error(`[Xote Hydration] Container element not found: ${containerId}`)
  }
}
