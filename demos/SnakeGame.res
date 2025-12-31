module Signal = Xote.Signal
module Computed = Xote.Computed
module Component = Xote.Component
module Effect = Xote.Effect

// External bindings
@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

// Types
type direction = Up | Down | Left | Right
type position = {x: int, y: int}
type gameState = Playing | Paused | GameOver | LevelComplete

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
    obstacles: [
      {x: 7, y: 7},
      {x: 7, y: 13},
      {x: 13, y: 7},
      {x: 13, y: 13},
    ],
    foodCount: 16,
  },
  {
    number: 8,
    speed: 90,
    gridSize: 21,
    obstacles: [
      {x: 10, y: 5},
      {x: 10, y: 10},
      {x: 10, y: 15},
      {x: 5, y: 10},
      {x: 15, y: 10},
    ],
    foodCount: 18,
  },
  {
    number: 9,
    speed: 80,
    gridSize: 23,
    obstacles: [
      {x: 6, y: 6},
      {x: 6, y: 16},
      {x: 16, y: 6},
      {x: 16, y: 16},
      {x: 11, y: 11},
    ],
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
let gameState = Signal.make(Paused)
let score = Signal.make(0)
let foodEaten = Signal.make(0)
let gameLoopId: ref<Nullable.t<int>> = ref(Nullable.null)

// Computed values
let currentLevel = Computed.make(() => {
  let levelNum = Signal.get(currentLevelNum)
  levels[levelNum - 1]->Option.getOr(levels[0]->Option.getExn)
})

let highScore = Signal.make(0)

// Helper functions
let positionsEqual = (p1: position, p2: position): bool => {
  p1.x == p2.x && p1.y == p2.y
}

let isPositionInArray = (pos: position, arr: array<position>): bool => {
  arr->Array.some(p => positionsEqual(p, pos))
}

let getRandomPosition = (gridSize: int, obstacles: array<position>, snake: array<position>): position => {
  let rec findPosition = () => {
    let x = Int.fromFloat(Math.random() *. Int.toFloat(gridSize))
    let y = Int.fromFloat(Math.random() *. Int.toFloat(gridSize))
    let pos = {x, y}

    if isPositionInArray(pos, obstacles) || isPositionInArray(pos, snake) {
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
  if Signal.get(gameState) == Playing {
    let level = Signal.get(currentLevel)
    let currentDir = Signal.get(direction)
    let next = Signal.get(nextDirection)

    // Update direction if valid
    if isValidMove(currentDir, next) {
      Signal.set(direction, next)
    }

    let currentSnake = Signal.get(snake)
    let head = currentSnake[0]->Option.getExn
    let newHead = getNextPosition(head, Signal.get(direction))

    // Check collisions
    if (
      isOutOfBounds(newHead, level.gridSize) ||
      isPositionInArray(newHead, currentSnake) ||
      isPositionInArray(newHead, level.obstacles)
    ) {
      Signal.set(gameState, GameOver)
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
          Signal.set(gameState, LevelComplete)
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
  Signal.set(gameState, Playing)
  Signal.set(foodEaten, 0)

  startGameLoop()
}

let pauseGame = () => {
  if Signal.get(gameState) == Playing {
    Signal.set(gameState, Paused)
    stopGameLoop()
  } else if Signal.get(gameState) == Paused {
    Signal.set(gameState, Playing)
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
let handleKeyPress = (evt: Dom.event) => {
  let key = %raw(`evt.key`)

  switch key {
  | "ArrowUp" | "w" | "W" => {
      %raw(`evt.preventDefault()`)
      Signal.set(nextDirection, Up)
    }
  | "ArrowDown" | "s" | "S" => {
      %raw(`evt.preventDefault()`)
      Signal.set(nextDirection, Down)
    }
  | "ArrowLeft" | "a" | "A" => {
      %raw(`evt.preventDefault()`)
      Signal.set(nextDirection, Left)
    }
  | "ArrowRight" | "d" | "D" => {
      %raw(`evt.preventDefault()`)
      Signal.set(nextDirection, Right)
    }
  | " " => {
      %raw(`evt.preventDefault()`)
      pauseGame()
    }
  | _ => ()
  }
}

// Components
module GameGrid = {
  let component = () => {
    let level = Signal.get(currentLevel)
    let gridSize = level.gridSize
    let cellSize = 20 // pixels

    <div
      class="inline-block bg-stone-100 dark:bg-stone-900 border-4 border-stone-300 dark:border-stone-700 rounded-lg overflow-hidden"
      style={`width: ${Int.toString(gridSize * cellSize + 8)}px; height: ${Int.toString(
          gridSize * cellSize + 8,
        )}px; box-sizing: border-box; position: relative;`}>
      {
        // Render snake
        Component.list(snake, segment => {
          <div
            class="absolute bg-green-500 dark:bg-green-400 rounded-sm transition-all duration-100"
            style={`width: ${Int.toString(cellSize - 2)}px; height: ${Int.toString(
                cellSize - 2,
              )}px; left: ${Int.toString(segment.x * cellSize)}px; top: ${Int.toString(
                segment.y * cellSize,
              )}px;`}
          />
        })
      }
      {
        // Render food - style must be reactive to update when food position changes
        <div
          class="absolute bg-red-500 dark:bg-red-400 rounded-full animate-pulse"
          style={() => {
            let foodPos = Signal.get(food)
            `width: ${Int.toString(cellSize - 4)}px; height: ${Int.toString(
                cellSize - 4,
              )}px; left: ${Int.toString(foodPos.x * cellSize + 2)}px; top: ${Int.toString(
                foodPos.y * cellSize + 2,
              )}px;`
          }}
        />
      }
      {
        // Render obstacles
        Component.list(Signal.make(level.obstacles), obstacle => {
          <div
            class="absolute bg-stone-600 dark:bg-stone-500 rounded-sm"
            style={`width: ${Int.toString(cellSize)}px; height: ${Int.toString(
                cellSize,
              )}px; left: ${Int.toString(obstacle.x * cellSize)}px; top: ${Int.toString(
                obstacle.y * cellSize,
              )}px;`}
          />
        })
      }
    </div>
  }
}

module GameInfo = {
  let component = () => {
    <div class="grid grid-cols-3 gap-4 mb-4">
      // Level
      <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 text-center">
        <div class="text-sm text-blue-600 dark:text-blue-400 mb-1">
          {Component.text("Level")}
        </div>
        <div class="text-2xl font-bold text-blue-700 dark:text-blue-300">
          {Component.textSignal(() => Signal.get(currentLevelNum)->Int.toString)}
        </div>
      </div>
      // Score
      <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 text-center">
        <div class="text-sm text-green-600 dark:text-green-400 mb-1">
          {Component.text("Score")}
        </div>
        <div class="text-2xl font-bold text-green-700 dark:text-green-300">
          {Component.textSignal(() => Signal.get(score)->Int.toString)}
        </div>
      </div>
      // Progress
      <div class="bg-purple-50 dark:bg-purple-900/20 rounded-lg p-4 text-center">
        <div class="text-sm text-purple-600 dark:text-purple-400 mb-1">
          {Component.text("Food")}
        </div>
        <div class="text-2xl font-bold text-purple-700 dark:text-purple-300">
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
    <div class="flex flex-wrap gap-3 justify-center mb-4">
      {
        let controlsSignal = Computed.make(() => {
          switch Signal.get(gameState) {
          | Paused => [
              <button
                class="px-6 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => startGame()}>
                {Component.text("▶ Start")}
              </button>,
            ]
          | Playing => [
              <button
                class="px-6 py-3 bg-yellow-500 hover:bg-yellow-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => pauseGame()}>
                {Component.text("⏸ Pause")}
              </button>,
            ]
          | GameOver => [
              <button
                class="px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => restartLevel()}>
                {Component.text("↻ Retry Level")}
              </button>,
              <button
                class="px-6 py-3 bg-stone-500 hover:bg-stone-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => restartGame()}>
                {Component.text("⟲ Restart Game")}
              </button>,
            ]
          | LevelComplete => [
              <button
                class="px-6 py-3 bg-green-500 hover:bg-green-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => nextLevel()}
                style={() =>
                  Signal.get(currentLevelNum) >= 10 ? "display: none" : ""}>
                {Component.text("→ Next Level")}
              </button>,
              <button
                class="px-6 py-3 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => restartLevel()}>
                {Component.text("↻ Replay Level")}
              </button>,
              <button
                class="px-6 py-3 bg-stone-500 hover:bg-stone-600 text-white rounded-lg font-medium transition-colors"
                onClick={_ => restartGame()}>
                {Component.text("⟲ Restart Game")}
              </button>,
            ]
          }
        })
        Component.signalFragment(controlsSignal)
      }
    </div>
  }
}

module GameStatus = {
  let component = () => {
    let statusSignal = Computed.make(() => {
      switch Signal.get(gameState) {
      | Paused => [
          <div class="bg-blue-50 dark:bg-blue-900/20 rounded-lg p-4 text-center border border-blue-200 dark:border-blue-800">
            <p class="text-blue-700 dark:text-blue-300 font-semibold">
              {Component.text("Press Start or SPACE to begin")}
            </p>
          </div>,
        ]
      | GameOver => [
          <div class="bg-red-50 dark:bg-red-900/20 rounded-lg p-4 text-center border border-red-200 dark:border-red-800">
            <p class="text-2xl font-bold text-red-700 dark:text-red-300 mb-2">
              {Component.text("Game Over!")}
            </p>
            <p class="text-red-600 dark:text-red-400">
              {Component.text("You crashed! Try again.")}
            </p>
          </div>,
        ]
      | LevelComplete => [
          <div class="bg-green-50 dark:bg-green-900/20 rounded-lg p-4 text-center border border-green-200 dark:border-green-800">
            <p class="text-2xl font-bold text-green-700 dark:text-green-300 mb-2">
              {Component.textSignal(() =>
                Signal.get(currentLevelNum) >= 10
                  ? "🏆 You Win! All Levels Complete!"
                  : "✨ Level Complete!"
              )}
            </p>
            <p class="text-green-600 dark:text-green-400">
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
    <div class="bg-stone-50 dark:bg-stone-700/50 rounded-lg p-4 border border-stone-200 dark:border-stone-600">
      <h3 class="font-semibold text-stone-900 dark:text-white mb-2">
        {Component.text("How to Play")}
      </h3>
      <div class="grid md:grid-cols-2 gap-4 text-sm text-stone-600 dark:text-stone-400">
        <div>
          <p class="font-semibold mb-1"> {Component.text("Controls:")} </p>
          <ul class="space-y-1 list-disc list-inside">
            <li> {Component.text("Arrow Keys or WASD to move")} </li>
            <li> {Component.text("SPACE to pause/resume")} </li>
          </ul>
        </div>
        <div>
          <p class="font-semibold mb-1"> {Component.text("Rules:")} </p>
          <ul class="space-y-1 list-disc list-inside">
            <li> {Component.text("Eat red food to grow")} </li>
            <li> {Component.text("Avoid walls, obstacles, and yourself")} </li>
            <li> {Component.text("Complete all 10 levels to win!")} </li>
          </ul>
        </div>
      </div>
    </div>
  }
}

module SnakeGame = {
  let component = () => {
    // Set up keyboard listener
    let _ = Effect.run(() => {
      %raw(`window.addEventListener('keydown', handleKeyPress)`)

      Some(() => {
        %raw(`window.removeEventListener('keydown', handleKeyPress)`)
      })
    })

    // Update high score
    let _ = Effect.run(() => {
      let currentScore = Signal.get(score)
      let current = Signal.get(highScore)
      if currentScore > current {
        Signal.set(highScore, currentScore)
      }
      None
    })

    <div class="max-w-4xl mx-auto p-4 md:p-6">
      // Header
      <div class="text-center mb-6">
        <h1 class="text-3xl md:text-4xl font-bold text-stone-900 dark:text-white mb-2">
          {Component.text("🐍 Snake Game")}
        </h1>
        <p class="text-stone-600 dark:text-stone-400">
          {Component.text("10 levels of classic snake action!")}
        </p>
      </div>
      // Game info
      {GameInfo.component()}
      // Game status
      {GameStatus.component()}
      // Game grid
      <div class="flex justify-center mb-4">
        {GameGrid.component()}
      </div>
      // Controls
      {GameControls.component()}
      // Instructions
      {Instructions.component()}
    </div>
  }
}
