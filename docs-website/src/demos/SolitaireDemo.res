open Xote

// Card types
type suit = Hearts | Diamonds | Clubs | Spades
type rank = Ace | Two | Three | Four | Five | Six | Seven | Eight | Nine | Ten | Jack | Queen | King

type card = {
  suit: suit,
  rank: rank,
  faceUp: bool,
}

// Game state
type gameState = {
  stock: array<card>,
  waste: array<card>,
  foundations: array<array<card>>, // 4 foundations
  tableau: array<array<card>>, // 7 columns
}

// Selected card tracking
type selection =
  | NoSelection
  | WasteSelected
  | TableauSelected(int, int) // column, index
  | FoundationSelected(int) // foundation index

let selectedCard = Signal.make(NoSelection)
let gameState = Signal.make({
  stock: [],
  waste: [],
  foundations: [[], [], [], []],
  tableau: [[], [], [], [], [], [], []],
})
let moves = Signal.make(0)
let gameWon = Signal.make(false)

// Utility functions
let rankValue = (rank: rank): int => {
  switch rank {
  | Ace => 1
  | Two => 2
  | Three => 3
  | Four => 4
  | Five => 5
  | Six => 6
  | Seven => 7
  | Eight => 8
  | Nine => 9
  | Ten => 10
  | Jack => 11
  | Queen => 12
  | King => 13
  }
}

let rankToString = (rank: rank): string => {
  switch rank {
  | Ace => "A"
  | Two => "2"
  | Three => "3"
  | Four => "4"
  | Five => "5"
  | Six => "6"
  | Seven => "7"
  | Eight => "8"
  | Nine => "9"
  | Ten => "10"
  | Jack => "J"
  | Queen => "Q"
  | King => "K"
  }
}

let suitToString = (suit: suit): string => {
  switch suit {
  | Hearts => `\u2665`
  | Diamonds => `\u2666`
  | Clubs => `\u2663`
  | Spades => `\u2660`
  }
}

let isRed = (suit: suit): bool => {
  switch suit {
  | Hearts | Diamonds => true
  | Clubs | Spades => false
  }
}

// Create a full deck
let createDeck = (): array<card> => {
  let suits = [Hearts, Diamonds, Clubs, Spades]
  let ranks = [Ace, Two, Three, Four, Five, Six, Seven, Eight, Nine, Ten, Jack, Queen, King]

  let deck = []
  suits->Array.forEach(suit => {
    ranks->Array.forEach(rank => {
      Array.push(deck, {suit, rank, faceUp: false})
    })
  })
  deck
}

// Shuffle array (Fisher-Yates)
let shuffle = (arr: array<'a>): array<'a> => {
  let result = Array.copy(arr)
  let n = Array.length(result)
  for i in 0 to n - 1 {
    let j = i + Int.fromFloat(Math.random() *. Int.toFloat(n - i))
    switch (result[i], result[j]) {
    | (Some(temp), Some(val)) => {
        result[i] = val
        result[j] = temp
      }
    | _ => ()
    }
  }
  result
}

// Initialize a new game
let newGame = (_evt: Dom.event) => {
  let deck = shuffle(createDeck())

  // Deal to tableau
  let tableau = [[], [], [], [], [], [], []]
  let deckIndex = ref(0)

  for col in 0 to 6 {
    for row in 0 to col {
      let card = Array.getUnsafe(deck, deckIndex.contents)
      let faceUp = row == col
      Array.push(Array.getUnsafe(tableau, col), {...card, faceUp})
      deckIndex := deckIndex.contents + 1
    }
  }

  // Remaining cards go to stock
  let stock = Array.slice(deck, ~start=deckIndex.contents, ~end=Array.length(deck))

  Signal.set(
    gameState,
    {
      stock,
      waste: [],
      foundations: [[], [], [], []],
      tableau,
    },
  )
  Signal.set(moves, 0)
  Signal.set(selectedCard, NoSelection)
  Signal.set(gameWon, false)
}

// Draw from stock
let drawCard = (_evt: Dom.event) => {
  let state = Signal.get(gameState)

  if Array.length(state.stock) > 0 {
    let card = Array.getUnsafe(state.stock, 0)
    let newStock = Array.slice(state.stock, ~start=1, ~end=Array.length(state.stock))
    let newWaste = Array.concat([{...card, faceUp: true}], state.waste)

    let newState: gameState = {
      stock: newStock,
      waste: newWaste,
      foundations: state.foundations,
      tableau: state.tableau,
    }
    Signal.set(gameState, newState)
  } else if Array.length(state.waste) > 0 {
    // Reset: move waste back to stock
    let mapped = Array.map(state.waste, card => {...card, faceUp: false})
    let newStock: array<card> = Array.toReversed(mapped)
    let emptyWaste: array<card> = []
    let newState: gameState = {
      stock: newStock,
      waste: emptyWaste,
      foundations: state.foundations,
      tableau: state.tableau,
    }
    Signal.set(gameState, newState)
  }
}

// Check if a move is valid
let canPlaceOnTableau = (card: card, targetCol: array<card>): bool => {
  if Array.length(targetCol) == 0 {
    rankValue(card.rank) == 13 // Only King on empty column
  } else {
    let lastCard = Array.getUnsafe(targetCol, Array.length(targetCol) - 1)
    lastCard.faceUp &&
    rankValue(card.rank) == rankValue(lastCard.rank) - 1 &&
    isRed(card.suit) != isRed(lastCard.suit)
  }
}

let canPlaceOnFoundation = (card: card, foundation: array<card>): bool => {
  if Array.length(foundation) == 0 {
    rankValue(card.rank) == 1 // Only Ace on empty foundation
  } else {
    let lastCard = Array.getUnsafe(foundation, Array.length(foundation) - 1)
    card.suit == lastCard.suit && rankValue(card.rank) == rankValue(lastCard.rank) + 1
  }
}

// Check win condition
let checkWin = () => {
  let state = Signal.get(gameState)
  let allFoundationsComplete =
    state.foundations->Array.every(foundation => Array.length(foundation) == 13)
  if allFoundationsComplete {
    Signal.set(gameWon, true)
  }
}

// Move card from waste to tableau
let moveWasteToTableau = (colIndex: int) => {
  let state = Signal.get(gameState)
  if Array.length(state.waste) > 0 {
    let card = Array.getUnsafe(state.waste, 0)
    if canPlaceOnTableau(card, Array.getUnsafe(state.tableau, colIndex)) {
      let newWaste = Array.slice(state.waste, ~start=1, ~end=Array.length(state.waste))
      let newTableau = Array.copy(state.tableau)
      Array.push(Array.getUnsafe(newTableau, colIndex), card)

      Signal.set(gameState, {...state, waste: newWaste, tableau: newTableau})
      Signal.update(moves, m => m + 1)
    }
  }
}

// Move card from waste to foundation
let moveWasteToFoundation = (foundIndex: int) => {
  let state = Signal.get(gameState)
  if Array.length(state.waste) > 0 {
    let card = Array.getUnsafe(state.waste, 0)
    if canPlaceOnFoundation(card, Array.getUnsafe(state.foundations, foundIndex)) {
      let newWaste = Array.slice(state.waste, ~start=1, ~end=Array.length(state.waste))
      let newFoundations = Array.copy(state.foundations)
      Array.push(Array.getUnsafe(newFoundations, foundIndex), card)

      Signal.set(gameState, {...state, waste: newWaste, foundations: newFoundations})
      Signal.update(moves, m => m + 1)
      checkWin()
    }
  }
}

// Move card(s) from tableau to tableau
let moveTableauToTableau = (fromCol: int, fromIndex: int, toCol: int) => {
  let state = Signal.get(gameState)
  let fromColArr = Array.getUnsafe(state.tableau, fromCol)
  let sourceCards = Array.slice(fromColArr, ~start=fromIndex, ~end=Array.length(fromColArr))

  if Array.length(sourceCards) > 0 {
    let firstCard = Array.getUnsafe(sourceCards, 0)
    if firstCard.faceUp && canPlaceOnTableau(firstCard, Array.getUnsafe(state.tableau, toCol)) {
      // Valid move
      let newTableau = Array.copy(state.tableau)
      newTableau[fromCol] = Array.slice(
        Array.getUnsafe(state.tableau, fromCol),
        ~start=0,
        ~end=fromIndex,
      )
      newTableau[toCol] = Array.concat(Array.getUnsafe(state.tableau, toCol), sourceCards)

      // Flip last card in source column if it exists and is face down
      let fromColCards = Array.getUnsafe(newTableau, fromCol)
      if Array.length(fromColCards) > 0 {
        let lastIndex = Array.length(fromColCards) - 1
        let lastCard = Array.getUnsafe(fromColCards, lastIndex)
        if !lastCard.faceUp {
          fromColCards[lastIndex] = {...lastCard, faceUp: true}
        }
      }

      Signal.set(gameState, {...state, tableau: newTableau})
      Signal.update(moves, m => m + 1)
    }
  }
}

// Move card from tableau to foundation
let moveTableauToFoundation = (fromCol: int, foundIndex: int) => {
  let state = Signal.get(gameState)
  let col = Array.getUnsafe(state.tableau, fromCol)

  if Array.length(col) > 0 {
    let card = Array.getUnsafe(col, Array.length(col) - 1)
    if card.faceUp && canPlaceOnFoundation(card, Array.getUnsafe(state.foundations, foundIndex)) {
      // Valid move
      let newTableau = Array.copy(state.tableau)
      newTableau[fromCol] = Array.slice(col, ~start=0, ~end=Array.length(col) - 1)

      // Flip last card in source column if it exists and is face down
      let fromColCards = Array.getUnsafe(newTableau, fromCol)
      if Array.length(fromColCards) > 0 {
        let lastIndex = Array.length(fromColCards) - 1
        let lastCard = Array.getUnsafe(fromColCards, lastIndex)
        if !lastCard.faceUp {
          fromColCards[lastIndex] = {...lastCard, faceUp: true}
        }
      }

      let newFoundations = Array.copy(state.foundations)
      Array.push(Array.getUnsafe(newFoundations, foundIndex), card)

      Signal.set(gameState, {...state, tableau: newTableau, foundations: newFoundations})
      Signal.update(moves, m => m + 1)
      checkWin()
    }
  }
}

// Handle card clicks
let handleWasteClick = (_evt: Dom.event) => {
  Signal.set(selectedCard, WasteSelected)
}

let handleTableauCardClick = (colIndex: int, cardIndex: int, _evt: Dom.event) => {
  let state = Signal.get(gameState)
  let card = Array.getUnsafe(Array.getUnsafe(state.tableau, colIndex), cardIndex)

  if card.faceUp {
    switch Signal.get(selectedCard) {
    | NoSelection => Signal.set(selectedCard, TableauSelected(colIndex, cardIndex))
    | WasteSelected => {
        moveWasteToTableau(colIndex)
        Signal.set(selectedCard, NoSelection)
      }
    | TableauSelected(fromCol, fromIndex) =>
      if fromCol == colIndex {
        Signal.set(selectedCard, NoSelection)
      } else {
        moveTableauToTableau(fromCol, fromIndex, colIndex)
        Signal.set(selectedCard, NoSelection)
      }
    | FoundationSelected(_) => Signal.set(selectedCard, NoSelection)
    }
  }
}

let handleTableauEmptyClick = (colIndex: int, _evt: Dom.event) => {
  switch Signal.get(selectedCard) {
  | WasteSelected => {
      moveWasteToTableau(colIndex)
      Signal.set(selectedCard, NoSelection)
    }
  | TableauSelected(fromCol, fromIndex) => {
      moveTableauToTableau(fromCol, fromIndex, colIndex)
      Signal.set(selectedCard, NoSelection)
    }
  | _ => Signal.set(selectedCard, NoSelection)
  }
}

let handleFoundationClick = (foundIndex: int, _evt: Dom.event) => {
  switch Signal.get(selectedCard) {
  | WasteSelected => {
      moveWasteToFoundation(foundIndex)
      Signal.set(selectedCard, NoSelection)
    }
  | TableauSelected(fromCol, _) => {
      moveTableauToFoundation(fromCol, foundIndex)
      Signal.set(selectedCard, NoSelection)
    }
  | _ => Signal.set(selectedCard, NoSelection)
  }
}

/* Card Component using JSX */
type cardProps = {
  card: card,
  isSelected: bool,
  onClick: Dom.event => unit,
}

let cardComponent = (props: cardProps) => {
  if !props.card.faceUp {
    // Card back
    <div
      class="solitaire-card face-down"
      onClick={props.onClick}
    >
      <div class="solitaire-card-back-symbol"> {Component.text(`\u2726`)} </div>
    </div>
  } else {
    // Card face
    let colorClass = isRed(props.card.suit) ? "solitaire-card-red" : "solitaire-card-black"
    let selectedClass = props.isSelected ? " selected" : ""

    <div
      class={`solitaire-card${selectedClass}`}
      onClick={props.onClick}
    >
      <div class={`solitaire-card-top ${colorClass}`}>
        {Component.text(rankToString(props.card.rank))}
        <span class="solitaire-card-suit"> {Component.text(suitToString(props.card.suit))} </span>
      </div>
      <div class={`solitaire-card-center ${colorClass}`}>
        {Component.text(suitToString(props.card.suit))}
      </div>
      <div class={`solitaire-card-bottom ${colorClass}`}>
        {Component.text(rankToString(props.card.rank))}
        <span class="solitaire-card-suit"> {Component.text(suitToString(props.card.suit))} </span>
      </div>
    </div>
  }
}

/* Empty Slot Component using JSX */
type emptySlotProps = {
  label: string,
  onClick: Dom.event => unit,
}

let emptySlot = (props: emptySlotProps) => {
  <div
    class="solitaire-empty-slot"
    onClick={props.onClick}
  >
    <span class="solitaire-empty-slot-label"> {Component.text(props.label)} </span>
  </div>
}

/* Stock and Waste Component using JSX */
let stockAndWaste = () => {
  <div style="display: flex; gap: 1rem;">
    {
      let stockSignal = Computed.make(() => {
        let state = Signal.get(gameState)
        if Array.length(state.stock) > 0 {
          [
            <div
              class="solitaire-card face-down"
              onClick={drawCard}
            >
              <div class="solitaire-card-back-symbol"> {Component.text(`\u2726`)} </div>
            </div>,
          ]
        } else {
          [
            <div
              class="solitaire-empty-slot"
              onClick={drawCard}
            >
              <span class="solitaire-empty-slot-label"> {Component.text(`\u21BB`)} </span>
            </div>,
          ]
        }
      })
      Component.signalFragment(stockSignal)
    }
    {
      let wasteSignal = Computed.make(() => {
        let state = Signal.get(gameState)
        let selection = Signal.get(selectedCard)
        if Array.length(state.waste) > 0 {
          let card = Array.getUnsafe(state.waste, 0)
          let isSelected = switch selection {
          | WasteSelected => true
          | _ => false
          }
          [cardComponent({card, isSelected, onClick: handleWasteClick})]
        } else {
          [emptySlot({label: "", onClick: _ => ()})]
        }
      })
      Component.signalFragment(wasteSignal)
    }
  </div>
}

/* Foundations Component using JSX */
let foundations = () => {
  <div style="display: flex; gap: 1rem;">
    {
      let foundationsSignal = Computed.make(() => {
        let state = Signal.get(gameState)
        Array.mapWithIndex(state.foundations, (foundation, index) => {
          if Array.length(foundation) > 0 {
            let card = Array.getUnsafe(foundation, Array.length(foundation) - 1)
            cardComponent({
              card,
              isSelected: false,
              onClick: evt => handleFoundationClick(index, evt),
            })
          } else {
            let label = switch index {
            | 0 => `\u2665`
            | 1 => `\u2666`
            | 2 => `\u2663`
            | _ => `\u2660`
            }
            emptySlot({label, onClick: evt => handleFoundationClick(index, evt)})
          }
        })
      })
      Component.signalFragment(foundationsSignal)
    }
  </div>
}

/* Tableau Column Component using JSX */
type tableauColumnProps = {colIndex: int}

let tableauColumn = (props: tableauColumnProps) => {
  <div style="display: flex; flex-direction: column;">
    {
      let tableauSignal = Computed.make(() => {
        let state = Signal.get(gameState)
        let selection = Signal.get(selectedCard)
        let column = Array.getUnsafe(state.tableau, props.colIndex)

        if Array.length(column) == 0 {
          [emptySlot({label: "K", onClick: evt => handleTableauEmptyClick(props.colIndex, evt)})]
        } else {
          Array.mapWithIndex(column, (card, cardIndex) => {
            let isSelected = switch selection {
            | TableauSelected(col, idx) => col == props.colIndex && idx == cardIndex
            | _ => false
            }

            let stackClass = if cardIndex > 0 {
              card.faceUp ? "solitaire-stack-card face-up" : "solitaire-stack-card"
            } else {
              ""
            }

            <div class={stackClass}>
              {cardComponent({
                card,
                isSelected,
                onClick: evt => handleTableauCardClick(props.colIndex, cardIndex, evt),
              })}
            </div>
          })
        }
      })
      Component.signalFragment(tableauSignal)
    }
  </div>
}

/* Main Solitaire Game - exported as content */
let content = () => {
  // Initialize game on mount
  let _ = Effect.run(() => {
    let state = Signal.get(gameState)
    if Array.length(state.stock) == 0 && Array.length(Array.getUnsafe(state.tableau, 0)) == 0 {
      newGame(%raw(`new Event('click')`))
    }
    None
  })

  <div class="demo-container">
    <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem;">
      <div>
        <h2 style="margin: 0 0 0.25rem 0;">
          {Component.text("Solitaire")}
        </h2>
        <p style="margin: 0; font-size: 0.875rem; opacity: 0.7;">
          {Component.text("Moves: ")}
          {Component.textSignal(() => Signal.get(moves)->Int.toString)}
        </p>
      </div>
      <button
        class="demo-btn demo-btn-primary"
        onClick={newGame}
      >
        {Component.text("New Game")}
      </button>
    </div>
    {
      let gameWonSignal = Computed.make(() => {
        if Signal.get(gameWon) {
          [
            <div class="solitaire-win">
              <p style="font-size: 1.25rem; font-weight: bold; margin: 0;">
                {Component.text("You Won! ")}
                {Component.textSignal(() =>
                  `Completed in ${Signal.get(moves)->Int.toString} moves`
                )}
              </p>
            </div>,
          ]
        } else {
          []
        }
      })
      Component.signalFragment(gameWonSignal)
    }
    <div class="solitaire-board">
      <div class="solitaire-top-row">
        {stockAndWaste()}
        {foundations()}
      </div>
      <div class="solitaire-tableau">
        {tableauColumn({colIndex: 0})}
        {tableauColumn({colIndex: 1})}
        {tableauColumn({colIndex: 2})}
        {tableauColumn({colIndex: 3})}
        {tableauColumn({colIndex: 4})}
        {tableauColumn({colIndex: 5})}
        {tableauColumn({colIndex: 6})}
      </div>
    </div>
    <div class="demo-info-box">
      <h3 style="margin: 0 0 0.5rem 0;">
        {Component.text("How to Play")}
      </h3>
      <ul style="margin: 0; padding-left: 1.25rem; font-size: 0.875rem; opacity: 0.8;">
        <li> {Component.text("Click cards to select, then click destination")} </li>
        <li> {Component.text("Build tableau columns in descending order, alternating colors")} </li>
        <li> {Component.text("Build foundations from Ace to King by suit")} </li>
        <li> {Component.text("Only Kings can be placed on empty columns")} </li>
        <li> {Component.text("Click stock to draw cards")} </li>
      </ul>
    </div>
  </div>
}
