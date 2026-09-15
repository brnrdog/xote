/* Common HTML element constructors.

   These are thin wrappers over `View.element` for the most frequently
   used tags. For tags not listed here, use `View.element(tag, ...)`
   directly, or prefer JSX syntax which supports the full set via the
   `XoteJSX.Elements` module. */

let div = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("div", ~attrs?, ~events?, ~children?, ())
let span = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("span", ~attrs?, ~events?, ~children?, ())
let button = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("button", ~attrs?, ~events?, ~children?, ())
let input = (~attrs=?, ~events=?, ()) => View.element("input", ~attrs?, ~events?, ())
let h1 = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("h1", ~attrs?, ~events?, ~children?, ())
let h2 = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("h2", ~attrs?, ~events?, ~children?, ())
let h3 = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("h3", ~attrs?, ~events?, ~children?, ())
let p = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("p", ~attrs?, ~events?, ~children?, ())
let ul = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("ul", ~attrs?, ~events?, ~children?, ())
let li = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("li", ~attrs?, ~events?, ~children?, ())
let a = (~attrs=?, ~events=?, ~children=?, ()) =>
  View.element("a", ~attrs?, ~events?, ~children?, ())
