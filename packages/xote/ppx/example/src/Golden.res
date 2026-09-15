/* Traversal-reach cases for the golden assertions in ../golden.mjs.

   Demo.res + verify.mjs prove *behaviour* (leaves are fine-grained, elements
   keep identity). They cannot prove *reach*: JSX the traversal never visits
   still compiles and still renders — just statically, and without even a
   `View.probe` to report it. That is invisible to a runtime test and is how the
   same bug shipped three times ("an expression that ends up in node position
   was not reached by the traversal").

   So these cases are asserted on the *emitted JavaScript* instead. Each uses its
   own signal so an assertion can name exactly one binding, and every case has a
   matching negative assertion — proving the leaf is reactive is only half the
   claim, the other half is that static things stayed static. */

let themeArray = Signal.make("light")
let themeOption = Signal.make("light")
let themeTuple = Signal.make("light")
let themeLambda = Signal.make("light")
let themeDirect = Signal.make("light")
let themeThunked = Signal.make("light")
let open_ = Signal.make(false)

/* --- reach: JSX one container down from the binding ----------------------

   These deliberately use `View.text` rather than a bare `{…}` child, so they
   compile whether or not the traversal reaches them. That matters: a bare child
   here would make an unreached binding a *compile error*, which would mask the
   silent half of the bug behind the loud half. As written, an unreached binding
   still builds and still renders — and the golden assertion is the only thing
   that notices the attribute went static. That is the failure mode being
   guarded. (The loud half is covered by the bare children further down.) */

/* An array of nodes — the single most ordinary way to build a list of markup. */
let rowsInArray = [<li class={Signal.get(themeArray)}> {View.text("row")} </li>]

/* Optional markup. */
let headerInOption = Some(<h1 class={Signal.get(themeOption)}> {View.text("title")} </h1>)

/* A tuple of nodes. */
let cellsInTuple = (
  <th class={Signal.get(themeTuple)}> {View.text("a")} </th>,
  <th> {View.text("b")} </th>,
)

/* JSX inside a nested lambda that is *not* itself a render callback: the
   binding's own body is the `Array.map` call, not JSX. */
let rowsFromLambda = xs =>
  Array.map(xs, x => <li class={Signal.get(themeLambda)}> {View.text(x)} </li>)

/* --- control: the binding that already worked ---------------------------- */

let directJsx = <p class={Signal.get(themeDirect)}> {"direct"} </p>

/* --- negative controls: things that must NOT be rewritten ---------------- */

/* A static attribute stays a plain string — no spurious computed attribute. */
let staticOnly = [<span class="static-class"> {View.text("plain")} </span>]

/* An explicit thunk is already reactive and must not be double-wrapped. */
let preThunked = [<span class={() => Signal.get(themeThunked)}> {View.text("thunked")} </span>]

@xote.component
let make = () =>
  <div>
    {View.fragment(rowsInArray)}
    /* control flow still tracks only its condition */
    {if Signal.get(open_) {
      <span class="open"> {"open"} </span>
    } else {
      View.null()
    }}
  </div>
