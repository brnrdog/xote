open Xote

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
    label: "Core Concepts",
    items: [
      {title: "Signals", path: "/docs/core-concepts/signals"},
      {title: "Computed", path: "/docs/core-concepts/computed"},
      {title: "Effects", path: "/docs/core-concepts/effects"},
      {title: "Batching", path: "/docs/core-concepts/batching"},
    ],
  },
  {
    label: "Components",
    items: [{title: "Overview", path: "/docs/components/overview"}],
  },
  {
    label: "Router",
    items: [{title: "Overview", path: "/docs/router/overview"}],
  },
  {
    label: "API Reference",
    items: [{title: "Signals", path: "/docs/api/signals"}],
  },
  {
    label: "Comparisons",
    items: [{title: "React", path: "/docs/comparisons/react"}],
  },
  {
    label: "Advanced",
    items: [{title: "Technical Overview", path: "/docs/technical-overview"}],
  },
  {
    label: "Demos",
    items: [
      {title: "Counter", path: "/docs/demos/counter"},
      {title: "Todo List", path: "/docs/demos/todo"},
      {title: "Color Mixer", path: "/docs/demos/color-mixer"},
      {title: "Reaction Game", path: "/docs/demos/reaction-game"},
      {title: "Solitaire", path: "/docs/demos/solitaire"},
      {title: "Memory Match", path: "/docs/demos/memory-match"},
      {title: "Snake Game", path: "/docs/demos/snake"},
      {title: "Bookstore", path: "/docs/demos/bookstore"},
    ],
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
      {Component.fragment(
        docsNav->Array.map(category => {
          <div class="sidebar-section">
            <div class="sidebar-section-title"> {Component.text(category.label)} </div>
            {Component.fragment(
              category.items->Array.map(item => {
                let isActive = currentPath == item.path
                let className = "sidebar-link" ++ (isActive ? " active" : "")
                Router.link(
                  ~to=item.path,
                  ~attrs=[Component.attr("class", className)],
                  ~children=[Component.text(item.title)],
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
      {Router.link(~to="/docs", ~children=[Component.text("Docs")], ())}
      {if category != "" && category != "Getting Started" {
        Component.fragment([
          <span class="docs-breadcrumb-sep"> {Component.text("/")} </span>,
          <span> {Component.text(category)} </span>,
        ])
      } else {
        Component.fragment([])
      }}
      <span class="docs-breadcrumb-sep"> {Component.text("/")} </span>
      <span class="docs-breadcrumb-current"> {Component.text(title)} </span>
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
        Router.link(
          ~to=item.path,
          ~attrs=[Component.attr("class", "docs-prev-next-link")],
          ~children=[
            <span class="docs-prev-next-label">
              {Component.text("\u2190 Previous")}
            </span>,
            <span class="docs-prev-next-title"> {Component.text(item.title)} </span>,
          ],
          (),
        )
      | None => <div />
      }}
      {switch next {
      | Some(item) =>
        Router.link(
          ~to=item.path,
          ~attrs=[Component.attr("class", "docs-prev-next-link next")],
          ~children=[
            <span class="docs-prev-next-label">
              {Component.text("Next \u2192")}
            </span>,
            <span class="docs-prev-next-title"> {Component.text(item.title)} </span>,
          ],
          (),
        )
      | None => <div />
      }}
    </div>
  }
}

// ---- Feedback Widget ----
module FeedbackWidget = {
  type props = {}

  let make = (_props: props) => {
    let feedback = Signal.make("")

    <div class="docs-feedback">
      {Component.text("Was this page helpful?")}
      {Component.element(
        "button",
        ~attrs=[
          Component.computedAttr("class", () =>
            "feedback-btn" ++ (Signal.get(feedback) == "yes" ? " selected" : "")
          ),
          Component.attr("title", "Yes"),
        ],
        ~events=[("click", _ => Signal.set(feedback, "yes"))],
        ~children=[Component.text("\u{1F44D}")],
        (),
      )}
      {Component.element(
        "button",
        ~attrs=[
          Component.computedAttr("class", () =>
            "feedback-btn" ++ (Signal.get(feedback) == "no" ? " selected" : "")
          ),
          Component.attr("title", "No"),
        ],
        ~events=[("click", _ => Signal.set(feedback, "no"))],
        ~children=[Component.text("\u{1F44E}")],
        (),
      )}
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
      Component.fragment([])
    } else {
      <aside class="docs-toc">
        <div class="toc-title"> {Component.text("On this page")} </div>
        {Component.fragment(
          props.items->Array.map(item => {
            let className = "toc-link" ++ (item.level == 3 ? " toc-link-h3" : "")
            <a href={"#" ++ item.id} class={className}>
              {Component.text(item.text)}
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
  content: Component.node,
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
          <h1 class="docs-page-title"> {Component.text(pageTitle)} </h1>
          {switch props.pageLead {
          | Some(lead) => <p class="docs-page-lead"> {Component.text(lead)} </p>
          | None => Component.fragment([])
          }}
          <div class="docs-content"> {content} </div>
          <PrevNextNav currentPath />
          <FeedbackWidget />
        </div>
        <TableOfContents items={tocItems} />
      </div>
    }
  />
}
