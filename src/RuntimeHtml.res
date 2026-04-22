let escape = (str: string): string => {
  str
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
