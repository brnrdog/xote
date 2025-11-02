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
          ~attrs=[Component.attr("class", "max-w-6xl mx-auto px-4 md:px-6 py-3 md:py-4")],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "flex items-center justify-between mb-3 md:mb-4")],
              ~children=[
                Component.h1(
                  ~attrs=[
                    Component.attr("class", "text-xl md:text-2xl font-bold text-stone-900 dark:text-white"),
                  ],
                  ~children=[Component.text("Xote Demos")],
                  (),
                ),
                Component.button(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "px-3 py-1.5 md:px-4 md:py-2 rounded-lg md:rounded-xl text-sm bg-stone-200 dark:bg-stone-700 text-stone-800 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-600 transition-colors",
                    ),
                  ],
                  ~events=[("click", toggleTheme)],
                  ~children=[
                    Component.textSignal(() => Signal.get(darkMode) ? "☀️" : "🌙"),
                  ],
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
                      let baseClass =
                        "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/"
                        ? baseClass ++
                          " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++
                          " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
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
                      let baseClass =
                        "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/counter"
                        ? baseClass ++
                          " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++
                          " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
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
                      let baseClass =
                        "px-3 py-1.5 md:px-5 md:py-2 rounded-full text-xs md:text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                      currentPath == "/todo"
                        ? baseClass ++
                          " bg-stone-900 text-white dark:bg-stone-700"
                        : baseClass ++
                          " bg-stone-200 text-stone-800 dark:bg-stone-700/50 dark:text-stone-200 hover:bg-stone-300 dark:hover:bg-stone-700"
                    }),
                  ],
                  ~children=[Component.text("✓ Todo List")],
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
              ~children=[Component.text("Welcome to Xote Demos")],
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
                      ~attrs=[Component.attr("class", "text-sm text-stone-600 dark:text-stone-400")],
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
                      ~attrs=[Component.attr("class", "text-sm text-stone-600 dark:text-stone-400")],
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
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "mt-6 pt-6 border-t border-stone-200 dark:border-stone-700")],
              ~children=[
                Component.p(
                  ~attrs=[Component.attr("class", "text-xs text-stone-600 dark:text-stone-400")],
                  ~children=[
                    Component.text("Built with "),
                    Component.a(
                      ~attrs=[
                        Component.attr("href", "https://github.com/brnrdog/xote"),
                        Component.attr("target", "_blank"),
                        Component.attr("class", "font-semibold dark:text-white underline"),
                      ],
                      ~children=[Component.text("Xote")],
                      (),
                    ),
                    Component.text(" - A lightweight, zero-dependency reactive UI library for ReScript"),
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
      ~attrs=[Component.attr("class", "min-h-screen bg-stone-50 dark:bg-stone-900 transition-colors")],
      ~children=[
        DemoHeader.component(),
        // Routes
        Router.routes([
          {pattern: "/", render: _params => HomePage.component()},
          {pattern: "/counter", render: _params => CounterApp.CounterApp.component()},
          {pattern: "/todo", render: _params => TodoApp.TodoApp.component()},
        ]),
      ],
      (),
    )
  }
}

// Mount the app
Component.mountById(Demos.component(), "app")
