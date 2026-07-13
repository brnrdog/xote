@jsx.component
let make = (~filename, ~code, ~caption=?, ~children=?) => {
  let activeTab = Signal.make("code")
  let hasDemo = switch children {
  | Some(_) => true
  | None => false
  }
  let exampleClass = hasDemo ? "docs-example-panel docs-example-panel-has-demo" : "docs-example-panel"

  let setTab = (tab, _evt: Dom.event) => Signal.set(activeTab, tab)
  let tabClass = tab =>
    if Signal.get(activeTab) == tab {
      "docs-example-tab active"
    } else {
      "docs-example-tab"
    }
  let panelClass = tab =>
    if Signal.get(activeTab) == tab {
      "docs-example-view active"
    } else {
      "docs-example-view"
    }

  <section class={exampleClass}>
    <div class="docs-example-header">
      <div class="docs-example-tabs" role="tablist">
        <button
          class={() => tabClass("code")}
          onClick={setTab("code", _)}
          role="tab"
          type_="button"
          ariaSelected={() => Signal.get(activeTab) == "code"}
        >
          {View.text("Code")}
        </button>
        {switch children {
        | Some(_) =>
          <button
            class={() => tabClass("demo")}
            onClick={setTab("demo", _)}
            role="tab"
            type_="button"
            ariaSelected={() => Signal.get(activeTab) == "demo"}
          >
            {View.text("Demo")}
          </button>
        | None => View.fragment([])
        }}
      </div>
      <div class="docs-example-filename"> {View.text(filename)} </div>
    </div>

    <div class="docs-example-body">
      <div class={() => panelClass("code")}>
        <pre class="docs-example-code-pre">
          <code> {SyntaxHighlight.highlight(code)} </code>
        </pre>
      </div>

      {switch children {
      | Some(children) =>
        <div class={() => panelClass("demo")}>
          <div class="docs-example-demo">
            <div class="docs-example-demo-stage"> {children} </div>
            {switch caption {
            | Some(text) => <div class="docs-example-caption"> {View.text(text)} </div>
            | None => View.fragment([])
            }}
          </div>
        </div>
      | None => View.fragment([])
      }}
    </div>
  </section>
}
