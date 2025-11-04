open Xote

// Initialize router
let _ = Router.init()

// Navigate to home on first load if we're at the HTML file path
let _ = Effect.run(() => {
  let pathname = Signal.get(Router.location).pathname
  if pathname == "/bookstore.html" || pathname == "/demos/bookstore.html" {
    Router.replace("/", ())
  }
})

// Types
type product = {
  id: int,
  title: string,
  author: string,
  description: string,
  price: float,
  cover: string, // emoji
}

type cartItem = {
  productId: int,
  quantity: int,
}

type checkoutForm = {
  name: string,
  email: string,
  address: string,
  city: string,
  cardNumber: string,
}

// Product catalog - Absurd FP/Reactivity themed books
let products = [
  {
    id: 1,
    title: "The Reactive Manifesto: A Monad's Journey",
    author: "Dr. Lambda Calculus",
    description: "Follow a lonely monad through the treacherous landscape of side effects and impurity. A heartwarming tale of composition and transformation.",
    price: 42.0,
    cover: "📘",
  },
  {
    id: 2,
    title: "Functors and You: A Love Story",
    author: "Category von Theory",
    description: "They said it couldn't work. A humble function and a container. But love finds a way, through map, flatMap, and beyond.",
    price: 31.5,
    cover: "💙",
  },
  {
    id: 3,
    title: "Currying for Beginners: One Argument at a Time",
    author: "Haskell B. Curry Jr.",
    description: "Why take all your arguments at once when you can take them one at a time? A revolutionary approach to function appreciation.",
    price: 28.99,
    cover: "🍛",
  },
  {
    id: 4,
    title: "The Art of Pure Functions",
    author: "Master Referential Transparency",
    description: "No side effects. No mutations. Just pure, beautiful mathematical perfection. Achieve zen through referential transparency.",
    price: 55.0,
    cover: "🎨",
  },
  {
    id: 5,
    title: "Signals and Slots: A Reactive Romance",
    author: "Observer Pattern-Smith",
    description: "When Signal met Slot, it was dependency at first sight. A tale of reactive updates and fine-grained tracking.",
    price: 38.75,
    cover: "💕",
  },
  {
    id: 6,
    title: "Composing the Composable",
    author: "Func T. Composition",
    description: "f(g(x))? More like f ∘ g! Learn to stack functions like a master chef stacks pancakes.",
    price: 33.33,
    cover: "🥞",
  },
  {
    id: 7,
    title: "Lazy Evaluation: Why Do Today What You Can Defer?",
    author: "Procrastin Ator",
    description: "Never compute a value until absolutely necessary. The ultimate guide to doing nothing until you have to.",
    price: 25.0,
    cover: "😴",
  },
  {
    id: 8,
    title: "The Side Effect Strikes Back",
    author: "I. O. Monad",
    description: "In a world of pure functions, one side effect dares to mutate. The thrilling sequel to 'A New Pure Function'.",
    price: 44.44,
    cover: "⚡",
  },
  {
    id: 9,
    title: "Immutability: Never Change",
    author: "Constant Values",
    description: "Why change is overrated and staying the same is the path to enlightenment. Once set, forever committed.",
    price: 37.0,
    cover: "🗿",
  },
  {
    id: 10,
    title: "Recursion: See Recursion",
    author: "Stack O. Verflow",
    description: "To understand recursion, you must first understand recursion. Warning: May cause infinite loops in brain.",
    price: 99.99,
    cover: "🔄",
  },
  {
    id: 11,
    title: "The Async/Await Awakens",
    author: "Promise Keeper",
    description: "In a galaxy far, far away, callbacks ruled with an iron fist. Then came the Promise. Then came async/await.",
    price: 48.0,
    cover: "🌟",
  },
  {
    id: 12,
    title: "Map, Filter, Reduce: The Holy Trinity",
    author: "Array Methods",
    description: "Forget everything you know about for loops. These three methods are all you'll ever need. (Spoiler: You might need more.)",
    price: 35.5,
    cover: "📊",
  },
]

// State
let cart = Signal.make([])
let checkoutForm = Signal.make({
  name: "",
  email: "",
  address: "",
  city: "",
  cardNumber: "",
})
let orderNumber = Signal.make(0)

// Computed values
let cartTotal = Computed.make(() => {
  let items = Signal.get(cart)
  items->Array.reduce(0.0, (total, item) => {
    let product = products->Array.find(p => p.id == item.productId)
    switch product {
    | Some(p) => total +. (p.price *. Float.fromInt(item.quantity))
    | None => total
    }
  })
})

let cartItemCount = Computed.make(() => {
  let items = Signal.get(cart)
  items->Array.reduce(0, (count, item) => count + item.quantity)
})

// Helper functions
let getProductById = (id: int) => {
  products->Array.find(p => p.id == id)
}

let getCartItem = (productId: int) => {
  Signal.get(cart)->Array.find(item => item.productId == productId)
}

let formatPrice = (price: float) => {
  "Ƒ" ++ Float.toFixed(price, ~digits=2)
}

// Cart actions
let addToCart = (productId: int) => {
  Signal.update(cart, items => {
    let existingItem = items->Array.find(item => item.productId == productId)
    switch existingItem {
    | Some(_) =>
      items->Array.map(item =>
        if item.productId == productId {
          {...item, quantity: item.quantity + 1}
        } else {
          item
        }
      )
    | None => Array.concat(items, [{productId, quantity: 1}])
    }
  })
}

let removeFromCart = (productId: int) => {
  Signal.update(cart, items => items->Array.filter(item => item.productId != productId))
}

let updateQuantity = (productId: int, quantity: int) => {
  if quantity <= 0 {
    removeFromCart(productId)
  } else {
    Signal.update(cart, items =>
      items->Array.map(item =>
        if item.productId == productId {
          {...item, quantity}
        } else {
          item
        }
      )
    )
  }
}

let clearCart = () => {
  Signal.set(cart, [])
}

// Checkout actions
let updateFormField = (field: string, value: string) => {
  Signal.update(checkoutForm, form =>
    switch field {
    | "name" => {...form, name: value}
    | "email" => {...form, email: value}
    | "address" => {...form, address: value}
    | "city" => {...form, city: value}
    | "cardNumber" => {...form, cardNumber: value}
    | _ => form
    }
  )
}

let completeOrder = () => {
  Signal.update(orderNumber, n => n + 1)
  Router.push("/order-confirmed", ())
  clearCart()
  Signal.set(checkoutForm, {
    name: "",
    email: "",
    address: "",
    city: "",
    cardNumber: "",
  })
}

// Components
module HomePage = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-4xl mx-auto p-6 text-center")],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "py-12")],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "text-6xl mb-6")],
              ~children=[Component.text("📚")],
              (),
            ),
            Component.h1(
              ~attrs=[Component.attr("class", "text-4xl md:text-5xl font-bold text-stone-900 dark:text-white mb-4")],
              ~children=[Component.text("Welcome to Functional Bookstore")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-xl text-stone-600 dark:text-stone-400 mb-8")],
              ~children=[Component.text("Your premier destination for absurd functional programming literature")],
              (),
            ),
            Router.link(
              ~to="/catalog",
              ~attrs=[Component.attr("class", "inline-block px-8 py-4 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-xl font-semibold text-lg transition-colors")],
              ~children=[Component.text("Browse Our Collection →")],
              (),
            ),
          ],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "grid grid-cols-1 md:grid-cols-3 gap-6 mt-12")],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-6 border-2 border-stone-200 dark:border-stone-700")],
              ~children=[
                Component.div(
                  ~attrs=[Component.attr("class", "text-3xl mb-3")],
                  ~children=[Component.text("📖")],
                  (),
                ),
                Component.h3(
                  ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-2")],
                  ~children=[Component.text("12 Unique Titles")],
                  (),
                ),
                Component.p(
                  ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
                  ~children=[Component.text("From monads to functors, explore our curated collection")],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-6 border-2 border-stone-200 dark:border-stone-700")],
              ~children=[
                Component.div(
                  ~attrs=[Component.attr("class", "text-3xl mb-3")],
                  ~children=[Component.text("🎨")],
                  (),
                ),
                Component.h3(
                  ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-2")],
                  ~children=[Component.text("Fictional Authors")],
                  (),
                ),
                Component.p(
                  ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
                  ~children=[Component.text("Written by legends like Dr. Lambda Calculus")],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-6 border-2 border-stone-200 dark:border-stone-700")],
              ~children=[
                Component.div(
                  ~attrs=[Component.attr("class", "text-3xl mb-3")],
                  ~children=[Component.text("Ƒ")],
                  (),
                ),
                Component.h3(
                  ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-2")],
                  ~children=[Component.text("Functor Currency")],
                  (),
                ),
                Component.p(
                  ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
                  ~children=[Component.text("All prices in our fictional Functor (Ƒ) currency")],
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

module AboutPage = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-3xl mx-auto p-6")],
      ~children=[
        Component.h1(
          ~attrs=[Component.attr("class", "text-4xl font-bold text-stone-900 dark:text-white mb-6")],
          ~children=[Component.text("About Functional Bookstore")],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-8 border-2 border-stone-200 dark:border-stone-700 space-y-6")],
          ~children=[
            Component.p(
              ~attrs=[Component.attr("class", "text-lg text-stone-700 dark:text-stone-300")],
              ~children=[Component.text("Welcome to the Functional Bookstore, your one-stop shop for the most absurd and delightful functional programming literature in the known universe.")],
              (),
            ),
            Component.h2(
              ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-900 dark:text-white mt-6")],
              ~children=[Component.text("Our Mission")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
              ~children=[Component.text("We believe that learning functional programming should be fun, quirky, and filled with clever puns. Our carefully curated collection features fictional books with titles that will make you laugh, think, and perhaps question your life choices.")],
              (),
            ),
            Component.h2(
              ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-900 dark:text-white mt-6")],
              ~children=[Component.text("Why Functors?")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
              ~children=[Component.text("Our currency, the Functor (Ƒ), represents the pure, mappable nature of value itself. Just as a functor maps values through a context, our prices map your desire for knowledge into tangible (albeit fictional) transactions.")],
              (),
            ),
            Component.h2(
              ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-900 dark:text-white mt-6")],
              ~children=[Component.text("Demo Purpose")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
              ~children=[Component.text("This bookstore is a demonstration of Xote's routing capabilities, showcasing multi-page navigation, shopping cart management, and a complete checkout flow. All built with reactive signals and zero dependencies.")],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "pt-6 mt-6 border-t-2 border-stone-200 dark:border-stone-700")],
              ~children=[
                Router.link(
                  ~to="/catalog",
                  ~attrs=[Component.attr("class", "inline-block px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors")],
                  ~children=[Component.text("Start Shopping →")],
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

module Header = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr("class", "bg-white dark:bg-stone-800 border-b-2 border-stone-200 dark:border-stone-700 p-4")
      ],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "max-w-7xl mx-auto flex justify-between items-center")],
          ~children=[
            Router.link(
              ~to="/",
              ~attrs=[Component.attr("class", "flex items-center gap-3 hover:opacity-80 transition-opacity")],
              ~children=[
                Component.span(
                  ~attrs=[Component.attr("class", "text-3xl")],
                  ~children=[Component.text("📚")],
                  (),
                ),
                Component.h1(
                  ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-900 dark:text-white")],
                  ~children=[Component.text("Functional Bookstore")],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "flex items-center gap-2")],
              ~children=[
                Router.link(
                  ~to="/",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let pathname = Signal.get(Router.location).pathname
                      if pathname == "/" {
                        "px-4 py-2 bg-stone-900 dark:bg-stone-700 text-white rounded-lg font-semibold"
                      } else {
                        "px-4 py-2 text-stone-900 dark:text-white hover:bg-stone-100 dark:hover:bg-stone-700 rounded-lg font-semibold transition-colors"
                      }
                    })
                  ],
                  ~children=[Component.text("Home")],
                  (),
                ),
                Router.link(
                  ~to="/catalog",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let pathname = Signal.get(Router.location).pathname
                      if pathname == "/catalog" {
                        "px-4 py-2 bg-stone-900 dark:bg-stone-700 text-white rounded-lg font-semibold"
                      } else {
                        "px-4 py-2 text-stone-900 dark:text-white hover:bg-stone-100 dark:hover:bg-stone-700 rounded-lg font-semibold transition-colors"
                      }
                    })
                  ],
                  ~children=[Component.text("Browse Books")],
                  (),
                ),
                Router.link(
                  ~to="/about",
                  ~attrs=[
                    Component.computedAttr("class", () => {
                      let pathname = Signal.get(Router.location).pathname
                      if pathname == "/about" {
                        "px-4 py-2 bg-stone-900 dark:bg-stone-700 text-white rounded-lg font-semibold"
                      } else {
                        "px-4 py-2 text-stone-900 dark:text-white hover:bg-stone-100 dark:hover:bg-stone-700 rounded-lg font-semibold transition-colors"
                      }
                    })
                  ],
                  ~children=[Component.text("About")],
                  (),
                ),
                Router.link(
                  ~to="/cart",
                  ~attrs=[
                    Component.attr("class", "relative px-4 py-2 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-semibold transition-colors")
                  ],
                  ~children=[
                    Component.text("🛒 Cart"),
                    Component.span(
                      ~attrs=[
                        Component.computedAttr("class", () => {
                          let count = Signal.get(cartItemCount)
                          if count > 0 {
                            "ml-2 px-2 py-1 bg-stone-900 dark:bg-stone-600 text-white text-xs rounded-full"
                          } else {
                            "hidden"
                          }
                        })
                      ],
                      ~children=[Component.textSignal(() => Int.toString(Signal.get(cartItemCount)))],
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
        ),
      ],
      (),
    )
  }
}

module ProductCard = {
  let component = (product: product) => {
    let inCart = Computed.make(() => {
      let item = getCartItem(product.id)
      Option.isSome(item)
    })

    Component.div(
      ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow border-2 border-stone-200 dark:border-stone-700")],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "text-6xl text-center mb-4")],
          ~children=[Component.text(product.cover)],
          (),
        ),
        Component.h3(
          ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-2")],
          ~children=[Component.text(product.title)],
          (),
        ),
        Component.p(
          ~attrs=[Component.attr("class", "text-sm text-stone-600 dark:text-stone-400 mb-2")],
          ~children=[Component.text("by " ++ product.author)],
          (),
        ),
        Component.p(
          ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400 text-sm mb-4 line-clamp-3")],
          ~children=[Component.text(product.description)],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "flex justify-between items-center")],
          ~children=[
            Component.span(
              ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-700 dark:text-stone-300")],
              ~children=[Component.text(formatPrice(product.price))],
              (),
            ),
            Component.button(
              ~attrs=[
                Component.computedAttr("class", () =>
                  if Signal.get(inCart) {
                    "px-4 py-2 bg-green-600 text-white rounded-lg font-semibold"
                  } else {
                    "px-4 py-2 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors"
                  }
                )
              ],
              ~events=[("click", _ => addToCart(product.id))],
              ~children=[
                Component.textSignal(() =>
                  if Signal.get(inCart) {
                    "✓ In Cart"
                  } else {
                    "Add to Cart"
                  }
                )
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

module CatalogView = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-7xl mx-auto p-6")],
      ~children=[
        Component.h2(
          ~attrs=[Component.attr("class", "text-3xl font-bold text-stone-900 dark:text-white mb-6")],
          ~children=[Component.text("Available Books")],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6")],
          ~children=products->Array.map(product => ProductCard.component(product)),
          (),
        ),
      ],
      (),
    )
  }
}

module CartItemRow = {
  let component = (item: cartItem) => {
    let product = getProductById(item.productId)

    switch product {
    | Some(p) =>
      Component.div(
        ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-lg p-4 shadow border-2 border-stone-200 dark:border-stone-700")],
        ~children=[
          Component.div(
            ~attrs=[Component.attr("class", "flex gap-4")],
            ~children=[
              Component.div(
                ~attrs=[Component.attr("class", "text-4xl")],
                ~children=[Component.text(p.cover)],
                (),
              ),
              Component.div(
                ~attrs=[Component.attr("class", "flex-1")],
                ~children=[
                  Component.h3(
                    ~attrs=[Component.attr("class", "font-bold text-stone-900 dark:text-white")],
                    ~children=[Component.text(p.title)],
                    (),
                  ),
                  Component.p(
                    ~attrs=[Component.attr("class", "text-sm text-stone-600 dark:text-stone-400")],
                    ~children=[Component.text("by " ++ p.author)],
                    (),
                  ),
                  Component.p(
                    ~attrs=[Component.attr("class", "text-stone-700 dark:text-stone-300 font-semibold mt-2")],
                    ~children=[Component.text(formatPrice(p.price) ++ " each")],
                    (),
                  ),
                ],
                (),
              ),
              Component.div(
                ~attrs=[Component.attr("class", "flex flex-col items-end gap-2")],
                ~children=[
                  Component.div(
                    ~attrs=[Component.attr("class", "flex items-center gap-2")],
                    ~children=[
                      Component.button(
                        ~attrs=[Component.attr("class", "px-3 py-1 bg-stone-200 dark:bg-stone-700 rounded hover:bg-stone-300 dark:hover:bg-stone-600 font-bold")],
                        ~events=[("click", _ => updateQuantity(p.id, item.quantity - 1))],
                        ~children=[Component.text("-")],
                        (),
                      ),
                      Component.span(
                        ~attrs=[Component.attr("class", "px-4 py-1 bg-stone-100 dark:bg-stone-700 rounded font-semibold text-stone-900 dark:text-white")],
                        ~children=[Component.text(Int.toString(item.quantity))],
                        (),
                      ),
                      Component.button(
                        ~attrs=[Component.attr("class", "px-3 py-1 bg-stone-200 dark:bg-stone-700 rounded hover:bg-stone-300 dark:hover:bg-stone-600 font-bold")],
                        ~events=[("click", _ => updateQuantity(p.id, item.quantity + 1))],
                        ~children=[Component.text("+")],
                        (),
                      ),
                    ],
                    (),
                  ),
                  Component.p(
                    ~attrs=[Component.attr("class", "text-lg font-bold text-stone-900 dark:text-white")],
                    ~children=[Component.text(formatPrice(p.price *. Float.fromInt(item.quantity)))],
                    (),
                  ),
                  Component.button(
                    ~attrs=[Component.attr("class", "text-sm text-red-600 hover:text-red-700 font-semibold")],
                    ~events=[("click", _ => removeFromCart(p.id))],
                    ~children=[Component.text("Remove")],
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
    | None => Component.div(~children=[], ())
    }
  }
}

module CartView = {
  let component = () => {
    let isEmpty = Computed.make(() => Array.length(Signal.get(cart)) == 0)

    Component.div(
      ~attrs=[Component.attr("class", "max-w-4xl mx-auto p-6")],
      ~children=[
        Component.h2(
          ~attrs=[Component.attr("class", "text-3xl font-bold text-stone-900 dark:text-white mb-6")],
          ~children=[Component.text("Shopping Cart")],
          (),
        ),
        Component.div(
          ~attrs=[
            Component.computedAttr("class", () =>
              if Signal.get(isEmpty) {
                "block"
              } else {
                "hidden"
              }
            )
          ],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "text-center py-12")],
              ~children=[
                Component.p(
                  ~attrs=[Component.attr("class", "text-xl text-stone-600 dark:text-stone-400 mb-4")],
                  ~children=[Component.text("Your cart is empty")],
                  (),
                ),
                Router.link(
                  ~to="/catalog",
                  ~attrs=[Component.attr("class", "px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors")],
                  ~children=[Component.text("Browse Books")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        Component.div(
          ~attrs=[
            Component.computedAttr("class", () =>
              if Signal.get(isEmpty) {
                "hidden"
              } else {
                "block"
              }
            )
          ],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "space-y-4 mb-6")],
              ~children=[
                Component.list(cart, item => CartItemRow.component(item))
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "bg-stone-100 dark:bg-stone-800 rounded-lg p-6 border-2 border-stone-300 dark:border-stone-700")],
              ~children=[
                Component.div(
                  ~attrs=[Component.attr("class", "flex justify-between items-center mb-4")],
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-900 dark:text-white")],
                      ~children=[Component.text("Total:")],
                      (),
                    ),
                    Component.span(
                      ~attrs=[Component.attr("class", "text-3xl font-bold text-stone-700 dark:text-stone-300")],
                      ~children=[Component.textSignal(() => formatPrice(Signal.get(cartTotal)))],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~attrs=[Component.attr("class", "flex gap-4")],
                  ~children=[
                    Router.link(
                      ~to="/catalog",
                      ~attrs=[Component.attr("class", "flex-1 px-6 py-3 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-semibold transition-colors text-center")],
                      ~children=[Component.text("Continue Shopping")],
                      (),
                    ),
                    Router.link(
                      ~to="/checkout",
                      ~attrs=[Component.attr("class", "flex-1 px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors text-center")],
                      ~children=[Component.text("Proceed to Checkout")],
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
        ),
      ],
      (),
    )
  }
}

module CheckoutView = {
  let component = () => {
    let handleInput = (field: string, evt: Dom.event) => {
      let value = %raw(`evt.target.value`)
      updateFormField(field, value)
    }

    Component.div(
      ~attrs=[Component.attr("class", "max-w-2xl mx-auto p-6")],
      ~children=[
        Component.h2(
          ~attrs=[Component.attr("class", "text-3xl font-bold text-stone-900 dark:text-white mb-6")],
          ~children=[Component.text("Checkout")],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-6 shadow-lg border-2 border-stone-200 dark:border-stone-700 mb-6")],
          ~children=[
            Component.h3(
              ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-4")],
              ~children=[Component.text("Shipping Information")],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "space-y-4")],
              ~children=[
                Component.div(
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2")],
                      ~children=[Component.text("Full Name")],
                      (),
                    ),
                    Component.input(
                      ~attrs=[
                        Component.attr("type", "text"),
                        Component.attr("class", "w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"),
                        Component.attr("placeholder", "John Doe"),
                      ],
                      ~events=[("input", handleInput("name", _))],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2")],
                      ~children=[Component.text("Email")],
                      (),
                    ),
                    Component.input(
                      ~attrs=[
                        Component.attr("type", "email"),
                        Component.attr("class", "w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"),
                        Component.attr("placeholder", "john@example.com"),
                      ],
                      ~events=[("input", handleInput("email", _))],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2")],
                      ~children=[Component.text("Address")],
                      (),
                    ),
                    Component.input(
                      ~attrs=[
                        Component.attr("type", "text"),
                        Component.attr("class", "w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"),
                        Component.attr("placeholder", "123 Lambda Lane"),
                      ],
                      ~events=[("input", handleInput("address", _))],
                      (),
                    ),
                  ],
                  (),
                ),
                Component.div(
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2")],
                      ~children=[Component.text("City")],
                      (),
                    ),
                    Component.input(
                      ~attrs=[
                        Component.attr("type", "text"),
                        Component.attr("class", "w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"),
                        Component.attr("placeholder", "Functional City"),
                      ],
                      ~events=[("input", handleInput("city", _))],
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
        ),
        Component.div(
          ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-6 shadow-lg border-2 border-stone-200 dark:border-stone-700 mb-6")],
          ~children=[
            Component.h3(
              ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white mb-4")],
              ~children=[Component.text("Payment Information")],
              (),
            ),
            Component.div(
              ~children=[
                Component.span(
                  ~attrs=[Component.attr("class", "block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2")],
                  ~children=[Component.text("Card Number")],
                  (),
                ),
                Component.input(
                  ~attrs=[
                    Component.attr("type", "text"),
                    Component.attr("class", "w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"),
                    Component.attr("placeholder", "1234 5678 9012 3456"),
                  ],
                  ~events=[("input", handleInput("cardNumber", _))],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "bg-stone-100 dark:bg-stone-800 rounded-lg p-6 border-2 border-stone-300 dark:border-stone-700 mb-6")],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "flex justify-between items-center mb-2")],
              ~children=[
                Component.span(
                  ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
                  ~children=[Component.textSignal(() => "Items (" ++ Int.toString(Signal.get(cartItemCount)) ++ ")")],
                  (),
                ),
                Component.span(
                  ~attrs=[Component.attr("class", "font-semibold text-stone-900 dark:text-white")],
                  ~children=[Component.textSignal(() => formatPrice(Signal.get(cartTotal)))],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "flex justify-between items-center mb-2")],
              ~children=[
                Component.span(
                  ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400")],
                  ~children=[Component.text("Shipping")],
                  (),
                ),
                Component.span(
                  ~attrs=[Component.attr("class", "font-semibold text-stone-700 dark:text-stone-300")],
                  ~children=[Component.text("FREE")],
                  (),
                ),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "border-t-2 border-purple-200 dark:border-purple-700 pt-2 mt-2")],
              ~children=[
                Component.div(
                  ~attrs=[Component.attr("class", "flex justify-between items-center")],
                  ~children=[
                    Component.span(
                      ~attrs=[Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white")],
                      ~children=[Component.text("Total:")],
                      (),
                    ),
                    Component.span(
                      ~attrs=[Component.attr("class", "text-2xl font-bold text-stone-700 dark:text-stone-300")],
                      ~children=[Component.textSignal(() => formatPrice(Signal.get(cartTotal)))],
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
        ),
        Component.div(
          ~attrs=[Component.attr("class", "flex gap-4")],
          ~children=[
            Router.link(
              ~to="/cart",
              ~attrs=[Component.attr("class", "flex-1 px-6 py-3 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-semibold transition-colors text-center")],
              ~children=[Component.text("Back to Cart")],
              (),
            ),
            Component.button(
              ~attrs=[Component.attr("class", "flex-1 px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors")],
              ~events=[("click", _ => completeOrder())],
              ~children=[Component.text("Complete Order")],
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

module OrderConfirmedView = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-2xl mx-auto p-6")],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "bg-white dark:bg-stone-800 rounded-xl p-8 shadow-lg border-2 border-stone-300 dark:border-stone-700 text-center")],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "text-6xl mb-4")],
              ~children=[Component.text("✅")],
              (),
            ),
            Component.h2(
              ~attrs=[Component.attr("class", "text-3xl font-bold text-stone-900 dark:text-white mb-4")],
              ~children=[Component.text("Order Confirmed!")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-xl text-stone-600 dark:text-stone-400 mb-2")],
              ~children=[Component.text("Thank you for your order!")],
              (),
            ),
            Component.p(
              ~attrs=[Component.attr("class", "text-lg text-stone-500 dark:text-stone-500 mb-6")],
              ~children=[
                Component.text("Order #"),
                Component.textSignal(() => Int.toString(Signal.get(orderNumber))),
              ],
              (),
            ),
            Component.div(
              ~attrs=[Component.attr("class", "bg-stone-100 dark:bg-stone-700 rounded-lg p-6 mb-6")],
              ~children=[
                Component.p(
                  ~attrs=[Component.attr("class", "text-stone-700 dark:text-stone-300 mb-2")],
                  ~children=[Component.text("Your books are being prepared for shipment.")],
                  (),
                ),
                Component.p(
                  ~attrs=[Component.attr("class", "text-stone-600 dark:text-stone-400 text-sm")],
                  ~children=[Component.text("You will receive a confirmation email shortly.")],
                  (),
                ),
              ],
              (),
            ),
            Router.link(
              ~to="/catalog",
              ~attrs=[Component.attr("class", "px-8 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors")],
              ~children=[Component.text("Continue Shopping")],
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

// Main App
module BookstoreApp = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "min-h-screen bg-stone-50 dark:bg-stone-900")],
      ~children=[
        Header.component(),
        Router.routes([
          {pattern: "/", render: _ => HomePage.component()},
          {pattern: "/catalog", render: _ => CatalogView.component()},
          {pattern: "/about", render: _ => AboutPage.component()},
          {pattern: "/cart", render: _ => CartView.component()},
          {pattern: "/checkout", render: _ => CheckoutView.component()},
          {pattern: "/order-confirmed", render: _ => OrderConfirmedView.component()},
        ]),
      ],
      (),
    )
  }
}
