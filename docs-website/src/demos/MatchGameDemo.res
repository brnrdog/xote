open Xote

@val external setTimeout: (unit => unit, int) => unit = "setTimeout"

// Game configuration
let levelsConfig = [4, 7, 10, 13, 16, 19, 22, 25, 28, 30]

// Card symbols/figures using Unicode characters
let symbols = [
  "A",
  "B",
  "C",
  "D",
  "E",
  "F",
  "G",
  "H",
  "I",
  "J",
  "K",
  "L",
  "M",
  "N",
  "O",
  "P",
  "Q",
  "R",
  "S",
  "T",
  "U",
  "V",
  "W",
  "X",
  "Y",
  "Z",
  "#",
  "@",
  "&",
  "+",
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
  let cardPairs = Array.make(~length=pairs, 0)->Array.mapWithIndex((_, i) => {
    let symbol = symbols[i]->Option.getOr("?")
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
            cards->Array.mapWithIndex(
              (card, i) =>
                if i == idx1 || i == idx2 {
                  {...card, matched: true, flipped: false}
                } else {
                  card
                },
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
            cards->Array.mapWithIndex(
              (card, i) =>
                if i == idx1 || i == idx2 {
                  {...card, flipped: false}
                } else {
                  card
                },
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

let content = () => {
  // Initialize game
  let _ = Effect.run(() => {
    if Array.length(Signal.get(cards)) == 0 {
      startLevel(1)
    }
    None
  })

  <div class="demo-container">
    // Header
    <div class="demo-section" style="text-align: center; margin-bottom: 1rem;">
      <h2 style="margin: 0 0 0.25rem 0;"> {Component.text("Memory Match Game")} </h2>
      <p style="color: var(--text-muted); margin: 0;">
        {Component.text("2 Players - Find matching pairs")}
      </p>
    </div>

    // Score and Level Info
    <div class="demo-section">
      <div style="display: flex; justify-content: space-between; align-items: center;">
        <div style="text-align: center;">
          <div
            class={() =>
              switch Signal.get(currentPlayer) {
              | Player1 => "match-score-active"
              | Player2 => "match-score-inactive"
              }}
          >
            {Component.textSignal(() => "P1: " ++ Int.toString(Signal.get(player1Score)))}
          </div>
          <div style="font-size: 0.75rem; color: var(--text-muted);">
            {Component.textSignal(() =>
              switch Signal.get(currentPlayer) {
              | Player1 => "Your Turn"
              | Player2 => ""
              }
            )}
          </div>
        </div>
        <div style="text-align: center;">
          <div style="font-weight: bold; font-size: 1.125rem;">
            {Component.textSignal(() => "Level " ++ Int.toString(Signal.get(currentLevel)))}
          </div>
          <div style="font-size: 0.75rem; color: var(--text-muted);">
            {Component.textSignal(() => {
              let level = Signal.get(currentLevel)
              let numCards = levelsConfig[level - 1]->Option.getOr(4)
              Int.toString(numCards) ++ " cards"
            })}
          </div>
        </div>
        <div style="text-align: center;">
          <div
            class={() =>
              switch Signal.get(currentPlayer) {
              | Player2 => "match-score-active"
              | Player1 => "match-score-inactive"
              }}
          >
            {Component.textSignal(() => "P2: " ++ Int.toString(Signal.get(player2Score)))}
          </div>
          <div style="font-size: 0.75rem; color: var(--text-muted);">
            {Component.textSignal(() =>
              switch Signal.get(currentPlayer) {
              | Player2 => "Your Turn"
              | Player1 => ""
              }
            )}
          </div>
        </div>
      </div>
    </div>

    // Game Board
    <div
      class={() => {
        let level = Signal.get(currentLevel)
        let numCards = levelsConfig[level - 1]->Option.getOr(4)
        if numCards <= 10 {
          "match-card-grid-sm"
        } else if numCards <= 20 {
          "match-card-grid-md"
        } else {
          "match-card-grid-lg"
        }
      }}
    >
      {Component.list(cards, card => {
        let className = if card.matched {
          "match-card matched"
        } else if card.flipped {
          "match-card flipped"
        } else {
          "match-card"
        }

        <button class={className} onClick={handleCardClick(card.id, _)}>
          {Component.textSignal(() =>
            if card.flipped || card.matched {
              card.symbol
            } else {
              "?"
            }
          )}
        </button>
      })}
    </div>

    // Level Complete / Game Won Modal
    <div
      class={() =>
        switch Signal.get(gameState) {
        | Playing => "match-modal-overlay hidden"
        | LevelComplete
        | GameWon => "match-modal-overlay"
        }}
    >
      <div class="match-modal">
        <h2 style="margin: 0 0 1rem 0;">
          {Component.textSignal(() =>
            switch Signal.get(gameState) {
            | LevelComplete => "Level Complete!"
            | GameWon => "Game Won!"
            | Playing => ""
            }
          )}
        </h2>
        <div style="margin-bottom: 1.5rem;">
          <div style="margin-bottom: 0.5rem; font-weight: bold;">
            {Component.textSignal(() => {
              let p1 = Signal.get(player1Score)
              let p2 = Signal.get(player2Score)
              if p1 > p2 {
                "Player 1 Wins!"
              } else if p2 > p1 {
                "Player 2 Wins!"
              } else {
                "It's a Tie!"
              }
            })}
          </div>
          <div style="color: var(--text-muted);">
            {Component.textSignal(() =>
              "Player 1: " ++
              Int.toString(Signal.get(player1Score)) ++
              " | Player 2: " ++
              Int.toString(Signal.get(player2Score))
            )}
          </div>
        </div>
        <div class="demo-btn-group">
          <button
            class="demo-btn demo-btn-primary"
            style={() =>
              switch Signal.get(gameState) {
              | GameWon => "display: none"
              | _ => ""
              }}
            onClick={nextLevel}
          >
            {Component.text("Next Level")}
          </button>
          <button class="demo-btn demo-btn-secondary" onClick={restartGame}>
            {Component.text("Restart Game")}
          </button>
        </div>
      </div>
    </div>

    // Restart button
    <div style="text-align: center; margin-top: 1rem;">
      <button class="demo-btn demo-btn-secondary" onClick={restartGame}>
        {Component.text("Restart Game")}
      </button>
    </div>
  </div>
}
