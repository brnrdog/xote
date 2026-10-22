// ---- Navigation ----
// Pages, sections and their order come from docs.pages.mjs via the generated
// DocsIndex module.

// Prev/next follow the sidebar order, skipping agent-only pages.
let readingOrder = DocsIndex.pages->Array.filter(page => !page.agentOnly)

let getPrevNext = (currentPath: string) => {
  let idx = readingOrder->Array.findIndex(item => item.path == currentPath)
  let prev = idx > 0 ? readingOrder[idx - 1] : None
  let next = idx >= 0 ? readingOrder[idx + 1] : None
  (prev, next)
}

// Section label and sidebar title for the breadcrumb.
let getCategoryAndTitle = (currentPath: string) =>
  switch DocsIndex.find(currentPath) {
  | Some(page) => (page.section, page.title)
  | None => ("", "")
  }

// ---- Sidebar ----
module Sidebar = {
  type props = {currentPath: string}

  let make = (props: props) => {
    let {currentPath} = props
    <aside class="docs-sidebar">
      {View.fragment(
        DocsIndex.sections->Array.map(category => {
          <div class="sidebar-section">
            <div class="sidebar-section-title"> {View.text(category.label)} </div>
            {View.fragment(
              category.pages->Array.map(item => {
                let isActive = currentPath == item.path
                let className =
                  "sidebar-link" ++ (isActive ? " active" : "") ++ (item.agentOnly ? " agent-only" : "")
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
      {if category != "" && category != "Get started" {
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
let agentFactsFor = (path: string) => DocsIndex.find(path)->Option.flatMap(page => page.agent)

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
  @get external offsetParent: Dom.element => Nullable.t<Dom.element> = "offsetParent"
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
    // Both layers' headings are tracked; only the visible layer's count.
    let visible =
      ids.contents->Array.filterMap(id =>
        getById(id)
        ->Nullable.toOption
        ->Option.flatMap(el => offsetParent(el)->Nullable.toOption->Option.map(_ => (id, el)))
      )
    let atBottom = scrollY +. innerHeight >= scrollHeight -. 2.0
    let current = if atBottom {
      visible->Array.at(-1)->Option.map(((id, _)) => id)
    } else {
      let passed = visible->Array.filter(((_, el)) => getBoundingClientRect(el)["top"] <= activationLine)
      switch passed->Array.at(-1) {
      | Some((id, _)) => Some(id)
      | None => visible[0]->Option.map(((id, _)) => id)
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

  // `agentItems` is the agent layer's own list, when the page has one; each
  // list then shows only in its layer.
  type props = {items: array<tocItem>, agentItems?: array<tocItem>, currentPath: string}

  let list = (items: array<tocItem>, ~layerClass) =>
    if Array.length(items) == 0 {
      View.fragment([])
    } else {
      <nav class={"toc-list" ++ layerClass} ariaLabel="On this page">
        <div class="toc-title"> {View.text("On this page")} </div>
        {View.fragment(
          items->Array.map(item => {
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
    }

  let make = (props: props) => {
    let agentItems = props.agentItems->Option.getOr([])
    TocSpy.track(Array.concat(props.items, agentItems)->Array.map(item => item.id))
    <aside class="docs-toc">
      {if Array.length(agentItems) == 0 {
        list(props.items, ~layerClass="")
      } else {
        View.fragment([
          list(props.items, ~layerClass=" human-only"),
          list(agentItems, ~layerClass=" agent-only"),
        ])
      }}
      <LayerNote currentPath={props.currentPath} />
    </aside>
  }
}

// ---- Main docs page component ----
type props = {
  page: DocsIndex.page,
  tocItems?: array<TableOfContents.tocItem>,
}

// h2 and h3 headings make the "On this page" list; h4s stay in search only.
let tocFor = (headings: array<DocsIndex.heading>): array<TableOfContents.tocItem> =>
  headings
  ->Array.filter(heading => heading.level <= 3)
  ->Array.map(heading => {
    let item: TableOfContents.tocItem = {text: heading.text, id: heading.id, level: heading.level}
    item
  })

let make = (props: props) => {
  let {page} = props
  let currentPath = page.path

  let tocItems = switch props.tocItems {
  | Some(items) => items
  | None => tocFor(page.headings)
  }

  let humanContent = switch page.document {
  | Some(document) => MdxDocs.render(document)
  | None => View.fragment([])
  }

  // A page with an agent layer shows each layer's own content; otherwise both
  // layers share the human content.
  let content = switch page.agentDocument {
  | Some(agentDocument) =>
    View.fragment([
      <div class="human-only"> {humanContent} </div>,
      <div class="agent-only"> {MdxDocs.render(agentDocument)} </div>,
    ])
  | None => humanContent
  }

  let apiAppendix = page.agent->Option.flatMap(f => f.api)

  <Layout
    children={
      <div class={() => DocsLayer.isAgent() ? "docs-layout is-agent" : "docs-layout"}>
        <Sidebar currentPath />
        <div class="docs-main">
          <DocsBreadcrumb currentPath />
          <h1 class="docs-page-title">
            <span class="agent-only agent-hash" ariaHidden=true> {View.text("# ")} </span>
            {View.text(page.pageTitle)}
          </h1>
          {page.lead == ""
            ? View.fragment([])
            : <p class="docs-page-lead"> {View.text(page.lead)} </p>}
          <AgentHeader currentPath />
          <div class="docs-content"> {content} </div>
          {switch apiAppendix {
          | Some(api) =>
            <div class="agent-only agent-appendix">
              <h2 class="agent-appendix-title"> {View.text("API reference")} </h2>
              <div class="docs-content"> {MdxDocs.render(api)} </div>
            </div>
          | None => View.fragment([])
          }}
          <div class="human-only"> <PrevNextNav currentPath /> </div>
        </div>
        <TableOfContents items={tocItems} agentItems={tocFor(page.agentHeadings)} currentPath />
      </div>
    }
  />
}
