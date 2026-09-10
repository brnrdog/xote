@module("./article.mdx") external article: Mdx.document = "default"

type mdxProps = {
  children?: Mdx.children,
  href?: string,
}

module Link = {
  let make = (props: mdxProps) => {
    View.element(
      "a",
      ~attrs=[
        View.attr("href", props.href->Option.getOr("#")),
        View.attr("target", "_blank"),
        View.attr("rel", "noreferrer"),
      ],
      ~children=switch props.children {
      | Some(children) => Mdx.childrenToNodes(children)
      | None => []
      },
      (),
    )
  }
}

module Heading = {
  let make = (props: mdxProps) =>
    <h1 class="article-title">
      {View.fragment(
        switch props.children {
        | Some(children) => Mdx.childrenToNodes(children)
        | None => []
        },
      )}
    </h1>
}

module Paragraph = {
  let make = (props: mdxProps) =>
    <p class="article-copy">
      {View.fragment(
        switch props.children {
        | Some(children) => Mdx.childrenToNodes(children)
        | None => []
        },
      )}
    </p>
}

let components = Mdx.components([
  ("a", Mdx.component(Link.make)),
  ("h1", Mdx.component(Heading.make)),
  ("p", Mdx.component(Paragraph.make)),
  ("Example", Mdx.component(Example.make)),
])

View.mountById(Mdx.render(article, ~components, ()), "root")
