/* Renders differently on the server and the client: a hydration mismatch. */

let name = Signal.make("world", ~name="name")

@xote.component
let make = () =>
  <div id="greeting">
    <h1> {"Hello, " ++ Signal.peek(name)} </h1>
    <p class={SSRContext.isServer ? "server" : "client"}> {SSRContext.isServer ? "rendered on the server" : "rendered in the browser"} </p>
  </div>
