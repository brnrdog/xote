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
          RuntimeOwner.ownComputed(signal)
          /* The server's text may be stale by the time the client runs, so the
             current value is written once before the node starts following. */
          let current = Signal.peek(signal)
          RuntimeDom.setTextContent(textNode, current)
          RuntimeRender.attachText(textNode, signal, Nullable.make(current))

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

      /* Set up reactivity: the same pass the render path runs, including the
         rule about retiring children the reconciler never tracked. A hydrated
         fragment is not adopted the way a keyed list is: the first pass clears
         the server's nodes and renders them again. */
      RuntimeRender.driveSignalFragment(~container, ~signal)
    }

  | View.Keyed({child, key: _, identity: _}) => hydrateNodeWithWalker(child, walker)

  | View.Element({attrs, events, children}) =>
    switch DOMWalker.next(walker) {
    | Some(domNode) => {
        /* Hydrate reactive attributes; static ones are already in the markup.
           What the effects register belongs to the region being hydrated. */
        attrs->Array.forEach(((key, value)) => {
          switch RuntimeNode.resolveAttr(value) {
          | RuntimeNode.ReadStatic(_) => ()
          | RuntimeNode.ReadReactive(read) => RuntimeRender.attachAttr(domNode, key, read)
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

  | View.KeyedList({signal, keyFn, renderItem}) => {
      /* The list's own markers become its anchors: `kl` carries the owner and
         `/kl` is the tail the reconciler inserts before, exactly as the pair of
         comment nodes the render path creates for itself. Adopting them is what
         lets hydration run the *same* reconcile pass instead of a second
         implementation of it. */
      let startAnchor = DOMWalker.skipUntilMarker(
        walker,
        RuntimeHydrationMarkers.keyedListStartContent,
      )

      let region = RuntimeRender.makeRegion()
      let endAnchor = ref(None)
      let position = ref(0)

      /* Indexed once: a scan per marker would make hydrating a list quadratic
         in its length, which is the size this path exists to serve. */
      let itemsByKey: Dict.t<Obj.t> = Dict.make()
      Signal.peek(signal)->Array.forEach(item => itemsByKey->Dict.set(keyFn(item), item))

      let rec parseKeyedItems = () => {
        switch DOMWalker.peek(walker) {
        | Some(node)
          if DOMWalker.isMarkerPrefix(node, RuntimeHydrationMarkers.keyedItemPrefixContent) => {
            let key = DOMWalker.extractKey(node)->Option.getOr("")
            let _ = DOMWalker.next(walker)

            /* SSR writes the row immediately after its key marker, so the node
               under the cursor is the row — unless the end marker is already
               there, which means the row rendered to nothing and there is no
               element for the reconciler to move. */
            let element = switch DOMWalker.peek(walker) {
            | Some(node)
              if !DOMWalker.isMarker(node, RuntimeHydrationMarkers.keyedItemEndContent) =>
              Some(node)
            | _ => None
            }

            switch (itemsByKey->Dict.get(key), element) {
            /* Hydrate the row through the ordinary path rather than merely
               recording it: its handlers and reactive attributes have to
               attach, or the adopted row renders once and is then inert. The
               row owns what that attaches, exactly like a rendered row. */
            | (Some(item), Some(element)) => {
                let owner = RuntimeOwner.createOwner()
                RuntimeOwner.runWithOwner(owner, () =>
                  hydrateNodeWithWalker(renderItem(item), walker)
                )
                region.items->Map.set(
                  key,
                  {key, item, element, owner, index: position.contents, stamp: 0, anchors: true},
                )
                position := position.contents + 1
              }
            | (Some(_), None) =>
              logHydrationWarning(`Keyed item "${key}" rendered no element on the server`)
            | (None, _) =>
              logHydrationWarning(`Keyed item "${key}" is in the markup but not in the list`)
            }
            let _ = DOMWalker.skipUntilMarker(walker, RuntimeHydrationMarkers.keyedItemEndContent)

            parseKeyedItems()
          }
        | Some(node) if DOMWalker.isMarker(node, RuntimeHydrationMarkers.keyedListEndContent) => {
            endAnchor := Some(node)
            let _ = DOMWalker.next(walker)
          }
        | _ => ()
        }
      }
      parseKeyedItems()

      /* Without this the parsed items were dropped on the floor: the list kept
         the server's markup and never subscribed to `signal`, so every later
         write was invisible and a hydrated `View.For` stayed frozen for the
         life of the page. */
      switch (startAnchor, endAnchor.contents) {
      | (Some(_), Some(endAnchor)) =>
        RuntimeRender.attachKeyedList(~region, ~signal, ~keyFn, ~renderItem, ~endAnchor)
      | _ => logHydrationWarning("Keyed list markers are missing; the list will not update")
      }
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
