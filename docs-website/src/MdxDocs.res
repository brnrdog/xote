@module("./docs/IntroDoc.mdx") external introDoc: Mdx.document = "default"
@module("./docs/LearningReScriptDoc.mdx") external learningReScriptDoc: Mdx.document = "default"
@module("./docs/JavaScriptTypeScriptDoc.mdx") external javaScriptTypeScriptDoc: Mdx.document =
  "default"
@module("./docs/SignalsDoc.mdx") external signalsDoc: Mdx.document = "default"
@module("./docs/ComputedDoc.mdx") external computedDoc: Mdx.document = "default"
@module("./docs/EffectsDoc.mdx") external effectsDoc: Mdx.document = "default"
@module("./docs/BatchingDoc.mdx") external batchingDoc: Mdx.document = "default"
@module("./docs/ViewsDoc.mdx") external viewsDoc: Mdx.document = "default"
@module("./docs/RouterDoc.mdx") external routerDoc: Mdx.document = "default"
@module("./docs/ApiSignalDoc.mdx") external apiSignalDoc: Mdx.document = "default"
@module("./docs/ApiComputedDoc.mdx") external apiComputedDoc: Mdx.document = "default"
@module("./docs/ApiEffectDoc.mdx") external apiEffectDoc: Mdx.document = "default"
@module("./docs/ApiViewDoc.mdx") external apiViewDoc: Mdx.document = "default"
@module("./docs/ReactComparisonDoc.mdx") external reactComparisonDoc: Mdx.document = "default"
@module("./docs/SolidJSComparisonDoc.mdx") external solidComparisonDoc: Mdx.document = "default"
@module("./docs/TechnicalOverviewDoc.mdx") external technicalOverviewDoc: Mdx.document = "default"
@module("./docs/SSRDoc.mdx") external ssrDoc: Mdx.document = "default"
@module("./docs/MdxDoc.mdx") external mdxDoc: Mdx.document = "default"
@module("./docs/ChangelogDoc.mdx") external changelogDoc: Mdx.document = "default"

type mdxProps = {
  children?: Mdx.children,
  className?: string,
  href?: string,
  target?: string,
  rel?: string,
  title?: string,
}

@send external startsWith: (string, string) => bool = "startsWith"

let stripTrailingNewline = (value: string): string => {
  ignore(value)
  %raw(`value.replace(/\n$/, "")`)
}

let childrenToNodes = children =>
  switch children {
  | Some(children) => Mdx.childrenToNodes(children)
  | None => []
  }

let attr = (attrs, key, value) => attrs->Array.push(View.attr(key, value))->ignore

let optionalAttr = (attrs, key, value) =>
  switch value {
  | Some(value) => attr(attrs, key, value)
  | None => ()
  }

module Link = {
  let make = (props: mdxProps) => {
    let href = props.href->Option.getOr("")
    let children = childrenToNodes(props.children)

    if href->startsWith("/") {
      let attrs = []
      optionalAttr(attrs, "class", props.className)
      optionalAttr(attrs, "title", props.title)

      Router.link(~to=href, ~attrs, ~children, ())
    } else {
      let attrs = []
      attr(attrs, "href", href)
      attr(attrs, "target", props.target->Option.getOr("_blank"))
      attr(attrs, "rel", props.rel->Option.getOr("noreferrer"))
      optionalAttr(attrs, "class", props.className)
      optionalAttr(attrs, "title", props.title)

      View.element("a", ~attrs, ~children, ())
    }
  }
}

module Pre = {
  let make = (props: mdxProps) => {
    let className = switch props.className {
    | Some(className) => "docs-code-pre " ++ className
    | None => "docs-code-pre"
    }

    View.element(
      "pre",
      ~attrs=[View.attr("class", className)],
      ~children=childrenToNodes(props.children),
      (),
    )
  }
}

module Code = {
  let make = (props: mdxProps) => {
    let attrs = []
    optionalAttr(attrs, "class", props.className)

    let isBlock = switch props.className {
    | Some(className) => className->startsWith("language-")
    | None => false
    }

    if isBlock {
      let code = switch props.children {
      | Some(children) => Mdx.childrenToText(children)->stripTrailingNewline
      | None => ""
      }

      View.element("code", ~children=[SyntaxHighlight.highlight(code)], ())
    } else {
      View.element("code", ~attrs, ~children=childrenToNodes(props.children), ())
    }
  }
}

let components = Mdx.components([
  ("a", Mdx.component(Link.make)),
  ("code", Mdx.component(Code.make)),
  ("pre", Mdx.component(Pre.make)),
  ("DocsExamplePanel", Mdx.component(DocsExamplePanel.make)),
])

let render = document => Mdx.render(document, ~components, ())

let intro = () => render(introDoc)
let learningReScript = () => render(learningReScriptDoc)
let javaScriptTypeScript = () => render(javaScriptTypeScriptDoc)
let signals = () => render(signalsDoc)
let computed = () => render(computedDoc)
let effects = () => render(effectsDoc)
let batching = () => render(batchingDoc)
let views = () => render(viewsDoc)
let router = () => render(routerDoc)
let apiSignal = () => render(apiSignalDoc)
let apiComputed = () => render(apiComputedDoc)
let apiEffect = () => render(apiEffectDoc)
let apiView = () => render(apiViewDoc)
let reactComparison = () => render(reactComparisonDoc)
let solidComparison = () => render(solidComparisonDoc)
let technicalOverview = () => render(technicalOverviewDoc)
let ssr = () => render(ssrDoc)
let mdx = () => render(mdxDoc)
let changelog = () => render(changelogDoc)
