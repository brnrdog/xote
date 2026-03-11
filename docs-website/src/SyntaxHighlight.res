// Simple ReScript syntax highlighter
open Xote

let keywords = [
  "let",
  "type",
  "module",
  "open",
  "switch",
  "if",
  "else",
  "true",
  "false",
  "and",
  "or",
  "rec",
  "external",
  "include",
  "when",
]

let types = ["int", "string", "bool", "float", "array", "option", "unit"]

let operators = ["=>", "->", "|>", "==", "!=", "+", "-", "*", "/", "="]

// Simple tokenizer for ReScript code
let highlight = (code: string): Component.node => {
  let lines = code->String.split("\n")

  let highlightLine = (line: string, lineNumber: int): Component.node => {
    let lineNum = (lineNumber + 1)->Int.toString

    // Check if line is a comment
    let lineContent = if line->String.trim->String.startsWith("//") {
      Component.element(
        "span",
        ~attrs=[Component.attr("class", "syntax-comment")],
        ~children=[Component.text(line)],
        (),
      )
    } else {
      // Simple word-based highlighting
      let words = line->String.split(" ")
      let highlightedWords = words->Array.mapWithIndex((word, idx) => {
        let trimmed = word->String.trim

        // Check for keywords
        let isKeyword = keywords->Array.some(k => trimmed == k || trimmed->String.startsWith(k ++ "("))

        // Check for types
        let isType = types->Array.some(t => trimmed == t)

        // Check for strings
        let isString = trimmed->String.startsWith("\"") || trimmed->String.startsWith("`")

        // Check for numbers
        let isNumber =
          trimmed->String.match(%re("/^[0-9]+$/")) != None ||
            trimmed->String.match(%re("/^[0-9]+\.[0-9]+$/")) != None

        let className = if isKeyword {
          "syntax-keyword"
        } else if isType {
          "syntax-type"
        } else if isString {
          "syntax-string"
        } else if isNumber {
          "syntax-number"
        } else {
          "syntax-text"
        }

        Component.fragment([
          Component.element(
            "span",
            ~attrs=[Component.attr("class", className)],
            ~children=[Component.text(word)],
            (),
          ),
          idx < Array.length(words) - 1
            ? Component.text(" ")
            : Component.fragment([]),
        ])
      })

      Component.fragment(highlightedWords)
    }

    Component.element(
      "div",
      ~attrs=[Component.attr("class", "syntax-line")],
      ~children=[
        Component.element(
          "span",
          ~attrs=[Component.attr("class", "syntax-line-number")],
          ~children=[Component.text(lineNum)],
          (),
        ),
        Component.element(
          "span",
          ~attrs=[Component.attr("class", "syntax-line-content")],
          ~children=[lineContent],
          (),
        ),
      ],
      (),
    )
  }

  Component.fragment(lines->Array.mapWithIndex((line, idx) => highlightLine(line, idx)))
}
