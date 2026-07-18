module DOM = RuntimeDom
module Reactivity = RuntimeOwner
module Core = RescriptCore

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
  | Keyed({key: string, identity: Obj.t, child: node})
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

module Attr = {
  let string = attr
  let signal = signalAttr
  let compute = computedAttr
}

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

  type keyedChild = {
    key: string,
    identity: Obj.t,
    child: node,
  }

  /* Dispose an element and its reactive state */
  let rec disposeElement = (el: Dom.element): unit => {
    /* Dispose the owner if it exists */
    switch getOwner(el) {
    | Some(owner) => disposeOwner(owner)
    | None => ()
    }

    /* Recursively dispose children */
    el->DOM.childNodesToArray->Array.forEach(disposeElement)
  }

  let shallowEqualIdentity = (a: Obj.t, b: Obj.t): bool =>
    if a === b {
      true
    } else {
      switch (a->Core.Type.Classify.classify, b->Core.Type.Classify.classify) {
      | (Object(objA), Object(objB)) => {
          let dictA: Dict.t<Obj.t> = Obj.magic(objA)
          let dictB: Dict.t<Obj.t> = Obj.magic(objB)
          let keysA = dictA->Dict.keysToArray
          let keysB = dictB->Dict.keysToArray

          if keysA->Array.length !== keysB->Array.length {
            false
          } else {
            keysA->Array.every(key =>
              switch (dictA->Dict.get(key), dictB->Dict.get(key)) {
              | (Some(valueA), Some(valueB)) => valueA === valueB
              | _ => false
              }
            )
          }
        }
      | _ => false
      }
    }

  let clearKeyedItems = (keyedItems: Dict.t<keyedItem<Obj.t>>): unit => {
    keyedItems->Dict.keysToArray->Array.forEach(key => keyedItems->Dict.delete(key)->ignore)
  }

  let getKeyedChildren = (children: array<node>): option<array<keyedChild>> => {
    if children->Core.Array.length == 0 {
      None
    } else {
      let keyedChildren = children->Core.Array.filterMap(child => {
        switch child {
        | Keyed({key, identity, child}) => Some({key, identity, child})
        | _ => None
        }
      })

      if keyedChildren->Core.Array.length == children->Core.Array.length {
        Some(keyedChildren)
      } else {
        None
      }
    }
  }

  let rec reconcileKeyedChildren = (
    ~keyedChildren: array<keyedChild>,
    ~keyedItems: Dict.t<keyedItem<Obj.t>>,
    ~parent: Dom.element,
  ): unit => {
    let newKeyMap: Dict.t<keyedChild> = Dict.make()
    keyedChildren->Array.forEach(child => newKeyMap->Dict.set(child.key, child))

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
          keyedItem.element->DOM.remove
          keyedItems->Dict.delete(key)->ignore
        }
      | None => ()
      }
    })

    let newOrder: array<keyedItem<Obj.t>> = []
    let elementsToReplace: Dict.t<Dom.element> = Dict.make()

    keyedChildren->Array.forEach(keyedChild => {
      switch keyedItems->Dict.get(keyedChild.key) {
      | Some(existing) =>
        if shallowEqualIdentity(existing.item, keyedChild.identity) {
          newOrder->Array.push(existing)->ignore
        } else {
          let element = render(keyedChild.child)
          let keyedItem: keyedItem<Obj.t> = {
            key: keyedChild.key,
            item: keyedChild.identity,
            element,
          }
          elementsToReplace->Dict.set(keyedChild.key, existing.element)
          newOrder->Array.push(keyedItem)->ignore
          keyedItems->Dict.set(keyedChild.key, keyedItem)
        }
      | None => {
          let element = render(keyedChild.child)
          let keyedItem: keyedItem<Obj.t> = {
            key: keyedChild.key,
            item: keyedChild.identity,
            element,
          }
          newOrder->Array.push(keyedItem)->ignore
          keyedItems->Dict.set(keyedChild.key, keyedItem)
        }
      }
    })

    let marker = ref(
      switch DOM.getFirstChild(parent)->Nullable.toOption {
      | Some(node) => Some(node)
      | None => None
      },
    )

    newOrder->Array.forEach(keyedItem => {
      let currentElement = marker.contents

      switch currentElement {
      | Some(elem) if elem === keyedItem.element =>
        marker := DOM.getNextSibling(elem)->Nullable.toOption
      | Some(elem) => {
          switch elementsToReplace->Dict.get(keyedItem.key) {
          | Some(previousElement) if elem === previousElement => {
              disposeElement(previousElement)
              DOM.replaceChild(parent, keyedItem.element, previousElement)
              marker := DOM.getNextSibling(keyedItem.element)->Nullable.toOption
            }
          | _ => {
              DOM.insertBefore(parent, keyedItem.element, elem)
              marker := DOM.getNextSibling(keyedItem.element)->Nullable.toOption
            }
          }
        }
      | None => {
          switch elementsToReplace->Dict.get(keyedItem.key) {
          | Some(previousElement) => {
              disposeElement(previousElement)
              previousElement->DOM.remove
              parent->DOM.appendChild(keyedItem.element)
            }
          | None => parent->DOM.appendChild(keyedItem.element)
          }
        }
      }
    })
  }

  /* Render a virtual node to a DOM element */
  and render = (node: node): Dom.element => {
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
        let keyedItems: Dict.t<keyedItem<Obj.t>> = Dict.make()

        runWithOwner(owner, () => {
          let disposer = Effect.runWithDisposer(() => {
            let children = Signal.get(signal)

            switch getKeyedChildren(children) {
            | Some(keyedChildren) =>
              reconcileKeyedChildren(~keyedChildren, ~keyedItems, ~parent=container)
            | None => {
                clearKeyedItems(keyedItems)

                /* Dispose existing children */
                container->DOM.childNodesToArray->Array.forEach(disposeElement)

                /* Clear existing children */
                DOM.setInnerHTML(container, "")

                /* Render and append new children */
                children->Array.forEach(
                  child => {
                    let childEl = render(child)
                    container->DOM.appendChild(childEl)
                  },
                )
              }
            }

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

    | Keyed({child, key: _, identity: _}) => render(child)

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
                    keyedItem.element->DOM.remove
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

let bool = (value: bool): node => Text(value ? "true" : "false")

/* Fragments */
let fragment = (children: array<node>): node => Fragment(children)

let signalFragment = (signal: Signal.t<array<node>>): node => SignalFragment(signal)

/* Auto-tracked reactive block: every signal read while `body` runs subscribes
   the block, which re-evaluates `body` and replaces its children wholesale
   (no diffing) whenever a dependency changes. Prefer `eachWithKey`/`For` for
   lists and keep tracked blocks small. */
let tracked = (body: unit => node): node => SignalFragment(Computed.make(() => [body()]))

let childrenToArray = (child: option<node>): array<node> => {
  switch child {
  | Some(Fragment(children)) => children
  | Some(child) => [child]
  | None => []
  }
}

/* Lists */
let each = (signal: Signal.t<array<'a>>, renderItem: 'a => node): node => {
  let nodesSignal = Computed.make(() => {
    Signal.get(signal)->Array.map(renderItem)
  })
  SignalFragment(nodesSignal)
}

let eachWithKey = (
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

/* JSX rendering primitives */
module For = {
  type props<'item> = {
    each: Prop.t<array<'item>>,
    by?: 'item => string,
    render: 'item => node,
  }

  let make = (props: props<'item>): node => {
    switch (props.each, props.by) {
    | (Static(items), Some(keyFn)) =>
      fragment(
        items->Array.map(item =>
          Keyed({key: keyFn(item), identity: Obj.magic(item), child: props.render(item)})
        ),
      )
    | (Static(items), None) => fragment(items->Array.map(props.render))
    | (Reactive(signal), Some(keyFn)) => eachWithKey(signal, keyFn, props.render)
    | (Reactive(signal), None) => each(signal, props.render)
    }
  }
}

module KeyedFor = {
  type props<'item> = {
    each: Prop.t<array<'item>>,
    by: 'item => string,
    render: 'item => node,
  }

  let make = (props: props<'item>): node => {
    switch props.each {
    | Static(items) =>
      fragment(
        items->Array.map(item =>
          Keyed({key: props.by(item), identity: Obj.magic(item), child: props.render(item)})
        ),
      )
    | Reactive(signal) => eachWithKey(signal, props.by, props.render)
    }
  }
}

module Show = {
  type props = {
    when_: Prop.t<bool>,
    children?: node,
    fallback?: node,
  }

  let make = (props: props): node => {
    switch props.when_ {
    | Static(true) => fragment(childrenToArray(props.children))
    | Static(false) => fragment(childrenToArray(props.fallback))
    | Reactive(signal) =>
      signalFragment(
        Computed.make(() =>
          if Signal.get(signal) {
            childrenToArray(props.children)
          } else {
            childrenToArray(props.fallback)
          }
        ),
      )
    }
  }
}

module Maybe = {
  type props<'value> = {
    value: Prop.t<option<'value>>,
    render: 'value => node,
    fallback?: node,
  }

  let renderValue = (props: props<'value>, value: option<'value>): array<node> => {
    switch value {
    | Some(value) => [props.render(value)]
    | None => childrenToArray(props.fallback)
    }
  }

  let make = (props: props<'value>): node => {
    switch props.value {
    | Static(value) => fragment(renderValue(props, value))
    | Reactive(signal) => signalFragment(Computed.make(() => renderValue(props, Signal.get(signal))))
    }
  }
}

module Value = {
  type props<'value> = {
    value: Prop.t<'value>,
    render: 'value => node,
  }

  let make = (props: props<'value>): node => {
    switch props.value {
    | Static(value) => props.render(value)
    | Reactive(signal) => signalFragment(Computed.make(() => [props.render(Signal.get(signal))]))
    }
  }
}

/* Element constructor */
let element = (
  tag: string,
  ~attrs: array<(string, attrValue)>=[],
  ~events: array<(string, Dom.event => unit)>=[],
  ~children: array<node>=[],
  (),
): node => Element({tag, attrs, events, children})

/* Null representation */
let null = () => text("")
let empty = null

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

let isReactiveProp = RuntimeValue.isReactiveProp

let valuePrimitive = (value: 'input, stringify: 'value => string): node => {
  if isReactiveProp(value) {
    let prop: Prop.t<'value> = Obj.magic(value)
    switch prop {
    | Static(value) => text(stringify(value))
    | Reactive(signal) => SignalText(Computed.make(() => stringify(Signal.get(signal))))
    }
  } else {
    switch value->Core.Type.Classify.classify {
    | Function(_) => {
        let compute: unit => 'value = Obj.magic(value)
        signalText(() => stringify(compute()))
      }
    | Object(_) => {
        let signal: Signal.t<'value> = Obj.magic(value)
        SignalText(Computed.make(() => stringify(Signal.get(signal))))
      }
    | Null | Undefined => null()
    | _ => {
        let value: 'value = Obj.magic(value)
        text(stringify(value))
      }
    }
  }
}

let renderValuePrimitiveProps = (props: 'props, stringify: 'scalar => string): node => {
  switch (props->RuntimeValue.getField("children"), props->RuntimeValue.getField("value")) {
  | (Some(children), _) => valuePrimitive(children, stringify)
  | (None, Some(value)) => valuePrimitive(value, stringify)
  | (None, None) => null()
  }
}

/* Is this runtime value already a `node`? Nodes are ReScript variants compiled
   to objects carrying a string `TAG` in the set below; Signals, Props, scalars
   and functions are not, so a value already built into a node passes straight
   through `child`. */
let isNode: 'a => bool = %raw(`function (v) {
  if (v === null || typeof v !== "object" || typeof v.TAG !== "string") { return false }
  switch (v.TAG) {
    case "Element":
    case "Text":
    case "SignalText":
    case "Fragment":
    case "SignalFragment":
    case "Keyed":
    case "LazyComponent":
    case "KeyedList":
      return true
    default:
      return false
  }
}`)

/* Stringify any scalar child (int/float/string/bool) without knowing its type
   at compile time; null/undefined render as empty. */
let stringifyChild: 'a => string = %raw(`function (v) { return v == null ? "" : String(v) }`)

/* Coerce an arbitrary JSX child into a node. This is what `@xote.component`
   emits for a *bare* child in element position — `<div>{Signal.get(count)}</div>`
   — so a value primitive (`<View.Int>`) is no longer required:

     - an already-built node passes through untouched;
     - a reactive thunk (what the ppx emits for an eager signal read) re-runs on
       change — a scalar result becomes reactive text, a node result a tracked
       fragment;
     - a bare `Signal.t` becomes reactive text; a plain scalar, static text;
     - null/undefined render nothing.

   The explicit `View.Text`/`Int`/`Float`/`Bool` value primitives still work for
   non-ppx code and for stronger typing; this is the ergonomic default under the
   annotation. */
let child = (value: 'a): node => {
  if isNode(value) {
    (Obj.magic(value): node)
  } else {
    switch value->Core.Type.Classify.classify {
    | Function(_) => {
        let compute: unit => 'b = Obj.magic(value)
        let signal = Computed.make(compute)
        if isNode(Signal.peek(signal)) {
          SignalFragment(Computed.make(() => [(Obj.magic(Signal.get(signal)): node)]))
        } else {
          SignalText(Computed.make(() => stringifyChild(Signal.get(signal))))
        }
      }
    | Object(_) => {
        let signal: Signal.t<'b> = Obj.magic(value)
        SignalText(Computed.make(() => stringifyChild(Signal.get(signal))))
      }
    | Null | Undefined => null()
    | _ => text(stringifyChild(value))
    }
  }
}

module Text = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, value => value)
  }
}

module Int = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, value => value->Int.toString)
  }
}

module Float = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, value => value->Float.toString)
  }
}

module Bool = {
  type props<'value, 'children> = {
    value?: 'value,
    children?: 'children,
  }

  let toString = value => value ? "true" : "false"

  let make = (props: props<'value, 'children>): node => {
    renderValuePrimitiveProps(props, toString)
  }
}
