open Signals

/* External DOM methods */
@send external replaceChild: (Dom.element, Dom.element, Dom.element) => unit = "replaceChild"
@send external insertBefore: (Dom.element, Dom.element, Dom.element) => unit = "insertBefore"

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
  | LazyComponent(unit => node)
  | KeyedList({signal: Signal.t<array<Obj.t>>, keyFn: Obj.t => string, renderItem: Obj.t => node})

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
@val @scope("document") external createComment: string => Dom.element = "createComment"
@val @scope("document")
external getElementById: string => Nullable.t<Dom.element> = "getElementById"

@get external getNextSibling: Dom.element => Nullable.t<Dom.element> = "nextSibling"
@get external getParentNode: Dom.element => Nullable.t<Dom.element> = "parentNode"
@send
external addEventListener: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
@send external appendChild: (Dom.element, Dom.element) => unit = "appendChild"
@send external setAttribute: (Dom.element, string, string) => unit = "setAttribute"
@set external setTextContent: (Dom.element, string) => unit = "textContent"
@set external setValue: (Dom.element, string) => unit = "value"

/* Owner system for component-scoped reactive state */
type owner = {
  disposers: array<Effect.disposer>,
  mutable signals: array<Obj.t>, // Heterogeneous array of signals
  mutable computeds: array<Obj.t>, // Heterogeneous array of computeds
}

/* Global owner stack - tracks current component context */
let currentOwner: ref<option<owner>> = ref(None)

/* Create a new owner */
let createOwner = (): owner => {
  disposers: [],
  signals: [],
  computeds: [],
}

/* Run a function with an owner context */
let runWithOwner = (owner: owner, fn: unit => 'a): 'a => {
  let previousOwner = currentOwner.contents
  currentOwner := Some(owner)
  let result = fn()
  currentOwner := previousOwner
  result
}

/* Register a signal with the current owner */
let registerSignal = (signal: Signal.t<'a>): unit => {
  switch currentOwner.contents {
  | Some(owner) => owner.signals->Array.push(Obj.magic(signal))->ignore
  | None => ()
  }
}

/* Register a computed with the current owner */
let registerComputed = (computed: Signal.t<'a>): unit => {
  switch currentOwner.contents {
  | Some(owner) => owner.computeds->Array.push(Obj.magic(computed))->ignore
  | None => ()
  }
}

/* Register an effect disposer with the current owner */
let registerEffectDisposer = (disposer: Effect.disposer): unit => {
  switch currentOwner.contents {
  | Some(owner) => owner.disposers->Array.push(disposer)->ignore
  | None => ()
  }
}

/* Disposer management for reactive nodes */
type disposerList = array<Effect.disposer>

@set external setDisposers: (Dom.element, disposerList) => unit = "__xote_disposers"
@get external getDisposers: Dom.element => Nullable.t<disposerList> = "__xote_disposers"

@set external setOwner: (Dom.element, owner) => unit = "__xote_owner"
@get external getOwner: Dom.element => Nullable.t<owner> = "__xote_owner"

/* Helper to add a disposer to an element */
let addDisposer = (el: Dom.element, disposer: Effect.disposer): unit => {
  let existing = getDisposers(el)->Nullable.toOption->Option.getOr([])
  setDisposers(el, Array.concat(existing, [disposer]))

  // Also register with current owner if exists
  switch currentOwner.contents {
  | Some(owner) => owner.disposers->Array.push(disposer)->ignore
  | None => ()
  }
}

/* Helper to mark an item as disposed in DevTools if tracking is enabled */
let markAsDisposedInDevTools: Obj.t => unit = %raw(`
  function(item) {
    if (item.__devtoolsId && window.__xoteDevToolsMarkAsDisposed) {
      window.__xoteDevToolsMarkAsDisposed(item.__devtoolsId);
    }
  }
`)

/* Dispose an owner's reactive state */
let disposeOwner = (owner: owner): unit => {
  // Dispose all effects (their dispose wrappers handle DevTools marking)
  owner.disposers->Array.forEach(d => d.dispose())

  // Dispose all computeds and mark in DevTools if available
  owner.computeds->Array.forEach(computed => {
    let computedSignal: Signal.t<'a> = Obj.magic(computed)
    Computed.dispose(computedSignal)
    markAsDisposedInDevTools(computed)
  })

  // Mark signals as disposed in DevTools (signals don't have dispose method)
  owner.signals->Array.forEach(signal => {
    markAsDisposedInDevTools(signal)
  })
}

/* Create a root ownership context (inspired by SolidJS createRoot) */
let createRoot = (fn: (unit => unit) => 'a): (unit => unit) => {
  let owner = createOwner()
  let _ = runWithOwner(owner, () => fn(() => disposeOwner(owner)))
  () => disposeOwner(owner)
}

/* Create a lazy component that runs within its own owner context */
let component = (fn: unit => node): node => {
  LazyComponent(fn)
}

/* Recursively dispose an element and all its children */
let rec disposeElement = (el: Dom.element): unit => {
  /* Dispose this element's owner (signals/computeds/effects) */
  switch getOwner(el)->Nullable.toOption {
  | Some(owner) => {
      disposeOwner(owner)
      setOwner(el, createOwner()) /* Clear the owner */
    }
  | None => ()
  }

  /* Also dispose old-style disposers for backwards compatibility */
  switch getDisposers(el)->Nullable.toOption {
  | Some(disposers) => {
      disposers->Array.forEach(d => d.dispose())
      setDisposers(el, [])
    }
  | None => ()
  }

  /* Dispose all children recursively */
  let children: array<Dom.element> = %raw(`Array.from(el.childNodes || [])`)
  children->Array.forEach(disposeElement)
}

/* Type for tracking keyed list items */
type keyedItem<'a> = {
  key: string,
  item: 'a,
  element: Dom.element,
}

/* Render a virtual node to a real DOM element */
let rec render = (node: node): Dom.element => {
  switch node {
  | Text(content) => createTextNode(content)
  | SignalText(signal) => {
      /* Create owner for this text node's reactive state */
      let owner = createOwner()

      let el = createTextNode(Signal.peek(signal))

      /* Attach owner to element */
      setOwner(el, owner)

      /* Set up effect to update text when signal changes */
      runWithOwner(owner, () => {
        let disposer = Effect.run(() => {
          let content = Signal.get(signal)
          el->setTextContent(content)
          None
        })

        addDisposer(el, disposer)
      })

      el
    }
  | Element({tag, attrs, events, children}) => {
      /* Create owner for this element's reactive state */
      let owner = createOwner()

      /* Create the DOM element */
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

      /* Attach owner to element */
      setOwner(el, owner)

      /* Run rendering within owner context */
      runWithOwner(owner, () => {
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
          | SignalValue(s) =>
            /* Signal attribute - set initial value and subscribe to changes */
            if key == "value" && tag == "input" {
              el->setValue(Signal.peek(s))
              let disposer = Effect.run(
                () => {
                  let v = Signal.get(s)
                  el->setValue(v)
                  None
                },
              )
              addDisposer(el, disposer)
            } else {
              el->setAttribute(key, Signal.peek(s))
              let disposer = Effect.run(
                () => {
                  let v = Signal.get(s)
                  el->setAttribute(key, v)
                  None
                },
              )
              addDisposer(el, disposer)
            }
          | Compute(f) => {
              /* Computed attribute - create computed signal and subscribe */
              let computedSignal = Computed.make(() => f())
              if key == "value" && tag == "input" {
                el->setValue(Signal.peek(computedSignal))
                let disposer = Effect.run(
                  () => {
                    let v = Signal.get(computedSignal)
                    el->setValue(v)
                    None
                  },
                )
                addDisposer(el, disposer)
              } else {
                el->setAttribute(key, Signal.peek(computedSignal))
                let disposer = Effect.run(
                  () => {
                    let v = Signal.get(computedSignal)
                    el->setAttribute(key, v)
                    None
                  },
                )
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
      /* Create owner for this container's reactive state */
      let owner = createOwner()

      /* Create a container element to hold the dynamic children */
      let container = createElement("div")
      setAttribute(container, "data-signal-fragment", "true")
      setAttribute(container, "style", "display: contents")

      /* Attach owner to container */
      setOwner(container, owner)

      /* Set up effect to update children when signal changes */
      runWithOwner(owner, () => {
        let disposer = Effect.run(() => {
          let children = Signal.get(signal)
          /* Dispose existing children before clearing DOM */
          let childNodes: array<Dom.element> = %raw(`Array.from(container.childNodes || [])`)
          childNodes->Array.forEach(disposeElement)
          /* Clear existing children */
          %raw(`container.innerHTML = ''`)
          /* Render and append new children */
          children->Array.forEach(
            child => {
              let childEl = render(child)
              container->appendChild(childEl)
            },
          )
          None
        })

        addDisposer(container, disposer)
      })

      container
    }
  | LazyComponent(fn) => {
      /* Create owner for this component's reactive state */
      let owner = createOwner()

      /* Run component function within owner context */
      let childNode = runWithOwner(owner, fn)

      /* Render the child node */
      let el = render(childNode)

      /* Attach owner to the element for disposal */
      setOwner(el, owner)

      el
    }
  | KeyedList({signal, keyFn, renderItem}) => {
      /* Create owner for this list's reactive state */
      let owner = createOwner()

      /* Create comment anchors to mark the list boundaries */
      let startAnchor = createComment(" keyed-list-start ")
      let endAnchor = createComment(" keyed-list-end ")

      /* Attach owner to start anchor */
      setOwner(startAnchor, owner)

      /* Track keyed items in a mutable map */
      let keyedItems: Dict.t<keyedItem<Obj.t>> = Dict.make()

      /* Helper function to reconcile the list */
      let reconcile = (): unit => {
        /* Get the parent from the end anchor - use fragment for initial render */
        let parentOpt = getParentNode(endAnchor)->Nullable.toOption

        switch parentOpt {
        | None => () /* Not mounted yet, will be handled after mount */
        | Some(parent) => {
            let newItems = Signal.get(signal)

            /* Build a map of new keys for quick lookup */
            let newKeyMap: Dict.t<Obj.t> = Dict.make()
            newItems->Array.forEach(item => {
              let key = keyFn(item)
              newKeyMap->Dict.set(key, item)
            })

            /* Phase 1: Remove items that are no longer in the list */
            let keysToRemove = []
            keyedItems
            ->Dict.keysToArray
            ->Array.forEach(key => {
              switch newKeyMap->Dict.get(key) {
              | None =>
                /* Key no longer exists - mark for removal */
                keysToRemove->Array.push(key)->ignore
              | Some(_) => ()
              }
            })

            /* Dispose and remove old items */
            keysToRemove->Array.forEach(key => {
              switch keyedItems->Dict.get(key) {
              | Some(keyedItem) => {
                  /* Dispose the element and its reactive state */
                  disposeElement(keyedItem.element)
                  /* Remove from DOM */
                  %raw(`keyedItem.element.remove()`)
                  /* Remove from tracking map */
                  keyedItems->Dict.delete(key)->ignore
                }
              | None => ()
              }
            })

            /* Phase 2: Build new order and identify changes */
            let newOrder: array<keyedItem<Obj.t>> = []
            let elementsToReplace: Dict.t<bool> = Dict.make()

            newItems->Array.forEach(item => {
              let key = keyFn(item)

              switch keyedItems->Dict.get(key) {
              | Some(existing) =>
                /* Item exists - check if data has changed */
                if existing.item !== item {
                  /* Item data changed - mark for replacement and re-render */
                  elementsToReplace->Dict.set(key, true)
                  let node = renderItem(item)
                  let element = render(node)
                  let keyedItem = {key, item, element}
                  newOrder->Array.push(keyedItem)->ignore
                  keyedItems->Dict.set(key, keyedItem)
                } else {
                  /* Item unchanged - reuse existing element */
                  newOrder->Array.push(existing)->ignore
                }
              | None => {
                  /* New item - create and render it */
                  let node = renderItem(item)
                  let element = render(node)
                  let keyedItem = {key, item, element}
                  newOrder->Array.push(keyedItem)->ignore
                  keyedItems->Dict.set(key, keyedItem)
                }
              }
            })

            /* Phase 3: Reconcile DOM to match new order */
            /* We insert all elements before the end anchor */
            let marker = ref(getNextSibling(startAnchor))

            newOrder->Array.forEach(keyedItem => {
              /* Get current element at this position (between start anchor and end anchor) */
              let currentElement = marker.contents

              switch currentElement->Nullable.toOption {
              | Some(elem) if elem === endAnchor =>
                /* Reached end anchor - insert here */
                insertBefore(parent, keyedItem.element, endAnchor)
              | Some(elem) if elem === keyedItem.element =>
                /* Element is already in correct position */
                marker := getNextSibling(elem)
              | Some(elem) => {
                  /* Check if this element was marked for replacement */
                  let needsReplacement =
                    elementsToReplace->Dict.get(keyedItem.key)->Option.getOr(false)

                  if needsReplacement {
                    /* Replace old element with new one */
                    disposeElement(elem)
                    replaceChild(parent, keyedItem.element, elem)
                    marker := getNextSibling(keyedItem.element)
                  } else {
                    /* Element needs to be moved here */
                    insertBefore(parent, keyedItem.element, elem)
                    marker := getNextSibling(keyedItem.element)
                  }
                }
              | None =>
                /* No more elements - should not happen between anchors */
                insertBefore(parent, keyedItem.element, endAnchor)
              }
            })
          }
        }
      }

      /* Return a document fragment with both anchors and initial items */
      let fragment = createDocumentFragment()
      fragment->appendChild(startAnchor)

      /* Render initial items into the fragment */
      let initialItems = Signal.peek(signal)
      initialItems->Array.forEach(item => {
        let key = keyFn(item)
        let node = renderItem(item)
        let element = render(node)
        let keyedItem = {key, item, element}
        keyedItems->Dict.set(key, keyedItem)
        fragment->appendChild(element)
      })

      fragment->appendChild(endAnchor)

      /* Set up effect to reconcile list when signal changes */
      runWithOwner(owner, () => {
        let disposer = Effect.run(() => {
          reconcile()
          None
        })

        addDisposer(startAnchor, disposer)
      })

      fragment
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

/* Create a reactive keyed list with efficient reconciliation */
let keyedList = (
  signal: Signal.t<array<'a>>,
  keyFn: 'a => string,
  renderItem: 'a => node,
): node => {
  /* Use Obj.magic to erase the type parameter 'a */
  KeyedList({
    signal: Obj.magic(signal),
    keyFn: Obj.magic(keyFn),
    renderItem: Obj.magic(renderItem),
  })
}
