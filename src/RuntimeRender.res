/* Internal: turns a `RuntimeNode.node` tree into live DOM.

   Shared by `View.mount` and by `Hydration`, which reuses the same
   reconciliation logic once a server-rendered tree becomes interactive. Not
   part of the public API — consumers go through `View`. */

open RuntimeNode
open RuntimeOwner

/* A row the keyed reconciler tracks. */
type keyedItem<'a> = {
  key: string,
  mutable item: 'a,
  mutable element: Dom.element,
  /* Everything reactive the row created; disposed when the row goes. */
  mutable owner: owner,
  /* Where the row stood after the last pass. Rows are placed in list order,
     so these are also their relative DOM order, which is all a reorder needs
     to know — no walk over the live children to find out. */
  mutable index: int,
  /* The pass that last listed this key; an older stamp means the row is gone. */
  mutable stamp: int,
  /* Whether the row's node can anchor an `insertBefore` — false for a row that
     rendered to a fragment, which is emptied when appended and so is a child
     of nothing. Decided once, when the row is built, rather than read back
     from the DOM for every row on every pass. */
  mutable anchors: bool,
}

type keyedChild = {
  key: string,
  identity: Obj.t,
  child: node,
}

/* The state of one reactive region: the rows it tracks by key, and the owner
   of whatever it rendered outside those rows on its last pass (a fragment's
   non-keyed children, or what a fragment's body created while it ran).

   Kept as one record so that the render path and hydration drive the same
   reconciler against the same bookkeeping. */
type region = {
  items: Map.t<string, keyedItem<Obj.t>>,
  mutable pass: int,
  mutable content: option<owner>,
  /* The shapes this region has rendered, for cloning — see `RuntimeTemplate`. */
  templates: RuntimeTemplate.cache,
}

let makeRegion = (): region => {
  items: Map.make(),
  pass: 0,
  content: None,
  templates: RuntimeTemplate.makeCache(),
}

let releaseContent = (region: region): unit =>
  switch region.content {
  | Some(owner) => {
      region.content = None
      disposeOwner(owner)
    }
  | None => ()
  }

let releaseItems = (region: region): unit =>
  if region.items->Map.size > 0 {
    region.items->Map.forEach(item => disposeOwner(item.owner))
    region.items->Map.clear
  }

/* Everything the region rendered is released when the region that rendered
   *it* goes away. */
let disposeRegion = (region: region): unit => {
  releaseItems(region)
  releaseContent(region)
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
   longest increasing subsequence of their current positions; everything
   outside it is inserted around it, walking backwards so the next element in
   the desired order is always available as the insertion anchor. */

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

let insertOrAppend = (parent: Dom.element, element: Dom.element, before: Nullable.t<Dom.element>) =>
  switch before->Nullable.toOption {
  | Some(node) => RuntimeDom.insertBefore(parent, element, node)
  | None => parent->RuntimeDom.appendChild(element)
  }

/* Put `items` into `parent` in the given order, moving as few nodes as
   possible. `tail` is what the last item must precede — a keyed list's end
   anchor — or null to append at the end. A row with index -1 is not in the
   document yet (freshly built, or rebuilt after an identity change) and can
   never be "already in place", so it is always inserted. */
let placeInOrder = (
  ~parent: Dom.element,
  ~items: array<keyedItem<Obj.t>>,
  ~tail: Nullable.t<Dom.element>,
): unit => {
  let positions = items->Array.map(item => item.index)
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

    if item.anchors {
      before := Nullable.make(item.element)
    }
    index := index.contents - 1
  }
}

/* The rows that survived kept their relative order, so nothing that is in the
   document has to move: only the fresh rows (index -1) need inserting. Each
   run of consecutive fresh rows is gathered into a fragment and inserted in
   one call before the surviving row that follows it — in document order, so
   that a row is never inserted ahead of one the browser has just laid out. */
let insertFresh = (
  ~parent: Dom.element,
  ~items: array<keyedItem<Obj.t>>,
  ~tail: Nullable.t<Dom.element>,
): unit => {
  let run: ref<Nullable.t<Dom.element>> = ref(Nullable.null)
  let count = Array.length(items)
  let index = ref(0)
  while index.contents < count {
    let item = items->Array.getUnsafe(index.contents)
    if item.index == -1 {
      let fragment = switch run.contents->Nullable.toOption {
      | Some(fragment) => fragment
      | None => {
          let fragment = RuntimeDom.createDocumentFragment()
          run := Nullable.make(fragment)
          fragment
        }
      }
      fragment->RuntimeDom.appendChild(item.element)
    } else if item.anchors {
      switch run.contents->Nullable.toOption {
      | Some(fragment) => {
          RuntimeDom.insertBefore(parent, fragment, item.element)
          run := Nullable.null
        }
      | None => ()
      }
    }
    index := index.contents + 1
  }
  switch run.contents->Nullable.toOption {
  | Some(fragment) => insertOrAppend(parent, fragment, tail)
  | None => ()
  }
}

/* One reconcile pass of a keyed region against `count` entries, described by
   accessors so the keyed list (items in a signal) and the keyed fragment
   children (`Keyed` nodes) share the algorithm.

   The pass walks the new order once: a key it already tracks is kept if its
   identity is unchanged and rebuilt in place if not; a new key is built. Rows
   are stamped as they are seen, so the stale ones are whatever the map still
   holds with an older stamp — found without materialising the key set, and
   not looked for at all when nothing was dropped. A key whose identity changed
   is retired *here*, where we still know which element it was: deferring that
   to the ordering pass would dispose whatever happens to sit at the marker — a
   different key's element once the list is also reordered — killing that row's
   effects while leaving the replaced one behind in the DOM.

   Placement then costs what the update needs. Survivors that kept their
   relative order (an append, a removal, a creation from empty) mean no node in
   the document moves and only fresh rows are inserted; otherwise the minimal
   move set is computed — see `placeInOrder`. */
let reconcileKeyed = (
  ~region: region,
  ~parent: Dom.element,
  ~count: int,
  ~keyAt: int => string,
  ~itemAt: int => Obj.t,
  ~sameIdentity: (Obj.t, Obj.t) => bool,
  ~build: Obj.t => Dom.element,
  ~tail: Nullable.t<Dom.element>,
): unit => {
  let items = region.items
  region.pass = region.pass + 1
  let pass = region.pass

  let order: array<keyedItem<Obj.t>> = []
  let survivors = ref(0)
  let fresh = ref(0)
  let ordered = ref(true)
  let lastIndex = ref(-1)

  let buildInto = (row: keyedItem<Obj.t>, item: Obj.t) => {
    let owner = createOwner()
    row.item = item
    row.owner = owner
    let element = runWithOwner(owner, () => build(item))
    row.element = element
    row.anchors = !RuntimeDom.isDocumentFragment(element)
    row.index = -1
    fresh := fresh.contents + 1
  }

  let position = ref(0)
  while position.contents < count {
    let key = keyAt(position.contents)
    let item = itemAt(position.contents)
    switch items->Map.get(key) {
    | Some(existing) if existing.stamp != pass => {
        if sameIdentity(existing.item, item) {
          if existing.index <= lastIndex.contents {
            ordered := false
          }
          lastIndex := existing.index
        } else {
          disposeOwner(existing.owner)
          existing.element->RuntimeDom.remove
          buildInto(existing, item)
        }
        existing.stamp = pass
        survivors := survivors.contents + 1
        order->Array.push(existing)->ignore
      }
    | Some(_) =>
      /* The same key twice in one pass: the first occurrence keeps the row,
         the second renders nothing rather than leaving a row nothing tracks. */
      ()
    | None => {
        let row: keyedItem<Obj.t> = {
          key,
          item,
          element: Obj.magic(Nullable.null),
          owner: Obj.magic(Nullable.null),
          index: -1,
          stamp: pass,
          anchors: false,
        }
        buildInto(row, item)
        items->Map.set(key, row)
        order->Array.push(row)->ignore
      }
    }
    position := position.contents + 1
  }

  /* Retire whatever the new order left out. */
  if survivors.contents < items->Map.size {
    items->Map.forEachWithKey((row, key) => {
      if row.stamp != pass {
        disposeOwner(row.owner)
        row.element->RuntimeDom.remove
        items->Map.delete(key)->ignore
      }
    })
  }

  if !ordered.contents {
    placeInOrder(~parent, ~items=order, ~tail)
  } else if fresh.contents > 0 {
    insertFresh(~parent, ~items=order, ~tail)
  }

  order->Array.forEachWithIndex((row, index) => row.index = index)
}

let keyedChildIdentity = (child: keyedChild): Obj.t => Obj.magic(child)

let rec reconcileKeyedChildren = (
  ~keyedChildren: array<keyedChild>,
  ~region: region,
  ~parent: Dom.element,
): unit =>
  reconcileKeyed(
    ~region,
    ~parent,
    ~count=Array.length(keyedChildren),
    ~keyAt=index => (keyedChildren->Array.getUnsafe(index)).key,
    /* The item a row is remembered by is the `Keyed` node itself, so its
       identity and its child are both at hand when the row is rebuilt. */
    ~itemAt=index => keyedChildIdentity(keyedChildren->Array.getUnsafe(index)),
    ~sameIdentity=(previous, next) => {
      let previous: keyedChild = Obj.magic(previous)
      let next: keyedChild = Obj.magic(next)
      shallowEqualIdentity(previous.identity, next.identity)
    },
    ~build=item => {
      let child: keyedChild = Obj.magic(item)
      renderInRegion(region, child.child)
    },
    ~tail=Nullable.null,
  )

/* Render a virtual node to a DOM element */
and render = (node: node): Dom.element => {
  switch node {
  | Text(content) => RuntimeDom.createTextNode(content)

  | SignalText(signal) => {
      let current = Signal.peek(signal)
      let textNode = RuntimeDom.createTextNode(current)
      ownComputed(signal)
      attachText(textNode, signal, Nullable.make(current))
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
      let container = RuntimeDom.createElement("div")
      RuntimeDom.setAttribute(container, "style", "display: contents")
      driveSignalFragment(~container, ~signal)
      container
    }

  | Element({tag, attrs, events, children}) => {
      let el = RuntimeDom.createElementForTag(tag)

      /* Some DOM properties need the child tree to exist before the browser
         can resolve them: a `select`'s value names one of its options. */
      let deferValue = tag == "select"

      attrs->Array.forEach(((key, value)) => {
        if !(deferValue && key == "value") {
          applyAttr(el, key, value)
        }
      })

      events->Array.forEach(((eventName, handler)) => {
        el->RuntimeDom.addEventListener(eventName, handler)
      })

      /* Text that is the only child is written through the element, the way
         compiled output does it: the browser creates the text node, and no
         wrapper for it is ever made on this side. */
      switch children {
      | [Text(content)] => RuntimeDom.setTextContent(el, content)
      | [SignalText(signal)] => {
          ownComputed(signal)
          attachText(el, signal, Nullable.null)
        }
      | children =>
        children->Array.forEach(child => {
          let childEl = render(child)
          el->RuntimeDom.appendChild(childEl)
        })
      }

      if deferValue {
        attrs->Array.forEach(((key, value)) => {
          if key == "value" {
            applyAttr(el, key, value)
          }
        })
      }

      el
    }

  | Keyed({child, key: _, identity: _}) => render(child)

  /* A component body is its own reactive scope. Rendering happens inside the
     enclosing region's effect (a `SignalFragment`, a keyed list), so without
     the untrack an eager read in the body — a `let` binding, a one-shot prop
     read — subscribes *that* region: one unrelated update then rebuilds the
     whole region wholesale, taking input focus and scroll position with it.
     Reads deferred into a thunk, a `Computed` or an `Effect` set up their own
     scope and are unaffected. Whatever the body registers belongs to the
     region rendering it, which is the region that removes its element. */
  | LazyComponent(fn) => render(Signal.untrack(fn))

  | KeyedList({signal, keyFn, renderItem}) => {
      let startAnchor = RuntimeDom.createComment(" keyed-list-start ")
      let endAnchor = RuntimeDom.createComment(" keyed-list-end ")
      let region = makeRegion()

      /* Initial render */
      let fragment = RuntimeDom.createDocumentFragment()
      fragment->RuntimeDom.appendChild(startAnchor)

      let initialItems = Signal.peek(signal)
      region.pass = 1
      initialItems->Array.forEachWithIndex((item, index) => {
        let owner = createOwner()
        let element = runWithOwner(owner, () => renderInRegion(region, renderItem(item)))
        let key = keyFn(item)
        region.items->Map.set(
          key,
          {key, item, element, owner, index, stamp: 1, anchors: !RuntimeDom.isDocumentFragment(element)},
        )
        fragment->RuntimeDom.appendChild(element)
      })

      fragment->RuntimeDom.appendChild(endAnchor)

      attachKeyedList(~region, ~signal, ~keyFn, ~renderItem, ~endAnchor)

      fragment
    }
  }
}

/* Write an attribute up front, or from an effect that re-runs on change. The
   effect remembers what it last wrote and skips the DOM when a run lands on
   the same value: a thousand rows react to one selection change, and all but
   two of them compute the class they already have. */
and applyAttr = (el: Dom.element, key: string, value: attrValue): unit =>
  switch resolveAttr(value) {
  | ReadStatic(value) => RuntimeDom.setAttrOrProp(el, key, value)
  | ReadReactive(read) => attachAttr(el, key, read)
  }

and attachAttr = (el: Dom.element, key: string, read: unit => Nullable.t<string>): unit => {
  let last: ref<Nullable.t<string>> = ref(Nullable.undefined)
  let written = ref(false)
  Effect.run(() => {
    let next = read()
    if !written.contents || next !== last.contents {
      written := true
      last := next
      RuntimeDom.setAttrOrProp(el, key, next)
    }
    None
  })
}

/* Keep a node's text in step with a signal — a text node's data, or an
   element's whole content when the text is its only child. `current` is what
   the node shows now, so a first run that lands on it writes nothing; null
   when that is unknown and the first run must write. */
and attachText = (
  node: Dom.element,
  signal: Signal.t<string>,
  current: Nullable.t<string>,
): unit => {
  let last = ref(current)
  Effect.run(() => {
    let next = Signal.get(signal)
    if Nullable.make(next) !== last.contents {
      last := Nullable.make(next)
      RuntimeDom.writeText(node, next)
    }
    None
  })
}

/* Render a node that belongs to a region — a keyed row, a fragment's child —
   through the region's templates, so repeated shapes are cloned. */
and renderInRegion = (region: region, node: node): Dom.element =>
  RuntimeTemplate.render(
    region.templates,
    node,
    ~hooks={render, applyAttr, attachAttr, attachText},
  )

/* Make `container` follow `signal`: one pass of its children per change.

   The signal's own body runs under the pass owner, so what it creates while it
   runs — a `View.signalText` leaf built by a `tracked` block, an effect a
   component body set up — is released with the pass that made it. The region
   itself is released with whatever region rendered the fragment. */
and driveSignalFragment = (~container: Dom.element, ~signal: Signal.t<array<node>>): unit => {
  let region = makeRegion()
  ownComputed(signal)
  track(addDisposer, () => disposeRegion(region))

  Effect.run(() => {
    let passOwner = createOwner()
    let children = runWithOwner(passOwner, () => Signal.get(signal))
    renderFragmentChildren(~container, ~children, ~region, ~passOwner)
    None
  })
}

/* Keep a keyed list's rows in step with its signal, given the region that
   tracks the rows the list already shows and the anchor its rows precede. The
   region is released with whatever region rendered the list; the render path
   and hydration both end up here, so a hydrated list cannot drift from a
   rendered one. */
and attachKeyedList = (
  ~region: region,
  ~signal: Signal.t<array<Obj.t>>,
  ~keyFn: Obj.t => string,
  ~renderItem: Obj.t => node,
  ~endAnchor: Dom.element,
): unit => {
  ownComputed(signal)
  track(addDisposer, () => disposeRegion(region))

  Effect.run(() => {
    reconcileKeyedList(~region, ~signal, ~keyFn, ~renderItem, ~endAnchor)
    None
  })
}

/* One reactive pass of a signal fragment's children into `container`, shared by
   the render path and by hydration so the rule below lives in one place.

   Keyed reconciliation can only retire elements it tracked. The region tracks
   no rows in exactly two cases: the first pass (container empty, so the sweep
   is a no-op) and right after a non-keyed pass — whose children are foreign to
   the reconciler and must be retired here, or a `Show` fallback stays in the
   DOM next to the keyed list that replaces it. */
and renderFragmentChildren = (
  ~container: Dom.element,
  ~children: array<node>,
  ~region: region,
  ~passOwner: owner,
): unit => {
  switch getKeyedChildren(children) {
  | Some(keyedChildren) => {
      if region.items->Map.size == 0 {
        releaseContent(region)
        RuntimeDom.setTextContent(container, "")
      } else {
        releaseContent(region)
      }
      region.content = Some(passOwner)
      reconcileKeyedChildren(~keyedChildren, ~region, ~parent=container)
    }
  | None => {
      disposeRegion(region)
      RuntimeDom.setTextContent(container, "")
      region.content = Some(passOwner)
      runWithOwner(passOwner, () =>
        children->Array.forEach(child =>
          container->RuntimeDom.appendChild(renderInRegion(region, child))
        )
      )
    }
  }
}

/* The keyed-list reconcile pass — see `reconcileKeyed`. */
and reconcileKeyedList = (
  ~region: region,
  ~signal: Signal.t<array<Obj.t>>,
  ~keyFn: Obj.t => string,
  ~renderItem: Obj.t => node,
  ~endAnchor: Dom.element,
): unit => {
  switch RuntimeDom.getParentNode(endAnchor)->Nullable.toOption {
  | None => ()
  | Some(parent) => {
      let newItems = Signal.get(signal)
      reconcileKeyed(
        ~region,
        ~parent,
        ~count=Array.length(newItems),
        ~keyAt=index => keyFn(newItems->Array.getUnsafe(index)),
        ~itemAt=index => newItems->Array.getUnsafe(index),
        ~sameIdentity=(previous, next) => previous === next,
        ~build=item => renderInRegion(region, renderItem(item)),
        ~tail=Nullable.make(endAnchor),
      )
    }
  }
}
