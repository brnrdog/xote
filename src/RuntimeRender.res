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
/* Visit every node of `root`'s subtree, `root` included.

   Disposal used to recurse, snapshotting each node's children into an array
   purely to iterate them — one throwaway array per node, measured at ten per
   row, so clearing a ten-thousand-row list allocated about a hundred thousand
   of them. Those snapshots were not pointless, though: a cleanup can mutate the
   tree while the walk is running, and a plain `nextSibling` walk loses the rest
   of a sibling chain the moment a cleanup detaches one of them.

   An explicit stack gets both. Each node's children are pushed *before* it is
   visited, so a node's own cleanup cannot hide them, and once pushed they are
   held by reference — detaching or moving a node that is already on the stack
   cannot drop it. One stack for the whole subtree replaces one array per node. */
let visitSubtree: (Dom.element, Dom.element => unit) => unit = %raw(`function (root, visit) {
  const stack = [root]
  while (stack.length > 0) {
    const node = stack.pop()
    for (let child = node.firstChild; child !== null; child = child.nextSibling) {
      stack.push(child)
    }
    visit(node)
  }
}`)

let disposeElement = (el: Dom.element): unit =>
  visitSubtree(el, node =>
    switch getOwner(node) {
    | Some(owner) => disposeOwner(owner)
    | None => ()
    }
  )

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

/* Does the reconciler already track an element in this container? Asked
   without materialising the key array: `keysToArray` on a ten-thousand-row map
   allocates ten thousand strings to answer a yes/no question the first key
   settles, and this runs on every pass. */
let tracksItems: Dict.t<keyedItem<Obj.t>> => bool = %raw(`function (items) {
  for (const _ in items) { return true }
  return false
}`)

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

/* ---- minimal reordering ---------------------------------------------------

   Both keyed paths finish by putting elements into the order the new list asks
   for. The obvious way — walk the desired order against the live DOM and insert
   whatever does not match — is what this used to do, and it cascades: one early
   mismatch puts every later element out of step with the walk, so swapping two
   rows of a thousand issued 997 `insertBefore` calls where Vue and SolidJS
   issue 2.

   The fix is to move the *complement* instead. Nodes already sitting in the
   right relative order need no moving at all, and the largest such set is a
   longest increasing subsequence of their current DOM positions; everything
   outside it is inserted around it, walking backwards so the next element in
   the desired order is always available as the insertion anchor. */

/* Current position of each element among `parent`'s children, or -1 for one
   that is not a child yet (freshly built, or rebuilt after an identity change).
   A -1 can never be "already in place", so such elements are always inserted.
   Foreign siblings shift every index equally, which leaves the relative order —
   the only thing the subsequence depends on — intact. */
let currentPositions: (Dom.element, array<Dom.element>) => array<int> = %raw(`function (parent, elements) {
  const positions = new Map()
  let i = 0
  for (let node = parent.firstChild; node !== null; node = node.nextSibling) {
    positions.set(node, i++)
  }
  return elements.map((element) => {
    const at = positions.get(element)
    return at === undefined ? -1 : at
  })
}`)

/* Indices of a longest increasing subsequence of `values`, ascending. Entries
   equal to `skip` are excluded. Patience sorting, O(n log n): `piles` holds, for
   each achievable length, the index of the smallest tail seen so far, and
   `parents` threads each entry back to its predecessor so the run can be
   reconstructed once the best length is known. */
let longestIncreasingSubsequence = (values: array<int>, ~skip: int): array<int> => {
  let count = Array.length(values)
  let parents = Array.make(~length=count, -1)
  let piles: array<int> = []

  values->Array.forEachWithIndex((value, index) => {
    if value != skip {
      let low = ref(0)
      let high = ref(Array.length(piles))
      while low.contents < high.contents {
        let middle = (low.contents + high.contents) / 2
        let tail = piles->Array.getUnsafe(middle)
        if values->Array.getUnsafe(tail) < value {
          low := middle + 1
        } else {
          high := middle
        }
      }
      let at = low.contents
      if at > 0 {
        parents->Array.setUnsafe(index, piles->Array.getUnsafe(at - 1))
      }
      if at == Array.length(piles) {
        piles->Array.push(index)->ignore
      } else {
        piles->Array.setUnsafe(at, index)
      }
    }
  })

  let length = Array.length(piles)
  let result = Array.make(~length, 0)
  if length > 0 {
    let cursor = ref(piles->Array.getUnsafe(length - 1))
    let slot = ref(length - 1)
    while slot.contents >= 0 {
      result->Array.setUnsafe(slot.contents, cursor.contents)
      cursor := parents->Array.getUnsafe(cursor.contents)
      slot := slot.contents - 1
    }
  }
  result
}

/* A node can only anchor an `insertBefore` on `parent` if it is actually a
   child of it. A row that rendered to a fragment is emptied when it is
   appended and ends up parented nowhere, so it must never become the anchor
   for the row before it. */
let isChildOf: (Dom.element, Dom.element) => bool = %raw(`function (parent, node) {
  return node.parentNode === parent
}`)

let insertOrAppend = (parent: Dom.element, element: Dom.element, before: Nullable.t<Dom.element>) =>
  switch before->Nullable.toOption {
  | Some(node) => RuntimeDom.insertBefore(parent, element, node)
  | None => parent->RuntimeDom.appendChild(element)
  }

/* Put `items` into `parent` in the given order, moving as few nodes as
   possible. `tail` is what the last item must precede — a keyed list's end
   anchor — or null to append at the end. */
let placeInOrder = (
  ~parent: Dom.element,
  ~items: array<keyedItem<Obj.t>>,
  ~tail: Nullable.t<Dom.element>,
): unit => {
  let positions = currentPositions(parent, items->Array.map(item => item.element))
  let settled = longestIncreasingSubsequence(positions, ~skip=-1)

  let nextSettled = ref(Array.length(settled) - 1)
  let before = ref(tail)
  let index = ref(Array.length(items) - 1)

  while index.contents >= 0 {
    let item = items->Array.getUnsafe(index.contents)
    let staysPut =
      nextSettled.contents >= 0 &&
        settled->Array.getUnsafe(nextSettled.contents) == index.contents

    if staysPut {
      nextSettled := nextSettled.contents - 1
    } else {
      insertOrAppend(parent, item.element, before.contents)
    }

    if isChildOf(parent, item.element) {
      before := Nullable.make(item.element)
    }
    index := index.contents - 1
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

  placeInOrder(~parent, ~items=newOrder, ~tail=Nullable.null)
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
          | Some(keyedChildren) => {
              /* Keyed reconciliation can only retire elements it tracked in
                 `keyedItems`. The dict is empty in exactly two cases: the first
                 pass (container empty, the sweep is a no-op) and right after a
                 non-keyed pass — whose children are foreign to the reconciler
                 and must be retired here, or a `Show` fallback stays in the DOM
                 next to the keyed list that replaces it. */
              if !tracksItems(keyedItems) {
                container->RuntimeDom.childNodesToArray->Array.forEach(disposeElement)
                RuntimeDom.setInnerHTML(container, "")
              }
              reconcileKeyedChildren(~keyedChildren, ~keyedItems, ~parent=container)
            }
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

      /* Most elements are static and register nothing, so the scope only
         becomes an owner if an attribute effect or a component body inside it
         actually needs one — see `RuntimeOwner`'s scope note. */
      runInScope(scopeFor(~host=Nullable.make(el)), () => {
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
      /* The component's element does not exist until its body has run, so this
         scope carries no host and is attached below — but only if the body
         registered anything, which a component with no effects never does. */
      let scope = scopeFor(~host=Nullable.null)

      /* A component body is its own reactive scope. Rendering happens inside
         the enclosing region's effect (a `SignalFragment`, a keyed list), so
         without the untrack an eager read in the body — a `let` binding, a
         one-shot prop read — subscribes *that* region: one unrelated update
         then rebuilds the whole region wholesale, taking input focus and
         scroll position with it. Reads deferred into a thunk, a `Computed` or
         an `Effect` set up their own scope and are unaffected. */
      let childNode = runInScope(scope, () => Signal.untrack(fn))
      let el = render(childNode)

      /* `el` already carries its own scope (its attribute effects); merge into
         it rather than replacing it. A fragment root is emptied when it is
         appended, so the component's scope rides on its first child instead. */
      switch scope.owner {
      | Some(owner) =>
        if RuntimeDom.isDocumentFragment(el) {
          switch RuntimeDom.getFirstChild(el)->Nullable.toOption {
          | Some(firstChild) => attachOwner(firstChild, owner)
          | None => ()
          }
        } else {
          attachOwner(el, owner)
        }
      | None => ()
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

            /* Phase 3: Reconcile DOM — see `placeInOrder`. */
            placeInOrder(~parent, ~items=newOrder, ~tail=Nullable.make(endAnchor))
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
