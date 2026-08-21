/* Internal: turns a `RuntimeNode.node` tree into live DOM.

   Shared by `View.mount` and by `Hydration`, which reuses the same
   reconciliation logic once a server-rendered tree becomes interactive. Not
   part of the public API — consumers go through `View`. */

open RuntimeNode
open RuntimeOwner

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

/* A node backed by a computed the library created carries its release with it:
   the scope that renders the node disposes the computed when the node goes
   away. A signal the consumer built and handed us is left alone. */
let ownComputed = (owner: owner, signal: Signal.t<'a>): unit =>
  if isOwned(signal) {
    addComputed(owner, Obj.magic(signal))
  }

/* Dispose an element and its reactive state */
let rec disposeElement = (el: Dom.element): unit => {
  /* Dispose the owner if it exists */
  switch getOwner(el) {
  | Some(owner) => disposeOwner(owner)
  | None => ()
  }

  /* Recursively dispose children */
  el->RuntimeDom.childNodesToArray->Array.forEach(disposeElement)
}

let shallowEqualIdentity = (a: Obj.t, b: Obj.t): bool =>
  if a === b {
    true
  } else {
    if RuntimeValue.isObject(a) && RuntimeValue.isObject(b) {
      let dictA: Dict.t<Obj.t> = Obj.magic(a)
      let dictB: Dict.t<Obj.t> = Obj.magic(b)
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
    } else {
      false
    }
  }

let clearKeyedItems = (keyedItems: Dict.t<keyedItem<Obj.t>>): unit => {
  keyedItems->Dict.keysToArray->Array.forEach(key => keyedItems->Dict.delete(key)->ignore)
}

let getKeyedChildren = (children: array<node>): option<array<keyedChild>> => {
  if children->Array.length == 0 {
    None
  } else {
    let keyedChildren = children->Array.filterMap(child => {
      switch child {
      | Keyed({key, identity, child}) => Some({key, identity, child})
      | _ => None
      }
    })

    if keyedChildren->Array.length == children->Array.length {
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
        keyedItem.element->RuntimeDom.remove
        keyedItems->Dict.delete(key)->ignore
      }
    | None => ()
    }
  })

  let newOrder: array<keyedItem<Obj.t>> = []

  /* A key whose identity changed is rebuilt and its previous element retired
     right here — see the note in the `KeyedList` build phase below. */
  let buildChild = (keyedChild: keyedChild) => {
    let element = render(keyedChild.child)
    let keyedItem: keyedItem<Obj.t> = {
      key: keyedChild.key,
      item: keyedChild.identity,
      element,
    }
    newOrder->Array.push(keyedItem)->ignore
    keyedItems->Dict.set(keyedChild.key, keyedItem)
  }

  keyedChildren->Array.forEach(keyedChild => {
    switch keyedItems->Dict.get(keyedChild.key) {
    | Some(existing) =>
      if shallowEqualIdentity(existing.item, keyedChild.identity) {
        newOrder->Array.push(existing)->ignore
      } else {
        disposeElement(existing.element)
        existing.element->RuntimeDom.remove
        buildChild(keyedChild)
      }
    | None => buildChild(keyedChild)
    }
  })

  let marker = ref(
    switch RuntimeDom.getFirstChild(parent)->Nullable.toOption {
    | Some(node) => Some(node)
    | None => None
    },
  )

  newOrder->Array.forEach(keyedItem => {
    let currentElement = marker.contents

    switch currentElement {
    | Some(elem) if elem === keyedItem.element =>
      marker := RuntimeDom.getNextSibling(elem)->Nullable.toOption
    | Some(elem) => {
        RuntimeDom.insertBefore(parent, keyedItem.element, elem)
        marker := RuntimeDom.getNextSibling(keyedItem.element)->Nullable.toOption
      }
    | None => parent->RuntimeDom.appendChild(keyedItem.element)
    }
  })
}

/* Render a virtual node to a DOM element */
and render = (node: node): Dom.element => {
  switch node {
  | Text(content) => RuntimeDom.createTextNode(content)

  | SignalText(signal) => {
      let textNode = RuntimeDom.createTextNode(Signal.peek(signal))
      let owner = createOwner()
      setOwner(textNode, owner)
      ownComputed(owner, signal)

      runWithOwner(owner, () =>
        Effect.run(() => {
          RuntimeDom.setTextContent(textNode, Signal.get(signal))
          None
        })
      )

      textNode
    }

  | Fragment(children) => {
      let fragment = RuntimeDom.createDocumentFragment()
      children->Array.forEach(child => {
        let childEl = render(child)
        fragment->RuntimeDom.appendChild(childEl)
      })
      fragment
    }

  | SignalFragment(signal) => {
      let owner = createOwner()
      let container = RuntimeDom.createElement("div")
      RuntimeDom.setAttribute(container, "style", "display: contents")
      setOwner(container, owner)
      ownComputed(owner, signal)
      let keyedItems: Dict.t<keyedItem<Obj.t>> = Dict.make()

      runWithOwner(owner, () =>
        Effect.run(() => {
          let children = Signal.get(signal)

          switch getKeyedChildren(children) {
          | Some(keyedChildren) =>
            reconcileKeyedChildren(~keyedChildren, ~keyedItems, ~parent=container)
          | None => {
              clearKeyedItems(keyedItems)

              /* Dispose existing children */
              container->RuntimeDom.childNodesToArray->Array.forEach(disposeElement)

              /* Clear existing children */
              RuntimeDom.setInnerHTML(container, "")

              /* Render and append new children */
              children->Array.forEach(
                child => {
                  let childEl = render(child)
                  container->RuntimeDom.appendChild(childEl)
                },
              )
            }
          }

          None
        })
      )

      container
    }

  | Element({tag, attrs, events, children}) => {
      let el = RuntimeDom.createElementForTag(tag)
      let owner = createOwner()
      setOwner(el, owner)

      runWithOwner(owner, () => {
        let shouldDeferAttrUntilAfterChildren = ((key, _value)) => tag == "select" && key == "value"

        let applyAttr = ((key, value)) => {
          switch resolveAttr(value) {
          | ReadStatic(value) => RuntimeDom.setAttrOrProp(el, key, value)
          | ReadReactive(read) =>
            Effect.run(() => {
              RuntimeDom.setAttrOrProp(el, key, read())
              None
            })
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
          el->RuntimeDom.addEventListener(eventName, handler)
        })

        /* Append children */
        children->Array.forEach(child => {
          let childEl = render(child)
          el->RuntimeDom.appendChild(childEl)
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

      /* A component body is its own reactive scope. Rendering happens inside
         the enclosing region's effect (a `SignalFragment`, a keyed list), so
         without the untrack an eager read in the body — a `let` binding, a
         one-shot prop read — subscribes *that* region: one unrelated update
         then rebuilds the whole region wholesale, taking input focus and
         scroll position with it. Reads deferred into a thunk, a `Computed` or
         an `Effect` set up their own scope and are unaffected. */
      let childNode = runWithOwner(owner, () => Signal.untrack(fn))
      let el = render(childNode)

      /* `el` already carries its own scope (its attribute effects); merge into
         it rather than replacing it. A fragment root is emptied when it is
         appended, so the component's scope rides on its first child instead. */
      if RuntimeDom.isDocumentFragment(el) {
        switch RuntimeDom.getFirstChild(el)->Nullable.toOption {
        | Some(firstChild) => attachOwner(firstChild, owner)
        | None => ()
        }
      } else {
        attachOwner(el, owner)
      }

      el
    }

  | KeyedList({signal, keyFn, renderItem}) => {
      let owner = createOwner()
      let startAnchor = RuntimeDom.createComment(" keyed-list-start ")
      let endAnchor = RuntimeDom.createComment(" keyed-list-end ")

      setOwner(startAnchor, owner)

      let keyedItems: Dict.t<keyedItem<Obj.t>> = Dict.make()

      /* Reconciliation logic */
      let reconcile = (): unit => {
        let parentOpt = RuntimeDom.getParentNode(endAnchor)->Nullable.toOption

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
                  keyedItem.element->RuntimeDom.remove
                  keyedItems->Dict.delete(key)->ignore
                }
              | None => ()
              }
            })

            /* Phase 2: Build new order.

               A key whose item identity changed is rebuilt, and its previous
               element is retired *here*, where we still know which element it
               was. Deferring that to the ordering pass below would dispose
               whatever happens to sit at the marker — a different key's element
               once the list is also reordered — killing that row's effects
               while leaving the replaced one behind in the DOM. */
            let newOrder: array<keyedItem<Obj.t>> = []

            let buildItem = (key, item) => {
              let node = renderItem(item)
              let element = render(node)
              let keyedItem = {key, item, element}
              newOrder->Array.push(keyedItem)->ignore
              keyedItems->Dict.set(key, keyedItem)
            }

            newItems->Array.forEach(item => {
              let key = keyFn(item)

              switch keyedItems->Dict.get(key) {
              | Some(existing) =>
                if existing.item !== item {
                  disposeElement(existing.element)
                  existing.element->RuntimeDom.remove
                  buildItem(key, item)
                } else {
                  newOrder->Array.push(existing)->ignore
                }
              | None => buildItem(key, item)
              }
            })

            /* Phase 3: Reconcile DOM */
            let marker = ref(RuntimeDom.getNextSibling(startAnchor))

            newOrder->Array.forEach(keyedItem => {
              let currentElement = marker.contents

              switch currentElement->Nullable.toOption {
              | Some(elem) if elem === endAnchor =>
                RuntimeDom.insertBefore(parent, keyedItem.element, endAnchor)
              | Some(elem) if elem === keyedItem.element =>
                marker := RuntimeDom.getNextSibling(elem)
              | Some(elem) => {
                  RuntimeDom.insertBefore(parent, keyedItem.element, elem)
                  marker := RuntimeDom.getNextSibling(keyedItem.element)
                }
              | None => RuntimeDom.insertBefore(parent, keyedItem.element, endAnchor)
              }
            })
          }
        }
      }

      /* Initial render */
      let fragment = RuntimeDom.createDocumentFragment()
      fragment->RuntimeDom.appendChild(startAnchor)

      let initialItems = Signal.peek(signal)
      initialItems->Array.forEach(item => {
        let key = keyFn(item)
        let node = renderItem(item)
        let element = render(node)
        let keyedItem = {key, item, element}
        keyedItems->Dict.set(key, keyedItem)
        fragment->RuntimeDom.appendChild(element)
      })

      fragment->RuntimeDom.appendChild(endAnchor)

      runWithOwner(owner, () =>
        Effect.run(() => {
          reconcile()
          None
        })
      )

      fragment
    }
  }
}
