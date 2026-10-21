// ---- External bindings ----
@val @scope("document.documentElement")
external setHtmlAttribute: (string, string) => unit = "setAttribute"
@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"

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

// ---- Header over the hero ----
// On the home page the sticky header wears the hero's lime colours until the
// hero has scrolled out from under it.
@val @scope("window") external scrollY: float = "scrollY"
@val @scope("window")
external addWindowListener: (string, unit => unit, {"passive": bool}) => unit = "addEventListener"
@val @scope("document") @return(nullable)
external querySelector: string => option<{"offsetHeight": float}> = "querySelector"

let infinity = Float.Constants.positiveInfinity

let overHero = Signal.make(true)

let syncOverHero = () => {
  let heroHeight = switch querySelector(".home-hero") {
  | Some(hero) => hero["offsetHeight"]
  | None => infinity
  }
  Signal.set(overHero, scrollY < heroHeight -. 72.0)
}

let _ = if SSRContext.isClient {
  addWindowListener("scroll", syncOverHero, {"passive": true})
  addWindowListener("resize", syncOverHero, {"passive": true})
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
        Signal.get(overHero) ? "site-header site-header-home site-header-hero" : "site-header site-header-home"
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
          ~events=[("click", _ => Search.open_())],
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
          ~events=[("click", _ => Search.open_())],
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
        {label: "Quick start", to: "/docs/quick-start"},
        {label: "Thinking in signals", to: "/docs/thinking-in-signals"},
        {label: "Tutorial", to: "/docs/tutorial"},
      ],
    ),
    (
      "Learn",
      [
        {label: "Signals", to: "/docs/learn/signals"},
        {label: "Computeds", to: "/docs/learn/computeds"},
        {label: "Effects", to: "/docs/learn/effects"},
        {label: "Components", to: "/docs/learn/components"},
        {label: "Routing", to: "/docs/learn/routing"},
      ],
    ),
    (
      "Guides",
      [
        {label: "Forms and inputs", to: "/docs/guides/forms"},
        {label: "Fetching data", to: "/docs/guides/fetching-data"},
        {label: "Testing", to: "/docs/guides/testing"},
        {label: "Deploying", to: "/docs/guides/deploying"},
      ],
    ),
    (
      "Reference",
      [
        {label: "Signal API", to: "/docs/api/signal"},
        {label: "View API", to: "/docs/api/view"},
        {label: "Server rendering", to: "/docs/advanced/ssr"},
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

// ---- Main layout wrapper ----
type props = {children: View.node}

let make = (props: props) => {
  let mainClass = () =>
    isDocsPath(Signal.get(Router.location()).pathname) ? "site-main site-main-docs" : "site-main"

  <div>
    <Header />
    <main id="main-content" class={mainClass}> {props.children} </main>
    <Footer />
    <Search.Modal />
  </div>
}
