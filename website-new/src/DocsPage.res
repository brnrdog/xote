open Xote

// Docs navigation structure
type docItem = {
  title: string,
  path: string,
}

type docCategory = {
  label: string,
  items: array<docItem>,
}

let docsNav = [
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
    label: "Advanced",
    items: [{title: "Technical Overview", path: "/docs/technical-overview"}],
  },
]

// Sidebar component
module Sidebar = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let {currentPath} = props
    <aside class="docs-sidebar">
      {Component.fragment(
        docsNav->Array.map(category => {
          <div style="margin-bottom: 1.5rem;">
            <h4 style="margin-bottom: 0.5rem; font-size: 0.9rem; text-transform: uppercase; color: var(--text-secondary);">
              {Component.text(category.label)}
            </h4>
            <ul>
              {Component.fragment(
                category.items->Array.map(item => {
                  let isActive = currentPath == item.path
                  let className = isActive ? "active" : ""
                  <li>
                    {Router.link(~to=item.path, ~attrs=[Component.attr("class", className)], ~children=[Component.text(item.title)], ())}
                  </li>
                }),
              )}
            </ul>
          </div>
        }),
      )}
    </aside>
  }
}

// Main docs page component
type props = {
  currentPath: string,
  content: Component.node,
}

let make = (props: props) => {
  let {currentPath, content} = props
  <Layout children={
    <div class="docs-container">
      <Sidebar currentPath={currentPath} />
      <article class="docs-content"> {content} </article>
    </div>
  } />
}
