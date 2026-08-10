type status = Loading | Ready(string)

let name = Signal.make("Ada")
let active = Signal.make(false)
let status = Signal.make(Loading)
let theme = Signal.make("light")
let count = Signal.make(0)
let mobileOpen = Signal.make(false)
let labels = Signal.make(["one", "two"])
let canvas = Signal.make("canvas-a")
let items = Signal.make(["a", "b"])
module S = Signal

/* Every case is an @xote.component: one annotation derives props (it emits
   @jsx.component) and fine-grains the returned JSX into reactive leaves.
   @jsx.component allows only one component per module, so each lives in its
   own submodule (in real code, one per file). */

/* Case 1: attribute + text leaves become fine-grained, static parts untouched */
module Card = {
  @xote.component
  let make = () => {
    <div class={Signal.get(active) ? "on" : "off"} id="card">
      <span class="static-label"> {View.text("Name:")} </span>
      <View.Text> {`Hello, ${Signal.get(name)}`} </View.Text>
    </div>
  }
}

/* Case 2: control flow in node position -> View.tracked (structural swap) */
module Panel = {
  @xote.component
  let make = () => {
    <div>
      {switch Signal.get(status) {
      | Loading => <span> {View.text("Loading...")} </span>
      | Ready(msg) => <strong> {View.text(msg)} </strong>
      }}
    </div>
  }
}

/* Case 2b: a branch whose leaf reads a *different* signal (theme) than the
   scrutinee (status). Branch decomposition keeps that leaf fine-grained, so
   the switch tracks only `status`: changing `theme` updates just the class and
   leaves the <strong> element in place (no branch rebuild). */
module SwitchLeaf = {
  @xote.component
  let make = () => {
    <div id="switch-leaf">
      {switch Signal.get(status) {
      | Loading => <span> {View.text("Loading...")} </span>
      | Ready(msg) =>
        <strong id="ready-strong" class={Signal.get(theme)}> {View.text(msg)} </strong>
      }}
    </div>
  }
}

/* Case 3: indirect read via a value alias — `let g = Signal.get` */
module Aliased = {
  @xote.component
  let make = () => {
    let g = Signal.get
    <div class={g(active) ? "on" : "off"} id="aliased">
      <View.Text> {`Hi, ${g(name)}`} </View.Text>
    </div>
  }
}

/* Case 4: indirect read via a module alias — `module S = Signal` (top level) */
module ModAliased = {
  @xote.component
  let make = () => {
    <div class={S.get(active) ? "on" : "off"} id="mod-aliased">
      <View.Text> {`Yo, ${S.get(name)}`} </View.Text>
    </div>
  }
}

/* Case 5: indirect read via `open Signal` then a bare `get` */
module OpenAliased = {
  @xote.component
  let make = () => {
    open Signal
    <div class={get(active) ? "on" : "off"} id="open-aliased">
      <View.Text> {`Hey, ${get(name)}`} </View.Text>
    </div>
  }
}

/* Case 6: pipe form — `active->Signal.get` (desugars to Signal.get(active)) */
module Piped = {
  @xote.component
  let make = () => {
    <div class={active->Signal.get ? "on" : "off"} id="piped">
      <View.Text> {`Pipe, ${name->Signal.get}`} </View.Text>
    </div>
  }
}

/* Case 7: a component with a prop — `label` (a prop) stays static while the
   signal reads become reactive leaves. */
module Labeled = {
  @xote.component
  let make = (~label: string) => {
    <div class={Signal.get(active) ? "on" : "off"} id="labeled">
      <View.Text> {`${label}: ${Signal.get(name)}`} </View.Text>
    </div>
  }
}

/* Case 8: pre-existing `() => …` thunks are left alone (not double-wrapped), so
   @xote.component is a safe drop-in on components already written that way. */
module PreThunked = {
  @xote.component
  let make = () => {
    <div class={() => Signal.get(active) ? "on" : "off"} id="pre-thunked">
      <View.Text> {() => `T: ${Signal.get(name)}`} </View.Text>
    </div>
  }
}

/* Case 9: a value already reactive on its own — `MaybeSignal.reactive(Computed…)` —
   reads a signal only inside a nested lambda, so it must NOT be thunked (that
   would wrap a MaybeSignal.t in a function and break attribute rendering). */
module PropWrapped = {
  @xote.component
  let make = () => {
    <div
      class={MaybeSignal.reactive(Computed.make(() => Signal.get(active) ? "on" : "off"))}
      id="prop-wrapped">
      <View.Text> {"x"} </View.Text>
    </div>
  }
}

/* Case 10: a read hidden behind a local helper. The helper's body eagerly reads
   a signal, so it is tracked as reactive and calling it inline stays fine-grained
   (rather than silently compiling to a static, once-evaluated attribute). */
let statusClass = () => Signal.get(active) ? "on" : "off"
module HelperHidden = {
  @xote.component
  let make = () => {
    <div class={statusClass()} id="helper-hidden"> <View.Text> {"hh"} </View.Text> </div>
  }
}

/* Case 11: a *bare* reactive scalar child — no <View.Int>/<View.Text> wrapper.
   The ppx wraps it in View.child, which coerces the eager signal read into a
   reactive text node. This is the value-primitive-free ergonomic default. */
module BareInt = {
  @xote.component
  let make = () => {
    <div id="bare-int"> {Signal.get(count)} </div>
  }
}

/* Case 12: a bare reactive *string* child alongside a static sibling — only the
   text leaf is reactive, the <span> and surrounding element keep their identity. */
module BareString = {
  @xote.component
  let make = () => {
    <div id="bare-string"> <span class="lbl"> {View.text("n: ")} </span> {Signal.get(name)} </div>
  }
}

/* Case 13: a bare *static* scalar child — previously a type error (string in node
   position); View.child now makes it a static text node. */
module BareStatic = {
  @xote.component
  let make = () => {
    <div id="bare-static"> {"literal"} </div>
  }
}

/* Case 14: a bare child that is *already a node* — View.child detects it at
   runtime and passes it through untouched (no double wrapping). */
module BareNode = {
  @xote.component
  let make = () => {
    <div id="bare-node"> {View.text("noded")} </div>
  }
}

/* Case 15: control flow whose branches are bare *scalars* (not nodes). The switch
   is still tracked (structural swap on `status`), but each branch is coerced by
   View.child, so scalar branches no longer need a value primitive. */
module ScalarSwitch = {
  @xote.component
  let make = () => {
    <div id="scalar-switch">
      {switch Signal.get(status) {
      | Loading => "…loading"
      | Ready(msg) => msg
      }}
    </div>
  }
}

/* Case 16: a make whose body is a *fragment* holding two independent reactive
   regions — a canvas element (reads `canvas`) and a nested mobile-backdrop `if`
   (reads `mobileOpen`). Each fragment child is decomposed on its own, so the
   backdrop toggle re-runs only its own View.tracked and leaves the canvas (and
   its content leaf) in place. A regression guard: before fragments were recursed
   into, the whole fragment collapsed into one coarse thunk and toggling the panel
   rebuilt every sibling. */
module Workspace = {
  @xote.component
  let make = () => {
    <>
      <div id="ws-canvas"> {Signal.get(canvas)} </div>
      {if Signal.get(mobileOpen) {
        <div id="ws-backdrop" />
      } else {
        View.null()
      }}
    </>
  }
}

/* Case 17: bare children *directly* in a fragment return (no wrapping element).
   A dropdown-style component whose labels sit next to a static anchor at the
   fragment's top level — each bare read is coerced by View.child in place, so
   the component needs no display:contents root just to make them type. */
module DropdownFragment = {
  @xote.component
  let make = () => {
    <>
      <span id="df-anchor" />
      {Signal.get(name)}
      {() => `#${Signal.get(count)->Int.toString}`}
    </>
  }
}

/* Case 18: a control-flow *branch body* that is itself a fragment of bare labels
   (a dropdown inlined into an `if`, not extracted into its own component). The
   switch is tracked on the toggle, and the fragment branch is decomposed so its
   bare labels are coerced — the anchor outside the `if` keeps its identity. */
module MenuBranch = {
  @xote.component
  let make = () => {
    <div id="mb-host">
      <span id="mb-anchor" />
      {if Signal.get(active) {
        <>
          {Signal.get(name)}
          {View.text(" / ")}
          {Signal.get(count)}
        </>
      } else {
        View.null()
      }}
    </div>
  }
}

/* Case 19: a signal read inside a *polymorphic variant* payload in attribute
   position — `#tone(Signal.get(theme))`. Exercises the Pexp_variant case of
   the eager-read traversal: before it was added, this class compiled to a
   static, once-evaluated attribute with no error. */
module VariantAttr = {
  @xote.component
  let make = () => {
    <div
      id="variant-attr"
      class={switch #tone(Signal.get(theme)) {
      | #tone(t) => "tone-" ++ t
      }}>
      <span id="va-anchor" />
    </div>
  }
}

/* Case 20: a switch whose ONLY signal read sits in a `when` guard. Guards are
   evaluated eagerly alongside the scrutinee, so the switch must still become a
   View.tracked region — before guards were visited by the eager-read traversal,
   this compiled to a once-evaluated static branch with no error. */
module GuardSwitch = {
  @xote.component
  let make = () => {
    let v = 1
    <div id="guard-switch">
      {switch v {
      | _ if Signal.get(active) => <span id="gs-on"> {View.text("on")} </span>
      | _ => <span id="gs-off"> {View.text("off")} </span>
      }}
    </div>
  }
}

/* Case 21: a component inside a signature-constrained module. The structure
   traversal must descend through `module X: Sig = { … }` (Pmod_constraint) —
   before it did, @xote.component was silently left unexpanded there. */
module ConstrainedPanel: {
  @res.jsxComponentProps
  type props = {}
  let make: props => View.node
} = {
  @xote.component
  let make = () => {
    <div id="constrained" class={Signal.get(theme)}> {Signal.get(count)} </div>
  }
}

/* Case 22: a block expression (`{let … ; <span/>}`) in node position. The tail
   JSX must keep fine-grained leaves — before blocks were recursed into, the
   whole block collapsed into one coarse View.child thunk that rebuilt the
   subtree (and lost element identity) on every dependency change. */
module LetBlockChild = {
  @xote.component
  let make = () => {
    <div id="lb-host">
      {
        let label = "L"
        <span id="lb-span" class={Signal.get(theme)}> {View.text(label)} </span>
      }
    </div>
  }
}

/* Cases 23/24: user-component props. A scalar prop that eagerly reads a signal
   is passed through untouched — a deliberate one-shot read into the component's
   typed props record (thunking it would be a type error; pass the signal itself
   for a reactive prop). A prop whose value is itself JSX is node position, so
   its own reactive leaves are decomposed and stay fine-grained. */
module TitleCard = {
  @xote.component
  let make = (~label: string, ~header: View.node) => {
    <div id="title-card">
      <em id="tc-label"> {View.text(label)} </em>
      {header}
    </div>
  }
}

module UseTitleCard = {
  @xote.component
  let make = () => {
    <TitleCard
      label={Signal.get(name)}
      header={<span id="tc-header" class={Signal.get(theme)} />}
    />
  }
}

/* Case 25: shadowing removes a reactive helper. `toneClass` (top level) eagerly
   reads a signal, but the local rebind below is peek-based — the rebind drops
   the name from the reactive-helper set, so `class={toneClass()}` is left as a
   plain, intentionally-static one-shot string. */
let toneClass = () => Signal.get(active) ? "on" : "off"
module PeekShadow = {
  @xote.component
  let make = () => {
    let toneClass = () => Signal.peek(active) ? "peek-on" : "peek-off"
    <div id="peek-shadow" class={toneClass()}> <span id="ps-anchor" /> </div>
  }
}

/* Case 26: a bare mapped-list child — `{Signal.get(items)->Array.map(…)}`. The
   eager read is thunked and View.child re-coerces the *array* result on every
   run (an array-returning thunk must not lock into reactive-text mode). */
module MappedList = {
  @xote.component
  let make = () => {
    <ul id="mapped-list">
      {Signal.get(items)->Array.map(item => <li class="ml-item"> {View.text(item)} </li>)}
    </ul>
  }
}

/* Case 20: control flow on a *plain* condition (a bool prop or local, no signal
   read anywhere in the condition). No View.tracked is needed since the
   structure cannot change, but the branches are still node position: their bare
   children must be coerced. Before the branches were decomposed on this path,
   `{if flag { <b> {"yes"} </b> } else { … }}` failed to compile with
   "This has type: string", pointing at the literal rather than the
   conditional. */
module StaticBranch = {
  @xote.component
  let make = (~flag: bool) =>
    <div id="static-branch">
      {if flag {
        <b id="sb-yes"> {"yes"} </b>
      } else {
        <i id="sb-no"> {"no"} </i>
      }}
      {flag ? "on" : "off"}
    </div>
}

/* Case 21: a plain-condition branch that also holds a reactive leaf. The
   conditional itself is built once; the leaf inside keeps its own reactive
   scope, so changing the signal updates the class without rebuilding. */
module StaticBranchReactiveLeaf = {
  @xote.component
  let make = (~flag: bool) =>
    <div id="sbrl">
      {if flag {
        <b id="sbrl-tag" class={Signal.get(theme)}> {Signal.get(name)} </b>
      } else {
        <i> {"none"} </i>
      }}
    </div>
}

/* Case 22: bare children inside a *render callback*. A prop whose value is a
   function returning JSX (View.For/Value/Maybe's `render`, or any user
   component's callback) is node position once applied, but it is not itself
   JSX, so the traversal used to stop at the callback boundary: nothing inside
   was decomposed and `<span> {item.author} </span>` failed to compile with
   "This has type: string". List rendering is written this way, so the shape is
   everywhere. The reactive leaf below also proves decomposition really happens
   inside the callback rather than the body being left alone. */
type row = {id: string, author: string}
let rows = Signal.make([{id: "r1", author: "Ada"}, {id: "r2", author: "Bo"}])

module CallbackRows = {
  @xote.component
  let make = () =>
    <ul id="cb-rows">
      <View.For
        each={MaybeSignal.reactive(rows)}
        by={row => row.id}
        render={row =>
          <li class={Signal.get(theme)}>
            <span class="author"> {row.author} </span>
            <span> {" · "} </span>
            {Signal.get(count)}
          </li>}
      />
    </ul>
}

/* Case 23: node-taking runtime helpers called as plain functions. An explicit
   `View.tracked(() => …)` or `View.each(xs, x => …)` is an ordinary
   application, not JSX, so the traversal used to stop at the call: bare
   children inside the callback were never coerced, even though the identical
   markup works when the ppx emits `View.tracked` itself for an `if`/`switch`.
   The callback body is node position, so it is decomposed like any other. */
module HelperCallbacks = {
  @xote.component
  let make = () =>
    <div id="helper-callbacks">
      {View.tracked(() =>
        if Signal.get(active) {
          <p id="hc-on" class={Signal.get(theme)}> {Signal.get(name)} </p>
        } else {
          <p id="hc-off"> {"inactive"} </p>
        }
      )}
      {View.each(labels, label => <span class="hc-item"> {label} </span>)}
    </div>
}

/* Case 24: JSX reached through something other than a child slot. Any JSX the
   component's markup contains is node position, however it is nested: inside an
   array, an application (including the pipe form), a `try`, or bound to a local
   name. Special-casing containers one at a time kept missing the next one, so
   the traversal now walks the whole expression. */
module NestedShapes = {
  @xote.component
  let make = () => {
    /* JSX bound to a local name, and a local helper returning JSX */
    let heading = <h4 id="ns-heading"> {"Nested"} </h4>
    let item = (label: string) => <li class={Signal.get(theme)}> {label} </li>

    <div id="nested-shapes">
      {heading}
      {View.fragment([<span id="ns-arr"> {"array"} </span>])}
      {View.fragment(["a", "b"]->Array.map(a => <em class="ns-map"> {a} </em>))}
      <ul> {View.fragment([item("one"), item("two")])} </ul>
    </div>
  }
}

/* Case 25: a plain helper function that returns markup — a component in all but
   name. In a file that opts in (it contains an @xote.component), helper bodies
   are decomposed like inline markup: bare children are coerced and reads become
   leaves, so a helper needs no value primitives and no manual thunks. */
let helperButton = (label: string) =>
  <button id="helper-btn" class={Signal.get(theme)}> {label} </button>

module HelperHost = {
  @xote.component
  let make = () => <div id="helper-host"> {helperButton("Press")} </div>
}
