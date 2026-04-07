/* Common HTML element constructors.

   These are thin wrappers over `Node.element` for the most frequently
   used tags. For tags not listed here, use `Node.element(tag, ...)`
   directly, or prefer JSX syntax which supports the full set via the
   `XoteJSX.Elements` module. */

let div = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("div", ~attrs?, ~events?, ~children?, ())
let span = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("span", ~attrs?, ~events?, ~children?, ())
let button = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("button", ~attrs?, ~events?, ~children?, ())
let input = (~attrs=?, ~events=?, ()) => Node.element("input", ~attrs?, ~events?, ())
let h1 = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("h1", ~attrs?, ~events?, ~children?, ())
let h2 = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("h2", ~attrs?, ~events?, ~children?, ())
let h3 = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("h3", ~attrs?, ~events?, ~children?, ())
let p = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("p", ~attrs?, ~events?, ~children?, ())
let ul = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("ul", ~attrs?, ~events?, ~children?, ())
let li = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("li", ~attrs?, ~events?, ~children?, ())
let a = (~attrs=?, ~events=?, ~children=?, ()) =>
  Node.element("a", ~attrs?, ~events?, ~children?, ())
