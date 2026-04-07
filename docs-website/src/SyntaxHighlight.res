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
let highlight = (code: string): Node.node => {
  let lines = code->String.split("\n")

  let highlightLine = (line: string, lineNumber: int): Node.node => {
    let lineNum = (lineNumber + 1)->Int.toString

    // Check if line is a comment
    let lineContent = if line->String.trim->String.startsWith("//") {
      Node.element(
        "span",
        ~attrs=[Node.attr("class", "syntax-comment")],
        ~children=[Node.text(line)],
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

        Node.fragment([
          Node.element(
            "span",
            ~attrs=[Node.attr("class", className)],
            ~children=[Node.text(word)],
            (),
          ),
          idx < Array.length(words) - 1
            ? Node.text(" ")
            : Node.fragment([]),
        ])
      })

      Node.fragment(highlightedWords)
    }

    Node.element(
      "div",
      ~attrs=[Node.attr("class", "syntax-line")],
      ~children=[
        Node.element(
          "span",
          ~attrs=[Node.attr("class", "syntax-line-number")],
          ~children=[Node.text(lineNum)],
          (),
        ),
        Node.element(
          "span",
          ~attrs=[Node.attr("class", "syntax-line-content")],
          ~children=[lineContent],
          (),
        ),
      ],
      (),
    )
  }

  Node.fragment(lines->Array.mapWithIndex((line, idx) => highlightLine(line, idx)))
}
