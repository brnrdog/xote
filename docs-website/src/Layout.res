// ---- External bindings ----
@val @scope("document.documentElement")
external setHtmlAttribute: (string, string) => unit = "setAttribute"
@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
@val @scope("window") external addEventListener: (string, 'a) => unit = "addEventListener"
@val @scope("window") external removeEventListener: (string, 'a) => unit = "removeEventListener"

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
    Basefn.Theme.applyTheme(t == "dark" ? Basefn.Theme.Dark : Basefn.Theme.Light)
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

// ---- Scroll state ----
let isScrolled = Signal.make(false)

// ---- Search items ----
type searchItem = {
  title: string,
  path: string,
  section: string,
}

let searchItems: array<searchItem> = [
  {title: "Introduction", path: "/docs", section: "Getting Started"},
  {title: "Signals", path: "/docs/core-concepts/signals", section: "Core Modules"},
  {title: "Computeds", path: "/docs/core-concepts/computed", section: "Core Modules"},
  {title: "Effects", path: "/docs/core-concepts/effects", section: "Core Modules"},
  {title: "View", path: "/docs/view/overview", section: "Core Modules"},
  {title: "Router", path: "/docs/router/overview", section: "Router"},
  {title: "Signals API", path: "/docs/api/signals", section: "API Reference"},
  {title: "React Comparison", path: "/docs/comparisons/react", section: "Comparisons"},
  {title: "SolidJS Comparison", path: "/docs/comparisons/solidjs", section: "Comparisons"},
  {title: "Server-Side Rendering", path: "/docs/advanced/ssr", section: "Advanced"},
  {title: "Batching", path: "/docs/advanced/batching", section: "Advanced"},
  {title: "Technical Overview", path: "/docs/technical-overview", section: "Advanced"},
  {title: "Changelog", path: "/docs/changelog", section: "Project"},
]

// ---- Search Modal ----
module SearchModal = {
  type props = {}

  let make = (_props: props) => {
    let query = Signal.make("")
    let selectedIndex = Signal.make(0)

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

    let handleInput = (_evt: Dom.event) => {
      let value: string = %raw(`_evt.target.value`)
      Signal.set(query, value)
      Signal.set(selectedIndex, 0)
    }

    let navigateToResult = () => {
      let items = Signal.peek(filteredItems)
      let idx = Signal.peek(selectedIndex)
      switch items->Array.get(idx) {
      | Some(item) =>
        PostHog.capture(
          "search_result_selected",
          ~properties={"result_path": item.path, "result_title": item.title},
        )
        Router.push(item.path, ())
        closeSearch()
        Signal.set(query, "")
      | None => ()
      }
    }

    let handleKeyDown = (_evt: Dom.event) => {
      let key: string = %raw(`_evt.key`)
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
      | "Escape" => {
          closeSearch()
          Signal.set(query, "")
        }
      | _ => ()
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
                      closeSearch()
                      Signal.set(query, "")
                    }
                  },
                ),
              ],
              ~children=[
                <div
                  class="search-modal"
                  tabIndex=0
                  onKeyDown={handleKeyDown}>
                  <div class="search-input-wrapper">
                    {Html.input(
                      ~attrs=[
                        View.attr("class", "search-input"),
                        View.attr("placeholder", "Search the docs..."),
                        View.attr("autofocus", "true"),
                      ],
                      ~events=[("input", handleInput)],
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
                                    _ => {
                                      PostHog.capture(
                                        "search_result_selected",
                                        ~properties={
                                          "result_path": item.path,
                                          "result_title": item.title,
                                        },
                                      )
                                      Router.push(item.path, ())
                                      closeSearch()
                                      Signal.set(query, "")
                                    },
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

// ---- Header ----
module Header = {
  type props = {}

  let make = (_props: props) => {
    // Scroll listener (client-only)
    if SSRContext.isClient {
      Effect.run(() => {
        let handleScroll = () => {
          let scrollY: float = %raw(`window.scrollY`)
          Signal.set(isScrolled, scrollY > 10.0)
        }
        addEventListener("scroll", handleScroll)
        Some(() => removeEventListener("scroll", handleScroll))
      })
    }

    <header class="site-header">
      <div class="header-inner">
        <div class="header-left">
          {Router.link(
            ~to="/",
            ~attrs=[View.attr("class", "header-logo-link")],
            ~children=[<span class="logo-text"> {View.text("xote")} </span>],
            (),
          )}
          {Router.link(
            ~to="/docs/changelog",
            ~attrs=[View.attr("class", "header-version")],
            ~children=[View.text("v" ++ RepoData.latestVersion)],
            (),
          )}
          <nav class="header-nav">
            {Router.link(
              ~to="/docs",
              ~attrs=[View.attr("class", "header-nav-link")],
              ~children=[View.text("Docs")],
              (),
            )}
            <a
              href="https://github.com/brnrdog/xote"
              target="_blank"
              class="header-nav-link"
              onClick={_ =>
                PostHog.capture("github_link_clicked", ~properties={"source": "header"})}>
              {View.text("GitHub")}
            </a>
          </nav>
        </div>
        <div class="header-right">
          {View.element(
            "button",
            ~attrs=[View.attr("class", "search-trigger")],
            ~events=[("click", _ => openSearch())],
            ~children=[
              <span> {View.text("Search")} </span>,
              <div class="search-trigger-keys">
                <span class="search-trigger-key"> {View.text("\u2318K")} </span>
              </div>,
            ],
            (),
          )}
          {View.element(
            "button",
            ~attrs=[
              View.attr("class", "header-icon-btn"),
              View.attr("title", "Toggle theme"),
            ],
            ~events=[("click", _ => toggleTheme())],
            ~children=[
              View.signalText(() =>
                Signal.get(theme) == "dark" ? "\u263E" : "\u2600"
              ),
            ],
            (),
          )}
          {View.element(
            "button",
            ~attrs=[
              View.attr("class", "header-icon-btn mobile-menu-btn"),
              View.attr("title", "Menu"),
            ],
            ~events=[("click", _ => openSearch())],
            ~children=[View.text("\u2261")],
            (),
          )}
        </div>
      </div>
    </header>
  }
}

// ---- Footer ----
module Footer = {
  type props = {}

  let make = (_props: props) => {
    <footer class="site-footer">
      <div class="footer-inner">
        <div class="footer-grid">
          <div class="footer-brand">
            <h4 class="footer-brand-name">
              <span class="logo-text"> {View.text("xote")} </span>
            </h4>
            <p>
              {View.text(
                "A ReScript Library for Interactive User Interfaces",
              )}
            </p>
          </div>
          <div class="footer-col">
            <h4> {View.text("Docs")} </h4>
            <ul>
              <li>
                {Router.link(~to="/docs", ~children=[View.text("Introduction")], ())}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/core-concepts/signals",
                  ~children=[View.text("Core Modules")],
                  (),
                )}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/api/signals",
                  ~children=[View.text("API Reference")],
                  (),
                )}
              </li>
              <li>
                {Router.link(~to="/docs/changelog", ~children=[View.text("Changelog")], ())}
              </li>
            </ul>
          </div>
          <div class="footer-col">
            <h4> {View.text("Community")} </h4>
            <ul>
              <li>
                <a href="https://github.com/brnrdog/xote" target="_blank">
                  {View.text("GitHub \u2197")}
                </a>
              </li>
              <li>
                <a href="https://www.npmjs.com/package/xote" target="_blank">
                  {View.text("npm \u2197")}
                </a>
              </li>
              <li>
                <a
                  href="https://github.com/brnrdog/xote/issues"
                  target="_blank">
                  {View.text("Issues \u2197")}
                </a>
              </li>
            </ul>
          </div>
        </div>
        <div class="footer-bottom">
          <div>
            {View.text("Bernardo Gurgel \u00B7  MIT License \u00B7 Built with ReScript and xote")}
          </div>
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
      let ctrlOrMeta: bool = %raw(`_evt.ctrlKey || _evt.metaKey`)
      let key: string = %raw(`_evt.key`)
      if ctrlOrMeta && key == "k" {
        let _ = %raw(`_evt.preventDefault()`)
        if Signal.peek(searchOpen) {
          closeSearch()
        } else {
          openSearch()
        }
      }
    }
    addEventListener("keydown", handler)
    Some(() => removeEventListener("keydown", handler))
  })
}

// ---- Main layout wrapper ----
type props = {children: View.node}

let make = (props: props) => {
  <div>
    <Header />
    <main id="main-content"> {props.children} </main>
    <Footer />
    <SearchModal />
  </div>
}
