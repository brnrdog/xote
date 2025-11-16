open Xote

// Dark mode state shared across demos
let darkMode = Signal.make(false)

let toggleTheme = (_evt: Dom.event) => {
  Signal.update(darkMode, mode => !mode)
}

// Initialize router
Router.init()

module DemoHeader = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "bg-white dark:bg-stone-800 border-b-2 border-stone-200 dark:border-stone-700 mb-4 md:mb-6",
        ),
      ],
      ~children=[
        Component.div(
          ~attrs=[
            Component.attr("class", "text-center max-w-6xl mx-auto px-4 md:px-6 py-3 md:py-4"),
          ],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "flex items-center gap-4 mb-3 md:mb-4")],
              ~children=[
                Component.h1(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-base md:text-xl font-bold text-stone-900 dark:text-white",
                    ),
                  ],
                  ~children=[Component.text("Xote: Example Applications")],
                  (),
                ),
              ],
              (),
            ),
            // Navigation menu - wraps on mobile
            Component.div(
              ~attrs=[Component.attr("class", "flex flex-wrap gap-2")],
              ~children=[
                Router.link(
                  ~to="/",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let currentPath = Signal.get(Router.location).pathname
                      let baseClass = "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/"
                        ? baseClass ++ " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++ " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("🏠 Home")],
                  (),
                ),
                Router.link(
                  ~to="/counter",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let currentPath = Signal.get(Router.location).pathname
                      let baseClass = "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/counter"
                        ? baseClass ++ " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++ " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("🔢 Counter")],
                  (),
                ),
                Router.link(
                  ~to="/todo",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let currentPath = Signal.get(Router.location).pathname
                      let baseClass = "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/todo"
                        ? baseClass ++ " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++ " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("✓ Todo List")],
                  (),
                ),
                Router.link(
                  ~to="/color",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let currentPath = Signal.get(Router.location).pathname
                      let baseClass = "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/color"
                        ? baseClass ++ " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++ " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("🎨 Color Mixer")],
                  (),
                ),
                Router.link(
                  ~to="/reaction",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let currentPath = Signal.get(Router.location).pathname
                      let baseClass = "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/reaction"
                        ? baseClass ++ " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++ " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("⚡ Reaction Game")],
                  (),
                ),
                Router.link(
                  ~to="/solitaire",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let currentPath = Signal.get(Router.location).pathname
                      let baseClass = "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/solitaire"
                        ? baseClass ++ " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++ " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("🃏 Solitaire")],
                  (),
                ),
                Component.button(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2",
                    ),
                  ],
                  ~events=[("click", toggleTheme)],
                  ~children=[Component.textSignal(() => Signal.get(darkMode) ? "☀️" : "🌙")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module Footer = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "mt-auto border-t border-stone-200 dark:border-stone-700 bg-white dark:bg-stone-800",
        ),
      ],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "max-w-6xl mx-auto px-4 md:px-6 py-4")],
          ~children=[
            Component.p(
              ~attrs=[
                Component.attr("class", "text-xs text-center text-stone-700 dark:text-stone-400"),
              ],
              ~children=[
                Component.text("Built with "),
                Component.a(
                  ~attrs=[
                    Component.attr("href", "https://github.com/brnrdog/xote"),
                    Component.attr("target", "_blank"),
                    Component.attr("class", "font-semibold text-stone-900 dark:text-white"),
                  ],
                  ~children=[Component.text("Xote")],
                  (),
                ),
                Component.text(" and "),
                Component.a(
                  ~attrs=[
                    Component.attr("href", "https://rescript-lang.org/"),
                    Component.attr("target", "_blank"),
                    Component.attr("class", "font-semibold text-stone-900 dark:text-white"),
                  ],
                  ~children=[Component.text("ReScript")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module HomePage = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-2xl mx-auto p-4 md:p-6")],
      ~children=[
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-8",
            ),
          ],
          ~children=[
            Component.h2(
              ~attrs=[
                Component.attr("class", "text-2xl font-bold text-stone-900 dark:text-white mb-4"),
              ],
              ~children=[Component.text("Welcome Example Applications")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400 mb-6")],
              ~children=[
                Component.text(
                  "Explore interactive examples showcasing Xote's reactive primitives and component system. Each demo demonstrates different features:",
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "space-y-4")],
              ~children=[
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl border border-stone-200 dark:border-stone-600",
                    ),
                  ],
                  ~children=[
                    Component.h3(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "font-semibold text-stone-900 dark:text-white mb-2",
                        ),
                      ],
                      ~children=[Component.text("🔢 Counter Demo")],
                      (),
                    ),
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-stone-600 dark:text-stone-400"),
                      ],
                      ~children=[
                        Component.text(
                          "A simple counter demonstrating reactive signals and event handlers.",
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl border border-stone-200 dark:border-stone-600",
                    ),
                  ],
                  ~children=[
                    Component.h3(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "font-semibold text-stone-900 dark:text-white mb-2",
                        ),
                      ],
                      ~children=[Component.text("✓ Todo List")],
                      (),
                    ),
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-stone-600 dark:text-stone-400"),
                      ],
                      ~children=[
                        Component.text(
                          "A full-featured todo app with computed values, filters, and reactive lists.",
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl border border-stone-200 dark:border-stone-600",
                    ),
                  ],
                  ~children=[
                    Component.h3(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "font-semibold text-stone-900 dark:text-white mb-2",
                        ),
                      ],
                      ~children=[Component.text("🎨 Color Mixer")],
                      (),
                    ),
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-stone-600 dark:text-stone-400"),
                      ],
                      ~children=[
                        Component.text(
                          "Mix colors with RGB sliders, explore variations, and save palettes.",
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl border border-stone-200 dark:border-stone-600",
                    ),
                  ],
                  ~children=[
                    Component.h3(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "font-semibold text-stone-900 dark:text-white mb-2",
                        ),
                      ],
                      ~children=[Component.text("⚡ Reaction Game")],
                      (),
                    ),
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-stone-600 dark:text-stone-400"),
                      ],
                      ~children=[
                        Component.text(
                          "Test your reflexes with a fun reaction time game. Features statistics and attempt history.",
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl border border-stone-200 dark:border-stone-600",
                    ),
                  ],
                  ~children=[
                    Component.h3(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "font-semibold text-stone-900 dark:text-white mb-2",
                        ),
                      ],
                      ~children=[Component.text("🃏 Solitaire")],
                      (),
                    ),
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-stone-600 dark:text-stone-400"),
                      ],
                      ~children=[
                        Component.text(
                          "Classic Klondike Solitaire with click-to-move gameplay and win detection.",
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module Demos = {
  let component = () => {
    // Effect to sync dark mode with HTML class
    let _ = Effect.run(() =>
      switch Signal.get(darkMode) {
      | true => %raw(`document.documentElement.classList.add('dark')`)
      | false => %raw(`document.documentElement.classList.remove('dark')`)
      }
    )

    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "min-h-screen bg-stone-50 dark:bg-stone-900 transition-colors flex flex-col",
        ),
      ],
      ~children=[
        DemoHeader.component(),
        // Routes - flex-1 to take remaining space
        Component.div(
          ~attrs=[Component.attr("class", "flex-1")],
          ~children=[
            Router.routes([
              {pattern: "/", render: _params => HomePage.component()},
              {pattern: "/counter", render: _params => CounterApp.counterApp()},
              {pattern: "/todo", render: _params => TodoApp.todoApp()},
              {pattern: "/color", render: _params => ColorMixerApp.ColorMixerApp.component()},
              {pattern: "/reaction", render: _params => ReactionGame.ReactionGame.component()},
              {pattern: "/solitaire", render: _params => SolitaireGame.app()},
            ]),
          ],
          (),
        ),
        // Footer always at bottom
        Footer.component(),
      ],
      (),
    )
  }
}

// Mount the app
Component.mountById(Demos.component(), "app")
