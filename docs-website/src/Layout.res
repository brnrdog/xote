// ---- External bindings ----
@val @scope("document.documentElement")
external setHtmlAttribute: (string, string) => unit = "setAttribute"
@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
@val @scope("window") external addEventListener: (string, 'a) => unit = "addEventListener"
@val @scope("window") external removeEventListener: (string, 'a) => unit = "removeEventListener"
@val @scope("window")
external addEventListenerCapture: (string, 'a, {"capture": bool}) => unit = "addEventListener"
@val @scope("window")
external removeEventListenerCapture: (string, 'a, {"capture": bool}) => unit = "removeEventListener"
@val @scope("document")
external addDocumentEventListenerCapture: (string, 'a, {"capture": bool}) => unit = "addEventListener"
@val @scope("document")
external removeDocumentEventListenerCapture: (string, 'a, {"capture": bool}) => unit = "removeEventListener"
@val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"
@val external decodeURIComponent: string => string = "decodeURIComponent"
@val external getById: string => Nullable.t<Dom.element> = "document.getElementById"
@send
external scrollIntoViewWithBlock: (Dom.element, {"block": string}) => unit = "scrollIntoView"

let isEscapeEvent = (_evt: Dom.event): bool =>
  %raw(`_evt.key === "Escape" || _evt.key === "Esc" || _evt.code === "Escape" || _evt.keyCode === 27 || _evt.which === 27`)

let isCommandKEvent = (_evt: Dom.event): bool =>
  %raw(`(_evt.ctrlKey || _evt.metaKey) && ((_evt.key && _evt.key.toLowerCase() === "k") || _evt.code === "KeyK" || _evt.keyCode === 75 || _evt.which === 75)`)

let stopPropagation = (_evt: Dom.event) => {
  let _ = %raw(`_evt.stopPropagation()`)
}

// ---- Theme management ----
let initialTheme = if SSRContext.isClient {
  switch getItem("xote-theme")->Nullable.toOption {
  | Some("light") => "light"
  | _ => "dark"
  }
} else {
  "dark"
}

let _ = if SSRContext.isClient {
  setHtmlAttribute("data-theme", initialTheme)
}

let theme = Signal.make(initialTheme)

let toggleTheme = () => {
  Signal.update(theme, current =>
    switch current {
    | "dark" => "light"
    | _ => "dark"
    }
  )
  PostHog.capture("theme_toggled", ~properties={"theme": Signal.peek(theme)})
}

if SSRContext.isClient {
  Effect.run(() => {
    let t = Signal.get(theme)
    setHtmlAttribute("data-theme", t)
    setItem("xote-theme", t)
    None
  })
}

// ---- Search state ----
let searchOpen = Signal.make(false)

let openSearch = () => {
  Signal.set(searchOpen, true)
  PostHog.capture("search_opened")
}
let closeSearch = () => Signal.set(searchOpen, false)

// ---- Search items ----
type searchItem = {
  title: string,
  path: string,
  section: string,
}

type parsedPath = {
  pathname: string,
  search: string,
  hash: string,
}

let searchItems: array<searchItem> = [
  {title: "Introduction", path: "/docs", section: "Getting Started"},
  {
    title: "Learning ReScript",
    path: "/docs/getting-started/rescript",
    section: "Getting Started",
  },
  {
    title: "JavaScript Runtime",
    path: "/docs/getting-started/javascript-typescript",
    section: "Getting Started",
  },
  {title: "Signals", path: "/docs/core-concepts/signals", section: "Core Modules"},
  {title: "Computeds", path: "/docs/core-concepts/computed", section: "Core Modules"},
  {title: "Effects", path: "/docs/core-concepts/effects", section: "Core Modules"},
  {title: "View", path: "/docs/view/overview", section: "Core Modules"},
  {title: "Context", path: "/docs/core-concepts/context", section: "Core Modules"},
  {title: "Resources", path: "/docs/core-concepts/resources", section: "Core Modules"},
  {title: "Router", path: "/docs/router/overview", section: "Router"},
  {title: "Signal API", path: "/docs/api/signal", section: "API Reference"},
  {title: "Computed API", path: "/docs/api/computed", section: "API Reference"},
  {title: "Effect API", path: "/docs/api/effect", section: "API Reference"},
  {title: "View API", path: "/docs/api/view", section: "API Reference"},
  {title: "React Comparison", path: "/docs/comparisons/react", section: "Comparisons"},
  {title: "SolidJS Comparison", path: "/docs/comparisons/solidjs", section: "Comparisons"},
  {title: "Server-Side Rendering", path: "/docs/advanced/ssr", section: "Advanced"},
  {title: "MDX Support", path: "/docs/advanced/mdx-support", section: "Advanced"},
  {title: "Batching", path: "/docs/advanced/batching", section: "Advanced"},
  {title: "Technical Overview", path: "/docs/technical-overview", section: "Advanced"},
  {title: "Changelog", path: "/docs/changelog", section: "Project"},
]

// ---- Search Modal ----
module SearchModal = {
  type props = {}

  let parsePath = (path: string): parsedPath => {
    let hashParts = path->String.split("#")
    let pathWithoutHash = hashParts->Array.get(0)->Option.getOr(path)
    let hash = switch hashParts->Array.get(1) {
    | Some(fragment) => "#" ++ fragment
    | None => ""
    }
    let searchParts = pathWithoutHash->String.split("?")
    let pathname = searchParts->Array.get(0)->Option.getOr(pathWithoutHash)
    let search = switch searchParts->Array.get(1) {
    | Some(query) => "?" ++ query
    | None => ""
    }
    {pathname, search, hash}
  }

  let focusSearchInput = () => {
    let _ = %raw(`(() => {
      const el = document.querySelector('.search-input');
      if (el && typeof el.focus === 'function') el.focus();
    })()`)
  }

  let scrollActiveIntoView = () => {
    let _ = %raw(`(() => {
      const el = document.querySelector('.search-result-item.active');
      if (el && typeof el.scrollIntoView === 'function') {
        el.scrollIntoView({block: 'nearest'});
      }
    })()`)
  }

  let scrollPathHashIntoView = (hash: string) => {
    if hash != "" {
      let id = hash->String.split("#")->Array.get(1)->Option.getOr("")->decodeURIComponent
      switch getById(id)->Nullable.toOption {
      | Some(el) => scrollIntoViewWithBlock(el, {"block": "start"})
      | None => ()
      }
    }
  }

  let make = (_props: props) => {
    let query = Signal.make("")
    let selectedIndex = Signal.make(0)

    let resetSearchState = () =>
      Signal.batch(() => {
        closeSearch()
        Signal.set(query, "")
        Signal.set(selectedIndex, 0)
      })

    let filteredItems = Computed.make(() => {
      let q = Signal.get(query)->String.toLowerCase
      if q == "" {
        searchItems
      } else {
        searchItems->Array.filter(item =>
          item.title->String.toLowerCase->String.includes(q) ||
            item.section->String.toLowerCase->String.includes(q)
        )
      }
    })

    if SSRContext.isClient {
      Effect.run(() => {
        if Signal.get(searchOpen) {
          queueMicrotask(focusSearchInput)
        } else {
          Signal.set(query, "")
          Signal.set(selectedIndex, 0)
        }
        None
      })

      Effect.run(() => {
        let _ = Signal.get(selectedIndex)
        let _ = Signal.get(filteredItems)
        if Signal.peek(searchOpen) {
          queueMicrotask(scrollActiveIntoView)
        }
        None
      })

      Effect.run(() => {
        let _ = Signal.get(Router.location())
        if Signal.peek(searchOpen) {
          resetSearchState()
        }
        None
      })

      Effect.run(() => {
        if Signal.get(searchOpen) {
          let escapeHandler = (_evt: Dom.event) => {
            if isEscapeEvent(_evt) {
              let _ = %raw(`_evt.preventDefault()`)
              stopPropagation(_evt)
              resetSearchState()
            }
          }
          addDocumentEventListenerCapture("keydown", escapeHandler, {"capture": true})
          addDocumentEventListenerCapture("keyup", escapeHandler, {"capture": true})
          addEventListenerCapture("keydown", escapeHandler, {"capture": true})
          addEventListenerCapture("keyup", escapeHandler, {"capture": true})
          Some(() =>
            {
              removeDocumentEventListenerCapture("keydown", escapeHandler, {"capture": true})
              removeDocumentEventListenerCapture("keyup", escapeHandler, {"capture": true})
              removeEventListenerCapture("keydown", escapeHandler, {"capture": true})
              removeEventListenerCapture("keyup", escapeHandler, {"capture": true})
            }
          )
        } else {
          None
        }
      })
    }

    let handleInput = (_evt: Dom.event) => {
      let value: string = %raw(`_evt.target.value`)
      Signal.set(query, value)
      Signal.set(selectedIndex, 0)
    }

    let navigateToItem = (item: searchItem) => {
      let {pathname, search, hash} = parsePath(item.path)
      PostHog.capture(
        "search_result_selected",
        ~properties={"result_path": item.path, "result_title": item.title},
      )
      resetSearchState()
      queueMicrotask(() => {
        Router.push(pathname, ~search, ~hash, ())
        if hash != "" {
          queueMicrotask(() => scrollPathHashIntoView(hash))
        }
      })
    }

    let navigateToResult = () => {
      let items = Signal.peek(filteredItems)
      let idx = Signal.peek(selectedIndex)
      switch items->Array.get(idx) {
      | Some(item) => navigateToItem(item)
      | None => ()
      }
    }

    let handleKeyDown = (_evt: Dom.event) => {
      let key: string = %raw(`_evt.key`)
      if isEscapeEvent(_evt) {
        let _ = %raw(`_evt.preventDefault()`)
        stopPropagation(_evt)
        resetSearchState()
      } else {
        switch key {
        | "ArrowDown" => {
            let _ = %raw(`_evt.preventDefault()`)
            let items = Signal.peek(filteredItems)
            Signal.update(selectedIndex, i => i < Array.length(items) - 1 ? i + 1 : i)
          }
        | "ArrowUp" => {
            let _ = %raw(`_evt.preventDefault()`)
            Signal.update(selectedIndex, i => i > 0 ? i - 1 : 0)
          }
        | "Enter" => navigateToResult()
        | _ => ()
        }
      }
    }

    let handleOverlayKeyDown = (_evt: Dom.event) => {
      if isEscapeEvent(_evt) {
          let _ = %raw(`_evt.preventDefault()`)
        stopPropagation(_evt)
        resetSearchState()
      }
    }

    View.signalFragment(
      Computed.make(() => {
        if Signal.get(searchOpen) {
          [
            View.element(
              "div",
              ~attrs=[View.attr("class", "search-overlay")],
              ~events=[
                (
                  "click",
                  _evt => {
                    let className: string = %raw(`_evt.target.className || ""`)
                    if className->String.includes("search-overlay") {
                      resetSearchState()
                    }
                  },
                ),
              ],
              ~children=[
                <div
                  class="search-modal"
                  tabIndex=0
                  onKeyDown={handleOverlayKeyDown}>
                  <div class="search-input-wrapper">
                    {Html.input(
                      ~attrs=[
                        View.attr("class", "search-input"),
                        View.attr("placeholder", "Search the docs..."),
                        View.attr("autofocus", "true"),
                      ],
                      ~events=[("input", handleInput), ("keydown", handleKeyDown)],
                      (),
                    )}
                  </div>
                  <div class="search-results">
                    {View.signalFragment(
                      Computed.make(() => {
                        let items = Signal.get(filteredItems)
                        let idx = Signal.get(selectedIndex)
                        if Array.length(items) == 0 {
                          [
                            <div class="search-empty">
                              {View.text("No results found.")}
                            </div>,
                          ]
                        } else {
                          let currentSection = ref("")
                          let globalIdx = ref(0)
                          items->Array.flatMap(item => {
                            let nodes = []
                            if currentSection.contents != item.section {
                              currentSection := item.section
                              nodes
                              ->Array.push(
                                <div class="search-group-label">
                                  {View.text(item.section)}
                                </div>,
                              )
                              ->ignore
                            }
                            let myIdx = globalIdx.contents
                            let isActive = myIdx == idx
                            let cn = "search-result-item" ++ (isActive ? " active" : "")
                            nodes
                            ->Array.push(
                              View.element(
                                "div",
                                ~attrs=[View.attr("class", cn)],
                                ~events=[
                                  (
                                    "click",
                                    _ => navigateToItem(item),
                                  ),
                                ],
                                ~children=[
                                  <div class="search-result-title">
                                    {View.text(item.title)}
                                  </div>,
                                ],
                                (),
                              ),
                            )
                            ->ignore
                            globalIdx := myIdx + 1
                            nodes
                          })
                        }
                      }),
                    )}
                  </div>
                  <div class="search-footer">
                    {View.text("\u2191\u2193 navigate  \u21B5 select  esc close")}
                  </div>
                </div>,
              ],
              (),
            ),
          ]
        } else {
          []
        }
      }),
    )
  }
}

// ---- Logo Mark ----
// The ring mark, coloured by tokens (core in the signal colour, rings in ink
// tones) so it follows the theme and turns near-black on the lime hero.
module LogoMark = {
  type props = {size: option<int>}

  let make = (props: props) => {
    let sizeStr = props.size->Option.getOr(24)->Int.toString
    <svg
      class="logo-mark" width={sizeStr} height={sizeStr} viewBox="0 0 100 100" fill="none" ariaHidden=true>
      <circle class="logo-ring-outer" cx="50" cy="50" r="40" />
      <circle class="logo-ring-mid" cx="50" cy="50" r="27" />
      <circle class="logo-ring-core" cx="50" cy="50" r="15" />
      <circle class="logo-dot" cx="50" cy="50" r="6.5" />
    </svg>
  }
}

let isDocsPath = path => path == "/docs" || path->String.startsWith("/docs/")

// ---- Header ----
module Header = {
  type props = {}

  let make = (_props: props) => {
    let headerClass = () => {
      let path = Signal.get(Router.location()).pathname
      if path == "/" {
        "site-header site-header-hero"
      } else if isDocsPath(path) {
        "site-header site-header-docs"
      } else {
        "site-header"
      }
    }

    let externalLink = (~href, ~label, ~event) =>
      <a
        href
        target="_blank"
        class="header-nav-link"
        onClick={_ => PostHog.capture(event, ~properties={"source": "header"})}>
        {View.text(label)}
      </a>

    <header class={headerClass}>
      <div class="header-inner">
        {Router.link(
          ~to="/",
          ~attrs=[View.attr("class", "header-logo-link"), View.attr("aria-label", "Xote home")],
          ~children=[<LogoMark size={Some(28)} />, <span class="logo-text"> {View.text("xote")} </span>],
          (),
        )}
        {Router.link(
          ~to="/docs/changelog",
          ~attrs=[View.attr("class", "header-version")],
          ~children=[View.text("v" ++ RepoData.latestVersion)],
          (),
        )}
        {View.element(
          "button",
          ~attrs=[View.attr("class", "search-trigger"), View.attr("type", "button")],
          ~events=[("click", _ => openSearch())],
          ~children=[
            <svg width="15" height="15" viewBox="0 0 16 16" ariaHidden=true>
              <circle cx="7" cy="7" r="5" fill="none" stroke="currentColor" strokeWidth="1.5" />
              <path d="M11 11l3.5 3.5" stroke="currentColor" strokeWidth="1.5" strokeLinecap="round" />
            </svg>,
            <span> {View.text("Search docs")} </span>,
            <kbd class="search-trigger-key"> {View.text("⌘K")} </kbd>,
          ],
          (),
        )}
        <nav class="header-nav" ariaLabel="Main">
          {Router.link(
            ~to="/docs",
            ~attrs=[View.attr("class", "header-nav-link")],
            ~children=[View.text("Docs")],
            (),
          )}
          {externalLink(
            ~href="https://brnrdog.github.io/xote-playground/",
            ~label="Playground",
            ~event="playground_link_clicked",
          )}
          {externalLink(
            ~href="https://github.com/brnrdog/xote",
            ~label="GitHub",
            ~event="github_link_clicked",
          )}
        </nav>
        {View.signalFragment(
          Computed.make(() =>
            isDocsPath(Signal.get(Router.location()).pathname) ? [<DocsLayer.Switch />] : []
          ),
        )}
        {View.element(
          "button",
          ~attrs=[
            View.attr("class", "header-icon-btn"),
            View.attr("type", "button"),
            View.attr("title", "Toggle theme"),
            View.attr("aria-label", "Toggle colour theme"),
          ],
          ~events=[("click", _ => toggleTheme())],
          ~children=[View.signalText(() => Signal.get(theme) == "dark" ? "☾" : "☀")],
          (),
        )}
        {View.element(
          "button",
          ~attrs=[
            View.attr("class", "header-icon-btn mobile-menu-btn"),
            View.attr("type", "button"),
            View.attr("aria-label", "Search the docs"),
          ],
          ~events=[("click", _ => openSearch())],
          ~children=[View.text("≡")],
          (),
        )}
      </div>
    </header>
  }
}

// ---- Footer ----
module Footer = {
  type props = {}

  type link = {label: string, to: string}

  let columns: array<(string, array<link>)> = [
    (
      "Get started",
      [
        {label: "Introduction", to: "/docs"},
        {label: "Learning ReScript", to: "/docs/getting-started/rescript"},
        {label: "JavaScript runtime", to: "/docs/getting-started/javascript-typescript"},
      ],
    ),
    (
      "Core",
      [
        {label: "Signals", to: "/docs/core-concepts/signals"},
        {label: "Computeds", to: "/docs/core-concepts/computed"},
        {label: "Effects", to: "/docs/core-concepts/effects"},
        {label: "View", to: "/docs/view/overview"},
        {label: "Context", to: "/docs/core-concepts/context"},
        {label: "Resources", to: "/docs/core-concepts/resources"},
      ],
    ),
    (
      "Guides",
      [
        {label: "Router", to: "/docs/router/overview"},
        {label: "Server-side rendering", to: "/docs/advanced/ssr"},
        {label: "MDX support", to: "/docs/advanced/mdx-support"},
        {label: "Batching", to: "/docs/advanced/batching"},
      ],
    ),
    (
      "Reference",
      [
        {label: "Signal API", to: "/docs/api/signal"},
        {label: "View API", to: "/docs/api/view"},
        {label: "Technical overview", to: "/docs/technical-overview"},
        {label: "Changelog", to: "/docs/changelog"},
      ],
    ),
  ]

  let make = (_props: props) => {
    <footer class="site-footer">
      <div class="footer-inner">
        <div class="footer-top">
          <div class="footer-brand">
            {Router.link(
              ~to="/",
              ~attrs=[View.attr("class", "header-logo-link")],
              ~children=[<LogoMark size={Some(28)} />, <span class="logo-text"> {View.text("xote")} </span>],
              (),
            )}
            <p> {View.text("Fine-grained reactivity for ReScript.")} </p>
          </div>
          <nav class="footer-sitemap" ariaLabel="Sitemap">
            {View.fragment(
              columns->Array.map(((title, links)) =>
                <div class="footer-col">
                  <span class="footer-col-title"> {View.text(title)} </span>
                  {View.fragment(
                    links->Array.map(link =>
                      Router.link(~to=link.to, ~children=[View.text(link.label)], ())
                    ),
                  )}
                </div>
              ),
            )}
            <div class="footer-col">
              <span class="footer-col-title"> {View.text("Community")} </span>
              <a href="https://github.com/brnrdog/xote" target="_blank"> {View.text("GitHub")} </a>
              <a href="https://github.com/brnrdog/xote/issues" target="_blank">
                {View.text("Issues")}
              </a>
              <a href="https://www.npmjs.com/package/xote" target="_blank"> {View.text("npm")} </a>
              <a href="https://brnrdog.github.io/xote-playground/" target="_blank">
                {View.text("Playground")}
              </a>
            </div>
          </nav>
        </div>
        <div class="footer-bottom">
          <span> {View.text("© Bernardo Gurgel · MIT License · Built with ReScript and Xote")} </span>
          {Router.link(
            ~to="/docs/changelog",
            ~attrs=[View.attr("class", "footer-version")],
            ~children=[View.text("v" ++ RepoData.latestVersion)],
            (),
          )}
        </div>
      </div>
    </footer>
  }
}

// ---- Global Cmd+K shortcut (client-only) ----
if SSRContext.isClient {
  Effect.run(() => {
    let handler = (_evt: Dom.event) => {
      if isCommandKEvent(_evt) {
        let _ = %raw(`_evt.preventDefault()`)
        if Signal.peek(searchOpen) {
          closeSearch()
        } else {
          openSearch()
        }
      } else if isEscapeEvent(_evt) && Signal.peek(searchOpen) {
        let _ = %raw(`_evt.preventDefault()`)
        stopPropagation(_evt)
        closeSearch()
      }
    }
    addEventListenerCapture("keydown", handler, {"capture": true})
    addEventListenerCapture("keyup", handler, {"capture": true})
    Some(() => {
      removeEventListenerCapture("keydown", handler, {"capture": true})
      removeEventListenerCapture("keyup", handler, {"capture": true})
    })
  })
}

// ---- Main layout wrapper ----
type props = {children: View.node}

let make = (props: props) => {
  let mainClass = () =>
    isDocsPath(Signal.get(Router.location()).pathname) ? "site-main site-main-docs" : "site-main"

  <div>
    <Header />
    <main id="main-content" class={mainClass}> {props.children} </main>
    <Footer />
    <SearchModal />
  </div>
}
