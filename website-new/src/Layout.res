open Xote

// SVG Icons
module MoonIcon = {
  let make = () => {
    Component.element(
      "svg",
      ~attrs=[
        Component.attr("width", "20"),
        Component.attr("height", "20"),
        Component.attr("viewBox", "0 0 24 24"),
        Component.attr("fill", "none"),
        Component.attr("stroke", "currentColor"),
        Component.attr("stroke-width", "2"),
      ],
      ~children=[
        Component.element(
          "path",
          ~attrs=[Component.attr("d", "M21 12.79A9 9 0 1 1 11.21 3 7 7 0 0 0 21 12.79z")],
          (),
        ),
      ],
      (),
    )
  }
}

module SunIcon = {
  let make = () => {
    Component.element(
      "svg",
      ~attrs=[
        Component.attr("width", "20"),
        Component.attr("height", "20"),
        Component.attr("viewBox", "0 0 24 24"),
        Component.attr("fill", "none"),
        Component.attr("stroke", "currentColor"),
        Component.attr("stroke-width", "2"),
      ],
      ~children=[
        Component.element(
          "circle",
          ~attrs=[Component.attr("cx", "12"), Component.attr("cy", "12"), Component.attr("r", "5")],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "12"),
            Component.attr("y1", "1"),
            Component.attr("x2", "12"),
            Component.attr("y2", "3"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "12"),
            Component.attr("y1", "21"),
            Component.attr("x2", "12"),
            Component.attr("y2", "23"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "4.22"),
            Component.attr("y1", "4.22"),
            Component.attr("x2", "5.64"),
            Component.attr("y2", "5.64"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "18.36"),
            Component.attr("y1", "18.36"),
            Component.attr("x2", "19.78"),
            Component.attr("y2", "19.78"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "1"),
            Component.attr("y1", "12"),
            Component.attr("x2", "3"),
            Component.attr("y2", "12"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "21"),
            Component.attr("y1", "12"),
            Component.attr("x2", "23"),
            Component.attr("y2", "12"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "4.22"),
            Component.attr("y1", "19.78"),
            Component.attr("x2", "5.64"),
            Component.attr("y2", "18.36"),
          ],
          (),
        ),
        Component.element(
          "line",
          ~attrs=[
            Component.attr("x1", "18.36"),
            Component.attr("y1", "5.64"),
            Component.attr("x2", "19.78"),
            Component.attr("y2", "4.22"),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

// Theme management
let theme = Signal.make("light")

let toggleTheme = _evt => {
  Signal.update(theme, current =>
    switch current {
    | "light" => "dark"
    | _ => "light"
    }
  )
}

// let _ = Effect.run(() => {
//   let currentTheme = Signal.get(theme)

//   // %raw(`document.documentElement.setAttribute('data-theme', currentTheme)`)
//   None
// })

// Header component
module Header = {
  type props = {}

  let make = (_props: props) => {
    // Track scroll position
    let isScrolled = Signal.make(false)

    // Set up scroll listener - use ref to store handler so removeEventListener works
    let _ = Effect.run(() => {
      let handlerRef = ref(None)

      let handleScroll = () => {
        let scrollY: float = %raw(`window.scrollY`)
        Signal.set(isScrolled, scrollY > 50.0)
      }

      handlerRef := Some(handleScroll)
      let _ = %raw(`window.addEventListener('scroll', handleScroll)`)

      Some(
        () => {
          switch handlerRef.contents {
          | Some(handler) =>
            let _ = handler // Suppress warning - used in %raw below
            %raw(`window.removeEventListener('scroll', handler)`)
          | None => ()
          }
        },
      )
    })

    // Debug: log when isScrolled changes
    let _ = Effect.run(() => {
      Console.log2("isScrolled changed:", Signal.get(isScrolled))
      None
    })

    {
      Component.element(
        "header",
        ~attrs=[
          Component.computedAttr("class", () => {
            let scrolled = Signal.get(isScrolled)
            let className = scrolled ? "header header-scrolled" : "header"
            Console.log2("Computing class:", className)
            className
          }),
        ],
        ~children=[
          <div class="header-container">
            <div class="header-logo">
              {Router.link(
                ~to="/",
                ~attrs=[Component.attr("class", "logo logo-container")],
                ~children=[<Logo size=18 color="var(--secondary-color)" />],
                (),
              )}
              <a href="https://www.npmjs.com/package/xote" target="_blank" class="version-link">
                <div class="version"> {Component.text("v4.1.0")} </div>
              </a>
            </div>
            <nav class="nav">
              {Router.link(~to="/", ~children=[Component.text("Learn")], ())}
              {Router.link(~to="/docs", ~children=[Component.text("API Reference")], ())}
              {Router.link(~to="/docs", ~children=[Component.text("Releases")], ())}
              {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())}
              <a href="https://github.com/brnrdog/xote" target="_blank" class="icon-link">
                <svg width="20" height="20" viewBox="0 0 16 16" fill="currentColor">
                  <path
                    d="M8 0C3.58 0 0 3.58 0 8c0 3.54 2.29 6.53 5.47 7.59.4.07.55-.17.55-.38 0-.19-.01-.82-.01-1.49-2.01.37-2.53-.49-2.69-.94-.09-.23-.48-.94-.82-1.13-.28-.15-.68-.52-.01-.53.63-.01 1.08.58 1.23.82.72 1.21 1.87.87 2.33.66.07-.52.28-.87.51-1.07-1.78-.2-3.64-.89-3.64-3.95 0-.87.31-1.59.82-2.15-.08-.2-.36-1.02.08-2.12 0 0 .67-.21 2.2.82.64-.18 1.32-.27 2-.27.68 0 1.36.09 2 .27 1.53-1.04 2.2-.82 2.2-.82.44 1.1.16 1.92.08 2.12.51.56.82 1.27.82 2.15 0 3.07-1.87 3.75-3.65 3.95.29.25.54.73.54 1.48 0 1.07-.01 1.93-.01 2.2 0 .21.15.46.55.38A8.013 8.013 0 0016 8c0-4.42-3.58-8-8-8z"
                  />
                </svg>
              </a>
              {Component.element(
                "button",
                ~attrs=[
                  Component.attr("class", "theme-toggle"),
                  Component.attr("title", "Toggle theme"),
                ],
                ~events=[("click", toggleTheme)],
                ~children=[
                  Component.signalFragment(
                    Computed.make(() =>
                      Signal.get(theme) == "light" ? [MoonIcon.make()] : [SunIcon.make()]
                    ),
                  ),
                ],
                (),
              )}
            </nav>
          </div>,
        ],
        (),
      )
    }
  }
}

// Footer component
module Footer = {
  type props = {}

  let make = (_props: props) => {
    <footer class="footer">
      <div class="footer-container">
        <div class="footer-column">
          <h4> {Component.text("Docs")} </h4>
          <ul>
            <li> {Router.link(~to="/docs", ~children=[Component.text("Getting Started")], ())} </li>
            <li>
              {Router.link(
                ~to="/docs/api/signals",
                ~children=[Component.text("API Reference")],
                (),
              )}
            </li>
          </ul>
        </div>
        <div class="footer-column">
          <h4> {Component.text("Resources")} </h4>
          <ul>
            <li> {Router.link(~to="/demos", ~children=[Component.text("Demos")], ())} </li>
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
          </ul>
        </div>
        <div class="footer-column">
          <h4> {Component.text("More")} </h4>
          <ul>
            <li>
              <a href="https://rescript-lang.org/" target="_blank">
                {Component.text("ReScript")}
              </a>
            </li>
            <li>
              <a href="https://github.com/tc39/proposal-signals" target="_blank">
                {Component.text("TC39 Signals Proposal")}
              </a>
            </li>
          </ul>
        </div>
      </div>
      <div class="footer-bottom">
        <div>
          {Component.text("Built with ")}
          <Logo />
          <div class="logo"> {Component.text("xote")} </div>
        </div>
        {Component.text(
          `Copyright © ${Date.now()
            ->Date.fromTime
            ->Date.getFullYear
            ->Int.toString} Bernardo Gurgel.`,
        )}
      </div>
    </footer>
  }
}

// Main layout wrapper
type props = {children: Component.node}

let make = (props: props) => {
  let {children} = props
  <div>
    <Header />
    <main> {children} </main>
    <Footer />
  </div>
}
