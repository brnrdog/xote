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
  | Hearts => "♥"
  | Diamonds => "♦"
  | Clubs => "♣"
  | Spades => "♠"
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
    switch (Array.get(result, i), Array.get(result, j)) {
    | (Some(temp), Some(val)) => {
        Array.set(result, i, val)
        Array.set(result, j, temp)
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
  let stock = Array.sliceToEnd(deck, ~start=deckIndex.contents)

  Signal.set(gameState, {
    stock,
    waste: [],
    foundations: [[], [], [], []],
    tableau,
  })
  Signal.set(moves, 0)
  Signal.set(selectedCard, NoSelection)
  Signal.set(gameWon, false)
}

// Draw from stock
let drawCard = (_evt: Dom.event) => {
  let state = Signal.get(gameState)

  if Array.length(state.stock) > 0 {
    let card = Array.getUnsafe(state.stock, 0)
    let newStock = Array.sliceToEnd(state.stock, ~start=1)
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
  let allFoundationsComplete = state.foundations->Array.every(foundation =>
    Array.length(foundation) == 13
  )
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
      let newWaste = Array.sliceToEnd(state.waste, ~start=1)
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
      let newWaste = Array.sliceToEnd(state.waste, ~start=1)
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
  let sourceCards = Array.sliceToEnd(Array.getUnsafe(state.tableau, fromCol), ~start=fromIndex)

  if Array.length(sourceCards) > 0 {
    let firstCard = Array.getUnsafe(sourceCards, 0)
    if firstCard.faceUp && canPlaceOnTableau(firstCard, Array.getUnsafe(state.tableau, toCol)) {
      // Valid move
      let newTableau = Array.copy(state.tableau)
      Array.set(newTableau, fromCol, Array.slice(Array.getUnsafe(state.tableau, fromCol), ~start=0, ~end=fromIndex))
      Array.set(newTableau, toCol, Array.concat(Array.getUnsafe(state.tableau, toCol), sourceCards))

      // Flip last card in source column if it exists and is face down
      let fromColCards = Array.getUnsafe(newTableau, fromCol)
      if Array.length(fromColCards) > 0 {
        let lastIndex = Array.length(fromColCards) - 1
        let lastCard = Array.getUnsafe(fromColCards, lastIndex)
        if !lastCard.faceUp {
          Array.set(fromColCards, lastIndex, {...lastCard, faceUp: true})
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
      Array.set(newTableau, fromCol, Array.slice(col, ~start=0, ~end=Array.length(col) - 1))

      // Flip last card in source column if it exists and is face down
      let fromColCards = Array.getUnsafe(newTableau, fromCol)
      if Array.length(fromColCards) > 0 {
        let lastIndex = Array.length(fromColCards) - 1
        let lastCard = Array.getUnsafe(fromColCards, lastIndex)
        if !lastCard.faceUp {
          Array.set(fromColCards, lastIndex, {...lastCard, faceUp: true})
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
    | TableauSelected(fromCol, fromIndex) => {
        if fromCol == colIndex {
          Signal.set(selectedCard, NoSelection)
        } else {
          moveTableauToTableau(fromCol, fromIndex, colIndex)
          Signal.set(selectedCard, NoSelection)
        }
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

// Components
module CardComponent = {
  let component = (~card: card, ~isSelected: bool, ~onClick: Dom.event => unit, ()) => {
    if !card.faceUp {
      // Card back
      Component.div(
        ~attrs=[
          Component.attr(
            "class",
            "w-16 h-24 bg-blue-600 border-2 border-blue-700 rounded-lg cursor-pointer shadow-md flex items-center justify-center",
          ),
        ],
        ~events=[("click", onClick)],
        ~children=[
          Component.div(
            ~attrs=[Component.attr("class", "text-blue-400 text-2xl")],
            ~children=[Component.text("✦")],
            (),
          ),
        ],
        (),
      )
    } else {
      // Card face
      let color = isRed(card.suit) ? "text-red-600" : "text-black"
      let borderColor = isSelected ? "border-yellow-400 border-4" : "border-stone-300 border-2"

      Component.div(
        ~attrs=[
          Component.attr(
            "class",
            `w-16 h-24 bg-white ${borderColor} rounded-lg cursor-pointer shadow-md p-1 flex flex-col justify-between`,
          ),
        ],
        ~events=[("click", onClick)],
        ~children=[
          Component.div(
            ~attrs=[Component.attr("class", `${color} text-sm font-bold text-left`)],
            ~children=[
              Component.text(rankToString(card.rank)),
              Component.span(
                ~attrs=[Component.attr("class", "text-base")],
                ~children=[Component.text(suitToString(card.suit))],
                (),
              ),
            ],
            (),
          ),
          Component.div(
            ~attrs=[Component.attr("class", `${color} text-2xl text-center`)],
            ~children=[Component.text(suitToString(card.suit))],
            (),
          ),
          Component.div(
            ~attrs=[Component.attr("class", `${color} text-sm font-bold text-right`)],
            ~children=[
              Component.text(rankToString(card.rank)),
              Component.span(
                ~attrs=[Component.attr("class", "text-base")],
                ~children=[Component.text(suitToString(card.suit))],
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
}

module EmptySlot = {
  let component = (~label: string, ~onClick: Dom.event => unit, ()) => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "w-16 h-24 border-2 border-dashed border-stone-300 dark:border-stone-600 rounded-lg flex items-center justify-center cursor-pointer hover:border-stone-400 dark:hover:border-stone-500 transition-colors",
        ),
      ],
      ~events=[("click", onClick)],
      ~children=[
        Component.span(
          ~attrs=[Component.attr("class", "text-stone-400 dark:text-stone-500 text-xs")],
          ~children=[Component.text(label)],
          (),
        ),
      ],
      (),
    )
  }
}

module StockAndWaste = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "flex gap-4")],
      ~children=[
        // Stock
        Component.signalFragment(
          Computed.make(() => {
            let state = Signal.get(gameState)
            if Array.length(state.stock) > 0 {
              [
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "w-16 h-24 bg-blue-600 border-2 border-blue-700 rounded-lg cursor-pointer shadow-md flex items-center justify-center hover:scale-105 transition-transform",
                    ),
                  ],
                  ~events=[("click", drawCard)],
                  ~children=[
                    Component.div(
                      ~attrs=[Component.attr("class", "text-blue-400 text-2xl")],
                      ~children=[Component.text("✦")],
                      (),
                    ),
                  ],
                  (),
                ),
              ]
            } else {
              [
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "w-16 h-24 border-2 border-dashed border-stone-300 dark:border-stone-600 rounded-lg cursor-pointer flex items-center justify-center hover:border-stone-400 dark:hover:border-stone-500",
                    ),
                  ],
                  ~events=[("click", drawCard)],
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "text-stone-400 text-xs")],
                      ~children=[Component.text("↻")],
                      (),
                    ),
                  ],
                  (),
                ),
              ]
            }
          }),
        ),
        // Waste
        Component.signalFragment(
          Computed.make(() => {
            let state = Signal.get(gameState)
            let selection = Signal.get(selectedCard)
            if Array.length(state.waste) > 0 {
              let card = Array.getUnsafe(state.waste, 0)
              let isSelected = switch selection {
              | WasteSelected => true
              | _ => false
              }
              [CardComponent.component(~card, ~isSelected, ~onClick=handleWasteClick, ())]
            } else {
              [EmptySlot.component(~label="", ~onClick=_ => (), ())]
            }
          }),
        ),
      ],
      (),
    )
  }
}

module Foundations = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "flex gap-4")],
      ~children=[
        Component.signalFragment(
          Computed.make(() => {
            let state = Signal.get(gameState)
            Array.mapWithIndex(state.foundations, (foundation, index) => {
              if Array.length(foundation) > 0 {
                let card = Array.getUnsafe(foundation, Array.length(foundation) - 1)
                CardComponent.component(
                  ~card,
                  ~isSelected=false,
                  ~onClick=evt => handleFoundationClick(index, evt),
                  (),
                )
              } else {
                let label = switch index {
                | 0 => "♥"
                | 1 => "♦"
                | 2 => "♣"
                | _ => "♠"
                }
                EmptySlot.component(~label, ~onClick=evt => handleFoundationClick(index, evt), ())
              }
            })
          }),
        ),
      ],
      (),
    )
  }
}

module TableauColumn = {
  let component = (~colIndex: int, ()) => {
    Component.div(
      ~attrs=[Component.attr("class", "flex flex-col")],
      ~children=[
        Component.signalFragment(
          Computed.make(() => {
            let state = Signal.get(gameState)
            let selection = Signal.get(selectedCard)
            let column = Array.getUnsafe(state.tableau, colIndex)

            if Array.length(column) == 0 {
              [EmptySlot.component(~label="K", ~onClick=evt => handleTableauEmptyClick(colIndex, evt), ())]
            } else {
              Array.mapWithIndex(column, (card, cardIndex) => {
                let isSelected = switch selection {
                | TableauSelected(col, idx) => col == colIndex && idx == cardIndex
                | _ => false
                }

                let marginClass = if cardIndex > 0 {
                  card.faceUp ? "-mt-16" : "-mt-20"
                } else {
                  ""
                }

                Component.div(
                  ~attrs=[Component.attr("class", marginClass)],
                  ~children=[
                    CardComponent.component(
                      ~card,
                      ~isSelected,
                      ~onClick=evt => handleTableauCardClick(colIndex, cardIndex, evt),
                      (),
                    ),
                  ],
                  (),
                )
              })
            }
          }),
        ),
      ],
      (),
    )
  }
}

module SolitaireGame = {
  let component = () => {
    // Initialize game on mount
    let _ = Effect.run(() => {
      let state = Signal.get(gameState)
      if Array.length(state.stock) == 0 &&
         Array.length(Array.getUnsafe(state.tableau, 0)) == 0 {
        newGame(%raw(`new Event('click')`))
      }
    })

    Component.div(
      ~attrs=[Component.attr("class", "max-w-6xl mx-auto p-4 md:p-6 space-y-6")],
      ~children=[
        // Header
        Component.div(
          ~attrs=[Component.attr("class", "flex items-center justify-between mb-6")],
          ~children=[
            Component.div(
              ~children=[
                Component.h1(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-1",
                    ),
                  ],
                  ~children=[Component.text("Solitaire")],
                  (),
                ),
                Component.p(
                  ~attrs=[
                    Component.attr("class", "text-sm text-stone-600 dark:text-stone-400"),
                  ],
                  ~children=[
                    Component.text("Moves: "),
                    Component.textSignal(() => Signal.get(moves)->Int.toString),
                  ],
                  (),
                ),
              ],
              (),
            ),
            Component.button(
              ~attrs=[
                Component.attr(
                  "class",
                  "px-4 py-2 bg-blue-500 hover:bg-blue-600 text-white rounded-lg font-medium transition-colors",
                ),
              ],
              ~events=[("click", newGame)],
              ~children=[Component.text("New Game")],
              (),
            ),
          ],
          (),
        ),
        // Win message
        Component.signalFragment(
          Computed.make(() => {
            if Signal.get(gameWon) {
              [
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "bg-green-100 dark:bg-green-900/30 border-2 border-green-500 rounded-xl p-4 text-center",
                    ),
                  ],
                  ~children=[
                    Component.p(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "text-xl font-bold text-green-800 dark:text-green-300",
                        ),
                      ],
                      ~children=[
                        Component.text("🎉 You Won! "),
                        Component.textSignal(() =>
                          `Completed in ${Signal.get(moves)->Int.toString} moves`
                        ),
                      ],
                      (),
                    ),
                  ],
                  (),
                ),
              ]
            } else {
              []
            }
          }),
        ),
        // Game area
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "bg-green-700 dark:bg-green-900 rounded-2xl p-6 min-h-[600px]",
            ),
          ],
          ~children=[
            // Top row: Stock/Waste and Foundations
            Component.div(
              ~attrs=[Component.attr("class", "flex justify-between mb-8")],
              ~children=[
                StockAndWaste.component(),
                Foundations.component(),
              ],
              (),
            ),
            // Tableau
            Component.div(
              ~attrs=[Component.attr("class", "grid grid-cols-7 gap-4")],
              ~children=[
                TableauColumn.component(~colIndex=0, ()),
                TableauColumn.component(~colIndex=1, ()),
                TableauColumn.component(~colIndex=2, ()),
                TableauColumn.component(~colIndex=3, ()),
                TableauColumn.component(~colIndex=4, ()),
                TableauColumn.component(~colIndex=5, ()),
                TableauColumn.component(~colIndex=6, ()),
              ],
              (),
            ),
          ],
          (),
        ),
        // Instructions
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "bg-stone-50 dark:bg-stone-800 rounded-xl p-4 border border-stone-200 dark:border-stone-700",
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
                Component.attr(
                  "class",
                  "text-sm text-stone-600 dark:text-stone-400 space-y-1 list-disc list-inside",
                ),
              ],
              ~children=[
                Component.li(
                  ~children=[Component.text("Click cards to select, then click destination")],
                  (),
                ),
                Component.li(
                  ~children=[
                    Component.text("Build tableau columns in descending order, alternating colors"),
                  ],
                  (),
                ),
                Component.li(
                  ~children=[Component.text("Build foundations from Ace to King by suit")],
                  (),
                ),
                Component.li(~children=[Component.text("Only Kings can be placed on empty columns")], ()),
                Component.li(~children=[Component.text("Click stock to draw cards")], ()),
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
