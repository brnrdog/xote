// ---- Navigation data ----
type docItem = {
  title: string,
  path: string,
}

type docCategory = {
  label: string,
  items: array<docItem>,
}

let docsNav: array<docCategory> = [
  {
    label: "Getting Started",
    items: [{title: "Introduction", path: "/docs"}],
  },
  {
    label: "Core Modules",
    items: [
      {title: "Signals", path: "/docs/core-concepts/signals"},
      {title: "Computeds", path: "/docs/core-concepts/computed"},
      {title: "Effects", path: "/docs/core-concepts/effects"},
      {title: "View", path: "/docs/view/overview"},
    ],
  },
  {
    label: "Router",
    items: [{title: "Router", path: "/docs/router/overview"}],
  },
  {
    label: "API Reference",
    items: [{title: "Signals API", path: "/docs/api/signals"}],
  },
  {
    label: "Comparisons",
    items: [
      {title: "React Comparison", path: "/docs/comparisons/react"},
      {title: "SolidJS Comparison", path: "/docs/comparisons/solidjs"},
    ],
  },
  {
    label: "Advanced",
    items: [
      {title: "Server-Side Rendering", path: "/docs/advanced/ssr"},
      {title: "Batching", path: "/docs/advanced/batching"},
      {title: "Technical Overview", path: "/docs/technical-overview"},
    ],
  },
  {
    label: "Project",
    items: [{title: "Changelog", path: "/docs/changelog"}],
  },
]

// Flatten for prev/next
let flatItems = docsNav->Array.flatMap(cat => cat.items)

// Find prev/next
let getPrevNext = (currentPath: string) => {
  let idx = flatItems->Array.findIndex(item => item.path == currentPath)
  let prev = if idx > 0 {
    flatItems->Array.get(idx - 1)
  } else {
    None
  }
  let next = if idx >= 0 && idx < Array.length(flatItems) - 1 {
    flatItems->Array.get(idx + 1)
  } else {
    None
  }
  (prev, next)
}

// Find category + title for breadcrumb
let getCategoryAndTitle = (currentPath: string) => {
  let result = ref(("", ""))
  docsNav->Array.forEach(cat => {
    cat.items->Array.forEach(item => {
      if item.path == currentPath {
        result := (cat.label, item.title)
      }
    })
  })
  result.contents
}

// ---- Sidebar ----
module Sidebar = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let {currentPath} = props
    <aside class="docs-sidebar">
      {View.fragment(
        docsNav->Array.map(category => {
          <div class="sidebar-section">
            <div class="sidebar-section-title"> {View.text(category.label)} </div>
            {View.fragment(
              category.items->Array.map(item => {
                let isActive = currentPath == item.path
                let className = "sidebar-link" ++ (isActive ? " active" : "")
                Router.link(
                  ~to=item.path,
                  ~attrs=[View.attr("class", className)],
                  ~children=[View.text(item.title)],
                  (),
                )
              }),
            )}
          </div>
        }),
      )}
    </aside>
  }
}

// ---- Breadcrumb ----
module DocsBreadcrumb = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let (category, title) = getCategoryAndTitle(props.currentPath)
    <nav class="docs-breadcrumb">
      {Router.link(~to="/docs", ~children=[View.text("Docs")], ())}
      {if category != "" && category != "Getting Started" {
        View.fragment([
          <span class="docs-breadcrumb-sep"> {View.text("/")} </span>,
          <span> {View.text(category)} </span>,
        ])
      } else {
        View.fragment([])
      }}
      <span class="docs-breadcrumb-sep"> {View.text("/")} </span>
      <span class="docs-breadcrumb-current"> {View.text(title)} </span>
    </nav>
  }
}

// ---- Prev/Next ----
module PrevNextNav = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let (prev, next) = getPrevNext(props.currentPath)
    <div class="docs-prev-next">
      {switch prev {
      | Some(item) =>
        View.element(
          "span",
          ~events=[
            (
              "click",
              _ =>
                PostHog.capture(
                  "docs_page_navigated",
                  ~properties={
                    "direction": "previous",
                    "target_path": item.path,
                    "target_title": item.title,
                  },
                ),
            ),
          ],
          ~children=[
            Router.link(
              ~to=item.path,
              ~attrs=[View.attr("class", "docs-prev-next-link")],
              ~children=[
                <span class="docs-prev-next-label">
                  {View.text("\u2190 Previous")}
                </span>,
                <span class="docs-prev-next-title"> {View.text(item.title)} </span>,
              ],
              (),
            ),
          ],
          (),
        )
      | None => <div />
      }}
      {switch next {
      | Some(item) =>
        View.element(
          "span",
          ~events=[
            (
              "click",
              _ =>
                PostHog.capture(
                  "docs_page_navigated",
                  ~properties={
                    "direction": "next",
                    "target_path": item.path,
                    "target_title": item.title,
                  },
                ),
            ),
          ],
          ~children=[
            Router.link(
              ~to=item.path,
              ~attrs=[View.attr("class", "docs-prev-next-link next")],
              ~children=[
                <span class="docs-prev-next-label">
                  {View.text("Next \u2192")}
                </span>,
                <span class="docs-prev-next-title"> {View.text(item.title)} </span>,
              ],
              (),
            ),
          ],
          (),
        )
      | None => <div />
      }}
    </div>
  }
}

// ---- Table of Contents (right side) ----
module TableOfContents = {
  type tocItem = {
    text: string,
    id: string,
    level: int,
  }

  type props = {items: array<tocItem>}

  let make = (props: props) => {
    if Array.length(props.items) == 0 {
      View.fragment([])
    } else {
      <aside class="docs-toc">
        <div class="toc-title"> {View.text("Contents")} </div>
        {View.fragment(
          props.items->Array.map(item => {
            let className = "toc-link" ++ (item.level == 3 ? " toc-link-h3" : "")
            <a href={"#" ++ item.id} class={className}>
              {View.text(item.text)}
            </a>
          }),
        )}
      </aside>
    }
  }
}

// ---- Main docs page component ----
type props = {
  currentPath: string,
  content: View.node,
  pageTitle?: string,
  pageLead?: string,
  tocItems?: array<TableOfContents.tocItem>,
}

let make = (props: props) => {
  let {currentPath, content} = props
  let (_, title) = getCategoryAndTitle(currentPath)

  let pageTitle = switch props.pageTitle {
  | Some(t) => t
  | None => title
  }

  let tocItems = switch props.tocItems {
  | Some(items) => items
  | None => []
  }

  <Layout
    children={
      <div class="docs-layout">
        <Sidebar currentPath />
        <div class="docs-main">
          <DocsBreadcrumb currentPath />
          <h1 class="docs-page-title"> {View.text(pageTitle)} </h1>
          {switch props.pageLead {
          | Some(lead) => <p class="docs-page-lead"> {View.text(lead)} </p>
          | None => View.fragment([])
          }}
          <div class="docs-content"> {content} </div>
          <PrevNextNav currentPath />
        </div>
        <TableOfContents items={tocItems} />
      </div>
    }
  />
}
