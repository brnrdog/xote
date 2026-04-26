// ReScript syntax highlighter — neutral palette, weight/italic only.

let keywords = [
  "let",
  "and",
  "rec",
  "type",
  "module",
  "open",
  "include",
  "external",
  "switch",
  "if",
  "else",
  "when",
  "for",
  "while",
  "do",
  "in",
  "to",
  "downto",
  "true",
  "false",
  "try",
  "catch",
  "exception",
  "mutable",
  "of",
  "as",
  "lazy",
  "fun",
  "assert",
  "async",
  "await",
  "None",
  "Some",
  "Ok",
  "Error",
]

let isDigit = c => c >= "0" && c <= "9"
let isLower = c => c >= "a" && c <= "z"
let isUpper = c => c >= "A" && c <= "Z"
let isAlpha = c => isLower(c) || isUpper(c)
let isIdentStart = c => isAlpha(c) || c == "_"
let isIdentChar = c => isIdentStart(c) || isDigit(c) || c == "'"

let operatorChars = "+-*/<>=|&!?:.@^"
let isOperatorChar = c => String.includes(operatorChars, c)

type token = {class_: string, text: string}

// Tokenize a single line into a sequence of classified spans.
let tokenizeLine = (line: string): array<token> => {
  let chars = line->String.split("")
  let len = Array.length(chars)
  let tokens: array<token> = []
  let i = ref(0)

  let at = n =>
    if n < len {
      chars->Array.getUnsafe(n)
    } else {
      ""
    }

  let sliceText = (start, end) => chars->Array.slice(~start, ~end)->Array.join("")

  while i.contents < len {
    let start = i.contents
    let c = at(start)

    if c == "/" && at(start + 1) == "/" {
      // line comment: consume to end
      tokens->Array.push({class_: "syntax-comment", text: sliceText(start, len)})
      i := len
    } else if c == "\"" {
      // string literal
      i := start + 1
      let escaped = ref(false)
      let closed = ref(false)
      while i.contents < len && !closed.contents {
        let ch = at(i.contents)
        if escaped.contents {
          escaped := false
          i := i.contents + 1
        } else if ch == "\\" {
          escaped := true
          i := i.contents + 1
        } else if ch == "\"" {
          i := i.contents + 1
          closed := true
        } else {
          i := i.contents + 1
        }
      }
      tokens->Array.push({class_: "syntax-string", text: sliceText(start, i.contents)})
    } else if c == "`" {
      // template literal (single-line portion)
      i := start + 1
      let escaped = ref(false)
      let closed = ref(false)
      while i.contents < len && !closed.contents {
        let ch = at(i.contents)
        if escaped.contents {
          escaped := false
          i := i.contents + 1
        } else if ch == "\\" {
          escaped := true
          i := i.contents + 1
        } else if ch == "`" {
          i := i.contents + 1
          closed := true
        } else {
          i := i.contents + 1
        }
      }
      tokens->Array.push({class_: "syntax-string", text: sliceText(start, i.contents)})
    } else if c == " " || c == "\t" {
      while i.contents < len && (at(i.contents) == " " || at(i.contents) == "\t") {
        i := i.contents + 1
      }
      tokens->Array.push({class_: "syntax-whitespace", text: sliceText(start, i.contents)})
    } else if isDigit(c) {
      while i.contents < len && isDigit(at(i.contents)) {
        i := i.contents + 1
      }
      if at(i.contents) == "." && isDigit(at(i.contents + 1)) {
        i := i.contents + 1
        while i.contents < len && isDigit(at(i.contents)) {
          i := i.contents + 1
        }
      }
      tokens->Array.push({class_: "syntax-number", text: sliceText(start, i.contents)})
    } else if isIdentStart(c) {
      while i.contents < len && isIdentChar(at(i.contents)) {
        i := i.contents + 1
      }
      let text = sliceText(start, i.contents)
      let first = text->String.charAt(0)
      let cls = if keywords->Array.includes(text) {
        "syntax-keyword"
      } else if isUpper(first) {
        // Module / variant / type constructor
        at(i.contents) == "." ? "syntax-module" : "syntax-ctor"
      } else if at(i.contents) == "(" {
        "syntax-fn"
      } else if c == "~" {
        "syntax-label"
      } else {
        "syntax-ident"
      }
      tokens->Array.push({class_: cls, text})
    } else if c == "~" && isLower(at(start + 1)) {
      // labelled argument: ~name
      i := start + 1
      while i.contents < len && isIdentChar(at(i.contents)) {
        i := i.contents + 1
      }
      tokens->Array.push({class_: "syntax-label", text: sliceText(start, i.contents)})
    } else if c == "<" && (isAlpha(at(start + 1)) || at(start + 1) == "/") {
      // JSX tag opening
      i := start + 1
      if at(i.contents) == "/" {
        i := i.contents + 1
      }
      while i.contents < len && (isIdentChar(at(i.contents)) || at(i.contents) == ".") {
        i := i.contents + 1
      }
      tokens->Array.push({class_: "syntax-tag", text: sliceText(start, i.contents)})
    } else if c == "/" && at(start + 1) == ">" {
      tokens->Array.push({class_: "syntax-tag", text: "/>"})
      i := start + 2
    } else if c == ">" || c == "<" {
      tokens->Array.push({class_: "syntax-tag", text: c})
      i := start + 1
    } else if isOperatorChar(c) {
      while i.contents < len && isOperatorChar(at(i.contents)) {
        i := i.contents + 1
      }
      tokens->Array.push({class_: "syntax-operator", text: sliceText(start, i.contents)})
    } else if c == "(" || c == ")" || c == "{" || c == "}" || c == "[" || c == "]" {
      tokens->Array.push({class_: "syntax-bracket", text: c})
      i := start + 1
    } else if c == "," || c == ";" {
      tokens->Array.push({class_: "syntax-punct", text: c})
      i := start + 1
    } else {
      tokens->Array.push({class_: "syntax-text", text: c})
      i := start + 1
    }
  }

  tokens
}

let renderToken = (t: token) =>
  View.element(
    "span",
    ~attrs=[View.attr("class", t.class_)],
    ~children=[View.text(t.text)],
    (),
  )

let highlight = (code: string): View.node => {
  let lines = code->String.split("\n")

  let highlightLine = (line: string, lineNumber: int): View.node => {
    let lineNum = (lineNumber + 1)->Int.toString
    let tokens = tokenizeLine(line)
    let content = tokens->Array.map(renderToken)

    View.element(
      "div",
      ~attrs=[View.attr("class", "syntax-line")],
      ~children=[
        View.element(
          "span",
          ~attrs=[View.attr("class", "syntax-line-number")],
          ~children=[View.text(lineNum)],
          (),
        ),
        View.element(
          "span",
          ~attrs=[View.attr("class", "syntax-line-content")],
          ~children=content,
          (),
        ),
      ],
      (),
    )
  }

  View.fragment(lines->Array.mapWithIndex((line, idx) => highlightLine(line, idx)))
}
