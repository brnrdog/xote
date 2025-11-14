module Signal = Xote.Signal
module Component = Xote.Component
module Effect = Xote.Effect

@val external setTimeout: (unit => unit, int) => unit = "setTimeout"

// Game configuration
let levelsConfig = [4, 7, 10, 13, 16, 19, 22, 25, 28, 30]

// Card symbols/figures using Unicode characters
let symbols = [
  "🌟", "🎨", "🎭", "🎪", "🎯", "🎲", "🎸", "🎹", "🎺", "🎻",
  "🏀", "⚽", "🏈", "⚾", "🎾", "🏐", "🏉", "🎱", "🏓", "🏸",
  "🌸", "🌺", "🌻", "🌷", "🌹", "🌼", "🌴", "🌲", "🌳", "🌿",
]

// Types
type card = {
  id: int,
  symbol: string,
  matched: bool,
  flipped: bool,
}

type gameState =
  | Playing
  | LevelComplete
  | GameWon

type player = Player1 | Player2

// Game state
let currentLevel = Signal.make(1)
let cards = Signal.make([])
let currentPlayer = Signal.make(Player1)
let player1Score = Signal.make(0)
let player2Score = Signal.make(0)
let flippedIndices = Signal.make([])
let gameState = Signal.make(Playing)
let isChecking = Signal.make(false)

// Helper functions
let getCardsForLevel = level => {
  let numCards = levelsConfig[level - 1]->Option.getOr(4)
  // Ensure even number of cards
  let pairs = numCards / 2

  // Create pairs of cards
  let cardPairs = Array.make(~length=pairs, 0)
    ->Array.mapWithIndex((_, i) => {
      let symbol = symbols[i]->Option.getOr("❓")
      [
        {id: i * 2, symbol, matched: false, flipped: false},
        {id: i * 2 + 1, symbol, matched: false, flipped: false},
      ]
    })

  // Flatten and shuffle
  let allCards = cardPairs->Array.flat
  // Simple shuffle using sort with random compare
  allCards->Array.toSorted((_, _) => Math.random() > 0.5 ? 1. : -1.)
}

let startLevel = level => {
  Signal.set(cards, getCardsForLevel(level))
  Signal.set(flippedIndices, [])
  Signal.set(gameState, Playing)
  Signal.set(isChecking, false)
}

let switchPlayer = () => {
  Signal.update(currentPlayer, p =>
    switch p {
    | Player1 => Player2
    | Player2 => Player1
    }
  )
}

let checkForMatch = () => {
  let indices = Signal.get(flippedIndices)
  if Array.length(indices) == 2 {
    Signal.set(isChecking, true)

    let (idx1, idx2) = switch indices {
    | [a, b] => (a, b)
    | _ => (0, 0)
    }

    let currentCards = Signal.get(cards)
    let card1 = currentCards[idx1]
    let card2 = currentCards[idx2]

    switch (card1, card2) {
    | (Some(c1), Some(c2)) =>
      if c1.symbol == c2.symbol {
        // Match found!
        setTimeout(() => {
          Signal.update(cards, cards =>
            cards->Array.mapWithIndex((card, i) =>
              if i == idx1 || i == idx2 {
                {...card, matched: true, flipped: false}
              } else {
                card
              }
            )
          )

          // Award point to current player
          switch Signal.get(currentPlayer) {
          | Player1 => Signal.update(player1Score, s => s + 1)
          | Player2 => Signal.update(player2Score, s => s + 1)
          }

          Signal.set(flippedIndices, [])
          Signal.set(isChecking, false)

          // Check if level is complete
          let updatedCards = Signal.get(cards)
          if updatedCards->Array.every(c => c.matched) {
            let level = Signal.get(currentLevel)
            if level >= 10 {
              Signal.set(gameState, GameWon)
            } else {
              Signal.set(gameState, LevelComplete)
            }
          }
        }, 600)
      } else {
        // No match - flip back and switch player
        setTimeout(() => {
          Signal.update(cards, cards =>
            cards->Array.mapWithIndex((card, i) =>
              if i == idx1 || i == idx2 {
                {...card, flipped: false}
              } else {
                card
              }
            )
          )
          Signal.set(flippedIndices, [])
          Signal.set(isChecking, false)
          switchPlayer()
        }, 1000)
      }
    | _ => ()
    }
  }
}

// Event handlers
let handleCardClick = (cardId: int, _evt: Dom.event) => {
  if Signal.get(isChecking) {
    ()
  } else {
    let currentCards = Signal.get(cards)
    let flipped = Signal.get(flippedIndices)

    // Find the index of the card with this id
    let index = currentCards->Array.findIndex(c => c.id == cardId)

    if index >= 0 {
      let card = currentCards[index]

      switch card {
      | Some(c) =>
        if !c.matched && !c.flipped && Array.length(flipped) < 2 {
          // Flip the card
          Signal.update(cards, cards =>
            cards->Array.mapWithIndex((card, i) =>
              if i == index {
                {...card, flipped: true}
              } else {
                card
              }
            )
          )

          Signal.update(flippedIndices, indices => Array.concat(indices, [index]))

          // Check for match if two cards are flipped
          if Array.length(flipped) == 1 {
            checkForMatch()
          }
        }
      | None => ()
      }
    }
  }
}

let nextLevel = (_evt: Dom.event) => {
  Signal.update(currentLevel, l => l + 1)
  let level = Signal.get(currentLevel)
  startLevel(level)
}

let restartGame = (_evt: Dom.event) => {
  Signal.set(currentLevel, 1)
  Signal.set(player1Score, 0)
  Signal.set(player2Score, 0)
  Signal.set(currentPlayer, Player1)
  startLevel(1)
}

module MatchGame = {
  let component = () => {
    // Initialize game
    let _ = Effect.run(() => {
      if Array.length(Signal.get(cards)) == 0 {
        startLevel(1)
      }
    })

    <div className="max-w-4xl mx-auto p-4 md:p-6">
      // Header
      <div className="mb-6">
        <h1 className="text-3xl font-bold text-stone-900 dark:text-white mb-2 text-center">
          {Component.text("Memory Match Game")}
        </h1>
        <p className="text-center text-stone-600 dark:text-stone-400">
          {Component.text("2 Players • Find matching pairs")}
        </p>
      </div>

      // Score and Level Info
      <div className="bg-white dark:bg-stone-800 rounded-xl p-4 mb-6 border-2 border-stone-200 dark:border-stone-700">
        <div className="flex justify-between items-center mb-4">
          <div className="text-center">
            <div
              className={switch Signal.get(currentPlayer) {
              | Player1 => "text-2xl font-bold text-blue-600 dark:text-blue-400"
              | Player2 => "text-2xl font-bold text-stone-500 dark:text-stone-400"
              }}>
              {Component.textSignal(() => "P1: " ++ Int.toString(Signal.get(player1Score)))}
            </div>
            <div className="text-xs text-stone-500 dark:text-stone-400">
              {Component.textSignal(() =>
                switch Signal.get(currentPlayer) {
                | Player1 => "• Your Turn"
                | Player2 => ""
                }
              )}
            </div>
          </div>
          <div className="text-center">
            <div className="text-xl font-bold text-stone-900 dark:text-white">
              {Component.textSignal(() => "Level " ++ Int.toString(Signal.get(currentLevel)))}
            </div>
            <div className="text-xs text-stone-500 dark:text-stone-400">
              {Component.textSignal(() => {
                let level = Signal.get(currentLevel)
                let numCards = levelsConfig[level - 1]->Option.getOr(4)
                Int.toString(numCards) ++ " cards"
              })}
            </div>
          </div>
          <div className="text-center">
            <div
              className={switch Signal.get(currentPlayer) {
              | Player2 => "text-2xl font-bold text-green-600 dark:text-green-400"
              | Player1 => "text-2xl font-bold text-stone-500 dark:text-stone-400"
              }}>
              {Component.textSignal(() => "P2: " ++ Int.toString(Signal.get(player2Score)))}
            </div>
            <div className="text-xs text-stone-500 dark:text-stone-400">
              {Component.textSignal(() =>
                switch Signal.get(currentPlayer) {
                | Player2 => "• Your Turn"
                | Player1 => ""
                }
              )}
            </div>
          </div>
        </div>
      </div>

      // Game Board
      <div
        className={let level = Signal.get(currentLevel)
        let numCards = levelsConfig[level - 1]->Option.getOr(4)
        if numCards <= 10 {
          "grid grid-cols-4 gap-3 mb-6"
        } else if numCards <= 20 {
          "grid grid-cols-5 gap-2 mb-6"
        } else {
          "grid grid-cols-6 gap-2 mb-6"
        }}>
        {Component.list(
          cards,
          card => {
            let className = {
              let baseClass = "aspect-square rounded-lg font-bold text-3xl transition-all duration-300 transform"
              if card.matched {
                baseClass ++ " bg-green-200 dark:bg-green-800 text-green-800 dark:text-green-200 scale-95 opacity-50"
              } else if card.flipped {
                baseClass ++ " bg-blue-500 dark:bg-blue-600 text-white shadow-lg"
              } else {
                baseClass ++ " bg-stone-300 dark:bg-stone-700 hover:bg-stone-400 dark:hover:bg-stone-600 hover:scale-105"
              }
            }

            <button className={className} onClick={handleCardClick(card.id, _)}>
              {Component.textSignal(() =>
                if card.flipped || card.matched {
                  card.symbol
                } else {
                  "?"
                }
              )}
            </button>
          },
        )}
      </div>

      // Level Complete / Game Won Modal
      <div
        className={switch Signal.get(gameState) {
        | Playing => "hidden"
        | LevelComplete | GameWon => "fixed inset-0 bg-black bg-opacity-50 flex items-center justify-center z-50"
        }}>
        <div className="bg-white dark:bg-stone-800 rounded-2xl p-8 max-w-md mx-4 text-center">
          <h2 className="text-3xl font-bold text-stone-900 dark:text-white mb-4">
            {Component.textSignal(() =>
              switch Signal.get(gameState) {
              | LevelComplete => "Level Complete! 🎉"
              | GameWon => "Game Won! 🏆"
              | Playing => ""
              }
            )}
          </h2>
          <div className="text-xl mb-6">
            <div className="mb-2">
              {Component.textSignal(() => {
                let p1 = Signal.get(player1Score)
                let p2 = Signal.get(player2Score)
                if p1 > p2 {
                  "🏅 Player 1 Wins!"
                } else if p2 > p1 {
                  "🏅 Player 2 Wins!"
                } else {
                  "🤝 It's a Tie!"
                }
              })}
            </div>
            <div className="text-base text-stone-600 dark:text-stone-400">
              {Component.textSignal(() =>
                "Player 1: " ++
                Int.toString(Signal.get(player1Score)) ++
                " | Player 2: " ++
                Int.toString(Signal.get(player2Score))
              )}
            </div>
          </div>
          <div className="flex gap-4 justify-center">
            <button
              className="px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white rounded-lg font-medium transition-colors"
              style={switch Signal.get(gameState) {
              | GameWon => "display: none"
              | _ => ""
              }}
              onClick={nextLevel}>
              {Component.text("Next Level →")}
            </button>
            <button
              className="px-6 py-3 bg-stone-600 hover:bg-stone-700 text-white rounded-lg font-medium transition-colors"
              onClick={restartGame}>
              {Component.text("Restart Game")}
            </button>
          </div>
        </div>
      </div>

      // Restart button
      <div className="text-center">
        <button
          className="px-6 py-2 bg-stone-200 hover:bg-stone-300 dark:bg-stone-700 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-medium transition-colors"
          onClick={restartGame}>
          {Component.text("Restart Game")}
        </button>
      </div>
    </div>
  }
}
