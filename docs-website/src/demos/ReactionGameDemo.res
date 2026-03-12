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
    <div
      class={() => {
        let stateClass = switch Signal.get(state) {
        | Idle => "idle"
        | Waiting => "waiting"
        | Ready => "ready"
        | Result(_) => "result"
        | TooEarly => "too-early"
        }
        `reaction-demo-area ${stateClass}`
      }}
      onClick={handleGameClick}
    >
      <div style="text-align: center; padding: 1.5rem;">
        <p style="font-size: 1.5rem; font-weight: bold; color: white;">
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
        {
          let gameAreaSignal = Computed.make(() => {
            switch Signal.get(state) {
            | Result(_) => [
                <p style="font-size: 0.875rem; color: rgba(255,255,255,0.7); margin-top: 0.5rem;">
                  {Component.text("Your reaction time")}
                </p>,
              ]
            | TooEarly => [
                <p style="font-size: 0.875rem; color: white; margin-top: 0.5rem;">
                  {Component.text("Wait for the green screen!")}
                </p>,
              ]
            | _ => []
            }
          })
          Component.signalFragment(gameAreaSignal)
        }
      </div>
    </div>
  }
}

module Instructions = {
  let component = () => {
    <div class="demo-info-box">
      <h3> {Component.text("How to Play")} </h3>
      <ul>
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
    <div class="demo-section">
      <h3> {Component.text("Your Statistics")} </h3>
      <div class="demo-grid-3">
        // Attempts count
        <div class="demo-stat">
          <div class="demo-stat-value">
            {Component.textSignal(() => Signal.get(attemptsCount)->Int.toString)}
          </div>
          <div class="demo-stat-label"> {Component.text("Attempts")} </div>
        </div>
        // Best time
        <div class="demo-stat">
          <div class="demo-stat-value">
            {Component.textSignal(() => {
              switch Signal.get(bestTime) {
              | Some(time) => `${Int.toString(time)} ms`
              | None => "-"
              }
            })}
          </div>
          <div class="demo-stat-label"> {Component.text("Best")} </div>
        </div>
        // Average time
        <div class="demo-stat">
          <div class="demo-stat-value">
            {Component.textSignal(() => {
              switch Signal.get(averageTime) {
              | Some(time) => `${Int.toString(time)} ms`
              | None => "-"
              }
            })}
          </div>
          <div class="demo-stat-label"> {Component.text("Average")} </div>
        </div>
      </div>
    </div>
  }
}

module AttemptHistory = {
  let component = () => {
    <div class="demo-section">
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem;">
        <h3> {Component.text("Recent Attempts")} </h3>
        {
          let clearButtonSignal = Computed.make(() => {
            if Signal.get(attemptsCount) > 0 {
              [
                <button
                  class="demo-btn demo-btn-secondary"
                  onClick={_evt => Signal.set(attempts, [])}
                >
                  {Component.text("Clear")}
                </button>,
              ]
            } else {
              []
            }
          })
          Component.signalFragment(clearButtonSignal)
        }
      </div>
      {
        let attemptsListSignal = Computed.make(() => {
          let list = Signal.get(attempts)
          if Array.length(list) == 0 {
            [
              <p style="text-align: center; padding: 2rem 0; opacity: 0.6;">
                {Component.text("No attempts yet. Click the box to start!")}
              </p>,
            ]
          } else {
            [
              <div>
                {Component.list(attempts, time => {
                  let best = Signal.get(bestTime)
                  let isBest = switch best {
                  | Some(b) => b == time
                  | None => false
                  }

                  let className = if isBest {
                    "color-demo-value-row best"
                  } else {
                    "color-demo-value-row"
                  }

                  <div class={className}>
                    <span style="font-family: monospace; font-weight: 600;">
                      {Component.text(`${Int.toString(time)} ms`)}
                    </span>
                    {
                      let bestBadgeSignal = Computed.make(
                        () => {
                          if isBest {
                            [
                              <span class="demo-badge">
                                {Component.text("Best!")}
                              </span>,
                            ]
                          } else {
                            []
                          }
                        },
                      )
                      Component.signalFragment(bestBadgeSignal)
                    }
                  </div>
                })}
              </div>,
            ]
          }
        })
        Component.signalFragment(attemptsListSignal)
      }
    </div>
  }
}

module Controls = {
  let component = () => {
    <div class="demo-btn-group">
      {
        let controlsSignal = Computed.make(() => {
          switch Signal.get(state) {
          | Result(_) | TooEarly => [
              <button class="demo-btn demo-btn-primary" onClick={startGame}>
                {Component.text("Try Again")}
              </button>,
              <button class="demo-btn demo-btn-secondary" onClick={resetGame}>
                {Component.text("Back to Start")}
              </button>,
            ]
          | _ => []
          }
        })
        Component.signalFragment(controlsSignal)
      }
    </div>
  }
}

let content = () => {
  <div class="demo-container">
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
