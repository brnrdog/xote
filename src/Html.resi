/***
Convenience constructors for the most frequently used HTML tags.

Thin wrappers over `View.element`. For tags not listed here call
`View.element(tag, ...)` directly, or use JSX, which supports the full set
through `XoteJSX.Elements`.

Every constructor takes the same optional arguments — `~attrs`, `~events` and
(except for void elements such as `input`) `~children` — followed by a `unit`,
which is required because all the others are optional.

## Examples

```rescript
let count = Signal.make(0)

let view = Html.div(
  ~attrs=[View.attr("class", "counter")],
  ~children=[
    Html.h1(~children=[View.text("Counter")], ()),
    Html.p(~children=[View.signalInt(() => Signal.get(count))], ()),
    Html.button(
      ~events=[("click", _evt => Signal.update(count, n => n + 1))],
      ~children=[View.text("Increment")],
      (),
    ),
  ],
  (),
)
```
*/

/**
`<div>`. A generic block container.

## Examples

```rescript
let node = Html.div(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let div: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<span>`. A generic inline container.

## Examples

```rescript
let node = Html.span(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let span: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<button>`. A clickable button. Pair it with an `onClick` handler in JSX, or a `"click"` entry in `~events`.

## Examples

```rescript
let node = Html.button(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let button: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<input>`. A form input. Void element, so it takes no `~children`.

## Examples

```rescript
let node = Html.input(
  ~attrs=[View.attr("type", "text"), View.attr("placeholder", "Name")],
  ~events=[("input", _evt => Console.log("changed"))],
  (),
)
```
*/
let input: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  unit,
) => View.node

/**
`<h1>`. A top-level heading.

## Examples

```rescript
let node = Html.h1(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let h1: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<h2>`. A second-level heading.

## Examples

```rescript
let node = Html.h2(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let h2: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<h3>`. A third-level heading.

## Examples

```rescript
let node = Html.h3(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let h3: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<p>`. A paragraph.

## Examples

```rescript
let node = Html.p(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let p: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<ul>`. An unordered list. Its children are usually `li` nodes, often produced by `View.eachWithKey` or `View.For`.

## Examples

```rescript
let node = Html.ul(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let ul: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<li>`. A list item.

## Examples

```rescript
let node = Html.li(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let li: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node

/**
`<a>`. A hyperlink. For in-app navigation that does not reload the page, use `Router.link` instead.

## Examples

```rescript
let node = Html.a(
  ~attrs=[View.attr("class", "example")],
  ~children=[View.text("Hello")],
  (),
)
```
*/
let a: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
