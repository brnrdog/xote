// A live example in the docs: the running demo on top, the code that makes it
// underneath, both inside the article column. Long code starts collapsed.

// Code longer than this many lines starts collapsed behind "Show all".
let collapsedLines = 18

@xote.component
let make = (~filename, ~code, ~caption=?, ~children=?) => {
  let lineCount = code->String.split("\n")->Array.length
  let isLong = lineCount > collapsedLines
  let expanded = Signal.make(false)

  <section class="docs-example-panel">
    {switch children {
    | Some(children) =>
      <div class="docs-example-demo">
        <div class="docs-example-demo-stage"> {children} </div>
        {switch caption {
        | Some(text) => <div class="docs-example-caption"> {text} </div>
        | None => View.null()
        }}
      </div>
    | None => View.null()
    }}
    <div
      class={isLong && !Signal.get(expanded)
        ? "docs-example-code is-collapsed"
        : "docs-example-code"}>
      <div class="docs-example-header">
        <span class="docs-example-filename"> {filename} </span>
        {isLong
          ? <button
              type_="button"
              class="docs-example-toggle"
              ariaExpanded={Signal.get(expanded)}
              onClick={_ => Signal.update(expanded, open_ => !open_)}>
              {Signal.get(expanded) ? "Show less" : `Show all ${Int.toString(lineCount)} lines`}
            </button>
          : View.null()}
      </div>
      <pre class="docs-example-code-pre">
        <code> {SyntaxHighlight.highlight(code)} </code>
      </pre>
    </div>
  </section>
}
