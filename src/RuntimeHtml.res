/* Attribute values arrive typed as `string`, but an untyped JSX value — a
   boolean signal in an `attrs` entry, an int through a `data-*` attribute —
   can be any scalar at runtime. The client's `setAttribute` stringifies it;
   the server must too, or `replaceAll` throws on the boolean. */
let stringify: string => string = %raw(`function (v) { return typeof v === "string" ? v : String(v) }`)

let escape = (str: string): string => {
  stringify(str)
  ->String.replaceAll("&", "&amp;")
  ->String.replaceAll("<", "&lt;")
  ->String.replaceAll(">", "&gt;")
  ->String.replaceAll("\"", "&quot;")
  ->String.replaceAll("'", "&#x27;")
}

let voidElements = [
  "area",
  "base",
  "br",
  "col",
  "embed",
  "hr",
  "img",
  "input",
  "link",
  "meta",
  "param",
  "source",
  "track",
  "wbr",
]

let isVoidElement = (tag: string): bool => voidElements->Array.includes(tag)
