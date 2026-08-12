/* Attributes whose presence carries the meaning: they are written with an empty
 value when true and removed when false.

 ARIA state is deliberately absent from this list. `aria-expanded`,
 `aria-checked`, `aria-selected`, ... are enumerated attributes, so they carry a
 literal "true"/"false" string — rendering them as bare presence loses the
 "false" state. Removing any attribute, ARIA or not, is expressed with an
 optional attribute value (`View.optionalAttr(key, None)` and friends). */
let booleanAttributes = [
  "checked",
  "disabled",
  "required",
  "readonly",
  "multiple",
  "draggable",
  "hidden",
  "contenteditable",
  "spellcheck",
  "autofocus",
]

let isBoolean = (key: string): bool => booleanAttributes->Array.includes(key)

let boolToString = (value: bool): string => value ? "true" : "false"

let shouldRenderBoolean = (value: string): bool => value == "true"
