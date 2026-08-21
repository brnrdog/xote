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
  /* View types */
  let elementNode = 1
  let commentNode = 8

  /* Get node type */
  @get external nodeType: Dom.element => int = "nodeType"

  /* Get node value (for comments/text) */
  @get external nodeValue: Dom.element => Nullable.t<string> = "nodeValue"

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
      | Some(value) if String.startsWith(value, RuntimeHydrationMarkers.keyedItemPrefixContent) =>
        Some(
          String.slice(value, ~start=String.length(RuntimeHydrationMarkers.keyedItemPrefixContent)),
        )
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

let logHydrationWarning = (msg: string): unit => {
  Console.warn(`[Xote Hydration] ${msg}`)
}

/* ============================================================================
 * Core Hydration Logic
 * ============================================================================ */

/* Hydrate a node by walking the server-rendered siblings of `walker` */
let rec hydrateNodeWithWalker = (node: View.node, walker: DOMWalker.t): unit => {
  switch node {
  | View.Text(_) => {
      /* Skip text node in DOM */
      let _ = DOMWalker.next(walker)
    }

  | View.SignalText(signal) => {
      /* Find the marker, then hydrate the text node */
      let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.signalTextStartContent)

      /* Get the text node */
      switch DOMWalker.next(walker) {
      | Some(textNode) => {
          let owner = RuntimeOwner.createOwner()
          RuntimeOwner.setOwner(textNode, owner)

          RuntimeOwner.runWithOwner(owner, () =>
            Effect.run(() => {
              RuntimeDom.setTextContent(textNode, Signal.get(signal))
              None
            })
          )

          /* Skip end marker */
          let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.signalTextEndContent)
        }
      | None => logHydrationWarning("Missing text node for SignalText")
      }
    }

  | View.Fragment(children) =>
    /* Fragment children are inline - hydrate each */
    children->Array.forEach(child => {
      hydrateNodeWithWalker(child, walker)
    })

  | View.SignalFragment(signal) => {
      /* Find the container (div with display:contents in SSR, markers in comments) */
      let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.signalFragmentStartContent)

      /* Collect all nodes until end marker - these become the container's content */
      let contentNodes = DOMWalker.collectUntilMarker(
        walker,
        RuntimeHydrationMarkers.signalFragmentEndContent,
      )

      /* Create a container div to hold the signal fragment */
      let container = RuntimeDom.createElement("div")
      RuntimeDom.setAttribute(container, "style", "display: contents")

      /* Get parent before moving nodes (we need it for insertion) */
      let parent: option<Dom.element> = switch contentNodes->Array.get(0) {
      | Some(firstNode) => RuntimeDom.getParentNode(firstNode)->Nullable.toOption
      | None => None
      }

      /* Move content nodes into container */
      contentNodes->Array.forEach(node => {
        container->RuntimeDom.appendChild(node)
      })

      /* Insert container where the markers were */
      switch (parent, DOMWalker.peek(walker)) {
      | (Some(p), Some(nextNode)) => RuntimeDom.insertBefore(p, container, nextNode)
      | (Some(p), None) => RuntimeDom.appendChild(p, container)
      | (None, _) => () /* No content nodes, nothing to do */
      }

      /* Set up reactivity */
      let owner = RuntimeOwner.createOwner()
      RuntimeOwner.setOwner(container, owner)
      let keyedItems: Dict.t<RuntimeRender.keyedItem<Obj.t>> = Dict.make()
      let initialized = ref(false)

      RuntimeOwner.runWithOwner(owner, () =>
        Effect.run(() => {
          let children = Signal.get(signal)

          switch RuntimeRender.getKeyedChildren(children) {
          | Some(keyedChildren) if initialized.contents =>
            RuntimeRender.reconcileKeyedChildren(~keyedChildren, ~keyedItems, ~parent=container)
          | keyedChildrenOpt => {
              RuntimeRender.clearKeyedItems(keyedItems)

              /* Clear and re-render */
              let childNodes = RuntimeDom.childNodesToArray(container)
              childNodes->Array.forEach(RuntimeRender.disposeElement)
              RuntimeDom.setInnerHTML(container, "")

              switch keyedChildrenOpt {
              | Some(keyedChildren) =>
                keyedChildren->Array.forEach(
                  keyedChild => {
                    let childEl = RuntimeRender.render(keyedChild.child)
                    keyedItems->Dict.set(
                      keyedChild.key,
                      {
                        key: keyedChild.key,
                        item: keyedChild.identity,
                        element: childEl,
                      },
                    )
                    container->RuntimeDom.appendChild(childEl)
                  },
                )
              | None =>
                children->Array.forEach(
                  child => {
                    let childEl = RuntimeRender.render(child)
                    container->RuntimeDom.appendChild(childEl)
                  },
                )
              }

              initialized := true
            }
          }

          None
        })
      )
    }

  | View.Keyed({child, key: _, identity: _}) => hydrateNodeWithWalker(child, walker)

  | View.Element({attrs, events, children}) =>
    switch DOMWalker.next(walker) {
    | Some(domNode) => {
        let owner = RuntimeOwner.createOwner()
        RuntimeOwner.setOwner(domNode, owner)

        RuntimeOwner.runWithOwner(owner, () => {
          /* Hydrate reactive attributes */
          attrs->Array.forEach(((key, value)) => {
            switch RuntimeNode.resolveAttr(value) {
            | RuntimeNode.ReadStatic(_) => ()
            | RuntimeNode.ReadReactive(read) =>
              Effect.run(() => {
                RuntimeDom.setAttrOrProp(domNode, key, read())
                None
              })
            }
          })

          /* Attach event listeners */
          events->Array.forEach(((eventName, handler)) => {
            domNode->RuntimeDom.addEventListener(eventName, handler)
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

  | View.LazyComponent(fn) => {
      /* Skip the lazy component markers and hydrate the content */
      let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.lazyComponentStartContent)

      /* Same scope rule as `RuntimeRender`: a component body never subscribes
         whatever observer happens to be running. */
      let childNode = Signal.untrack(fn)
      hydrateNodeWithWalker(childNode, walker)

      let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.lazyComponentEndContent)
    }

  | View.KeyedList({signal, keyFn, renderItem: _}) => {
      /* Find the keyed list in the DOM */
      let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.keyedListStartContent)

      /* Parse existing keyed items from DOM */
      let keyedItems: Dict.t<RuntimeRender.keyedItem<Obj.t>> = Dict.make()

      let rec parseKeyedItems = () => {
        switch DOMWalker.peek(walker) {
        | Some(node)
          if DOMWalker.isMarkerPrefix(node, RuntimeHydrationMarkers.keyedItemPrefixContent) => {
            let key = DOMWalker.extractKey(node)->Option.getOr("")
            let _ = DOMWalker.next(walker)

            let itemElements = DOMWalker.collectUntilMarker(
              walker,
              RuntimeHydrationMarkers.keyedItemEndContent,
            )

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
        | Some(node) if DOMWalker.isMarker(node, RuntimeHydrationMarkers.keyedListEndContent) => {
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
  component: unit => View.node,
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
  component: unit => View.node,
  containerId: string,
  ~options: hydrateOptions={},
): unit => {
  switch RuntimeDom.getElementById(containerId)->Nullable.toOption {
  | Some(container) => hydrate(component, container, ~options)
  | None => Console.error(`[Xote Hydration] Container element not found: ${containerId}`)
  }
}
