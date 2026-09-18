/* Internal: template cloning for node trees that keep coming back in the same
   shape.

   A keyed list renders one tree per item, a `tracked` block one per pass, and
   the trees differ in their data — text, attribute values, handlers, what the
   reactive leaves read — not in their structure. Building each one node by
   node spent twenty-odd DOM calls on a row that a compiled framework clones in
   one; the walk below recovers that at runtime, without a compiler, by
   learning the structure from the first tree it sees.

   The first time a region renders a tree of some root, it builds the tree the
   ordinary way and, alongside it, a *skeleton*: the same elements with their
   static attributes and text, empty placeholders where the tree has a
   reactive leaf or a dynamic child, and no handlers or effects. It also
   records a *shape*: what stood at every position. From then on a tree with
   the same root is rendered by cloning the skeleton and walking the tree
   against the shape, filling in what the clone cannot carry — handlers,
   effects, text and attribute values that differ from the first tree's, and
   the dynamic children (`SignalFragment`, `KeyedList`), which are rendered and
   put in place of their placeholder.

   The match is checked as the walk goes, and it is soft: a subtree that does
   not match its shape is rendered normally and swapped into the clone at that
   position, so a heterogeneous list still clones what its rows share. A
   subtree the shape marks as static is not walked in the DOM at all; it is
   compared in JavaScript, and only touched when something differs. A static
   attribute or text that turns out to vary between rows flips its position to
   active, so later rows compare and set it in place instead of rebuilding.

   Text that is an element's only child is written through `textContent`, the
   way compiled output does: no text node is created from script, and no
   wrapper for it either. */

open RuntimeNode
open RuntimeOwner

type textChild = NoText | StaticText(string) | ReactiveText

type rec shape =
  | SElement(elementShape)
  | SText(string)
  | SSignalText
  | SFragment(array<shape>)
  | SComponent(shape)
  | SDynamic
and elementShape = {
  tag: string,
  /* The first tree's attributes, as what the skeleton carries. An entry whose
     value turns out to vary between rows is rewritten to `OptionalStatic(None)`
     and dropped from the skeleton, so later rows write it once instead of
     cloning one value and overwriting it with another. */
  attrs: array<(string, attrValue)>,
  eventNames: array<string>,
  mutable textChild: textChild,
  children: array<shape>,
  /* Whether filling has work below this element: a reactive attribute, a
     handler, a reactive text child, or an active child. A static subtree is
     verified without touching the DOM, and becomes active once a value in it
     turns out to vary. */
  mutable active: bool,
  /* This element in the skeleton, so a value learned to vary can be taken out
     of it. */
  skeleton: Dom.element,
}

type template = {
  /* Root tag, or a marker for a fragment root — enough to pick a template
     before the walk verifies the rest. */
  signature: string,
  shape: shape,
  /* What is cloned per instance: the root element itself when the shape is a
     single element, otherwise a fragment holding the root's nodes. */
  skeleton: Dom.element,
  single: bool,
}

type cache = {
  mutable templates: array<template>,
  mutable builds: int,
}

/* One skeleton per root shape a region has shown, up to this many. Beyond it
   a tree that matches none is rendered the ordinary way. */
let maxTemplates = 3

let makeCache = (): cache => {templates: [], builds: 0}

/* What the renderer hands us so this module need not depend on it. */
type hooks = {
  render: node => Dom.element,
  applyAttr: (Dom.element, string, attrValue) => unit,
  attachAttr: (Dom.element, string, unit => Nullable.t<string>) => unit,
  /* `current` is what the node shows now, or null when that is unknown and
     the first run must write. */
  attachText: (Dom.element, Signal.t<string>, Nullable.t<string>) => unit,
}

@send external cloneNode: (Dom.element, bool) => Dom.element = "cloneNode"
@get external lastChild: Dom.element => Nullable.t<Dom.element> = "lastChild"
@set external setData: (Dom.element, string) => unit = "data"

/* `value` and `checked` land on DOM properties that `cloneNode` does not carry
   over, so they are written per instance whatever the skeleton says. */
let isPerInstanceProp = (key: string): bool => key == "value" || key == "checked"

let attrKind = (value: attrValue): int =>
  switch value {
  | Static(_) => 0
  | SignalValue(_) => 1
  | Compute(_) => 2
  | OptionalStatic(_) => 3
  | OptionalSignalValue(_) => 4
  | OptionalCompute(_) => 5
  }

let isStaticAttr = (value: attrValue): bool =>
  switch value {
  | Static(_) | OptionalStatic(_) => true
  | _ => false
  }

let staticValue = (value: attrValue): Nullable.t<string> =>
  switch value {
  | Static(value) => Nullable.make(value)
  | OptionalStatic(value) => Nullable.fromOption(value)
  | _ => Nullable.null
  }

let rec unwrapKeyed = (node: node): node =>
  switch node {
  | Keyed({child, key: _, identity: _}) => unwrapKeyed(child)
  | node => node
  }

/* Root signature of a tree, once components and keys are peeled off. Empty
   for a tree templates do not cover. */
let signatureOf = (node: node): string =>
  switch node {
  | Element({tag, attrs: _, events: _, children: _}) => tag
  | Fragment(children) => "#" ++ Int.toString(Array.length(children))
  | _ => ""
  }

let rec isActive = (shape: shape): bool =>
  switch shape {
  | SElement(element) => element.active
  | SText(_) => false
  | SSignalText | SComponent(_) | SDynamic => true
  | SFragment(children) => children->Array.some(isActive)
  }

/* How many top-level DOM nodes a shape occupies. */
let rec span = (shape: shape): int =>
  switch shape {
  | SElement(_) | SText(_) | SSignalText | SDynamic => 1
  | SFragment(children) => children->Array.reduce(0, (sum, child) => sum + span(child))
  | SComponent(inner) => span(inner)
  }

/* ---- recording ------------------------------------------------------------

   Builds `node` into `instance` exactly as the renderer would, and the static
   skeleton of it into `skeleton`, returning the shape of what it built. Runs
   once per template, so it is allowed to be the slow path. */

let rec record = (
  node: node,
  ~skeleton: Dom.element,
  ~instance: Dom.element,
  ~hooks: hooks,
): shape =>
  switch node {
  | Text(content) => {
      skeleton->RuntimeDom.appendChild(RuntimeDom.createTextNode(content))
      instance->RuntimeDom.appendChild(RuntimeDom.createTextNode(content))
      SText(content)
    }

  | SignalText(signal) => {
      skeleton->RuntimeDom.appendChild(RuntimeDom.createTextNode(""))
      let current = Signal.peek(signal)
      let textNode = RuntimeDom.createTextNode(current)
      ownComputed(signal)
      hooks.attachText(textNode, signal, Nullable.make(current))
      instance->RuntimeDom.appendChild(textNode)
      SSignalText
    }

  | Fragment(children) =>
    SFragment(children->Array.map(child => record(child, ~skeleton, ~instance, ~hooks)))

  | Keyed({child, key: _, identity: _}) => record(child, ~skeleton, ~instance, ~hooks)

  | LazyComponent(fn) => SComponent(record(Signal.untrack(fn), ~skeleton, ~instance, ~hooks))

  | SignalFragment(_) | KeyedList(_) => {
      skeleton->RuntimeDom.appendChild(RuntimeDom.createTextNode(""))
      instance->RuntimeDom.appendChild(hooks.render(node))
      SDynamic
    }

  | Element({tag, attrs, events, children}) => {
      let skeletonEl = RuntimeDom.createElementForTag(tag)
      let instanceEl = RuntimeDom.createElementForTag(tag)
      let deferValue = tag == "select"
      let reactive = ref(false)

      attrs->Array.forEach(((key, value)) => {
        switch resolveAttr(value) {
        | ReadStatic(static) => {
            if !isPerInstanceProp(key) {
              RuntimeDom.setAttrOrProp(skeletonEl, key, static)
            }
            if !(deferValue && key == "value") {
              RuntimeDom.setAttrOrProp(instanceEl, key, static)
            }
          }
        | ReadReactive(read) => {
            reactive := true
            if !(deferValue && key == "value") {
              hooks.attachAttr(instanceEl, key, read)
            }
          }
        }
      })

      events->Array.forEach(((eventName, handler)) => {
        instanceEl->RuntimeDom.addEventListener(eventName, handler)
      })

      let (textChild, childShapes) = switch children {
      | [Text(content)] => {
          RuntimeDom.setTextContent(skeletonEl, content)
          RuntimeDom.setTextContent(instanceEl, content)
          (StaticText(content), [])
        }
      | [SignalText(signal)] => {
          ownComputed(signal)
          hooks.attachText(instanceEl, signal, Nullable.null)
          (ReactiveText, [])
        }
      | children => (
          NoText,
          children->Array.map(child =>
            record(child, ~skeleton=skeletonEl, ~instance=instanceEl, ~hooks)
          ),
        )
      }

      if deferValue {
        attrs->Array.forEach(((key, value)) => {
          if key == "value" {
            hooks.applyAttr(instanceEl, key, value)
          }
        })
      }

      skeleton->RuntimeDom.appendChild(skeletonEl)
      instance->RuntimeDom.appendChild(instanceEl)

      let active =
        reactive.contents ||
        Array.length(events) > 0 ||
        textChild == ReactiveText ||
        attrs->Array.some(((key, _)) => isPerInstanceProp(key)) ||
        childShapes->Array.some(isActive)

      SElement({
        tag,
        attrs: Array.copy(attrs),
        eventNames: events->Array.map(((eventName, _)) => eventName),
        textChild,
        children: childShapes,
        active,
        skeleton: skeletonEl,
      })
    }
  }

/* ---- verifying ------------------------------------------------------------

   A static subtree is compared in JavaScript only. 0: identical. 1: same
   structure, some value differs. 2: different structure. */

let matchValue = 0
let matchStructure = 1
let mismatch = 2

let rec verifyStatic = (shape: shape, node: node): int =>
  switch (shape, unwrapKeyed(node)) {
  | (SText(expected), Text(content)) => content == expected ? matchValue : matchStructure
  | (SFragment(shapes), Fragment(children)) =>
    if Array.length(shapes) != Array.length(children) {
      mismatch
    } else {
      verifyAll(shapes, children)
    }
  | (SElement(element), Element({tag, attrs, events, children})) =>
    if (
      tag != element.tag ||
      Array.length(attrs) != Array.length(element.attrs) ||
      Array.length(events) != Array.length(element.eventNames)
    ) {
      mismatch
    } else {
      let result = ref(matchValue)
      let index = ref(0)
      while result.contents != mismatch && index.contents < Array.length(attrs) {
        let (key, value) = attrs->Array.getUnsafe(index.contents)
        let (expectedKey, expected) = element.attrs->Array.getUnsafe(index.contents)
        if key != expectedKey || attrKind(value) != attrKind(expected) {
          result := mismatch
        } else if isStaticAttr(value) && staticValue(value) !== staticValue(expected) {
          result := matchStructure
        }
        index := index.contents + 1
      }
      if result.contents == mismatch {
        mismatch
      } else {
        let childResult = switch (element.textChild, children) {
        | (StaticText(expected), [Text(content)]) =>
          content == expected ? matchValue : matchStructure
        | (NoText, children) =>
          if Array.length(children) != Array.length(element.children) {
            mismatch
          } else {
            verifyAll(element.children, children)
          }
        | _ => mismatch
        }
        childResult > result.contents ? childResult : result.contents
      }
    }
  | _ => mismatch
  }

and verifyAll = (shapes: array<shape>, nodes: array<node>): int => {
  let result = ref(matchValue)
  let index = ref(0)
  while result.contents != mismatch && index.contents < Array.length(shapes) {
    let outcome = verifyStatic(shapes->Array.getUnsafe(index.contents), nodes->Array.getUnsafe(index.contents))
    if outcome > result.contents {
      result := outcome
    }
    index := index.contents + 1
  }
  result.contents
}

/* ---- filling --------------------------------------------------------------

   Walks a tree against its shape over a fresh clone, cursor at the DOM node
   the shape position corresponds to, and returns the cursor for the position
   after. */

/* Replace the `count` nodes starting at `cursor` with the ordinary rendering
   of `node`. */
let replaceSpan = (
  ~parent: Dom.element,
  ~cursor: Dom.element,
  ~count: int,
  ~node: node,
  ~hooks: hooks,
): Nullable.t<Dom.element> => {
  let next = ref(RuntimeDom.getNextSibling(cursor))
  let remaining = ref(count - 1)
  while remaining.contents > 0 {
    switch next.contents->Nullable.toOption {
    | Some(node) => {
        next := RuntimeDom.getNextSibling(node)
        node->RuntimeDom.remove
      }
    | None => remaining := 0
    }
    remaining := remaining.contents - 1
  }
  RuntimeDom.replaceChild(parent, hooks.render(node), cursor)
  next.contents
}

let rec fillNode = (
  shape: shape,
  node: node,
  ~parent: Dom.element,
  ~cursor: Dom.element,
  ~hooks: hooks,
): Nullable.t<Dom.element> => {
  let node = unwrapKeyed(node)
  switch shape {
  | SComponent(inner) =>
    switch node {
    | LazyComponent(fn) => fillNode(inner, Signal.untrack(fn), ~parent, ~cursor, ~hooks)
    | node => replaceSpan(~parent, ~cursor, ~count=span(inner), ~node, ~hooks)
    }

  | SDynamic => replaceSpan(~parent, ~cursor, ~count=1, ~node, ~hooks)

  | SSignalText =>
    switch node {
    | SignalText(signal) => {
        let next = RuntimeDom.getNextSibling(cursor)
        ownComputed(signal)
        hooks.attachText(cursor, signal, Nullable.null)
        next
      }
    | node => replaceSpan(~parent, ~cursor, ~count=1, ~node, ~hooks)
    }

  | SText(expected) =>
    switch node {
    | Text(content) => {
        let next = RuntimeDom.getNextSibling(cursor)
        if content != expected {
          setData(cursor, content)
        }
        next
      }
    | node => replaceSpan(~parent, ~cursor, ~count=1, ~node, ~hooks)
    }

  | SFragment(shapes) =>
    switch node {
    | Fragment(children) if Array.length(children) == Array.length(shapes) =>
      fillChildren(shapes, children, ~parent, ~cursor=Nullable.make(cursor), ~hooks)
    | node => replaceSpan(~parent, ~cursor, ~count=span(shape), ~node, ~hooks)
    }

  | SElement(element) =>
    if element.active {
      let next = RuntimeDom.getNextSibling(cursor)
      if fillElement(element, node, ~el=cursor, ~hooks) {
        next
      } else {
        replaceSpan(~parent, ~cursor, ~count=1, ~node, ~hooks)
      }
    } else {
      let outcome = verifyStatic(shape, node)
      if outcome == matchValue {
        RuntimeDom.getNextSibling(cursor)
      } else if outcome == matchStructure {
        /* Same structure, some value differs: a static attribute or text that
           varies between rows. Fill this one in place — the structure is known
           to match — and walk the DOM here from now on. */
        element.active = true
        let next = RuntimeDom.getNextSibling(cursor)
        let _ = fillElement(element, node, ~el=cursor, ~hooks)
        next
      } else {
        replaceSpan(~parent, ~cursor, ~count=1, ~node, ~hooks)
      }
    }
  }
}

and fillChildren = (
  shapes: array<shape>,
  nodes: array<node>,
  ~parent: Dom.element,
  ~cursor: Nullable.t<Dom.element>,
  ~hooks: hooks,
): Nullable.t<Dom.element> => {
  let cursor = ref(cursor)
  let index = ref(0)
  let count = Array.length(shapes)
  while index.contents < count {
    switch cursor.contents->Nullable.toOption {
    | Some(at) =>
      cursor :=
        fillNode(
          shapes->Array.getUnsafe(index.contents),
          nodes->Array.getUnsafe(index.contents),
          ~parent,
          ~cursor=at,
          ~hooks,
        )
    /* The clone ran out of nodes before the shape did — only possible after
       a replaced subtree changed the span. Append what is left. */
    | None =>
      parent->RuntimeDom.appendChild(hooks.render(nodes->Array.getUnsafe(index.contents)))
    }
    index := index.contents + 1
  }
  cursor.contents
}

/* Fill one element of the clone from `node`. False when the structure does
   not match, before anything was written to the element. */
and fillElement = (element: elementShape, node: node, ~el: Dom.element, ~hooks: hooks): bool =>
  switch node {
  | Element({tag, attrs, events, children}) =>
    if (
      tag != element.tag ||
      Array.length(attrs) != Array.length(element.attrs) ||
      Array.length(events) != Array.length(element.eventNames)
    ) {
      false
    } else {
      let structural = ref(true)
      let index = ref(0)
      while structural.contents && index.contents < Array.length(attrs) {
        let (key, value) = attrs->Array.getUnsafe(index.contents)
        let (expectedKey, expected) = element.attrs->Array.getUnsafe(index.contents)
        if key != expectedKey || attrKind(value) != attrKind(expected) {
          structural := false
        }
        index := index.contents + 1
      }
      index := 0
      while structural.contents && index.contents < Array.length(events) {
        let (eventName, _) = events->Array.getUnsafe(index.contents)
        if eventName != element.eventNames->Array.getUnsafe(index.contents) {
          structural := false
        }
        index := index.contents + 1
      }
      let childrenMatch = switch (element.textChild, children) {
      | (StaticText(_), [Text(_)]) => true
      | (ReactiveText, [SignalText(_)]) => true
      | (NoText, children) => Array.length(children) == Array.length(element.children)
      | _ => false
      }

      if !(structural.contents && childrenMatch) {
        false
      } else {
        let deferValue = tag == "select"

        attrs->Array.forEachWithIndex(((key, value), index) => {
          if !(deferValue && key == "value") {
            switch resolveAttr(value) {
            | ReadStatic(static) => {
                let (_, expected) = element.attrs->Array.getUnsafe(index)
                if isPerInstanceProp(key) {
                  RuntimeDom.setAttrOrProp(el, key, static)
                } else if static !== staticValue(expected) {
                  /* Varies between rows: from now on the skeleton carries no
                     value for it and every row writes its own. */
                  if !isStaticAttr(expected) || staticValue(expected) !== Nullable.null {
                    element.attrs->Array.setUnsafe(index, (key, OptionalStatic(None)))
                    RuntimeDom.removeAttrOrProp(element.skeleton, key)
                  }
                  RuntimeDom.setAttrOrProp(el, key, static)
                }
              }
            | ReadReactive(read) => hooks.attachAttr(el, key, read)
            }
          }
        })

        events->Array.forEach(((eventName, handler)) => {
          el->RuntimeDom.addEventListener(eventName, handler)
        })

        switch (element.textChild, children) {
        | (StaticText(expected), [Text(content)]) =>
          if content != expected {
            /* Varies between rows: the skeleton stops carrying the first
               row's text, so later rows write theirs into an empty element
               rather than over a cloned text node. */
            if expected != "" {
              element.textChild = StaticText("")
              RuntimeDom.setTextContent(element.skeleton, "")
            }
            RuntimeDom.setTextContent(el, content)
          }
        | (ReactiveText, [SignalText(signal)]) => {
            ownComputed(signal)
            hooks.attachText(el, signal, Nullable.null)
          }
        | (_, children) =>
          let _ = fillChildren(
            element.children,
            children,
            ~parent=el,
            ~cursor=RuntimeDom.getFirstChild(el),
            ~hooks,
          )
        }

        if deferValue {
          attrs->Array.forEach(((key, value)) => {
            if key == "value" {
              hooks.applyAttr(el, key, value)
            }
          })
        }
        true
      }
    }
  | _ => false
  }

/* What `render` returns for a fragment holding the result: the single node
   when there is one, the fragment itself otherwise. */
let unwrapResult = (fragment: Dom.element): Dom.element =>
  switch RuntimeDom.getFirstChild(fragment)->Nullable.toOption {
  | Some(first) if first === Obj.magic(lastChild(fragment)) => first
  | _ => fragment
  }

/* Render `node` through the region's templates: with one, by cloning; without
   one and past the first build, by recording one while rendering. The very
   first build of a region is rendered plainly — a region that renders once
   should not pay for a skeleton it never clones. */
let render = (cache: cache, node: node, ~hooks: hooks): Dom.element => {
  let node = switch unwrapKeyed(node) {
  | LazyComponent(fn) => unwrapKeyed(Signal.untrack(fn))
  | node => node
  }
  let signature = signatureOf(node)
  let builds = cache.builds
  cache.builds = builds + 1

  if signature == "" {
    hooks.render(node)
  } else {
    switch cache.templates->Array.find(template => template.signature == signature) {
    | Some(template) =>
      if template.single {
        /* A single root element is cloned as itself — no fragment around it
           to clone and discard — and filled in place; a root that does not
           match its shape is rendered the ordinary way instead. */
        let clone = cloneNode(template.skeleton, true)
        switch template.shape {
        | SElement(element) if fillElement(element, node, ~el=clone, ~hooks) => clone
        | _ => hooks.render(node)
        }
      } else {
        let clone = cloneNode(template.skeleton, true)
        switch RuntimeDom.getFirstChild(clone)->Nullable.toOption {
        | Some(cursor) => {
            let _ = fillNode(template.shape, node, ~parent=clone, ~cursor, ~hooks)
            unwrapResult(clone)
          }
        | None => hooks.render(node)
        }
      }
    | None =>
      if builds > 0 && Array.length(cache.templates) < maxTemplates {
        let skeleton = RuntimeDom.createDocumentFragment()
        let instance = RuntimeDom.createDocumentFragment()
        let shape = record(node, ~skeleton, ~instance, ~hooks)
        let template = switch shape {
        | SElement(element) => {signature, shape, skeleton: element.skeleton, single: true}
        | shape => {signature, shape, skeleton, single: false}
        }
        cache.templates->Array.push(template)->ignore
        unwrapResult(instance)
      } else {
        hooks.render(node)
      }
    }
  }
}
