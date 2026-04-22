let booleanAttributes = [
  "checked",
  "disabled",
  "required",
  "readonly",
  "multiple",
  "aria-hidden",
  "aria-expanded",
  "aria-selected",
  "draggable",
  "hidden",
  "contenteditable",
  "spellcheck",
  "autofocus",
]

let isBoolean = (key: string): bool => booleanAttributes->Array.includes(key)

let boolToString = (value: bool): string => value ? "true" : "false"

let shouldRenderBoolean = (value: string): bool => value == "true"
