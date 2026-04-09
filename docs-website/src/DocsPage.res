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
    items: [
      {title: "React", path: "/docs/comparisons/react"},
      {title: "SolidJS", path: "/docs/comparisons/solidjs"},
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
    label: "Demos",
    items: [
      {title: "Counter", path: "/docs/demos/counter"},
      {title: "Todo List", path: "/docs/demos/todo"},
      {title: "Color Mixer", path: "/docs/demos/color-mixer"},
      {title: "Reaction Game", path: "/docs/demos/reaction-game"},
      {title: "Solitaire", path: "/docs/demos/solitaire"},
      {title: "Memory Match", path: "/docs/demos/memory-match"},
      {title: "Snake Game", path: "/docs/demos/snake"},
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
      {Node.fragment(
        docsNav->Array.map(category => {
          <div class="sidebar-section">
            <div class="sidebar-section-title"> {Node.text(category.label)} </div>
            {Node.fragment(
              category.items->Array.map(item => {
                let isActive = currentPath == item.path
                let className = "sidebar-link" ++ (isActive ? " active" : "")
                Router.link(
                  ~to=item.path,
                  ~attrs=[Node.attr("class", className)],
                  ~children=[Node.text(item.title)],
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
      {Router.link(~to="/docs", ~children=[Node.text("Docs")], ())}
      {if category != "" && category != "Getting Started" {
        Node.fragment([
          <span class="docs-breadcrumb-sep"> {Node.text("/")} </span>,
          <span> {Node.text(category)} </span>,
        ])
      } else {
        Node.fragment([])
      }}
      <span class="docs-breadcrumb-sep"> {Node.text("/")} </span>
      <span class="docs-breadcrumb-current"> {Node.text(title)} </span>
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
          ~attrs=[Node.attr("class", "docs-prev-next-link")],
          ~children=[
            <span class="docs-prev-next-label">
              {Node.text("\u2190 Previous")}
            </span>,
            <span class="docs-prev-next-title"> {Node.text(item.title)} </span>,
          ],
          (),
        )
      | None => <div />
      }}
      {switch next {
      | Some(item) =>
        Router.link(
          ~to=item.path,
          ~attrs=[Node.attr("class", "docs-prev-next-link next")],
          ~children=[
            <span class="docs-prev-next-label">
              {Node.text("Next \u2192")}
            </span>,
            <span class="docs-prev-next-title"> {Node.text(item.title)} </span>,
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
      {Node.text("Was this page helpful?")}
      {Node.element(
        "button",
        ~attrs=[
          Node.computedAttr("class", () =>
            "feedback-btn" ++ (Signal.get(feedback) == "yes" ? " selected" : "")
          ),
          Node.attr("title", "Yes"),
        ],
        ~events=[("click", _ => Signal.set(feedback, "yes"))],
        ~children=[Node.text("\u{1F44D}")],
        (),
      )}
      {Node.element(
        "button",
        ~attrs=[
          Node.computedAttr("class", () =>
            "feedback-btn" ++ (Signal.get(feedback) == "no" ? " selected" : "")
          ),
          Node.attr("title", "No"),
        ],
        ~events=[("click", _ => Signal.set(feedback, "no"))],
        ~children=[Node.text("\u{1F44E}")],
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
      Node.fragment([])
    } else {
      <aside class="docs-toc">
        <div class="toc-title"> {Node.text("On this page")} </div>
        {Node.fragment(
          props.items->Array.map(item => {
            let className = "toc-link" ++ (item.level == 3 ? " toc-link-h3" : "")
            <a href={"#" ++ item.id} class={className}>
              {Node.text(item.text)}
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
  content: Node.node,
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
          <h1 class="docs-page-title"> {Node.text(pageTitle)} </h1>
          {switch props.pageLead {
          | Some(lead) => <p class="docs-page-lead"> {Node.text(lead)} </p>
          | None => Node.fragment([])
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
