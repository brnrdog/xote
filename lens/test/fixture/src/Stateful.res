/* Server state handed to the client: one key restored, one the client
   decodes with the wrong codec, one the client asks for that the server never
   sent, and one the server sends that nothing restores. */

let visits = Signal.make(0, ~name="visits")
let _ = SSRContext.onServer(() => Signal.set(visits, 42))
SSRState.sync("visits", visits, SSRState.Codec.int)

let theme = Signal.make(0, ~name="theme")
SSRContext.match(
  ~server=() => SSRState.register("theme", Signal.make("dark"), SSRState.Codec.string),
  ~client=() => SSRState.restore("theme", theme, SSRState.Codec.int),
)

let cart = Signal.make(0, ~name="cart")
let _ = SSRContext.onClient(() => SSRState.restore("cart", cart, SSRState.Codec.int))

let _ = SSRContext.onServer(() => SSRState.register("orphan", Signal.make(true), SSRState.Codec.bool))

let items = Signal.make(["a", "b"], ~name="items")

@xote.component
let make = () =>
  <div id="stateful">
    <p id="visits"> {Signal.get(visits)} </p>
    <p id="cart"> {Signal.get(cart)} </p>
    <ul> {View.eachWithKey(items, item => item, item => <li> {item} </li>)} </ul>
  </div>
