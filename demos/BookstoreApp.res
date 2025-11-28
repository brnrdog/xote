/* Bookstore demo using JSX syntax - showcases routing and e-commerce flow */

open Xote

// Initialize router
let _ = Router.init()

// Navigate to home on first load if we're at the HTML file path
let _ = Effect.run(() => {
  let pathname = Signal.get(Router.location).pathname

  // Handle various paths where the HTML file might be served
  // - Local: /bookstore.html or /demos/bookstore.html
  // - GitHub Pages: /xote/demos/bookstore.html
  if (
    pathname == "/bookstore.html" ||
    pathname == "/demos/bookstore.html" ||
    pathname == "/xote/demos/bookstore.html"
  ) {
    Router.replace("/", ())
  }
  None
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
    | Some(p) => total +. p.price *. Float.fromInt(item.quantity)
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
  Signal.set(
    checkoutForm,
    {
      name: "",
      email: "",
      address: "",
      city: "",
      cardNumber: "",
    },
  )
}

/* Header Component using JSX */
let header = () => {
  <div class="bg-white dark:bg-stone-800 border-b-2 border-stone-200 dark:border-stone-700 p-4">
    <div class="max-w-7xl mx-auto flex justify-between items-center">
      {Router.link(
        ~to="/",
        ~attrs=[
          Component.attr("class", "flex items-center gap-3 hover:opacity-80 transition-opacity"),
        ],
        ~children=[
          <span class="text-3xl"> {Component.text("📚")} </span>,
          <h1 class="text-2xl font-bold text-stone-900 dark:text-white">
            {Component.text("Functional Bookstore")}
          </h1>,
        ],
        (),
      )}
      <div class="flex items-center gap-2">
        {Router.link(
          ~to="/",
          ~attrs=[
            Component.computedAttr("class", () => {
              let pathname = Signal.get(Router.location).pathname
              if pathname == "/" {
                "px-4 py-2 bg-stone-900 dark:bg-stone-700 text-white rounded-lg font-semibold"
              } else {
                "px-4 py-2 text-stone-900 dark:text-white hover:bg-stone-100 dark:hover:bg-stone-700 rounded-lg font-semibold transition-colors"
              }
            }),
          ],
          ~children=[Component.text("Home")],
          (),
        )}
        {Router.link(
          ~to="/catalog",
          ~attrs=[
            Component.computedAttr("class", () => {
              let pathname = Signal.get(Router.location).pathname
              if pathname == "/catalog" {
                "px-4 py-2 bg-stone-900 dark:bg-stone-700 text-white rounded-lg font-semibold"
              } else {
                "px-4 py-2 text-stone-900 dark:text-white hover:bg-stone-100 dark:hover:bg-stone-700 rounded-lg font-semibold transition-colors"
              }
            }),
          ],
          ~children=[Component.text("Browse Books")],
          (),
        )}
        {Router.link(
          ~to="/about",
          ~attrs=[
            Component.computedAttr("class", () => {
              let pathname = Signal.get(Router.location).pathname
              if pathname == "/about" {
                "px-4 py-2 bg-stone-900 dark:bg-stone-700 text-white rounded-lg font-semibold"
              } else {
                "px-4 py-2 text-stone-900 dark:text-white hover:bg-stone-100 dark:hover:bg-stone-700 rounded-lg font-semibold transition-colors"
              }
            }),
          ],
          ~children=[Component.text("About")],
          (),
        )}
        {Router.link(
          ~to="/cart",
          ~attrs=[
            Component.attr(
              "class",
              "relative px-4 py-2 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-semibold transition-colors",
            ),
          ],
          ~children=[
            Component.text("🛒 Cart"),
            <span
              class={
                let count = Signal.get(cartItemCount)
                if count > 0 {
                  "ml-2 px-2 py-1 bg-stone-900 dark:bg-stone-600 text-white text-xs rounded-full"
                } else {
                  "hidden"
                }
              }>
              {Component.textSignal(() => Int.toString(Signal.get(cartItemCount)))}
            </span>,
          ],
          (),
        )}
      </div>
    </div>
  </div>
}

/* HomePage Component using JSX */
let homePage = () => {
  <div class="max-w-4xl mx-auto p-6 text-center">
    <div class="py-12">
      <div class="text-6xl mb-6"> {Component.text("📚")} </div>
      <h1 class="text-4xl md:text-5xl font-bold text-stone-900 dark:text-white mb-4">
        {Component.text("Welcome to Functional Bookstore")}
      </h1>
      <p class="text-xl text-stone-600 dark:text-stone-400 mb-8">
        {Component.text("Your premier destination for absurd functional programming literature")}
      </p>
      {Router.link(
        ~to="/catalog",
        ~attrs=[
          Component.attr(
            "class",
            "inline-block px-8 py-4 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-xl font-semibold text-lg transition-colors",
          ),
        ],
        ~children=[Component.text("Browse Our Collection →")],
        (),
      )}
    </div>
    <div class="grid grid-cols-1 md:grid-cols-3 gap-6 mt-12">
      <div
        class="bg-white dark:bg-stone-800 rounded-xl p-6 border-2 border-stone-200 dark:border-stone-700">
        <div class="text-3xl mb-3"> {Component.text("📖")} </div>
        <h3 class="text-xl font-bold text-stone-900 dark:text-white mb-2">
          {Component.text("12 Unique Titles")}
        </h3>
        <p class="text-stone-600 dark:text-stone-400">
          {Component.text("From monads to functors, explore our curated collection")}
        </p>
      </div>
      <div
        class="bg-white dark:bg-stone-800 rounded-xl p-6 border-2 border-stone-200 dark:border-stone-700">
        <div class="text-3xl mb-3"> {Component.text("🎨")} </div>
        <h3 class="text-xl font-bold text-stone-900 dark:text-white mb-2">
          {Component.text("Fictional Authors")}
        </h3>
        <p class="text-stone-600 dark:text-stone-400">
          {Component.text("Written by legends like Dr. Lambda Calculus")}
        </p>
      </div>
      <div
        class="bg-white dark:bg-stone-800 rounded-xl p-6 border-2 border-stone-200 dark:border-stone-700">
        <div class="text-3xl mb-3"> {Component.text("Ƒ")} </div>
        <h3 class="text-xl font-bold text-stone-900 dark:text-white mb-2">
          {Component.text("Functor Currency")}
        </h3>
        <p class="text-stone-600 dark:text-stone-400">
          {Component.text("All prices in our fictional Functor (Ƒ) currency")}
        </p>
      </div>
    </div>
  </div>
}

/* AboutPage Component using JSX */
let aboutPage = () => {
  <div class="max-w-3xl mx-auto p-6">
    <h1 class="text-4xl font-bold text-stone-900 dark:text-white mb-6">
      {Component.text("About Functional Bookstore")}
    </h1>
    <div
      class="bg-white dark:bg-stone-800 rounded-xl p-8 border-2 border-stone-200 dark:border-stone-700 space-y-6">
      <p class="text-lg text-stone-700 dark:text-stone-300">
        {Component.text(
          "Welcome to the Functional Bookstore, your one-stop shop for the most absurd and delightful functional programming literature in the known universe.",
        )}
      </p>
      <h2 class="text-2xl font-bold text-stone-900 dark:text-white mt-6">
        {Component.text("Our Mission")}
      </h2>
      <p class="text-stone-600 dark:text-stone-400">
        {Component.text(
          "We believe that learning functional programming should be fun, quirky, and filled with clever puns. Our carefully curated collection features fictional books with titles that will make you laugh, think, and perhaps question your life choices.",
        )}
      </p>
      <h2 class="text-2xl font-bold text-stone-900 dark:text-white mt-6">
        {Component.text("Why Functors?")}
      </h2>
      <p class="text-stone-600 dark:text-stone-400">
        {Component.text(
          "Our currency, the Functor (Ƒ), represents the pure, mappable nature of value itself. Just as a functor maps values through a context, our prices map your desire for knowledge into tangible (albeit fictional) transactions.",
        )}
      </p>
      <h2 class="text-2xl font-bold text-stone-900 dark:text-white mt-6">
        {Component.text("Demo Purpose")}
      </h2>
      <p class="text-stone-600 dark:text-stone-400">
        {Component.text(
          "This bookstore is a demonstration of Xote's routing capabilities, showcasing multi-page navigation, shopping cart management, and a complete checkout flow. All built with reactive signals and zero dependencies.",
        )}
      </p>
      <div class="pt-6 mt-6 border-t-2 border-stone-200 dark:border-stone-700">
        {Router.link(
          ~to="/catalog",
          ~attrs=[
            Component.attr(
              "class",
              "inline-block px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors",
            ),
          ],
          ~children=[Component.text("Start Shopping →")],
          (),
        )}
      </div>
    </div>
  </div>
}

/* ProductCard Component using JSX */
type productCardProps = {product: product}

let productCard = (props: productCardProps) => {
  let inCart = Computed.make(() => {
    let item = getCartItem(props.product.id)
    Option.isSome(item)
  })

  <div
    class="bg-white dark:bg-stone-800 rounded-xl p-6 shadow-lg hover:shadow-xl transition-shadow border-2 border-stone-200 dark:border-stone-700">
    <div class="text-6xl text-center mb-4"> {Component.text(props.product.cover)} </div>
    <h3 class="text-xl font-bold text-stone-900 dark:text-white mb-2">
      {Component.text(props.product.title)}
    </h3>
    <p class="text-sm text-stone-600 dark:text-stone-400 mb-2">
      {Component.text("by " ++ props.product.author)}
    </p>
    <p class="text-stone-600 dark:text-stone-400 text-sm mb-4 line-clamp-3">
      {Component.text(props.product.description)}
    </p>
    <div class="flex justify-between items-center">
      <span class="text-2xl font-bold text-stone-700 dark:text-stone-300">
        {Component.text(formatPrice(props.product.price))}
      </span>
      <button
        class={() =>
          if Signal.get(inCart) {
            "px-4 py-2 bg-green-600 text-white rounded-lg font-semibold"
          } else {
            "px-4 py-2 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors"
          }}
        onClick={_ => addToCart(props.product.id)}>
        {Component.textSignal(() =>
          if Signal.get(inCart) {
            "✓ In Cart"
          } else {
            "Add to Cart"
          }
        )}
      </button>
    </div>
  </div>
}

/* CatalogView Component using JSX */
let catalogView = () => {
  <div class="max-w-7xl mx-auto p-6">
    <h2 class="text-3xl font-bold text-stone-900 dark:text-white mb-6">
      {Component.text("Available Books")}
    </h2>
    <div class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
      {Component.fragment(products->Array.map(product => productCard({product: product})))}
    </div>
  </div>
}

/* CartItemRow Component using JSX */
type cartItemRowProps = {item: cartItem}

let cartItemRow = (props: cartItemRowProps) => {
  let product = getProductById(props.item.productId)

  switch product {
  | Some(p) =>
    <div
      class="bg-white dark:bg-stone-800 rounded-lg p-4 shadow border-2 border-stone-200 dark:border-stone-700">
      <div class="flex gap-4">
        <div class="text-4xl"> {Component.text(p.cover)} </div>
        <div class="flex-1">
          <h3 class="font-bold text-stone-900 dark:text-white"> {Component.text(p.title)} </h3>
          <p class="text-sm text-stone-600 dark:text-stone-400">
            {Component.text("by " ++ p.author)}
          </p>
          <p class="text-stone-700 dark:text-stone-300 font-semibold mt-2">
            {Component.text(formatPrice(p.price) ++ " each")}
          </p>
        </div>
        <div class="flex flex-col items-end gap-2">
          <div class="flex items-center gap-2">
            <button
              class="px-3 py-1 bg-stone-200 dark:bg-stone-700 rounded hover:bg-stone-300 dark:hover:bg-stone-600 font-bold"
              onClick={_ => updateQuantity(p.id, props.item.quantity - 1)}>
              {Component.text("-")}
            </button>
            <span
              class="px-4 py-1 bg-stone-100 dark:bg-stone-700 rounded font-semibold text-stone-900 dark:text-white">
              {Component.text(Int.toString(props.item.quantity))}
            </span>
            <button
              class="px-3 py-1 bg-stone-200 dark:bg-stone-700 rounded hover:bg-stone-300 dark:hover:bg-stone-600 font-bold"
              onClick={_ => updateQuantity(p.id, props.item.quantity + 1)}>
              {Component.text("+")}
            </button>
          </div>
          <p class="text-lg font-bold text-stone-900 dark:text-white">
            {Component.text(formatPrice(p.price *. Float.fromInt(props.item.quantity)))}
          </p>
          <button
            class="text-sm text-red-600 hover:text-red-700 font-semibold"
            onClick={_ => removeFromCart(p.id)}>
            {Component.text("Remove")}
          </button>
        </div>
      </div>
    </div>
  | None => <div />
  }
}

/* CartView Component using JSX */
let cartView = () => {
  let isEmpty = Computed.make(() => Array.length(Signal.get(cart)) == 0)

  <div class="max-w-4xl mx-auto p-6">
    <h2 class="text-3xl font-bold text-stone-900 dark:text-white mb-6">
      {Component.text("Shopping Cart")}
    </h2>
    <div
      class={() =>
        if Signal.get(isEmpty) {
          "block"
        } else {
          "hidden"
        }}>
      <div class="text-center py-12">
        <p class="text-xl text-stone-600 dark:text-stone-400 mb-4">
          {Component.text("Your cart is empty")}
        </p>
        {Router.link(
          ~to="/catalog",
          ~attrs=[
            Component.attr(
              "class",
              "px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors",
            ),
          ],
          ~children=[Component.text("Browse Books")],
          (),
        )}
      </div>
    </div>
    <div
      class={() =>
        if Signal.get(isEmpty) {
          "hidden"
        } else {
          "block"
        }}>
      <div class="space-y-4 mb-6">
        {Component.list(cart, item => cartItemRow({item: item}))}
      </div>
      <div
        class="bg-stone-100 dark:bg-stone-800 rounded-lg p-6 border-2 border-stone-300 dark:border-stone-700">
        <div class="flex justify-between items-center mb-4">
          <span class="text-2xl font-bold text-stone-900 dark:text-white">
            {Component.text("Total:")}
          </span>
          <span class="text-3xl font-bold text-stone-700 dark:text-stone-300">
            {Component.textSignal(() => formatPrice(Signal.get(cartTotal)))}
          </span>
        </div>
        <div class="flex gap-4">
          {Router.link(
            ~to="/catalog",
            ~attrs=[
              Component.attr(
                "class",
                "flex-1 px-6 py-3 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-semibold transition-colors text-center",
              ),
            ],
            ~children=[Component.text("Continue Shopping")],
            (),
          )}
          {Router.link(
            ~to="/checkout",
            ~attrs=[
              Component.attr(
                "class",
                "flex-1 px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors text-center",
              ),
            ],
            ~children=[Component.text("Proceed to Checkout")],
            (),
          )}
        </div>
      </div>
    </div>
  </div>
}

/* CheckoutView Component using JSX */
let checkoutView = () => {
  let handleInput = (field: string, evt: Dom.event) => {
    let value = %raw(`evt.target.value`)
    updateFormField(field, value)
  }

  <div class="max-w-2xl mx-auto p-6">
    <h2 class="text-3xl font-bold text-stone-900 dark:text-white mb-6">
      {Component.text("Checkout")}
    </h2>
    <div
      class="bg-white dark:bg-stone-800 rounded-xl p-6 shadow-lg border-2 border-stone-200 dark:border-stone-700 mb-6">
      <h3 class="text-xl font-bold text-stone-900 dark:text-white mb-4">
        {Component.text("Shipping Information")}
      </h3>
      <div class="space-y-4">
        <div>
          <span class="block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2">
            {Component.text("Full Name")}
          </span>
          <input
            type_="text"
            class="w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"
            placeholder="John Doe"
            onInput={handleInput("name", _)}
          />
        </div>
        <div>
          <span class="block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2">
            {Component.text("Email")}
          </span>
          <input
            type_="email"
            class="w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"
            placeholder="john@example.com"
            onInput={handleInput("email", _)}
          />
        </div>
        <div>
          <span class="block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2">
            {Component.text("Address")}
          </span>
          <input
            type_="text"
            class="w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"
            placeholder="123 Lambda Lane"
            onInput={handleInput("address", _)}
          />
        </div>
        <div>
          <span class="block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2">
            {Component.text("City")}
          </span>
          <input
            type_="text"
            class="w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"
            placeholder="Functional City"
            onInput={handleInput("city", _)}
          />
        </div>
      </div>
    </div>
    <div
      class="bg-white dark:bg-stone-800 rounded-xl p-6 shadow-lg border-2 border-stone-200 dark:border-stone-700 mb-6">
      <h3 class="text-xl font-bold text-stone-900 dark:text-white mb-4">
        {Component.text("Payment Information")}
      </h3>
      <div>
        <span class="block text-sm font-semibold text-stone-700 dark:text-stone-300 mb-2">
          {Component.text("Card Number")}
        </span>
        <input
          type_="text"
          class="w-full px-4 py-2 border-2 border-stone-300 dark:border-stone-600 rounded-lg bg-white dark:bg-stone-700 text-stone-900 dark:text-white"
          placeholder="1234 5678 9012 3456"
          onInput={handleInput("cardNumber", _)}
        />
      </div>
    </div>
    <div
      class="bg-stone-100 dark:bg-stone-800 rounded-lg p-6 border-2 border-stone-300 dark:border-stone-700 mb-6">
      <div class="flex justify-between items-center mb-2">
        <span class="text-stone-600 dark:text-stone-400">
          {Component.textSignal(() => "Items (" ++ Int.toString(Signal.get(cartItemCount)) ++ ")")}
        </span>
        <span class="font-semibold text-stone-900 dark:text-white">
          {Component.textSignal(() => formatPrice(Signal.get(cartTotal)))}
        </span>
      </div>
      <div class="flex justify-between items-center mb-2">
        <span class="text-stone-600 dark:text-stone-400"> {Component.text("Shipping")} </span>
        <span class="font-semibold text-stone-700 dark:text-stone-300">
          {Component.text("FREE")}
        </span>
      </div>
      <div class="border-t-2 border-purple-200 dark:border-purple-700 pt-2 mt-2">
        <div class="flex justify-between items-center">
          <span class="text-xl font-bold text-stone-900 dark:text-white">
            {Component.text("Total:")}
          </span>
          <span class="text-2xl font-bold text-stone-700 dark:text-stone-300">
            {Component.textSignal(() => formatPrice(Signal.get(cartTotal)))}
          </span>
        </div>
      </div>
    </div>
    <div class="flex gap-4">
      {Router.link(
        ~to="/cart",
        ~attrs=[
          Component.attr(
            "class",
            "flex-1 px-6 py-3 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 text-stone-900 dark:text-white rounded-lg font-semibold transition-colors text-center",
          ),
        ],
        ~children=[Component.text("Back to Cart")],
        (),
      )}
      <button
        class="flex-1 px-6 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors"
        onClick={_ => completeOrder()}>
        {Component.text("Complete Order")}
      </button>
    </div>
  </div>
}

/* OrderConfirmedView Component using JSX */
let orderConfirmedView = () => {
  <div class="max-w-2xl mx-auto p-6">
    <div
      class="bg-white dark:bg-stone-800 rounded-xl p-8 shadow-lg border-2 border-stone-300 dark:border-stone-700 text-center">
      <div class="text-6xl mb-4"> {Component.text("✅")} </div>
      <h2 class="text-3xl font-bold text-stone-900 dark:text-white mb-4">
        {Component.text("Order Confirmed!")}
      </h2>
      <p class="text-xl text-stone-600 dark:text-stone-400 mb-2">
        {Component.text("Thank you for your order!")}
      </p>
      <p class="text-lg text-stone-500 dark:text-stone-500 mb-6">
        {Component.text("Order #")}
        {Component.textSignal(() => Int.toString(Signal.get(orderNumber)))}
      </p>
      <div class="bg-stone-100 dark:bg-stone-700 rounded-lg p-6 mb-6">
        <p class="text-stone-700 dark:text-stone-300 mb-2">
          {Component.text("Your books are being prepared for shipment.")}
        </p>
        <p class="text-stone-600 dark:text-stone-400 text-sm">
          {Component.text("You will receive a confirmation email shortly.")}
        </p>
      </div>
      {Router.link(
        ~to="/catalog",
        ~attrs=[
          Component.attr(
            "class",
            "px-8 py-3 bg-stone-900 hover:bg-stone-700 dark:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg font-semibold transition-colors",
          ),
        ],
        ~children=[Component.text("Continue Shopping")],
        (),
      )}
    </div>
  </div>
}

/* Main Bookstore App Component using JSX */
let app = () => {
  <div class="min-h-screen bg-stone-50 dark:bg-stone-900">
    {header()}
    {Router.routes([
      {pattern: "/", render: _ => homePage()},
      {pattern: "/catalog", render: _ => catalogView()},
      {pattern: "/about", render: _ => aboutPage()},
      {pattern: "/cart", render: _ => cartView()},
      {pattern: "/checkout", render: _ => checkoutView()},
      {pattern: "/order-confirmed", render: _ => orderConfirmedView()},
    ])}
  </div>
}
