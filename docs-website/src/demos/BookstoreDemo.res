open Xote

// Signal-based view switching (replaces Router)
let currentView = Signal.make("home")

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
    description: "f(g(x))? More like f . g! Learn to stack functions like a master chef stacks pancakes.",
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
let checkoutFormState = Signal.make({
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
  "\u0191" ++ Float.toFixed(price, ~digits=2)
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
  Signal.update(checkoutFormState, form =>
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
  Signal.set(currentView, "order-confirmed")
  clearCart()
  Signal.set(
    checkoutFormState,
    {
      name: "",
      email: "",
      address: "",
      city: "",
      cardNumber: "",
    },
  )
}

// Navigation helper
let navigate = (view: string) => (_evt: Dom.event) => {
  Signal.set(currentView, view)
}

/* Header Component */
let header = () => {
  <div class="bookstore-nav">
    <div style="display: flex; justify-content: space-between; align-items: center;">
      <button class="bookstore-nav-link" onClick={navigate("home")}>
        <span style="font-size: 1.5rem; margin-right: 0.5rem;"> {Component.text("📚")} </span>
        <strong> {Component.text("Functional Bookstore")} </strong>
      </button>
      <div style="display: flex; align-items: center; gap: 0.25rem;">
        <button
          class={() => {
            let view = Signal.get(currentView)
            if view == "home" {
              "bookstore-nav-link active"
            } else {
              "bookstore-nav-link"
            }
          }}
          onClick={navigate("home")}
        >
          {Component.text("Home")}
        </button>
        <button
          class={() => {
            let view = Signal.get(currentView)
            if view == "catalog" {
              "bookstore-nav-link active"
            } else {
              "bookstore-nav-link"
            }
          }}
          onClick={navigate("catalog")}
        >
          {Component.text("Browse Books")}
        </button>
        <button
          class={() => {
            let view = Signal.get(currentView)
            if view == "about" {
              "bookstore-nav-link active"
            } else {
              "bookstore-nav-link"
            }
          }}
          onClick={navigate("about")}
        >
          {Component.text("About")}
        </button>
        <button class="bookstore-nav-link" onClick={navigate("cart")}>
          {Component.text("Cart")}
          <span
            class={() => {
              let count = Signal.get(cartItemCount)
              if count > 0 {
                "bookstore-cart-badge"
              } else {
                "bookstore-cart-badge hidden"
              }
            }}
          >
            {Component.textSignal(() => Int.toString(Signal.get(cartItemCount)))}
          </span>
        </button>
      </div>
    </div>
  </div>
}

/* HomePage Component */
let homePage = () => {
  <div style="text-align: center; padding: 2rem 0;">
    <div style="font-size: 3rem; margin-bottom: 1rem;"> {Component.text("📚")} </div>
    <h2 style="margin: 0 0 0.5rem 0;"> {Component.text("Welcome to Functional Bookstore")} </h2>
    <p style="color: var(--text-muted); margin-bottom: 1.5rem;">
      {Component.text("Your premier destination for absurd functional programming literature")}
    </p>
    <button class="demo-btn demo-btn-primary" onClick={navigate("catalog")}>
      {Component.text("Browse Our Collection")}
    </button>
    <div class="demo-grid-3" style="margin-top: 2rem;">
      <div class="demo-section">
        <div style="font-size: 1.5rem; margin-bottom: 0.5rem;"> {Component.text("📖")} </div>
        <strong> {Component.text("12 Unique Titles")} </strong>
        <p style="color: var(--text-muted); margin: 0.25rem 0 0 0; font-size: 0.875rem;">
          {Component.text("From monads to functors, explore our curated collection")}
        </p>
      </div>
      <div class="demo-section">
        <div style="font-size: 1.5rem; margin-bottom: 0.5rem;"> {Component.text("🎨")} </div>
        <strong> {Component.text("Fictional Authors")} </strong>
        <p style="color: var(--text-muted); margin: 0.25rem 0 0 0; font-size: 0.875rem;">
          {Component.text("Written by legends like Dr. Lambda Calculus")}
        </p>
      </div>
      <div class="demo-section">
        <div style="font-size: 1.5rem; margin-bottom: 0.5rem;">
          {Component.text("\u0191")}
        </div>
        <strong> {Component.text("Functor Currency")} </strong>
        <p style="color: var(--text-muted); margin: 0.25rem 0 0 0; font-size: 0.875rem;">
          {Component.text("All prices in our fictional Functor currency")}
        </p>
      </div>
    </div>
  </div>
}

/* AboutPage Component */
let aboutPage = () => {
  <div style="max-width: 40rem;">
    <h2 style="margin: 0 0 1rem 0;"> {Component.text("About Functional Bookstore")} </h2>
    <div class="demo-section">
      <p>
        {Component.text(
          "Welcome to the Functional Bookstore, your one-stop shop for the most absurd and delightful functional programming literature in the known universe.",
        )}
      </p>
      <h3> {Component.text("Our Mission")} </h3>
      <p style="color: var(--text-muted);">
        {Component.text(
          "We believe that learning functional programming should be fun, quirky, and filled with clever puns. Our carefully curated collection features fictional books with titles that will make you laugh, think, and perhaps question your life choices.",
        )}
      </p>
      <h3> {Component.text("Why Functors?")} </h3>
      <p style="color: var(--text-muted);">
        {Component.text(
          "Our currency, the Functor, represents the pure, mappable nature of value itself. Just as a functor maps values through a context, our prices map your desire for knowledge into tangible (albeit fictional) transactions.",
        )}
      </p>
      <h3> {Component.text("Demo Purpose")} </h3>
      <p style="color: var(--text-muted);">
        {Component.text(
          "This bookstore is a demonstration of Xote's capabilities, showcasing signal-based view switching, shopping cart management, and a complete checkout flow. All built with reactive signals and zero dependencies.",
        )}
      </p>
      <div style="border-top: 1px solid var(--border); padding-top: 1rem; margin-top: 1rem;">
        <button class="demo-btn demo-btn-primary" onClick={navigate("catalog")}>
          {Component.text("Start Shopping")}
        </button>
      </div>
    </div>
  </div>
}

/* ProductCard Component */
type productCardProps = {product: product}

let productCard = (props: productCardProps) => {
  let inCart = Computed.make(() => {
    let item = getCartItem(props.product.id)
    Option.isSome(item)
  })

  <div class="bookstore-product-card">
    <div class="bookstore-product-cover"> {Component.text(props.product.cover)} </div>
    <strong> {Component.text(props.product.title)} </strong>
    <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0.25rem 0;">
      {Component.text("by " ++ props.product.author)}
    </p>
    <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0.25rem 0 0.75rem 0;">
      {Component.text(props.product.description)}
    </p>
    <div style="display: flex; justify-content: space-between; align-items: center; margin-top: auto;">
      <span class="bookstore-product-price">
        {Component.text(formatPrice(props.product.price))}
      </span>
      <button
        class={() =>
          if Signal.get(inCart) {
            "demo-btn demo-btn-secondary"
          } else {
            "demo-btn demo-btn-primary"
          }}
        onClick={_ => addToCart(props.product.id)}
      >
        {Component.textSignal(() =>
          if Signal.get(inCart) {
            "In Cart"
          } else {
            "Add to Cart"
          }
        )}
      </button>
    </div>
  </div>
}

/* CatalogView Component */
let catalogView = () => {
  <div>
    <h2 style="margin: 0 0 1rem 0;"> {Component.text("Available Books")} </h2>
    <div class="bookstore-grid">
      {Component.fragment(products->Array.map(product => productCard({product: product})))}
    </div>
  </div>
}

/* CartItemRow Component */
type cartItemRowProps = {item: cartItem}

let cartItemRow = (props: cartItemRowProps) => {
  let product = getProductById(props.item.productId)

  switch product {
  | Some(p) =>
    <div class="bookstore-cart-item">
      <div style="display: flex; gap: 1rem;">
        <div style="font-size: 2rem;"> {Component.text(p.cover)} </div>
        <div style="flex: 1;">
          <strong> {Component.text(p.title)} </strong>
          <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0.25rem 0;">
            {Component.text("by " ++ p.author)}
          </p>
          <p style="font-weight: 600; margin: 0.5rem 0 0 0;">
            {Component.text(formatPrice(p.price) ++ " each")}
          </p>
        </div>
        <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 0.5rem;">
          <div style="display: flex; align-items: center; gap: 0.5rem;">
            <button
              class="demo-btn demo-btn-secondary"
              style="padding: 0.25rem 0.75rem;"
              onClick={_ => updateQuantity(p.id, props.item.quantity - 1)}
            >
              {Component.text("-")}
            </button>
            <span style="padding: 0.25rem 0.75rem; font-weight: 600;">
              {Component.text(Int.toString(props.item.quantity))}
            </span>
            <button
              class="demo-btn demo-btn-secondary"
              style="padding: 0.25rem 0.75rem;"
              onClick={_ => updateQuantity(p.id, props.item.quantity + 1)}
            >
              {Component.text("+")}
            </button>
          </div>
          <p style="font-size: 1.125rem; font-weight: bold; margin: 0;">
            {Component.text(formatPrice(p.price *. Float.fromInt(props.item.quantity)))}
          </p>
          <button
            style="background: none; border: none; color: var(--danger, #dc2626); cursor: pointer; font-size: 0.875rem; font-weight: 600; padding: 0;"
            onClick={_ => removeFromCart(p.id)}
          >
            {Component.text("Remove")}
          </button>
        </div>
      </div>
    </div>
  | None => <div />
  }
}

/* CartView Component */
let cartView = () => {
  let isEmpty = Computed.make(() => Array.length(Signal.get(cart)) == 0)

  <div>
    <h2 style="margin: 0 0 1rem 0;"> {Component.text("Shopping Cart")} </h2>
    <div
      style={() =>
        if Signal.get(isEmpty) {
          ""
        } else {
          "display: none"
        }}
    >
      <div class="demo-section" style="text-align: center; padding: 2rem 0;">
        <p style="color: var(--text-muted); margin-bottom: 1rem;">
          {Component.text("Your cart is empty")}
        </p>
        <button class="demo-btn demo-btn-primary" onClick={navigate("catalog")}>
          {Component.text("Browse Books")}
        </button>
      </div>
    </div>
    <div
      style={() =>
        if Signal.get(isEmpty) {
          "display: none"
        } else {
          ""
        }}
    >
      <div style="display: flex; flex-direction: column; gap: 0.75rem; margin-bottom: 1.5rem;">
        {Component.list(cart, item => cartItemRow({item: item}))}
      </div>
      <div class="bookstore-summary">
        <div style="display: flex; justify-content: space-between; align-items: center; margin-bottom: 1rem;">
          <span style="font-size: 1.25rem; font-weight: bold;">
            {Component.text("Total:")}
          </span>
          <span style="font-size: 1.5rem; font-weight: bold;">
            {Component.textSignal(() => formatPrice(Signal.get(cartTotal)))}
          </span>
        </div>
        <div style="display: flex; gap: 0.75rem;">
          <button
            class="demo-btn demo-btn-secondary"
            style="flex: 1;"
            onClick={navigate("catalog")}
          >
            {Component.text("Continue Shopping")}
          </button>
          <button
            class="demo-btn demo-btn-primary"
            style="flex: 1;"
            onClick={navigate("checkout")}
          >
            {Component.text("Proceed to Checkout")}
          </button>
        </div>
      </div>
    </div>
  </div>
}

/* CheckoutView Component */
let checkoutView = () => {
  let handleInput = (field: string, _evt: Dom.event) => {
    let value = %raw(`_evt.target.value`)
    updateFormField(field, value)
  }

  <div style="max-width: 40rem;">
    <h2 style="margin: 0 0 1rem 0;"> {Component.text("Checkout")} </h2>
    <div class="demo-section" style="margin-bottom: 1rem;">
      <h3 style="margin: 0 0 1rem 0;"> {Component.text("Shipping Information")} </h3>
      <div class="bookstore-form-group">
        <span class="bookstore-form-label"> {Component.text("Full Name")} </span>
        <input
          type_="text"
          class="bookstore-form-input"
          placeholder="John Doe"
          onInput={handleInput("name", _)}
        />
      </div>
      <div class="bookstore-form-group">
        <span class="bookstore-form-label"> {Component.text("Email")} </span>
        <input
          type_="email"
          class="bookstore-form-input"
          placeholder="john@example.com"
          onInput={handleInput("email", _)}
        />
      </div>
      <div class="bookstore-form-group">
        <span class="bookstore-form-label"> {Component.text("Address")} </span>
        <input
          type_="text"
          class="bookstore-form-input"
          placeholder="123 Lambda Lane"
          onInput={handleInput("address", _)}
        />
      </div>
      <div class="bookstore-form-group">
        <span class="bookstore-form-label"> {Component.text("City")} </span>
        <input
          type_="text"
          class="bookstore-form-input"
          placeholder="Functional City"
          onInput={handleInput("city", _)}
        />
      </div>
    </div>
    <div class="demo-section" style="margin-bottom: 1rem;">
      <h3 style="margin: 0 0 1rem 0;"> {Component.text("Payment Information")} </h3>
      <div class="bookstore-form-group">
        <span class="bookstore-form-label"> {Component.text("Card Number")} </span>
        <input
          type_="text"
          class="bookstore-form-input"
          placeholder="1234 5678 9012 3456"
          onInput={handleInput("cardNumber", _)}
        />
      </div>
    </div>
    <div class="bookstore-summary" style="margin-bottom: 1rem;">
      <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
        <span style="color: var(--text-muted);">
          {Component.textSignal(() => "Items (" ++ Int.toString(Signal.get(cartItemCount)) ++ ")")}
        </span>
        <span style="font-weight: 600;">
          {Component.textSignal(() => formatPrice(Signal.get(cartTotal)))}
        </span>
      </div>
      <div style="display: flex; justify-content: space-between; margin-bottom: 0.5rem;">
        <span style="color: var(--text-muted);"> {Component.text("Shipping")} </span>
        <span style="font-weight: 600;"> {Component.text("FREE")} </span>
      </div>
      <div style="border-top: 1px solid var(--border); padding-top: 0.5rem; margin-top: 0.5rem;">
        <div style="display: flex; justify-content: space-between; align-items: center;">
          <span style="font-size: 1.125rem; font-weight: bold;">
            {Component.text("Total:")}
          </span>
          <span style="font-size: 1.25rem; font-weight: bold;">
            {Component.textSignal(() => formatPrice(Signal.get(cartTotal)))}
          </span>
        </div>
      </div>
    </div>
    <div style="display: flex; gap: 0.75rem;">
      <button class="demo-btn demo-btn-secondary" style="flex: 1;" onClick={navigate("cart")}>
        {Component.text("Back to Cart")}
      </button>
      <button
        class="demo-btn demo-btn-primary" style="flex: 1;" onClick={_ => completeOrder()}
      >
        {Component.text("Complete Order")}
      </button>
    </div>
  </div>
}

/* OrderConfirmedView Component */
let orderConfirmedView = () => {
  <div style="max-width: 32rem; text-align: center;">
    <div class="demo-section">
      <div style="font-size: 3rem; margin-bottom: 1rem;"> {Component.text("✅")} </div>
      <h2 style="margin: 0 0 0.5rem 0;"> {Component.text("Order Confirmed!")} </h2>
      <p style="color: var(--text-muted); margin-bottom: 0.25rem;">
        {Component.text("Thank you for your order!")}
      </p>
      <p style="color: var(--text-muted); margin-bottom: 1.5rem;">
        {Component.text("Order #")}
        {Component.textSignal(() => Int.toString(Signal.get(orderNumber)))}
      </p>
      <div class="bookstore-summary" style="margin-bottom: 1.5rem; text-align: left;">
        <p style="margin: 0 0 0.5rem 0;">
          {Component.text("Your books are being prepared for shipment.")}
        </p>
        <p style="font-size: 0.875rem; color: var(--text-muted); margin: 0;">
          {Component.text("You will receive a confirmation email shortly.")}
        </p>
      </div>
      <button class="demo-btn demo-btn-primary" onClick={navigate("catalog")}>
        {Component.text("Continue Shopping")}
      </button>
    </div>
  </div>
}

/* Main content function */
let content = () => {
  <div class="demo-container">
    {header()}
    <div style="padding: 1rem 0;">
      {Component.signalFragment(Computed.make(() =>
        switch Signal.get(currentView) {
        | "home" => [homePage()]
        | "catalog" => [catalogView()]
        | "about" => [aboutPage()]
        | "cart" => [cartView()]
        | "checkout" => [checkoutView()]
        | "order-confirmed" => [orderConfirmedView()]
        | _ => [homePage()]
        }
      ))}
    </div>
  </div>
}
