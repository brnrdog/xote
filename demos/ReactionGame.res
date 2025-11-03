open Xote

// External bindings for setTimeout/clearTimeout
@val external setTimeout: (unit => unit, float) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"
@val external dateNow: unit => float = "Date.now"

// Game states
type gameState = Idle | Waiting | Ready | Result(int) | TooEarly

let state = Signal.make(Idle)
let attempts = Signal.make([])
let startTime = ref(0.0)
let timeoutId: ref<Nullable.t<int>> = ref(Nullable.null)

// Clear any pending timeout
let clearGameTimeout = () => {
  switch Nullable.toOption(timeoutId.contents) {
  | Some(id) => clearTimeout(id)
  | None => ()
  }
  timeoutId := Nullable.null
}

// Start the game
let startGame = (_evt: Dom.event) => {
  clearGameTimeout()
  Signal.set(state, Waiting)

  // Random delay between 2-5 seconds
  let delay = 2000.0 +. Math.random() *. 3000.0

  // Create a callback that sets the Ready state
  let readyCallback = () => {
    startTime := dateNow()
    Signal.set(state, Ready)
  }

  // Set up the timer
  let id = setTimeout(readyCallback, delay)
  timeoutId := Nullable.make(id)
}

// Handle click during game
let handleGameClick = (_evt: Dom.event) => {
  switch Signal.get(state) {
  | Idle => startGame(_evt)
  | Waiting => {
      clearGameTimeout()
      Signal.set(state, TooEarly)
    }
  | Ready => {
      let now = dateNow()
      let reactionTime = Int.fromFloat(now -. startTime.contents)
      Signal.update(attempts, list => {
        let newList = Array.concat([reactionTime], list)
        Array.slice(newList, ~start=0, ~end=10) // Keep last 10 attempts
      })
      Signal.set(state, Result(reactionTime))
    }
  | Result(_) => ()
  | TooEarly => ()
  }
}

// Reset game
let resetGame = (_evt: Dom.event) => {
  clearGameTimeout()
  Signal.set(state, Idle)
}

// Computed statistics
let bestTime = Computed.make(() => {
  let list = Signal.get(attempts)
  if Array.length(list) == 0 {
    None
  } else {
    Array.reduce(list, None, (best, current) => {
      switch best {
      | None => Some(current)
      | Some(b) => Some(Math.Int.min(b, current))
      }
    })
  }
})

let averageTime = Computed.make(() => {
  let list = Signal.get(attempts)
  if Array.length(list) == 0 {
    None
  } else {
    let sum = Array.reduce(list, 0, (acc, time) => acc + time)
    Some(sum / Array.length(list))
  }
})

let attemptsCount = Computed.make(() => {
  Signal.get(attempts)->Array.length
})

module GameArea = {
  let component = () => {
    let (bgColor, textContent, cursorStyle) = switch Signal.get(state) {
    | Idle => ("bg-blue-500", "Click to Start", "cursor-pointer")
    | Waiting => ("bg-red-500", "Wait for green...", "cursor-not-allowed")
    | Ready => ("bg-green-500", "Click Now!", "cursor-pointer")
    | Result(time) => (
        "bg-stone-800",
        `${Int.toString(time)} ms`,
        "cursor-default"
      )
    | TooEarly => ("bg-orange-500", "Too early! Wait for green.", "cursor-default")
    }

    Component.div(
      ~attrs=[
        Component.computedAttr("class", () => {
          let (bgColor, _, cursorStyle) = switch Signal.get(state) {
          | Idle => ("bg-blue-500", "", "cursor-pointer")
          | Waiting => ("bg-red-500", "", "cursor-not-allowed")
          | Ready => ("bg-green-500", "", "cursor-pointer")
          | Result(_) => ("bg-stone-800", "", "cursor-default")
          | TooEarly => ("bg-orange-500", "", "cursor-default")
          }
          `h-64 md:h-80 rounded-2xl border-4 border-stone-200 dark:border-stone-700 flex items-center justify-center transition-all duration-300 ${bgColor} ${cursorStyle}`
        }),
      ],
      ~events=[("click", handleGameClick)],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "text-center px-6")],
          ~children=[
            Component.p(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-2xl md:text-4xl font-bold text-white drop-shadow-lg",
                ),
              ],
              ~children=[
                Component.textSignal(() => {
                  switch Signal.get(state) {
                  | Idle => "Click to Start"
                  | Waiting => "Wait for green..."
                  | Ready => "Click Now!"
                  | Result(time) => `${Int.toString(time)} ms`
                  | TooEarly => "Too early!"
                  }
                }),
              ],
              (),
            ),
            Component.signalFragment(
              Computed.make(() => {
                switch Signal.get(state) {
                | Result(_) => [
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-stone-300 mt-2"),
                      ],
                      ~children=[Component.text("Your reaction time")],
                      (),
                    ),
                  ]
                | TooEarly => [
                    Component.p(
                      ~attrs=[
                        Component.attr("class", "text-sm text-white mt-2"),
                      ],
                      ~children=[Component.text("Wait for the green screen!")],
                      (),
                    ),
                  ]
                | _ => []
                }
              }),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module Instructions = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "bg-stone-50 dark:bg-stone-700/50 rounded-xl p-4 border border-stone-200 dark:border-stone-600",
        ),
      ],
      ~children=[
        Component.h3(
          ~attrs=[
            Component.attr("class", "font-semibold text-stone-900 dark:text-white mb-2"),
          ],
          ~children=[Component.text("How to Play")],
          (),
        ),
        Component.ul(
          ~attrs=[
            Component.attr("class", "text-sm text-stone-600 dark:text-stone-400 space-y-1 list-disc list-inside"),
          ],
          ~children=[
            Component.li(~children=[Component.text("Click the blue box to start")], ()),
            Component.li(~children=[Component.text("Wait for the box to turn green (red = wait)")], ()),
            Component.li(~children=[Component.text("Click as fast as you can when it turns green!")], ()),
            Component.li(~children=[Component.text("Try to beat your best time")], ()),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module Statistics = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6",
        ),
      ],
      ~children=[
        Component.h3(
          ~attrs=[
            Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-4"),
          ],
          ~children=[Component.text("Your Statistics")],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "grid grid-cols-3 gap-4")],
          ~children=[
            // Attempts count
            Component.div(
              ~attrs=[
                Component.attr("class", "text-center p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl"),
              ],
              ~children=[
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-2xl font-bold text-stone-900 dark:text-white mb-1",
                    ),
                  ],
                  ~children=[
                    Component.textSignal(() => Signal.get(attemptsCount)->Int.toString),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr("class", "text-xs text-stone-600 dark:text-stone-400"),
                  ],
                  ~children=[Component.text("Attempts")],
                  (),
                ),
              ],
              (),
            ),
            // Best time
            Component.div(
              ~attrs=[
                Component.attr("class", "text-center p-4 bg-green-50 dark:bg-green-900/20 rounded-xl"),
              ],
              ~children=[
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-2xl font-bold text-green-700 dark:text-green-400 mb-1",
                    ),
                  ],
                  ~children=[
                    Component.textSignal(() => {
                      switch Signal.get(bestTime) {
                      | Some(time) => `${Int.toString(time)} ms`
                      | None => "-"
                      }
                    }),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr("class", "text-xs text-green-600 dark:text-green-500"),
                  ],
                  ~children=[Component.text("Best")],
                  (),
                ),
              ],
              (),
            ),
            // Average time
            Component.div(
              ~attrs=[
                Component.attr("class", "text-center p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl"),
              ],
              ~children=[
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-2xl font-bold text-blue-700 dark:text-blue-400 mb-1",
                    ),
                  ],
                  ~children=[
                    Component.textSignal(() => {
                      switch Signal.get(averageTime) {
                      | Some(time) => `${Int.toString(time)} ms`
                      | None => "-"
                      }
                    }),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[
                    Component.attr("class", "text-xs text-blue-600 dark:text-blue-500"),
                  ],
                  ~children=[Component.text("Average")],
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

module AttemptHistory = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6",
        ),
      ],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "flex items-center justify-between mb-4")],
          ~children=[
            Component.h3(
              ~attrs=[
                Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white"),
              ],
              ~children=[Component.text("Recent Attempts")],
              (),
            ),
            Component.signalFragment(
              Computed.make(() => {
                if Signal.get(attemptsCount) > 0 {
                  [
                    Component.button(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "text-xs px-3 py-1.5 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 rounded-lg transition-colors",
                        ),
                      ],
                      ~events=[
                        (
                          "click",
                          _evt => Signal.set(attempts, []),
                        ),
                      ],
                      ~children=[Component.text("Clear")],
                      (),
                    ),
                  ]
                } else {
                  []
                }
              }),
            ),
          ],
          (),
        ),
        Component.signalFragment(
          Computed.make(() => {
            let list = Signal.get(attempts)
            if Array.length(list) == 0 {
              [
                Component.p(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-sm text-stone-500 dark:text-stone-500 text-center py-8",
                    ),
                  ],
                  ~children=[Component.text("No attempts yet. Click the box to start!")],
                  (),
                ),
              ]
            } else {
              [
                Component.div(
                  ~attrs=[Component.attr("class", "space-y-2")],
                  ~children=[
                    Component.list(
                      attempts,
                      time => {
                        let best = Signal.get(bestTime)
                        let isBest = switch best {
                        | Some(b) => b == time
                        | None => false
                        }

                        Component.div(
                          ~attrs=[
                            Component.attr(
                              "class",
                              "flex items-center justify-between p-3 bg-stone-50 dark:bg-stone-700/50 rounded-lg mb-2 " ++ (
                                isBest ? "ring-2 ring-green-500" : ""
                              ),
                            ),
                          ],
                          ~children=[
                            Component.span(
                              ~attrs=[
                                Component.attr(
                                  "class",
                                  "font-mono font-semibold text-stone-900 dark:text-white",
                                ),
                              ],
                              ~children=[Component.text(`${Int.toString(time)} ms`)],
                              (),
                            ),
                            Component.signalFragment(
                              Computed.make(() => {
                                if isBest {
                                  [
                                    Component.span(
                                      ~attrs=[
                                        Component.attr(
                                          "class",
                                          "text-xs px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-full font-semibold",
                                        ),
                                      ],
                                      ~children=[Component.text("Best!")],
                                      (),
                                    ),
                                  ]
                                } else {
                                  []
                                }
                              }),
                            ),
                          ],
                          (),
                        )
                      },
                    ),
                  ],
                  (),
                ),
              ]
            }
          }),
        ),
      ],
      (),
    )
  }
}

module Controls = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "flex flex-wrap gap-3 justify-center")],
      ~children=[
        Component.signalFragment(
          Computed.make(() => {
            switch Signal.get(state) {
            | Result(_) | TooEarly => [
                Component.button(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2",
                    ),
                  ],
                  ~events=[("click", startGame)],
                  ~children=[Component.text("Try Again")],
                  (),
                ),
                Component.button(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "px-6 py-3 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2",
                    ),
                  ],
                  ~events=[("click", resetGame)],
                  ~children=[Component.text("Back to Start")],
                  (),
                ),
              ]
            | _ => []
            }
          }),
        ),
      ],
      (),
    )
  }
}

module ReactionGame = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-4xl mx-auto p-4 md:p-6 space-y-6")],
      ~children=[
        // Header
        Component.div(
          ~attrs=[Component.attr("class", "mb-6")],
          ~children=[
            Component.h1(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-2",
                ),
              ],
              ~children=[Component.text("Reaction Time Game")],
              (),
            ),
            Component.p(
              ~attrs=[
                Component.attr("class", "text-sm md:text-base text-stone-600 dark:text-stone-400"),
              ],
              ~children=[Component.text("Test your reflexes and beat your best time")],
              (),
            ),
          ],
          (),
        ),
        // Instructions
        Instructions.component(),
        // Game area
        GameArea.component(),
        // Controls
        Controls.component(),
        // Statistics
        Statistics.component(),
        // History
        AttemptHistory.component(),
      ],
      (),
    )
  }
}
