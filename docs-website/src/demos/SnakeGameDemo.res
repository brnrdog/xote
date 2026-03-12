open Xote

// External bindings
@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

// Types
type direction = Up | Down | Left | Right
type position = {x: int, y: int}
type gameStatus = Playing | Paused | GameOver | LevelComplete

type level = {
  number: int,
  speed: int, // milliseconds between moves
  gridSize: int,
  obstacles: array<position>,
  foodCount: int, // food needed to complete level
}

// Game constants
let levels = [
  {number: 1, speed: 200, gridSize: 15, obstacles: [], foodCount: 5},
  {number: 2, speed: 180, gridSize: 15, obstacles: [], foodCount: 7},
  {number: 3, speed: 160, gridSize: 17, obstacles: [{x: 8, y: 8}], foodCount: 8},
  {
    number: 4,
    speed: 140,
    gridSize: 17,
    obstacles: [{x: 8, y: 6}, {x: 8, y: 10}],
    foodCount: 10,
  },
  {
    number: 5,
    speed: 120,
    gridSize: 19,
    obstacles: [{x: 9, y: 5}, {x: 9, y: 9}, {x: 9, y: 13}],
    foodCount: 12,
  },
  {
    number: 6,
    speed: 110,
    gridSize: 19,
    obstacles: [{x: 5, y: 9}, {x: 9, y: 9}, {x: 13, y: 9}],
    foodCount: 14,
  },
  {
    number: 7,
    speed: 100,
    gridSize: 21,
    obstacles: [{x: 7, y: 7}, {x: 7, y: 13}, {x: 13, y: 7}, {x: 13, y: 13}],
    foodCount: 16,
  },
  {
    number: 8,
    speed: 90,
    gridSize: 21,
    obstacles: [{x: 10, y: 5}, {x: 10, y: 10}, {x: 10, y: 15}, {x: 5, y: 10}, {x: 15, y: 10}],
    foodCount: 18,
  },
  {
    number: 9,
    speed: 80,
    gridSize: 23,
    obstacles: [{x: 6, y: 6}, {x: 6, y: 16}, {x: 16, y: 6}, {x: 16, y: 16}, {x: 11, y: 11}],
    foodCount: 20,
  },
  {
    number: 10,
    speed: 70,
    gridSize: 23,
    obstacles: [
      {x: 5, y: 5},
      {x: 5, y: 11},
      {x: 5, y: 17},
      {x: 11, y: 5},
      {x: 11, y: 17},
      {x: 17, y: 5},
      {x: 17, y: 11},
      {x: 17, y: 17},
    ],
    foodCount: 25,
  },
]

// Game state signals
let currentLevelNum = Signal.make(1)
let snake = Signal.make([{x: 7, y: 7}, {x: 6, y: 7}, {x: 5, y: 7}])
let direction = Signal.make(Right)
let nextDirection = Signal.make(Right)
let food = Signal.make({x: 10, y: 10})
let gameStatus = Signal.make(Paused)
let score = Signal.make(0)
let foodEaten = Signal.make(0)
let gameLoopId: ref<Nullable.t<int>> = ref(Nullable.null)

// Computed values
let currentLevel = Computed.make(() => {
  let levelNum = Signal.get(currentLevelNum)
  levels[levelNum - 1]->Option.getOr(levels[0]->Option.getUnsafe)
})

let highScore = Signal.make(0)

// Helper functions
let positionsEqual = (p1: position, p2: position): bool => {
  p1.x == p2.x && p1.y == p2.y
}

let isPositionInArray = (pos: position, arr: array<position>): bool => {
  arr->Array.some(p => positionsEqual(p, pos))
}

let getRandomPosition = (
  gridSize: int,
  obstacles: array<position>,
  snakeBody: array<position>,
): position => {
  let rec findPosition = () => {
    let x = Int.fromFloat(Math.random() *. Int.toFloat(gridSize))
    let y = Int.fromFloat(Math.random() *. Int.toFloat(gridSize))
    let pos = {x, y}

    if isPositionInArray(pos, obstacles) || isPositionInArray(pos, snakeBody) {
      findPosition()
    } else {
      pos
    }
  }
  findPosition()
}

let getNextPosition = (head: position, dir: direction): position => {
  switch dir {
  | Up => {x: head.x, y: head.y - 1}
  | Down => {x: head.x, y: head.y + 1}
  | Left => {x: head.x - 1, y: head.y}
  | Right => {x: head.x + 1, y: head.y}
  }
}

let isValidMove = (from: direction, to: direction): bool => {
  switch (from, to) {
  | (Up, Down) | (Down, Up) | (Left, Right) | (Right, Left) => false
  | _ => true
  }
}

let isOutOfBounds = (pos: position, gridSize: int): bool => {
  pos.x < 0 || pos.x >= gridSize || pos.y < 0 || pos.y >= gridSize
}

// Game loop
let stopGameLoop = () => {
  switch Nullable.toOption(gameLoopId.contents) {
  | Some(id) => clearTimeout(id)
  | None => ()
  }
  gameLoopId := Nullable.null
}

let rec startGameLoop = () => {
  if Signal.get(gameStatus) == Playing {
    let level = Signal.get(currentLevel)
    let currentDir = Signal.get(direction)
    let next = Signal.get(nextDirection)

    // Update direction if valid
    if isValidMove(currentDir, next) {
      Signal.set(direction, next)
    }

    let currentSnake = Signal.get(snake)
    let head = currentSnake[0]->Option.getUnsafe
    let newHead = getNextPosition(head, Signal.get(direction))

    // Check collisions
    if (
      isOutOfBounds(newHead, level.gridSize) ||
      isPositionInArray(newHead, currentSnake) ||
      isPositionInArray(newHead, level.obstacles)
    ) {
      Signal.set(gameStatus, GameOver)
      stopGameLoop()
    } else {
      let currentFood = Signal.get(food)
      let ateFood = positionsEqual(newHead, currentFood)

      // Update snake
      let newSnake = if ateFood {
        // Grow snake
        Array.concat([newHead], currentSnake)
      } else {
        // Move snake
        let withoutTail = Array.slice(currentSnake, ~start=0, ~end=Array.length(currentSnake) - 1)
        Array.concat([newHead], withoutTail)
      }

      Signal.set(snake, newSnake)

      if ateFood {
        Signal.update(score, s => s + level.number * 10)
        Signal.update(foodEaten, f => f + 1)

        // Check if level complete
        if Signal.get(foodEaten) >= level.foodCount {
          Signal.set(gameStatus, LevelComplete)
          stopGameLoop()
        } else {
          // Spawn new food
          Signal.set(food, getRandomPosition(level.gridSize, level.obstacles, newSnake))
        }
      }

      // Continue game loop
      let id = setTimeout(startGameLoop, level.speed)
      gameLoopId := Nullable.make(id)
    }
  }
}

// Event handlers
let startGame = () => {
  let level = Signal.get(currentLevel)
  let initialSnake = [
    {x: level.gridSize / 2, y: level.gridSize / 2},
    {x: level.gridSize / 2 - 1, y: level.gridSize / 2},
    {x: level.gridSize / 2 - 2, y: level.gridSize / 2},
  ]

  Signal.set(snake, initialSnake)
  Signal.set(direction, Right)
  Signal.set(nextDirection, Right)
  Signal.set(food, getRandomPosition(level.gridSize, level.obstacles, initialSnake))
  Signal.set(gameStatus, Playing)
  Signal.set(foodEaten, 0)

  startGameLoop()
}

let pauseGame = () => {
  if Signal.get(gameStatus) == Playing {
    Signal.set(gameStatus, Paused)
    stopGameLoop()
  } else if Signal.get(gameStatus) == Paused {
    Signal.set(gameStatus, Playing)
    startGameLoop()
  }
}

let nextLevel = () => {
  Signal.update(currentLevelNum, l => Math.Int.min(l + 1, 10))
  startGame()
}

let restartLevel = () => {
  startGame()
}

let restartGame = () => {
  Signal.set(currentLevelNum, 1)
  Signal.set(score, 0)
  startGame()
}

// Keyboard controls
let handleKeyPress = (_evt: Dom.event) => {
  let key: string = %raw(`_evt.key`)
  let preventDefault: unit => unit = %raw(`() => _evt.preventDefault()`)

  switch key {
  | "ArrowUp" | "w" | "W" => {
      preventDefault()
      Signal.set(nextDirection, Up)
    }
  | "ArrowDown" | "s" | "S" => {
      preventDefault()
      Signal.set(nextDirection, Down)
    }
  | "ArrowLeft" | "a" | "A" => {
      preventDefault()
      Signal.set(nextDirection, Left)
    }
  | "ArrowRight" | "d" | "D" => {
      preventDefault()
      Signal.set(nextDirection, Right)
    }
  | " " => {
      preventDefault()
      pauseGame()
    }
  | _ => ()
  }
}

// Components
let cellSize = 16

module GameGrid = {
  let component = () => {
    let obstaclesSignal = Computed.make(() => {
      let level = Signal.get(currentLevel)
      level.obstacles
    })

    <div
      class="snake-game-grid"
      style={() => {
        let level = Signal.get(currentLevel)
        let gridSize = level.gridSize
        `width: ${Int.toString(gridSize * cellSize)}px; height: ${Int.toString(
            gridSize * cellSize,
          )}px;`
      }}
    >
      {// Render snake
      Component.list(snake, segment => {
        <div
          class="snake-segment"
          style={`width: ${Int.toString(cellSize - 2)}px; height: ${Int.toString(
              cellSize - 2,
            )}px; left: ${Int.toString(segment.x * cellSize)}px; top: ${Int.toString(
              segment.y * cellSize,
            )}px;`}
        />
      })}
      {<div
        // Render food - style must be reactive to update when food position changes
        class="snake-food"
        style={() => {
          let foodPos = Signal.get(food)
          `width: ${Int.toString(cellSize - 4)}px; height: ${Int.toString(
              cellSize - 4,
            )}px; left: ${Int.toString(foodPos.x * cellSize + 2)}px; top: ${Int.toString(
              foodPos.y * cellSize + 2,
            )}px;`
        }}
      />}
      {// Render obstacles
      Component.list(obstaclesSignal, obstacle => {
        <div
          class="snake-obstacle"
          style={`width: ${Int.toString(cellSize)}px; height: ${Int.toString(
              cellSize,
            )}px; left: ${Int.toString(obstacle.x * cellSize)}px; top: ${Int.toString(
              obstacle.y * cellSize,
            )}px;`}
        />
      })}
    </div>
  }
}

module GameInfo = {
  let component = () => {
    <div class="demo-grid-3">
      // Level
      <div class="demo-stat">
        <div class="demo-stat-label"> {Component.text("Level")} </div>
        <div class="demo-stat-value">
          {Component.textSignal(() => Signal.get(currentLevelNum)->Int.toString)}
        </div>
      </div>
      // Score
      <div class="demo-stat">
        <div class="demo-stat-label"> {Component.text("Score")} </div>
        <div class="demo-stat-value">
          {Component.textSignal(() => Signal.get(score)->Int.toString)}
        </div>
      </div>
      // Progress
      <div class="demo-stat">
        <div class="demo-stat-label"> {Component.text("Food")} </div>
        <div class="demo-stat-value">
          {Component.textSignal(() => {
            let eaten = Signal.get(foodEaten)
            let needed = Signal.get(currentLevel).foodCount
            `${Int.toString(eaten)}/${Int.toString(needed)}`
          })}
        </div>
      </div>
    </div>
  }
}

module GameControls = {
  let component = () => {
    <div style="display: flex; flex-wrap: wrap; gap: 0.75rem; justify-content: center; margin-bottom: 1rem;">
      {
        let controlsSignal = Computed.make(() => {
          switch Signal.get(gameStatus) {
          | Paused => [
              <button
                class="demo-btn demo-btn-primary"
                onClick={_ => startGame()}
              >
                {Component.text("Start")}
              </button>,
            ]
          | Playing => [
              <button
                class="demo-btn demo-btn-secondary"
                onClick={_ => pauseGame()}
              >
                {Component.text("Pause")}
              </button>,
            ]
          | GameOver => [
              <button
                class="demo-btn demo-btn-primary"
                onClick={_ => restartLevel()}
              >
                {Component.text("Retry Level")}
              </button>,
              <button
                class="demo-btn demo-btn-secondary"
                onClick={_ => restartGame()}
              >
                {Component.text("Restart Game")}
              </button>,
            ]
          | LevelComplete => [
              <button
                class="demo-btn demo-btn-primary"
                onClick={_ => nextLevel()}
                style={() => Signal.get(currentLevelNum) >= 10 ? "display: none" : ""}
              >
                {Component.text("Next Level")}
              </button>,
              <button
                class="demo-btn demo-btn-primary"
                onClick={_ => restartLevel()}
              >
                {Component.text("Replay Level")}
              </button>,
              <button
                class="demo-btn demo-btn-secondary"
                onClick={_ => restartGame()}
              >
                {Component.text("Restart Game")}
              </button>,
            ]
          }
        })
        Component.signalFragment(controlsSignal)
      }
    </div>
  }
}

module GameStatusDisplay = {
  let component = () => {
    let statusSignal = Computed.make(() => {
      switch Signal.get(gameStatus) {
      | Paused => [
          <div class="snake-status paused">
            <p style="font-weight: 600; margin: 0;">
              {Component.text("Press Start or SPACE to begin")}
            </p>
          </div>,
        ]
      | GameOver => [
          <div class="snake-status game-over">
            <p style="font-size: 1.5rem; font-weight: bold; margin: 0 0 0.5rem 0;">
              {Component.text("Game Over!")}
            </p>
            <p style="margin: 0;">
              {Component.text("You crashed! Try again.")}
            </p>
          </div>,
        ]
      | LevelComplete => [
          <div class="snake-status level-complete">
            <p style="font-size: 1.5rem; font-weight: bold; margin: 0 0 0.5rem 0;">
              {Component.textSignal(() =>
                Signal.get(currentLevelNum) >= 10
                  ? "You Win! All Levels Complete!"
                  : "Level Complete!"
              )}
            </p>
            <p style="margin: 0;">
              {Component.textSignal(() =>
                Signal.get(currentLevelNum) >= 10
                  ? `Final Score: ${Signal.get(score)->Int.toString}`
                  : "Great job! Ready for the next challenge?"
              )}
            </p>
          </div>,
        ]
      | Playing => []
      }
    })
    Component.signalFragment(statusSignal)
  }
}

module Instructions = {
  let component = () => {
    <div class="demo-info-box">
      <h3 style="margin: 0 0 0.5rem 0;">
        {Component.text("How to Play")}
      </h3>
      <div class="demo-grid-2">
        <div>
          <p style="font-weight: 600; margin: 0 0 0.25rem 0;"> {Component.text("Controls:")} </p>
          <ul style="margin: 0; padding-left: 1.25rem; font-size: 0.875rem;">
            <li> {Component.text("Arrow Keys or WASD to move")} </li>
            <li> {Component.text("SPACE to pause/resume")} </li>
          </ul>
        </div>
        <div>
          <p style="font-weight: 600; margin: 0 0 0.25rem 0;"> {Component.text("Rules:")} </p>
          <ul style="margin: 0; padding-left: 1.25rem; font-size: 0.875rem;">
            <li> {Component.text("Eat red food to grow")} </li>
            <li> {Component.text("Avoid walls, obstacles, and yourself")} </li>
            <li> {Component.text("Complete all 10 levels to win!")} </li>
          </ul>
        </div>
      </div>
    </div>
  }
}

let content = () => {
  // Set up keyboard listener (client-only)
  let _ = if Xote.SSRContext.isClient {
    Effect.run(() => {
      let _ = %raw(`window.addEventListener('keydown', handleKeyPress)`)

      Some(
        () => {
          let _ = %raw(`window.removeEventListener('keydown', handleKeyPress)`)
        },
      )
    })->ignore
  }

  // Update high score (client-only)
  let _ = if Xote.SSRContext.isClient {
    Effect.run(() => {
      let currentScore = Signal.get(score)
      let current = Signal.get(highScore)
      if currentScore > current {
        Signal.set(highScore, currentScore)
      }
      None
    })->ignore
  }

  <div class="demo-container">
    // Header
    <div class="demo-section" style="text-align: center;">
      <h2 style="margin: 0 0 0.25rem 0;">
        {Component.text("Snake Game")}
      </h2>
      <p style="margin: 0; opacity: 0.7;">
        {Component.text("10 levels of classic snake action!")}
      </p>
    </div>
    // Game info
    {GameInfo.component()}
    // Game status
    {GameStatusDisplay.component()}
    // Game grid
    <div style="display: flex; justify-content: center; margin-bottom: 1rem;">
      {GameGrid.component()}
    </div>
    // Controls
    {GameControls.component()}
    // Instructions
    {Instructions.component()}
  </div>
}
