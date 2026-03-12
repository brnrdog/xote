open Xote

// ---- External bindings ----
@val @scope("document.documentElement")
external setHtmlAttribute: (string, string) => unit = "setAttribute"
@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
@val @scope("window") external addEventListener: (string, 'a) => unit = "addEventListener"
@val @scope("window") external removeEventListener: (string, 'a) => unit = "removeEventListener"

// ---- Theme management ----
let initialTheme = switch getItem("xote-theme")->Nullable.toOption {
| Some("light") => "light"
| _ => "dark"
}

let _ = setHtmlAttribute("data-theme", initialTheme)

let theme = Signal.make(initialTheme)

let toggleTheme = () => {
  Signal.update(theme, current =>
    switch current {
    | "dark" => "light"
    | _ => "dark"
    }
  )
}

let _ = Effect.run(() => {
  let t = Signal.get(theme)
  setHtmlAttribute("data-theme", t)
  setItem("xote-theme", t)
  Basefn.Theme.applyTheme(t == "dark" ? Basefn.Theme.Dark : Basefn.Theme.Light)
  None
})

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
  {title: "Batching", path: "/docs/core-concepts/batching", section: "Core Concepts"},
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

    Component.signalFragment(
      Computed.make(() => {
        if Signal.get(searchOpen) {
          [
            Component.element(
              "div",
              ~attrs=[Component.attr("class", "search-overlay")],
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
                    {Component.input(
                      ~attrs=[
                        Component.attr("class", "search-input"),
                        Component.attr("placeholder", "Search documentation..."),
                        Component.attr("autofocus", "true"),
                      ],
                      ~events=[("input", handleInput), ("keydown", handleKeyDown)],
                      (),
                    )}
                    <div class="search-trigger-key"> {Component.text("esc")} </div>
                  </div>
                  <div class="search-results">
                    {Component.signalFragment(
                      Computed.make(() => {
                        let items = Signal.get(filteredItems)
                        let idx = Signal.get(selectedIndex)
                        if Array.length(items) == 0 {
                          [
                            <div class="search-empty">
                              {Component.text("No results found.")}
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
                                  {Component.text(item.section)}
                                </div>,
                              )
                              ->ignore
                            }
                            let myIdx = globalIdx.contents
                            let isActive = myIdx == idx
                            let cn = "search-result-item" ++ (isActive ? " active" : "")
                            nodes
                            ->Array.push(
                              Component.element(
                                "div",
                                ~attrs=[Component.attr("class", cn)],
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
                                    {Component.text(item.title)}
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
                    {Component.text("Use arrow keys to navigate, Enter to select, Esc to close")}
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
    // Scroll listener
    let _ = Effect.run(() => {
      let handleScroll = () => {
        let scrollY: float = %raw(`window.scrollY`)
        Signal.set(isScrolled, scrollY > 10.0)
      }
      addEventListener("scroll", handleScroll)
      Some(() => removeEventListener("scroll", handleScroll))
    })

    Component.element(
      "header",
      ~attrs=[
        Component.computedAttr("class", () =>
          Signal.get(isScrolled) ? "site-header scrolled" : "site-header"
        ),
      ],
      ~children=[
        <div class="header-inner">
          <div class="header-left">
            {Router.link(
              ~to="/",
              ~attrs=[Component.attr("class", "header-logo-link")],
              ~children=[
                <Logo size=20 color="var(--text-accent)" />,
                <span class="logo-text"> {Component.text("xote")} </span>,
              ],
              (),
            )}
            <a href="https://www.npmjs.com/package/xote" target="_blank" class="header-version">
              {Component.text("v4.15.1")}
            </a>
            <nav class="header-nav">
              {Router.link(
                ~to="/docs",
                ~attrs=[Component.attr("class", "header-nav-link")],
                ~children=[Component.text("Learn")],
                (),
              )}
              {Router.link(
                ~to="/docs/api/signals",
                ~attrs=[Component.attr("class", "header-nav-link")],
                ~children=[Component.text("API Reference")],
                (),
              )}
            </nav>
          </div>
          <div class="header-right">
            {Component.element(
              "button",
              ~attrs=[Component.attr("class", "search-trigger")],
              ~events=[("click", _ => openSearch())],
              ~children=[
                Basefn.Icon.make({name: Search, size: Sm}),
                <span> {Component.text("Search docs...")} </span>,
                <div class="search-trigger-keys">
                  <span class="search-trigger-key"> {Component.text("\u2318")} </span>
                  <span class="search-trigger-key"> {Component.text("K")} </span>
                </div>,
              ],
              (),
            )}
            {Component.element(
              "a",
              ~attrs=[
                Component.attr("href", "https://github.com/brnrdog/xote"),
                Component.attr("target", "_blank"),
                Component.attr("class", "header-icon-btn"),
                Component.attr("title", "GitHub"),
              ],
              ~children=[Basefn.Icon.make({name: GitHub, size: Sm})],
              (),
            )}
            {Component.element(
              "button",
              ~attrs=[
                Component.attr("class", "header-icon-btn"),
                Component.attr("title", "Toggle theme"),
              ],
              ~events=[("click", _ => toggleTheme())],
              ~children=[
                Component.signalFragment(
                  Computed.make(() =>
                    Signal.get(theme) == "dark"
                      ? [Basefn.Icon.make({name: Sun, size: Sm})]
                      : [Basefn.Icon.make({name: Moon, size: Sm})]
                  ),
                ),
              ],
              (),
            )}
            {Component.element(
              "button",
              ~attrs=[
                Component.attr("class", "header-icon-btn mobile-menu-btn"),
                Component.attr("title", "Menu"),
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
              <span> {Component.text("xote")} </span>
            </div>
            <p>
              {Component.text(
                "A lightweight UI library for ReScript with fine-grained reactivity powered by TC39 Signals.",
              )}
            </p>
          </div>
          <div class="footer-col">
            <h4> {Component.text("Docs")} </h4>
            <ul>
              <li>
                {Router.link(~to="/docs", ~children=[Component.text("Getting Started")], ())}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/core-concepts/signals",
                  ~children=[Component.text("Core Concepts")],
                  (),
                )}
              </li>
              <li>
                {Router.link(
                  ~to="/docs/api/signals",
                  ~children=[Component.text("API Reference")],
                  (),
                )}
              </li>
            </ul>
          </div>
          <div class="footer-col">
            <h4> {Component.text("Community")} </h4>
            <ul>
              <li>
                <a href="https://github.com/brnrdog/xote" target="_blank">
                  {Component.text("GitHub")}
                </a>
              </li>
              <li>
                <a href="https://www.npmjs.com/package/xote" target="_blank">
                  {Component.text("npm")}
                </a>
              </li>
              <li>
                {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
              </li>
            </ul>
          </div>
          <div class="footer-col">
            <h4> {Component.text("More")} </h4>
            <ul>
              <li>
                <a href="https://rescript-lang.org/" target="_blank">
                  {Component.text("ReScript")}
                </a>
              </li>
              <li>
                <a href="https://github.com/tc39/proposal-signals" target="_blank">
                  {Component.text("TC39 Signals")}
                </a>
              </li>
              <li>
                <a href="https://github.com/brnrdog/rescript-signals" target="_blank">
                  {Component.text("rescript-signals")}
                </a>
              </li>
            </ul>
          </div>
        </div>
        <div class="footer-bottom">
          <div> {Component.text(`Copyright \u00A9 ${year} Bernardo Gurgel. MIT License.`)} </div>
          <div class="footer-bottom-right">
            {Component.text("Built with ")}
            <Logo size=14 color="var(--text-accent)" />
            {Component.text(" xote")}
          </div>
        </div>
      </div>
    </footer>
  }
}

// ---- Global Cmd+K shortcut ----
let _ = Effect.run(() => {
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

// ---- Main layout wrapper ----
type props = {children: Component.node}

let make = (props: props) => {
  <div>
    <Header />
    <main id="main-content"> {props.children} </main>
    <Footer />
    <SearchModal />
  </div>
}
