/* Convenience constructors for the most frequently used HTML tags.

   Thin wrappers over `View.element`. For tags not listed here call
   `View.element(tag, ...)` directly, or use JSX, which supports the full set
   through `XoteJSX.Elements`. */

let div: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let span: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let button: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let input: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  unit,
) => View.node
let h1: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let h2: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let h3: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let p: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let ul: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let li: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
let a: (
  ~attrs: array<(string, View.attrValue)>=?,
  ~events: array<(string, Dom.event => unit)>=?,
  ~children: array<View.node>=?,
  unit,
) => View.node
