# Attributes, forms and SVG

## The three ways to set an attribute

In JSX on a built-in element, just pass the value — raw, signal, thunk or
`MaybeSignal`:

```rescript
<div class="static" />
<div class={classSignal} />
<div class={() => Signal.get(active) ? "on" : "off"} />
```

In the function-based API, build an entry with a `View` helper:

```rescript
View.attr("class", "btn")                       /* static */
View.signalAttr("class", classSignal)           /* from a signal */
View.computedAttr("class", () => …)             /* from a computation */
View.optionalAttr("aria-describedby", maybeId)  /* option<string> */
View.optionalSignalAttr(key, signalOfOption)
View.optionalComputedAttr(key, () => …)
```

`View.Attr` holds the same six under shorter names (`Attr.string`, `Attr.signal`,
`Attr.compute`, `Attr.optional`, `Attr.optionalSignal`, `Attr.optionalCompute`).

## Removing an attribute

`None` from any of the optional helpers **removes** the attribute rather than
writing an empty value. This is not a nicety — presence-based CSS depends on it:

```rescript
/* [data-checked] matches only while checked */
View.optionalComputedAttr("data-checked", () => Signal.get(checked) ? Some("") : None)
```

An attribute that is always present, even as `""`, always matches `[data-open]`.
A `null`/`undefined` arriving through an untyped JSX value removes the attribute
too, so `{None}` in an attribute position behaves the same way.

## Boolean attributes

`disabled`, `checked`, `required`, `readonly`, `multiple`, `draggable`,
`hidden`, `contenteditable`, `spellcheck` and `autofocus` are added or removed
based on the value, rather than stringified. Pass the string `"true"` /
`"false"` (or a bool through JSX) and xote does the right thing.

**ARIA attributes are deliberately not on that list.** ARIA is enumerated, so
`aria-expanded` renders the literal `"false"` instead of disappearing —
`aria-expanded="false"` means something different from a missing attribute.

## Properties vs attributes

`value`, `checked` and `disabled` are set as DOM **properties**, not attributes.
That is what makes a controlled input behave. Everything else goes through
`setAttribute`.

## The `attrs` escape hatch

Typed JSX props do not cover every attribute. `attrs` takes `(key, value)`
pairs and is merged **after** the typed props, so an entry overrides a prop with
the same key — the prop is dropped, not rendered twice.

```rescript
<div role="tablist" attrs=[("aria-controls", "panel-1"), ("aria-orientation", "horizontal")]>
```

Values accept everything a typed attribute accepts. To mix static and reactive
entries in one array, use `View.attrValue` builders — an array's elements share
one type, so the builders are what make a heterogeneous list typecheck:

```rescript
<button
  role="switch"
  attrs=[
    View.attr("aria-controls", panelId),
    View.computedAttr("aria-checked", () => Signal.get(checked) ? "true" : "false"),
    View.optionalComputedAttr("data-checked", () => Signal.get(checked) ? Some("") : None),
  ]>
  {"Toggle"}
</button>
```

`Router.Link` takes the same `attrs` prop.

## Typed JSX props

Covered by name (no `attrs` needed): `id`, `class`, `style`, `title`; the form
set `type_`, `name`, `value`, `placeholder`, `disabled`, `checked`, `required`,
`readOnly`, `maxLength`, `minLength`, `min`, `max`, `step`, `pattern`,
`autoComplete`, `multiple`, `accept`, `rows`, `cols`, `autofocus`, `action`,
`method`; `for_` on labels; `href`, `target`, `src`, `alt`, `width`, `height`;
`draggable`, `hidden`, `contentEditable`, `spellcheck`; `role`, `tabIndex`,
`ariaLabel`, `ariaHidden`, `ariaExpanded`, `ariaSelected`; and `data`, which
takes a dict expanded into `data-*` attributes.

Note the ReScript spellings: `type_` and `for_` (reserved words), `class` (not
`className`).

## Forms

Reading a value out of a DOM event needs an interop step. Write `%raw` as a
**self-contained function literal** — a raw snippet that refers to a
surrounding ReScript binding by name breaks the moment the compiler renames or
inlines it.

```rescript
let targetValue: Dom.event => string = %raw(`function (evt) { return evt.target.value }`)

let handleInput = (evt: Dom.event) => Signal.set(draft, targetValue(evt))

<input type_="text" value={Signal.get(draft)} onInput={handleInput} />
```

Because `value` is set as a property, that input is controlled: the signal is
the source of truth, and rejecting a keystroke by not updating the signal
snaps the field back.

## SVG

SVG elements are created with the correct namespace automatically — the
renderer detects SVG tags. The typed prop set covers the common geometry,
presentation, gradient, marker, text and clipping attributes (`d`, `viewBox`,
`cx`, `fill`, `stroke`, `strokeWidth`, `transform`, `offset`, `stopColor`, …).
Anything else goes through `attrs`.

```rescript
<svg viewBox="0 0 24 24" width="24" height="24">
  <path d="M4 12h16" stroke={() => Signal.get(color)} strokeWidth="2" fill="none" />
</svg>
```
