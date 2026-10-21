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
    items: [
      {title: "Introduction", path: "/docs"},
      {
        title: "Learning ReScript",
        path: "/docs/getting-started/rescript",
      },
      {
        title: "JavaScript Runtime",
        path: "/docs/getting-started/javascript-typescript",
      },
    ],
  },
  {
    label: "Core Modules",
    items: [
      {title: "Signals", path: "/docs/core-concepts/signals"},
      {title: "Computeds", path: "/docs/core-concepts/computed"},
      {title: "Effects", path: "/docs/core-concepts/effects"},
      {title: "View", path: "/docs/view/overview"},
      {title: "Context", path: "/docs/core-concepts/context"},
      {title: "Resources", path: "/docs/core-concepts/resources"},
    ],
  },
  {
    label: "Router",
    items: [{title: "Router", path: "/docs/router/overview"}],
  },
  {
    label: "API Reference",
    items: [
      {title: "Signal API", path: "/docs/api/signal"},
      {title: "Computed API", path: "/docs/api/computed"},
      {title: "Effect API", path: "/docs/api/effect"},
      {title: "View API", path: "/docs/api/view"},
    ],
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
      {title: "MDX Support", path: "/docs/advanced/mdx-support"},
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

// ---- Agent layer ----
// Facts about the module a page documents, shown at the top of the agent layer.
// Pages with an API reference get it appended there, so an agent reading the
// page sees the whole surface in one place.
type agentFacts = {
  moduleName: string,
  boundary: string,
  entry: string,
  apiPath: option<string>,
  api: option<unit => View.node>,
}

let facts = (~moduleName, ~boundary, ~entry, ~apiPath=?, ~api=?, ()) => {
  moduleName,
  boundary,
  entry,
  apiPath,
  api,
}

let agentFactsFor = (path: string): option<agentFacts> =>
  switch path {
  | "/docs/core-concepts/signals" | "/docs/api/signal" | "/docs/api/signals" =>
    Some(
      facts(
        ~moduleName="Xote.Signal",
        ~boundary="src/Signal.resi",
        ~entry="xote · xote/signal",
        ~apiPath="/docs/api/signal",
        ~api=?(path == "/docs/core-concepts/signals" ? Some(MdxDocs.apiSignal) : None),
        (),
      ),
    )
  | "/docs/core-concepts/computed" | "/docs/api/computed" =>
    Some(
      facts(
        ~moduleName="Xote.Computed",
        ~boundary="src/Computed.resi",
        ~entry="xote · xote/computed",
        ~apiPath="/docs/api/computed",
        ~api=?(path == "/docs/core-concepts/computed" ? Some(MdxDocs.apiComputed) : None),
        (),
      ),
    )
  | "/docs/core-concepts/effects" | "/docs/api/effect" =>
    Some(
      facts(
        ~moduleName="Xote.Effect",
        ~boundary="src/Effect.resi",
        ~entry="xote · xote/effect",
        ~apiPath="/docs/api/effect",
        ~api=?(path == "/docs/core-concepts/effects" ? Some(MdxDocs.apiEffect) : None),
        (),
      ),
    )
  | "/docs/view/overview" | "/docs/components/overview" | "/docs/api/view" =>
    Some(
      facts(
        ~moduleName="Xote.View",
        ~boundary="src/View.resi",
        ~entry="xote · xote/view",
        ~apiPath="/docs/api/view",
        ~api=?(path == "/docs/api/view" ? None : Some(MdxDocs.apiView)),
        (),
      ),
    )
  | "/docs/core-concepts/context" =>
    Some(facts(~moduleName="Xote.Context", ~boundary="src/Context.resi", ~entry="xote · xote/context", ()))
  | "/docs/core-concepts/resources" =>
    Some(facts(~moduleName="Xote.Resource", ~boundary="src/Resource.resi", ~entry="xote/resource", ()))
  | "/docs/router/overview" =>
    Some(facts(~moduleName="Xote.Router, Xote.Route", ~boundary="src/Router.resi", ~entry="xote/router", ()))
  | "/docs/advanced/ssr" =>
    Some(
      facts(
        ~moduleName="Xote.SSR, Xote.Hydration",
        ~boundary="src/SSR.resi",
        ~entry="xote/ssr · xote/hydration",
        (),
      ),
    )
  | "/docs/advanced/mdx-support" =>
    Some(facts(~moduleName="Xote.Mdx", ~boundary="src/Mdx.resi", ~entry="xote/mdx", ()))
  | "/docs/advanced/batching" =>
    Some(facts(~moduleName="Xote.Signal.batch", ~boundary="src/Signal.resi", ~entry="xote", ()))
  | _ => None
  }

// The plain-Markdown copy of a page, written next to its HTML at build time.
let markdownPath = (path: string) => path == "/docs" ? "/docs/index.md" : path ++ ".md"

let copyMarkdown = (_url: string, _onDone: unit => unit) => {
  let _ = %raw(`(() => {
    fetch(_url)
      .then(r => (r.ok ? r.text() : Promise.reject(r.status)))
      .then(text => navigator.clipboard && navigator.clipboard.writeText(text))
      .then(() => _onDone())
      .catch(() => {})
  })()`)
}

@val external setTimeout: (unit => unit, int) => int = "setTimeout"

module AgentHeader = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let copied = Signal.make(false)
    let mdPath = markdownPath(props.currentPath)

    let factPill = (label, value) =>
      <span class="agent-fact">
        <b> {View.text(label)} </b>
        {View.text(value)}
      </span>

    <div class="agent-only agent-header">
      <div class="agent-path"> {View.text(String.slice(mdPath, ~start=1))} </div>
      {switch agentFactsFor(props.currentPath) {
      | Some(f) =>
        <div class="agent-facts">
          {factPill("module", f.moduleName)}
          {factPill("boundary", f.boundary)}
          {factPill("entry", f.entry)}
          {factPill("version", RepoData.latestVersion)}
        </div>
      | None => View.fragment([])
      }}
      <div class="agent-actions">
        {View.element(
          "button",
          ~attrs=[View.attr("type", "button"), View.attr("class", "btn-pill btn-signal btn-mono")],
          ~events=[
            (
              "click",
              _ => {
                PostHog.capture("docs_markdown_copied", ~properties={"path": props.currentPath})
                copyMarkdown(mdPath, () => {
                  Signal.set(copied, true)
                  let _ = setTimeout(() => Signal.set(copied, false), 1600)
                })
              },
            ),
          ],
          ~children=[
            View.signalText(() =>
              Signal.get(copied) ? "Copied ✓" : "Copy page as Markdown"
            ),
          ],
          (),
        )}
        <a class="btn-pill btn-soft btn-mono" href={mdPath}> {View.text("Raw Markdown")} </a>
        {switch agentFactsFor(props.currentPath)->Option.flatMap(f => f.apiPath) {
        | Some(apiPath) if apiPath != props.currentPath =>
          Router.link(
            ~to=apiPath,
            ~attrs=[View.attr("class", "btn-pill btn-soft btn-mono")],
            ~children=[View.text("API reference")],
            (),
          )
        | _ => View.fragment([])
        }}
      </div>
    </div>
  }
}

// The right-rail note that offers the other layer.
module LayerNote = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let button = (layer, label) =>
      View.element(
        "button",
        ~attrs=[View.attr("type", "button"), View.attr("class", "text-link")],
        ~events=[("click", _ => DocsLayer.set(layer))],
        ~children=[View.text(label)],
        (),
      )

    View.fragment([
      <div class="rail-note human-only">
        <span class="rail-note-title rail-note-mono"> {View.text(">_ for agents")} </span>
        <span> {View.text("The complete version, with every signature and rule.")} </span>
        {button(DocsLayer.Agent, "Open agent layer →")}
      </div>,
      <div class="rail-note agent-only">
        <span class="rail-note-title"> {View.text("Machine-readable")} </span>
        <code> {View.text(markdownPath(props.currentPath))} </code>
        <code> {View.text("/llms.txt")} </code>
        <span> {View.text("Same content, plain Markdown, no layout.")} </span>
      </div>,
      <div class="rail-note agent-only">
        <span class="rail-note-title"> {View.text("◎ For humans")} </span>
        <span> {View.text("A friendlier read of this page.")} </span>
        {button(DocsLayer.Human, "Open human layer →")}
      </div>,
    ])
  }
}

// ---- Table of Contents (right side) ----
// ---- Scroll spy for "On this page" ----
// One window listener tracks which heading of the current page was scrolled
// past last; the TOC links read it to mark themselves active.
module TocSpy = {
  @val external getById: string => Nullable.t<Dom.element> = "document.getElementById"
  @send external getBoundingClientRect: Dom.element => {"top": float} = "getBoundingClientRect"
  @val @scope("window") external scrollY: float = "scrollY"
  @val @scope("window") external innerHeight: float = "innerHeight"
  @val @scope(("document", "documentElement")) external scrollHeight: float = "scrollHeight"
  @val @scope("window")
  external addWindowListener: (string, unit => unit, {"passive": bool}) => unit = "addEventListener"
  @val external requestAnimationFrame: (unit => unit) => int = "requestAnimationFrame"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"

  // A heading counts as current once its top passes this line, just below
  // the sticky header.
  let activationLine = 120.0

  let activeId = Signal.make("")
  let ids: ref<array<string>> = ref([])
  let scheduled = ref(false)

  let sync = () => {
    scheduled := false
    let headings = ids.contents->Array.filterMap(id => getById(id)->Nullable.toOption)
    let atBottom = scrollY +. innerHeight >= scrollHeight -. 2.0
    let current = if atBottom {
      ids.contents->Array.at(-1)
    } else {
      let passed = ids.contents->Array.filterWithIndex((_, i) =>
        switch headings[i] {
        | Some(el) => getBoundingClientRect(el)["top"] <= activationLine
        | None => false
        }
      )
      switch passed->Array.at(-1) {
      | Some(id) => Some(id)
      | None => ids.contents[0]
      }
    }
    Signal.set(activeId, current->Option.getOr(""))
  }

  let schedule = () =>
    if !scheduled.contents {
      scheduled := true
      let _ = requestAnimationFrame(sync)
    }

  let _ = if SSRContext.isClient {
    addWindowListener("scroll", schedule, {"passive": true})
    addWindowListener("resize", schedule, {"passive": true})
  }

  // Called when a page's TOC renders: track its headings once they are in
  // the DOM.
  let track = (pageIds: array<string>) => {
    ids := pageIds
    if SSRContext.isClient {
      let _ = setTimeout(sync, 0)
    }
  }
}

module TableOfContents = {
  type tocItem = {
    text: string,
    id: string,
    level: int,
  }

  type props = {items: array<tocItem>, currentPath: string}

  let make = (props: props) => {
    TocSpy.track(props.items->Array.map(item => item.id))
    <aside class="docs-toc">
      {if Array.length(props.items) == 0 {
        View.fragment([])
      } else {
        <nav class="toc-list" ariaLabel="On this page">
          <div class="toc-title"> {View.text("On this page")} </div>
          {View.fragment(
            props.items->Array.map(item => {
              let className = "toc-link" ++ (item.level >= 3 ? " toc-link-h3" : "")
              <a
                href={"#" ++ item.id}
                class={() =>
                  Signal.get(TocSpy.activeId) == item.id ? className ++ " active" : className}
                attrs=[
                  View.computedAttr("aria-current", () =>
                    Signal.get(TocSpy.activeId) == item.id ? "location" : "false"
                  ),
                ]>
                {View.text(item.text)}
              </a>
            }),
          )}
        </nav>
      }}
      <LayerNote currentPath={props.currentPath} />
    </aside>
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

  let apiAppendix = agentFactsFor(currentPath)->Option.flatMap(f => f.api)

  <Layout
    children={
      <div class={() => DocsLayer.isAgent() ? "docs-layout is-agent" : "docs-layout"}>
        <Sidebar currentPath />
        <div class="docs-main">
          <DocsBreadcrumb currentPath />
          <h1 class="docs-page-title">
            <span class="agent-only agent-hash" ariaHidden=true> {View.text("# ")} </span>
            {View.text(pageTitle)}
          </h1>
          {switch props.pageLead {
          | Some(lead) => <p class="docs-page-lead"> {View.text(lead)} </p>
          | None => View.fragment([])
          }}
          <AgentHeader currentPath />
          <div class="docs-content"> {content} </div>
          {switch apiAppendix {
          | Some(api) =>
            <div class="agent-only agent-appendix">
              <h2 class="agent-appendix-title"> {View.text("API reference")} </h2>
              <div class="docs-content"> {api()} </div>
            </div>
          | None => View.fragment([])
          }}
          <div class="human-only"> <PrevNextNav currentPath /> </div>
        </div>
        <TableOfContents items={tocItems} currentPath />
      </div>
    }
  />
}
