// ---- Browser bindings ----
@val external setTimeout: (unit => unit, int) => int = "setTimeout"
@val external clearTimeout: int => unit = "clearTimeout"

let copyToClipboard = (_text: string) => {
  let _ = %raw(`(() => { try { navigator.clipboard && navigator.clipboard.writeText(_text) } catch (_) {} })()`)
}

let eventValue = (_evt: Dom.event): string => %raw(`_evt.target.value`)
let eventKey = (_evt: Dom.event): string => %raw(`_evt.key`)

// "7.2.0-beta.2" -> "Xote 7.2 beta"
let releaseName = {
  let version = RepoData.latestVersion
  let short = version->String.split(".")->Array.slice(~start=0, ~end=2)->Array.join(".")
  let channel = if version->String.includes("beta") {
    " beta"
  } else if version->String.includes("rc") {
    " RC"
  } else {
    ""
  }
  "Xote " ++ short ++ channel
}

// ---- Shared pieces ----

// The npm install line, with a copy button that confirms for a moment.
module InstallCopy = {
  @xote.component
  let make = () => {
    let copied = Signal.make(false)
    let timer = ref(None)

    let copy = _ => {
      copyToClipboard("npm install xote")
      Signal.set(copied, true)
      timer.contents->Option.forEach(clearTimeout)
      timer := Some(setTimeout(() => Signal.set(copied, false), 1600))
      PostHog.capture("install_copied")
    }

    <div class="install">
      <span class="install-prompt" ariaHidden=true> {View.text("$")} </span>
      <span class="install-command"> {View.text("npm install xote")} </span>
      <button
        type_="button"
        class="install-copy"
        ariaLabel={Signal.get(copied) ? "Copied" : "Copy install command"}
        onClick={copy}>
        {Signal.get(copied) ? View.text("✓") : View.text("Copy")}
      </button>
    </div>
  }
}

let ringIcon =
  <svg width="14" height="14" viewBox="0 0 14 14" ariaHidden=true>
    <circle cx="7" cy="7" r="6" fill="none" stroke="currentColor" strokeWidth="1.2" />
    <circle class="section-eyebrow-dot" cx="7" cy="7" r="2.6" />
  </svg>

// The shared heading for every home section: eyebrow, two-tone title, and a
// short paragraph (plus an optional link) on the right.
module SectionHead = {
  type props = {
    label: string,
    title: string,
    titleMuted: string,
    body: string,
    link?: (string, string),
  }

  let make = (props: props) => {
    <div class="section-head">
      <div class="section-head-main">
        <span class="section-eyebrow"> ringIcon <span> {View.text(props.label)} </span> </span>
        <h2 class="section-title">
          {View.text(props.title ++ " ")}
          <span class="section-title-muted"> {View.text(props.titleMuted)} </span>
        </h2>
      </div>
      <div class="section-head-side">
        <p> {View.text(props.body)} </p>
        {switch props.link {
        | Some((to, label)) =>
          Router.link(
            ~to,
            ~attrs=[View.attr("class", "text-link")],
            ~children=[View.text(label ++ " →")],
            (),
          )
        | None => View.fragment([])
        }}
      </div>
    </div>
  }
}

// ---- Hero ----
module Hero = {
  type props = {}

  let make = (_props: props) => {
    <section class="home-hero" ariaLabel="Introduction">
      <div class="hero-rings" ariaHidden=true />
      <div class="hero-inner">
        {Router.link(
          ~to="/docs/changelog",
          ~attrs=[View.attr("class", "hero-release")],
          ~children=[View.text(releaseName ++ " is out — see what’s new →")],
          (),
        )}
        <h1 class="hero-title">
          {View.text("Signals,")}
          <br />
          {View.text("all the way down.")}
        </h1>
        <p class="hero-lead">
          {View.text(
            "Build applications with fine-grained reactivity while leveraging a robust type system with ReScript.",
          )}
        </p>
        <div class="hero-actions">
          {View.element(
            "span",
            ~events=[("click", _ => PostHog.capture("get_started_clicked"))],
            ~children=[
              Router.link(
                ~to="/docs",
                ~attrs=[View.attr("class", "btn-pill btn-ink btn-lg")],
                ~children=[View.text("Get started →")],
                (),
              ),
            ],
            (),
          )}
          <InstallCopy />
        </div>
      </div>
      <a class="hero-next" href="#examples"> {View.text("↓ See it in code")} </a>
    </section>
  }
}

// ---- Examples: three small programs, each running live next to its code ----

let counterCode = `open Xote

@xote.component
let make = () => {
  let count = Signal.make(0)
  let doubled = Computed.make(() => Signal.get(count) * 2)

  <button onClick={_ => Signal.update(count, n => n + 1)}>
    {"Doubled: " ++ Int.toString(Signal.get(doubled))}
  </button>
}`

let todosCode = `type todo = {id: string, text: string, done: Signal.t<bool>}

let todos = Signal.make([
  {id: "1", text: "Learn signals", done: Signal.make(true)},
  {id: "2", text: "Build something small", done: Signal.make(false)},
])

let left = Computed.make(() =>
  Signal.get(todos)->Array.filter(t => !Signal.get(t.done))->Array.length
)

@xote.component
let make = () =>
  <section>
    <ul>
      {View.eachWithKey(todos, t => t.id, t =>
        <li
          class={Signal.get(t.done) ? "done" : ""}
          onClick={_ => Signal.update(t.done, d => !d)}>
          {View.text(t.text)}
        </li>
      )}
    </ul>
    {Int.toString(Signal.get(left)) ++ " left"}
  </section>`

let autosaveCode = `let draft = Signal.make("")
let status = Signal.make("Idle")

Effect.run(() => {
  let text = Signal.get(draft)
  Signal.set(status, "Saving…")
  let id = setTimeout(() => Signal.set(status, "Saved: " ++ text), 600)
  Some(() => clearTimeout(id)) // cleanup: runs before the next change
})

@xote.component
let make = () =>
  <div>
    <input
      value={Signal.get(draft)}
      onInput={e => Signal.set(draft, targetValue(e))}
    />
    {Signal.get(status)}
  </div>`

module CounterDemo = {
  @xote.component
  let make = () => {
    let count = Signal.make(0)
    let doubled = Computed.make(() => Signal.get(count) * 2)

    <div class="demo-counter">
      <button type_="button" class="btn-pill btn-soft btn-lg" onClick={_ => Signal.update(count, n => n + 1)}>
        {"Doubled: " ++ Int.toString(Signal.get(doubled))}
      </button>
      <span class="demo-meta"> {"count = " ++ Int.toString(Signal.get(count))} </span>
    </div>
  }
}

module TodosDemo = {
  type todo = {id: string, text: string, done: Signal.t<bool>}

  @xote.component
  let make = () => {
    let todos = Signal.make([
      {id: "1", text: "Learn signals", done: Signal.make(true)},
      {id: "2", text: "Build something small", done: Signal.make(false)},
      {id: "3", text: "Ship it", done: Signal.make(false)},
    ])
    let draft = Signal.make("")
    let nextId = ref(4)
    let left = Computed.make(() =>
      Signal.get(todos)->Array.filter(t => !Signal.get(t.done))->Array.length
    )

    let add = () => {
      let text = Signal.peek(draft)->String.trim
      if text != "" {
        let id = Int.toString(nextId.contents)
        nextId := nextId.contents + 1
        Signal.batch(() => {
          Signal.update(todos, ts => Array.concat(ts, [{id, text, done: Signal.make(false)}]))
          Signal.set(draft, "")
        })
      }
    }

    <div class="demo-todos">
      <div class="demo-row">
        <input
          class="demo-input"
          type_="text"
          placeholder="Add a task"
          ariaLabel="New task"
          value={Signal.get(draft)}
          onInput={e => Signal.set(draft, eventValue(e))}
          onKeyDown={e => eventKey(e) == "Enter" ? add() : ()}
        />
        <button type_="button" class="btn-pill btn-soft" onClick={_ => add()}>
          {View.text("Add")}
        </button>
      </div>
      <ul class="demo-list">
        {View.eachWithKey(todos, t => t.id, t =>
          <li>
            <button
              type_="button"
              class={Signal.get(t.done) ? "demo-todo done" : "demo-todo"}
              onClick={_ => Signal.update(t.done, d => !d)}>
              <span class="demo-todo-box" ariaHidden=true />
              {View.text(t.text)}
            </button>
          </li>
        )}
      </ul>
      <span class="demo-meta">
        {switch Signal.get(left) {
        | 1 => "1 left"
        | n => Int.toString(n) ++ " left"
        }}
      </span>
    </div>
  }
}

module AutosaveDemo = {
  @xote.component
  let make = () => {
    let draft = Signal.make("")
    let status = Signal.make("Idle")
    let saving = Signal.make(false)
    let saves: Signal.t<array<string>> = Signal.make([])

    Effect.run(() => {
      let text = Signal.get(draft)->String.trim
      if text == "" {
        Signal.set(status, "Idle")
        Signal.set(saving, false)
        None
      } else {
        Signal.set(status, "Saving…")
        Signal.set(saving, true)
        let id = setTimeout(() => {
          Signal.batch(() => {
            Signal.set(status, "Saved")
            Signal.set(saving, false)
            Signal.update(saves, list => Array.concat([text], list)->Array.slice(~start=0, ~end=3))
          })
        }, 600)
        Some(() => clearTimeout(id))
      }
    })

    <div class="demo-autosave">
      <label class="demo-label" for_="demo-autosave-input"> {View.text("Draft")} </label>
      <input
        id="demo-autosave-input"
        class="demo-input"
        type_="text"
        placeholder="Write a short note…"
        value={Signal.get(draft)}
        onInput={e => Signal.set(draft, eventValue(e))}
      />
      <div class="demo-status" role="status">
        <span class={Signal.get(saving) ? "demo-dot saving" : Signal.get(status) == "Saved" ? "demo-dot saved" : "demo-dot"} />
        {Signal.get(status)}
      </div>
      <ul class="demo-saves">
        {View.each(saves, text => <li> {View.text("“" ++ text ++ "”")} </li>)}
      </ul>
    </div>
  }
}

type example = {
  id: string,
  label: string,
  file: string,
  code: string,
  caption: string,
}

let examples = [
  {
    id: "counter",
    label: "Counter",
    file: "Counter.res",
    code: counterCode,
    caption: "Click it: only the button’s text changes.",
  },
  {
    id: "todos",
    label: "Todo list",
    file: "Todos.res",
    code: todosCode,
    caption: "Each todo owns a signal, so ticking one updates that item alone.",
  },
  {
    id: "autosave",
    label: "Auto-save",
    file: "Autosave.res",
    code: autosaveCode,
    caption: "Each keystroke re-runs the effect; its cleanup cancels the pending save.",
  },
]

module Examples = {
  type props = {}

  let make = (_props: props) => {
    let selected = Signal.make("counter")

    let tab = (example: example) =>
      View.element(
        "button",
        ~attrs=[
          View.attr("type", "button"),
          View.attr("role", "tab"),
          View.computedAttr("class", () =>
            Signal.get(selected) == example.id ? "examples-tab active" : "examples-tab"
          ),
          View.computedAttr("aria-selected", () =>
            Signal.get(selected) == example.id ? "true" : "false"
          ),
        ],
        ~events=[
          (
            "click",
            _ => {
              Signal.set(selected, example.id)
              PostHog.capture("home_example_selected", ~properties={"example": example.id})
            },
          ),
        ],
        ~children=[View.text(example.label)],
        (),
      )

    let current = Computed.make(() => {
      let id = Signal.get(selected)
      examples->Array.find(e => e.id == id)->Option.getOr(examples->Array.getUnsafe(0))
    })

    <section id="examples" class="home-section" ariaLabel="Examples">
      <SectionHead
        label="Examples"
        title="See some examples."
        titleMuted="Then try it yourself."
        body="Have a quick look at how small applications written in Xote look. Then try it yourself in the playground."
        link=("/docs/learn/signals", "All examples")
      />
      <div class="examples-panel">
        <div class="examples-tabs" role="tablist" ariaLabel="Examples">
          {View.fragment(examples->Array.map(tab))}
          <span class="examples-file"> {View.signalText(() => Signal.get(current).file)} </span>
        </div>
        <div class="examples-body">
          <div class="examples-code">
            {View.signalFragment(
              Computed.make(() => [
                <pre class="examples-pre"> {SyntaxHighlight.highlight(Signal.get(current).code)} </pre>,
              ]),
            )}
          </div>
          <div class="examples-demo">
            <div class="examples-stage">
              {View.signalFragment(
                Computed.make(() =>
                  switch Signal.get(selected) {
                  | "todos" => [<TodosDemo />]
                  | "autosave" => [<AutosaveDemo />]
                  | _ => [<CounterDemo />]
                  }
                ),
              )}
            </div>
            <p class="examples-caption"> {View.signalText(() => Signal.get(current).caption)} </p>
          </div>
        </div>
      </div>
    </section>
  }
}

// ---- How it works + why it matters, sharing one ring background ----

let triadSignalCode = `let count = Signal.make(0)`
let triadComputedCode = `let doubled = Computed.make(() =>
  Signal.get(count) * 2
)`
let triadEffectCode = `Effect.run(() => {
  Console.log(Signal.get(doubled))
  None
})`

module TriadItem = {
  type props = {
    role: string,
    name: string,
    description: string,
    code: string,
    icon: View.node,
    linked: bool,
  }

  let make = (props: props) => {
    <li class="triad-item">
      <div class="triad-row">
        {props.icon}
        {props.linked ? <span class="triad-link" ariaHidden=true /> : View.fragment([])}
      </div>
      <span class="triad-role"> {View.text(props.role)} </span>
      <h3 class="triad-name"> {View.text(props.name)} </h3>
      <p> {View.text(props.description)} </p>
      <pre class="triad-code"> {SyntaxHighlight.highlight(props.code)} </pre>
    </li>
  }
}

let triadIcon = children =>
  <svg class="triad-node" width="64" height="64" viewBox="0 0 64 64" ariaHidden=true>
    <circle class="triad-node-ring" cx="32" cy="32" r="30" />
    {children}
  </svg>

module HowItWorks = {
  type props = {}

  let make = (_props: props) => {
    <section class="home-pane" ariaLabel="How it works">
      <div class="home-pane-inner">
        <SectionHead
          label="How it works"
          title="Meet the triad."
          titleMuted="The core of everything in Xote."
          body="Signals hold state, computed values derive from it, and effects carry changes out to the page. That’s everything you need before you build."
          link=("/docs/learn/signals", "Read the guide")
        />
        <ol class="triad">
          <TriadItem
            role="01 · Source"
            name="Signal"
            description="Holds a value and tells whoever reads it when it changes."
            code=triadSignalCode
            linked=true
            icon={triadIcon(
              View.fragment([
                <circle class="triad-signal-ring" cx="32" cy="32" r="19" />,
                <circle class="triad-signal-dot" cx="32" cy="32" r="9" />,
              ]),
            )}
          />
          <TriadItem
            role="02 · Derived"
            name="Computed"
            description="Derives a value from other signals and keeps it current on its own."
            code=triadComputedCode
            linked=true
            icon={triadIcon(<circle class="triad-shape" cx="32" cy="32" r="15" />)}
          />
          <TriadItem
            role="03 · Reaction"
            name="Effect"
            description="Runs whenever what it reads changes: update the page, save, log."
            code=triadEffectCode
            linked=false
            icon={triadIcon(<path class="triad-shape" d="M32 17 L47 32 L32 47 L17 32 Z" />)}
          />
        </ol>
      </div>
    </section>
  }
}

type benefit = {title: string, body: string}

let benefits = [
  {title: "Fast by default", body: "No virtual DOM. Updates touch only the nodes that changed."},
  {title: "Sound types", body: "ReScript catches mistakes before they reach the browser."},
  {title: "Small surface", body: "Sixteen modules you can keep in your head."},
  {title: "Full stack", body: "Router, SSR and hydration when you need them."},
]

module WhyItMatters = {
  type props = {}

  let make = (_props: props) => {
    <section class="home-section" ariaLabel="Why it matters">
      <SectionHead
        label="Why it matters"
        title="Less to learn and hold."
        titleMuted="Less to break."
        body="A small API on top of a sound type system: fewer concepts to hold in your head, and fewer surprises once it ships."
      />
      <div class="benefits">
        {View.fragment(
          benefits->Array.map(b =>
            <div class="benefit">
              <h3> {View.text(b.title)} </h3>
              <p> {View.text(b.body)} </p>
            </div>
          ),
        )}
      </div>
    </section>
  }
}

// ---- Closing call to action ----
module GetStarted = {
  type props = {}

  let make = (_props: props) => {
    <section class="home-cta" ariaLabel="Get started">
      <div class="home-cta-inner">
        <div class="home-cta-copy">
          <h2>
            {View.text("Start with")}
            <br />
            {View.text("one signal.")}
          </h2>
          <p>
            {View.text("Install the package, add the JSX transform, and render your first component in a few minutes.")}
          </p>
          <div class="home-cta-actions">
            {Router.link(
              ~to="/docs",
              ~attrs=[View.attr("class", "btn-pill btn-ink btn-lg")],
              ~children=[View.text("Read the quick start \u2192")],
              (),
            )}
            <InstallCopy />
          </div>
        </div>
        <img
          class="home-cta-art"
          src="/images/xote-trio.webp"
          alt="Three marmosets in straw hats playing a forr\u00F3 trio on a log: zabumba drum, accordion and triangle"
          width="1115"
          height="640"
          attrs=[View.attr("loading", "lazy"), View.attr("decoding", "async")]
        />
      </div>
    </section>
  }
}

type props = {}

let make = (_props: props) => {
  <Layout
    children={View.fragment([
      <Hero />,
      <Examples />,
      <div class="home-rings-area">
        <HowItWorks />
        <WhyItMatters />
      </div>,
      <GetStarted />,
    ])}
  />
}
