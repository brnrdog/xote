open Xote

// Counter state
let count = Signal.make(0)

// Event handlers
let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
let decrement = (_evt: Dom.event) => Signal.update(count, n => n - 1)
let reset = (_evt: Dom.event) => Signal.set(count, 0)

module CounterApp = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-2xl mx-auto p-4 md:p-6 space-y-4")],
      ~children=[
        // Header
        Component.div(
          ~attrs=[Component.attr("class", "mb-6 md:mb-8")],
          ~children=[
            Component.h1(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-2",
                ),
              ],
              ~children=[Component.text("Counter Demo")],
              (),
            ),
            Component.p(
              ~attrs=[
                Component.attr("class", "text-sm md:text-base text-stone-600 dark:text-stone-400"),
              ],
              ~children=[Component.text("A simple reactive counter built with Xote")],
              (),
            ),
          ],
          (),
        ),
        // Counter display
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-8 md:p-12 text-center",
            ),
          ],
          ~children=[
            Component.div(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-5xl md:text-6xl font-bold text-stone-900 dark:text-white mb-2",
                ),
              ],
              ~children=[Component.textSignal(() => Signal.get(count)->Int.toString)],
              (),
            ),
            Component.div(
              ~attrs=[
                Component.attr("class", "text-xs md:text-sm text-stone-500 dark:text-stone-400"),
              ],
              ~children=[Component.text("Current Count")],
              (),
            ),
          ],
          (),
        ),
        // Button controls
        Component.div(
          ~attrs=[Component.attr("class", "flex flex-col sm:flex-row gap-3 justify-center")],
          ~children=[
            Component.button(
              ~attrs=[
                Component.attr(
                  "class",
                  "px-6 py-3 md:px-8 bg-stone-900 hover:bg-stone-700 text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2 dark:bg-stone-700 dark:hover:bg-stone-600",
                ),
              ],
              ~events=[("click", decrement)],
              ~children=[Component.text("− Decrement")],
              (),
            ),
            Component.button(
              ~attrs=[
                Component.attr(
                  "class",
                  "px-6 py-3 md:px-8 bg-stone-200 hover:bg-stone-300 text-stone-900 rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-300 focus:ring-offset-2 dark:bg-stone-800 dark:hover:bg-stone-700 dark:text-white",
                ),
              ],
              ~events=[("click", reset)],
              ~children=[Component.text("Reset")],
              (),
            ),
            Component.button(
              ~attrs=[
                Component.attr(
                  "class",
                  "px-6 py-3 md:px-8 bg-stone-900 hover:bg-stone-700 text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2 dark:bg-stone-700 dark:hover:bg-stone-600",
                ),
              ],
              ~events=[("click", increment)],
              ~children=[Component.text("+ Increment")],
              (),
            ),
          ],
          (),
        ),
        // Footer
        Component.div(
          ~attrs=[Component.attr("class", "text-xs text-stone-600 dark:text-stone-400 pt-4")],
          ~children=[
            Component.text("Powered by "),
            Component.a(
              ~attrs=[
                Component.attr("href", "https://github.com/brnrdog/xote"),
                Component.attr("target", "_blank"),
                Component.attr("class", "font-semibold dark:text-white underline"),
              ],
              ~children=[Component.text("Xote")],
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
