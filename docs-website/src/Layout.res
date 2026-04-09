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

let openSearch = () => Signal.set(searchOpen, true)
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
  {title: "Signals", path: "/docs/core-concepts/signals", section: "Core Concepts"},
  {title: "Computed", path: "/docs/core-concepts/computed", section: "Core Concepts"},
  {title: "Effects", path: "/docs/core-concepts/effects", section: "Core Concepts"},
  {title: "Batching", path: "/docs/advanced/batching", section: "Advanced"},
  {title: "Server-Side Rendering", path: "/docs/advanced/ssr", section: "Advanced"},
  {title: "Components Overview", path: "/docs/components/overview", section: "Components"},
  {title: "Router Overview", path: "/docs/router/overview", section: "Router"},
  {title: "Signals API", path: "/docs/api/signals", section: "API Reference"},
  {title: "React Comparison", path: "/docs/comparisons/react", section: "Comparisons"},
  {title: "Technical Overview", path: "/docs/technical-overview", section: "Advanced"},
  {title: "Counter", path: "/docs/demos/counter", section: "Demos"},
  {title: "Todo List", path: "/docs/demos/todo", section: "Demos"},
  {title: "Color Mixer", path: "/docs/demos/color-mixer", section: "Demos"},
  {title: "Reaction Game", path: "/docs/demos/reaction-game", section: "Demos"},
  {title: "Solitaire", path: "/docs/demos/solitaire", section: "Demos"},
  {title: "Memory Match", path: "/docs/demos/memory-match", section: "Demos"},
  {title: "Snake Game", path: "/docs/demos/snake", section: "Demos"},
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

    Node.signalFragment(
      Computed.make(() => {
        if Signal.get(searchOpen) {
          [
            Node.element(
              "div",
              ~attrs=[Node.attr("class", "search-overlay")],
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
                <div class="search-modal">
                  <div class="search-input-wrapper">
                    {Basefn.Icon.make({name: Search, size: Sm})}
                    {Html.input(
                      ~attrs=[
                        Node.attr("class", "search-input"),
                        Node.attr("placeholder", "Search documentation..."),
                        Node.attr("autofocus", "true"),
                      ],
                      ~events=[("input", handleInput), ("keydown", handleKeyDown)],
                      (),
                    )}
                    <div class="search-trigger-key"> {Node.text("esc")} </div>
                  </div>
                  <div class="search-results">
                    {Node.signalFragment(
                      Computed.make(() => {
                        let items = Signal.get(filteredItems)
                        let idx = Signal.get(selectedIndex)
                        if Array.length(items) == 0 {
                          [
                            <div class="search-empty">
                              {Node.text("No results found.")}
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
                                  {Node.text(item.section)}
                                </div>,
                              )
                              ->ignore
                            }
                            let myIdx = globalIdx.contents
                            let isActive = myIdx == idx
                            let cn = "search-result-item" ++ (isActive ? " active" : "")
                            nodes
                            ->Array.push(
                              Node.element(
                                "div",
                                ~attrs=[Node.attr("class", cn)],
                                ~events=[
                                  (
                                    "click",
                                    _ => {
                                      Router.push(item.path, ())
                                      closeSearch()
                                      Signal.set(query, "")
                                    },
                                  ),
                                ],
                                ~children=[
                                  <div class="search-result-title">
                                    {Node.text(item.title)}
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
                    {Node.text("Use arrow keys to navigate, Enter to select, Esc to close")}
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

    Node.element(
      "header",
      ~attrs=[
        Node.computedAttr("class", () =>
          Signal.get(isScrolled) ? "site-header scrolled" : "site-header"
        ),
      ],
      ~children=[
        <div class="header-inner">
          <div class="header-left">
            {Router.link(
              ~to="/",
              ~attrs=[Node.attr("class", "header-logo-link")],
              ~children=[
                <Logo size=20 color="var(--text-accent)" />,
                <span class="logo-text"> {Node.text("xote")} </span>,
              ],
              (),
            )}
            <a href="https://www.npmjs.com/package/xote" target="_blank" class="header-version">
              {Node.text("v6.0.0")}
            </a>
            <nav class="header-nav">
              {Router.link(
                ~to="/docs",
                ~attrs=[Node.attr("class", "header-nav-link")],
                ~children=[Node.text("Learn")],
                (),
              )}
              {Router.link(
                ~to="/docs/api/signals",
                ~attrs=[Node.attr("class", "header-nav-link")],
                ~children=[Node.text("API Reference")],
                (),
              )}
            </nav>
          </div>
          <div class="header-right">
            {Node.element(
              "button",
              ~attrs=[Node.attr("class", "search-trigger")],
              ~events=[("click", _ => openSearch())],
              ~children=[
                Basefn.Icon.make({name: Search, size: Sm}),
                <span> {Node.text("Search docs...")} </span>,
                <div class="search-trigger-keys">
                  <span class="search-trigger-key"> {Node.text("\u2318")} </span>
                  <span class="search-trigger-key"> {Node.text("K")} </span>
                </div>,
              ],
              (),
            )}
            {Node.element(
              "a",
              ~attrs=[
                Node.attr("href", "https://github.com/brnrdog/xote"),
                Node.attr("target", "_blank"),
                Node.attr("class", "gh-star-btn"),
                Node.attr("title", "Star on GitHub"),
              ],
              ~children=[
                Basefn.Icon.make({name: Star, size: Sm}),
                Node.element(
                  "span",
                  ~attrs=[Node.attr("class", "gh-star-label")],
                  ~children=[Node.text("Star")],
                  (),
                ),
              ],
              (),
            )}
            {Node.element(
              "a",
              ~attrs=[
                Node.attr("href", "https://github.com/brnrdog/xote"),
                Node.attr("target", "_blank"),
                Node.attr("class", "header-icon-btn"),
                Node.attr("title", "GitHub"),
              ],
              ~children=[Basefn.Icon.make({name: GitHub, size: Sm})],
              (),
            )}
            {Node.element(
              "button",
              ~attrs=[
                Node.attr("class", "header-icon-btn"),
                Node.attr("title", "Toggle theme"),
              ],
              ~events=[("click", _ => toggleTheme())],
              ~children=[
                Node.signalFragment(
                  Computed.make(() =>
                    Signal.get(theme) == "dark"
                      ? [Basefn.Icon.make({name: Sun, size: Sm})]
                      : [Basefn.Icon.make({name: Moon, size: Sm})]
                  ),
                ),
              ],
              (),
            )}
            {Node.element(
              "button",
              ~attrs=[
                Node.attr("class", "header-icon-btn mobile-menu-btn"),
                Node.attr("title", "Menu"),
              ],
              ~events=[("click", _ => openSearch())],
              ~children=[Basefn.Icon.make({name: Menu, size: Sm})],
              (),
            )}
          </div>
        </div>,
      ],
      (),
    )
  }
}

// ---- Footer ----
module Footer = {
  type props = {}

  let make = (_props: props) => {
    let year = Date.now()->Date.fromTime->Date.getFullYear->Int.toString

    <footer class="site-footer">
      <div class="footer-inner">
        <div class="footer-grid">
          <div class="footer-brand">
            <div class="footer-brand-logo">
              <Logo size=16 color="var(--text-accent)" />
              <span> {Node.text("xote")} </span>
            </div>
            <p>
              {Node.text(
                "A lightweight UI library for ReScript with fine-grained reactivity powered by TC39 Signals.",
              )}
            </p>
          </div>
          <div class="footer-col">
            <h4> {Node.text("Docs")} </h4>
            <ul>
              <li>
                {Router.link(~to="/docs", ~children=[Node.text("Getting Started")], ())}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/core-concepts/signals",
                  ~children=[Node.text("Core Concepts")],
                  (),
                )}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/api/signals",
                  ~children=[Node.text("API Reference")],
                  (),
                )}
              </li>
            </ul>
          </div>
          <div class="footer-col">
            <h4> {Node.text("Community")} </h4>
            <ul>
              <li>
                <a href="https://github.com/brnrdog/xote" target="_blank">
                  {Node.text("GitHub")}
                </a>
              </li>
              <li>
                <a href="https://www.npmjs.com/package/xote" target="_blank">
                  {Node.text("npm")}
                </a>
              </li>
              <li>
                {Router.link(~to="/demos", ~children=[Node.text("Demos")], ())}
              </li>
            </ul>
          </div>
          <div class="footer-col">
            <h4> {Node.text("More")} </h4>
            <ul>
              <li>
                <a href="https://rescript-lang.org/" target="_blank">
                  {Node.text("ReScript")}
                </a>
              </li>
              <li>
                <a href="https://github.com/tc39/proposal-signals" target="_blank">
                  {Node.text("TC39 Signals")}
                </a>
              </li>
              <li>
                <a href="https://brnrdog.github.io/rescript-signals" target="_blank">
                  {Node.text("rescript-signals")}
                </a>
              </li>
            </ul>
          </div>
        </div>
        <div class="footer-bottom">
          <div> {Node.text(`Copyright \u00A9 ${year} Bernardo Gurgel. MIT License.`)} </div>
          <div class="footer-bottom-right">
            {Node.text("Built with ")}
            <Logo size=14 color="var(--text-accent)" />
            {Node.text(" xote")}
          </div>
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
type props = {children: Node.node}

let make = (props: props) => {
  <div>
    <Header />
    <main id="main-content"> {props.children} </main>
    <Footer />
    <SearchModal />
  </div>
}
