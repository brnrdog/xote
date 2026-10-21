
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
  ("CounterDemo", Mdx.component(CounterDemo.make)),
  ("ComputedOrderDemo", Mdx.component(ComputedOrderDemo.make)),
  ("EffectAutosaveDemo", Mdx.component(EffectAutosaveDemo.make)),
  ("TodoListDemo", Mdx.component(TodoListDemo.make)),
  ("IntroCounterDemo", Mdx.component(IntroCounterDemo.make)),
  ("RunsOnceDemo", Mdx.component(RunsOnceDemo.make)),
  ("FormsSignupDemo", Mdx.component(FormsSignupDemo.make)),
  ("FetchingDataDemo", Mdx.component(FetchingDataDemo.make)),
  ("TutorialStep1", Mdx.component(TutorialDemos.Step1.make)),
  ("TutorialStep2", Mdx.component(TutorialDemos.Step2.make)),
  ("TutorialStep3", Mdx.component(TutorialDemos.Step3.make)),
  ("TutorialStep4", Mdx.component(TutorialDemos.Step4.make)),
])

// MDX documents are imported in the generated DocsIndex module.
let render = document => Mdx.render(document, ~components, ())
