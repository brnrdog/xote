module Signal = Xote.Signal
module Computed = Xote.Computed
module Component = Xote.Component
module Effect = Xote.Effect

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
    let (bgColor, cursorStyle) = switch Signal.get(state) {
    | Idle => ("bg-blue-500", "cursor-pointer")
    | Waiting => ("bg-red-500", "cursor-not-allowed")
    | Ready => ("bg-green-500", "cursor-pointer")
    | Result(_) => ("bg-stone-800", "cursor-default")
    | TooEarly => ("bg-orange-500", "cursor-default")
    }
    let className = `h-64 md:h-80 rounded-2xl border-4 border-stone-200 dark:border-stone-700 flex items-center justify-center transition-all duration-300 ${bgColor} ${cursorStyle}`

    <div className={className} onClick={handleGameClick}>
      <div className="text-center px-6">
        <p className="text-2xl md:text-4xl font-bold text-white drop-shadow-lg">
          {Component.textSignal(() => {
            switch Signal.get(state) {
            | Idle => "Click to Start"
            | Waiting => "Wait for green..."
            | Ready => "Click Now!"
            | Result(time) => `${Int.toString(time)} ms`
            | TooEarly => "Too early!"
            }
          })}
        </p>
        {Component.signalFragment(
          Computed.make(() => {
            switch Signal.get(state) {
            | Result(_) => [
                <p className="text-sm text-stone-300 mt-2">
                  {Component.text("Your reaction time")}
                </p>,
              ]
            | TooEarly => [
                <p className="text-sm text-white mt-2">
                  {Component.text("Wait for the green screen!")}
                </p>,
              ]
            | _ => []
            }
          }),
        )}
      </div>
    </div>
  }
}

module Instructions = {
  let component = () => {
    <div className="bg-stone-50 dark:bg-stone-700/50 rounded-xl p-4 border border-stone-200 dark:border-stone-600">
      <h3 className="font-semibold text-stone-900 dark:text-white mb-2">
        {Component.text("How to Play")}
      </h3>
      <ul className="text-sm text-stone-600 dark:text-stone-400 space-y-1 list-disc list-inside">
        <li> {Component.text("Click the blue box to start")} </li>
        <li> {Component.text("Wait for the box to turn green (red = wait)")} </li>
        <li> {Component.text("Click as fast as you can when it turns green!")} </li>
        <li> {Component.text("Try to beat your best time")} </li>
      </ul>
    </div>
  }
}

module Statistics = {
  let component = () => {
    <div className="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6">
      <h3 className="text-xl font-bold text-stone-900 dark:text-white mb-4">
        {Component.text("Your Statistics")}
      </h3>
      <div className="grid grid-cols-3 gap-4">
        // Attempts count
        <div className="text-center p-4 bg-stone-50 dark:bg-stone-700/50 rounded-xl">
          <div className="text-2xl font-bold text-stone-900 dark:text-white mb-1">
            {Component.textSignal(() => Signal.get(attemptsCount)->Int.toString)}
          </div>
          <div className="text-xs text-stone-600 dark:text-stone-400">
            {Component.text("Attempts")}
          </div>
        </div>
        // Best time
        <div className="text-center p-4 bg-green-50 dark:bg-green-900/20 rounded-xl">
          <div className="text-2xl font-bold text-green-700 dark:text-green-400 mb-1">
            {Component.textSignal(() => {
              switch Signal.get(bestTime) {
              | Some(time) => `${Int.toString(time)} ms`
              | None => "-"
              }
            })}
          </div>
          <div className="text-xs text-green-600 dark:text-green-500">
            {Component.text("Best")}
          </div>
        </div>
        // Average time
        <div className="text-center p-4 bg-blue-50 dark:bg-blue-900/20 rounded-xl">
          <div className="text-2xl font-bold text-blue-700 dark:text-blue-400 mb-1">
            {Component.textSignal(() => {
              switch Signal.get(averageTime) {
              | Some(time) => `${Int.toString(time)} ms`
              | None => "-"
              }
            })}
          </div>
          <div className="text-xs text-blue-600 dark:text-blue-500">
            {Component.text("Average")}
          </div>
        </div>
      </div>
    </div>
  }
}

module AttemptHistory = {
  let component = () => {
    <div className="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6">
      <div className="flex items-center justify-between mb-4">
        <h3 className="text-xl font-bold text-stone-900 dark:text-white">
          {Component.text("Recent Attempts")}
        </h3>
        {Component.signalFragment(
          Computed.make(() => {
            if Signal.get(attemptsCount) > 0 {
              [
                <button
                  className="text-xs px-3 py-1.5 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 rounded-lg transition-colors"
                  onClick={_evt => Signal.set(attempts, [])}>
                  {Component.text("Clear")}
                </button>,
              ]
            } else {
              []
            }
          }),
        )}
      </div>
      {Component.signalFragment(
        Computed.make(() => {
          let list = Signal.get(attempts)
          if Array.length(list) == 0 {
            [
              <p className="text-sm text-stone-500 dark:text-stone-500 text-center py-8">
                {Component.text("No attempts yet. Click the box to start!")}
              </p>,
            ]
          } else {
            [
              <div className="space-y-2">
                {Component.list(
                  attempts,
                  time => {
                    let best = Signal.get(bestTime)
                    let isBest = switch best {
                    | Some(b) => b == time
                    | None => false
                    }

                    let className =
                      "flex items-center justify-between p-3 bg-stone-50 dark:bg-stone-700/50 rounded-lg mb-2 " ++
                      if isBest { "ring-2 ring-green-500" } else { "" }

                    <div className={className}>
                      <span className="font-mono font-semibold text-stone-900 dark:text-white">
                        {Component.text(`${Int.toString(time)} ms`)}
                      </span>
                      {Component.signalFragment(
                        Computed.make(() => {
                          if isBest {
                            [
                              <span className="text-xs px-2 py-1 bg-green-100 dark:bg-green-900/30 text-green-700 dark:text-green-400 rounded-full font-semibold">
                                {Component.text("Best!")}
                              </span>,
                            ]
                          } else {
                            []
                          }
                        }),
                      )}
                    </div>
                  },
                )}
              </div>,
            ]
          }
        }),
      )}
    </div>
  }
}

module Controls = {
  let component = () => {
    <div className="flex flex-wrap gap-3 justify-center">
      {Component.signalFragment(
        Computed.make(() => {
          switch Signal.get(state) {
          | Result(_) | TooEarly => [
              <button
                className="px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2"
                onClick={startGame}>
                {Component.text("Try Again")}
              </button>,
              <button
                className="px-6 py-3 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-xl font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-stone-500 focus:ring-offset-2"
                onClick={resetGame}>
                {Component.text("Back to Start")}
              </button>,
            ]
          | _ => []
          }
        }),
      )}
    </div>
  }
}

module ReactionGame = {
  let component = () => {
    <div className="max-w-4xl mx-auto p-4 md:p-6 space-y-6">
      // Header
      <div className="mb-6">
        <h1 className="text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-2">
          {Component.text("Reaction Time Game")}
        </h1>
        <p className="text-sm md:text-base text-stone-600 dark:text-stone-400">
          {Component.text("Test your reflexes and beat your best time")}
        </p>
      </div>
      // Instructions
      {Instructions.component()}
      // Game area
      {GameArea.component()}
      // Controls
      {Controls.component()}
      // Statistics
      {Statistics.component()}
      // History
      {AttemptHistory.component()}
    </div>
  }
}
