open Xote

// ---- Helper bindings ----
module DomHelpers = {
  type target = {value: string}
  @get external target: Dom.event => target = "target"
  let targetValue = (evt: Dom.event): string => target(evt).value

  @val external setInterval: (unit => unit, int) => int = "setInterval"
  @val external clearInterval: int => unit = "clearInterval"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"

  type clipboard
  @val @scope("navigator") external clipboard: clipboard = "clipboard"
  @send external writeText: (clipboard, string) => Promise.t<unit> = "writeText"

  let copyToClipboard = (text: string): unit => {
    clipboard->writeText(text)->ignore
  }
}

// ---- Feature data ----
type feature = {
  title: string,
  description: string,
  iconName: Basefn.Icon.name,
  linkText: option<string>,
  linkTo: option<string>,
}

let features = [
  {
    title: "Fine-Grained Reactivity",
    description: "Direct DOM updates without a virtual DOM. Automatic dependency tracking means only what changed gets updated.",
    iconName: Basefn.Icon.Star,
    linkText: Some("Learn about Signals"),
    linkTo: Some("/docs/core-concepts/signals"),
  },
  {
    title: "Based on TC39 Signals",
    description: "Aligned with the TC39 Signals proposal. Build with patterns that will become native to JavaScript.",
    iconName: Basefn.Icon.Heart,
    linkText: Some("Read the spec"),
    linkTo: Some("/docs/technical-overview"),
  },
  {
    title: "Type-Safe by Default",
    description: "Built with ReScript's powerful type system. Catch bugs at compile time with sound types and pattern matching.",
    iconName: Basefn.Icon.Check,
    linkText: Some("View API Reference"),
    linkTo: Some("/docs/api/signals"),
  },
  {
    title: "Lightweight & Fast",
    description: "Minimal runtime overhead with no virtual DOM diffing. Components compile to efficient JavaScript.",
    iconName: Basefn.Icon.Download,
    linkText: None,
    linkTo: None,
  },
  {
    title: "JSX Support",
    description: "Full ReScript JSX v4 support for declarative components. Familiar markup with type system safety.",
    iconName: Basefn.Icon.Edit,
    linkText: Some("Component docs"),
    linkTo: Some("/docs/components/overview"),
  },
  {
    title: "Client-Side Router",
    description: "Built-in signal-based router with pattern matching and dynamic routes — no extra dependencies.",
    iconName: Basefn.Icon.ExternalLink,
    linkText: Some("Router guide"),
    linkTo: Some("/docs/router/overview"),
  },
  {
    title: "Server-Side Rendering",
    description: "Full SSR with hydration, state serialization, and environment-aware components — render on the server, hydrate on the client.",
    iconName: Basefn.Icon.Download,
    linkText: Some("SSR guide"),
    linkTo: Some("/docs/advanced/ssr"),
  },
]

// ---- Feature Card ----
module FeatureCard = {
  type props = {feature: feature}

  let make = (props: props) => {
    let {feature: f} = props
    <div class="feature-card">
      <div class="feature-card-icon">
        {Basefn.Icon.make({name: f.iconName, size: Md})}
      </div>
      <h3> {Node.text(f.title)} </h3>
      <p> {Node.text(f.description)} </p>
      {switch (f.linkText, f.linkTo) {
      | (Some(text), Some(to)) =>
        Router.link(
          ~to,
          ~attrs=[Node.attr("class", "feature-card-link")],
          ~children=[
            Node.text(text ++ " "),
            Basefn.Icon.make({name: ChevronRight, size: Sm}),
          ],
          (),
        )
      | _ => Node.fragment([])
      }}
    </div>
  }
}

// ---- Hero ----
module Hero = {
  type props = {}

  let make = (_props: props) => {
    <section class="hero">
      <div class="hero-inner">
        <div class="hero-logo">
          <Logo size=48 color="var(--text-accent)" />
          <span class="hero-logo-text"> {Node.text("xote")} </span>
        </div>
        <h1>
          {Node.text("Build reactive interfaces with ")}
          <em> {Node.text("fine-grained signals")} </em>
          {Node.text(" and ")}
          <em> {Node.text("sound types")} </em>
        </h1>
        <p class="hero-subtitle">
          {Node.text(
            "Xote is a lightweight UI library for ReScript that combines signal-powered reactivity with a minimal component system. No virtual DOM, no diffing \u2014 just precise, efficient updates.",
          )}
        </p>
        <div class="hero-buttons">
          {Router.link(
            ~to="/docs",
            ~attrs=[Node.attr("class", "btn btn-primary")],
            ~children=[
              Node.text("Get Started "),
              Basefn.Icon.make({name: ChevronRight, size: Sm}),
            ],
            (),
          )}
          <a href="https://github.com/brnrdog/xote" target="_blank" class="btn btn-ghost">
            {Basefn.Icon.make({name: GitHub, size: Sm})}
            {Node.text(" View on GitHub")}
          </a>
        </div>
      </div>
    </section>
  }
}

// ---- Features Section ----
module Features = {
  type props = {}

  let make = (_props: props) => {
    <section class="features-section">
      <div class="features-inner">
        <div class="features-heading">
          <h2> {Node.text("Everything you need for reactive UIs")} </h2>
          <p>
            {Node.text(
              "Powerful reactive primitives, a declarative component system, and type safety \u2014 all in a focused package.",
            )}
          </p>
        </div>
        <div class="features-grid">
          {Node.fragment(features->Array.map(f => <FeatureCard feature={f} />))}
        </div>
      </div>
    </section>
  }
}

// ---- Interactive Code Demo ----
module CodeDemo = {
  type props = {}

  module CounterApp = {
    type props = {}
    let make = (_props: props) => {
      {
        let count = Signal.make(0)
        let increment = (_evt: Dom.event) => Signal.update(count, n => n + 1)
        let decrement = (_evt: Dom.event) => Signal.update(count, n => n - 1)
        let reset = (_evt: Dom.event) => Signal.set(count, 0)

        <div class="counter-app">
          <div class="counter-display">
            {Node.signalText(() => Signal.get(count)->Int.toString)}
          </div>
          <div class="counter-buttons">
            <button onClick={decrement} class="counter-btn"> {Node.text("-")} </button>
            <button onClick={reset} class="counter-btn counter-btn-reset">
              {Node.text("Reset")}
            </button>
            <button onClick={increment} class="counter-btn"> {Node.text("+")} </button>
          </div>
        </div>
      }
    }
  }

  module TemperatureApp = {
    type props = {}
    let make = (_props: props) => {
      {
        let celsius = Signal.make(0.0)
        let fahrenheit = Computed.make(() => Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0)
        let kelvin = Computed.make(() => Signal.get(celsius) +. 273.15)

        let handleInput = (evt: Dom.event) => {
          let value = DomHelpers.targetValue(evt)
          switch value->Float.fromString {
          | Some(num) => Signal.set(celsius, num)
          | None => ()
          }
        }

        <div class="temp-app">
          <div class="temp-input-group">
            <label class="temp-label"> {Node.text("Celsius")} </label>
            {Html.input(
              ~attrs=[
                Node.attr("type", "number"),
                Node.attr("class", "temp-input"),
                Node.attr("placeholder", "0"),
              ],
              ~events=[("input", handleInput)],
              (),
            )}
          </div>
          <div class="temp-results">
            <div class="temp-result">
              <span class="temp-result-label"> {Node.text("Fahrenheit")} </span>
              <span class="temp-result-value">
                {Node.signalText(() => Signal.get(fahrenheit)->Float.toFixed(~digits=1))}
              </span>
            </div>
            <div class="temp-result">
              <span class="temp-result-label"> {Node.text("Kelvin")} </span>
              <span class="temp-result-value">
                {Node.signalText(() => Signal.get(kelvin)->Float.toFixed(~digits=1))}
              </span>
            </div>
          </div>
        </div>
      }
    }
  }

  module TimerApp = {
    type props = {}
    let make = (_props: props) => {
      {
        let isRunning = Signal.make(false)
        let seconds = Signal.make(0)

        if SSRContext.isClient {
          Effect.run(() => {
            if Signal.get(isRunning) {
              let id = DomHelpers.setInterval(() => Signal.update(seconds, s => s + 1), 1000)
              Some(() => DomHelpers.clearInterval(id))
            } else {
              None
            }
          })
        }

        let toggleTimer = (_evt: Dom.event) => Signal.update(isRunning, r => !r)
        let resetTimer = (_evt: Dom.event) => {
          Signal.set(isRunning, false)
          Signal.set(seconds, 0)
        }

        <div class="timer-app">
          <div class="timer-display">
            {Node.signalText(() => {
              let s = Signal.get(seconds)
              let mins = s / 60
              let secs = mod(s, 60)
              `${mins->Int.toString->String.padStart(2, "0")}:${secs->Int.toString->String.padStart(2, "0")}`
            })}
          </div>
          <div class="timer-buttons">
            <button onClick={toggleTimer} class="timer-btn timer-btn-primary">
              {Node.signalText(() => Signal.get(isRunning) ? "Pause" : "Start")}
            </button>
            <button onClick={resetTimer} class="timer-btn"> {Node.text("Reset")} </button>
          </div>
        </div>
      }
    }
  }

  let counterCode = `open Xote

let make = () => {
  let count = Signal.make(0)

  let increment = (_evt) =>
    Signal.update(count, n => n + 1)

  let decrement = (_evt) =>
    Signal.update(count, n => n - 1)

  <div class="counter-app">
    <div class="counter-display">
      {Node.signalText(() =>
        Signal.get(count)->Int.toString
      )}
    </div>
    <div class="counter-buttons">
      <button onClick={decrement}>
        {Node.text("-")}
      </button>
      <button onClick={increment}>
        {Node.text("+")}
      </button>
    </div>
  </div>
}`

  let tempCode = `open Xote

let make = () => {
  let celsius = Signal.make(0.0)

  // Computed values auto-update
  let fahrenheit = Computed.make(() =>
    Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0
  )

  let kelvin = Computed.make(() =>
    Signal.get(celsius) +. 273.15
  )

  <div class="temp-app">
    <label> {Node.text("Celsius")} </label>
    {Html.input(
      ~attrs=[Node.attr("type", "number")],
      ~events=[("input", handleInput)],
      (),
    )}
    <span>
      {Node.signalText(() =>
        Signal.get(fahrenheit)
          ->Float.toFixed(~digits=1)
      )}
    </span>
  </div>
}`

  let timerCode = `open Xote

let make = () => {
  let isRunning = Signal.make(false)
  let seconds = Signal.make(0)

  // Effect with cleanup callback
  Effect.run(() => {
    if Signal.get(isRunning) {
      let id = setInterval(
        () => Signal.update(seconds, s => s + 1),
        1000
      )
      // Cleanup: clear interval
      Some(() => clearInterval(id))
    } else {
      None
    }
  })

  <button onClick={toggleTimer}>
    {Node.signalText(() =>
      Signal.get(isRunning)
        ? "Pause" : "Start"
    )}
  </button>
}`

  let make = (_props: props) => {
    let activeTab = Signal.make("counter")
    let copied = Signal.make(false)

    let setTab = (tab: string) => (_evt: Dom.event) => Signal.set(activeTab, tab)

    let handleCopy = (_evt: Dom.event) => {
      let snippet = switch Signal.peek(activeTab) {
      | "counter" => counterCode
      | "temperature" => tempCode
      | _ => timerCode
      }
      DomHelpers.copyToClipboard(snippet)
      Signal.set(copied, true)
      let _ = DomHelpers.setTimeout(() => Signal.set(copied, false), 2000)
    }

    <section class="code-demo-section">
      <div class="code-demo-inner">
        <div class="code-demo-heading">
          <h2> {Node.text("Signals, Computeds, and Effects")} </h2>
          <p>
            {Node.text(
              "Three powerful building blocks for seamless reactivity. Your mental model stays simple and predictable.",
            )}
          </p>
        </div>
        <div class="code-demo-container">
          <div class="code-editor-pane">
            <div class="code-editor-tabs">
              {Node.element(
                "div",
                ~attrs=[
                  Node.computedAttr("class", () =>
                    "code-editor-tab" ++ (Signal.get(activeTab) == "counter" ? " active" : "")
                  ),
                ],
                ~events=[("click", setTab("counter"))],
                ~children=[Node.text("Counter.res")],
                (),
              )}
              {Node.element(
                "div",
                ~attrs=[
                  Node.computedAttr("class", () =>
                    "code-editor-tab" ++ (Signal.get(activeTab) == "temperature" ? " active" : "")
                  ),
                ],
                ~events=[("click", setTab("temperature"))],
                ~children=[Node.text("Temperature.res")],
                (),
              )}
              {Node.element(
                "div",
                ~attrs=[
                  Node.computedAttr("class", () =>
                    "code-editor-tab" ++ (Signal.get(activeTab) == "timer" ? " active" : "")
                  ),
                ],
                ~events=[("click", setTab("timer"))],
                ~children=[Node.text("Timer.res")],
                (),
              )}
            </div>
            <div class="code-editor-body">
              {Node.element(
                "button",
                ~attrs=[
                  Node.computedAttr("class", () =>
                    "code-copy-btn" ++ (Signal.get(copied) ? " copied" : "")
                  ),
                ],
                ~events=[("click", handleCopy)],
                ~children=[
                  Node.signalFragment(
                    Computed.make(() =>
                      Signal.get(copied)
                        ? [Basefn.Icon.make({name: Check, size: Sm}), Node.text(" Copied")]
                        : [Basefn.Icon.make({name: Copy, size: Sm}), Node.text(" Copy")]
                    ),
                  ),
                ],
                (),
              )}
              <pre class="code-editor-pre">
                <code>
                  {Node.signalFragment(
                    Computed.make(() => {
                      let code = switch Signal.get(activeTab) {
                      | "counter" => counterCode
                      | "temperature" => tempCode
                      | _ => timerCode
                      }
                      [SyntaxHighlight.highlight(code)]
                    }),
                  )}
                </code>
              </pre>
            </div>
          </div>
          <div class="code-preview-pane">
            <div class="code-preview-header">
              <div class="browser-dots">
                <span class="browser-dot browser-dot-red" />
                <span class="browser-dot browser-dot-yellow" />
                <span class="browser-dot browser-dot-green" />
              </div>
              <div class="browser-url"> {Node.text("localhost:5173")} </div>
            </div>
            <div class="code-preview-body">
              {Node.signalFragment(
                Computed.make(() =>
                  switch Signal.get(activeTab) {
                  | "counter" => [<CounterApp />]
                  | "temperature" => [<TemperatureApp />]
                  | _ => [<TimerApp />]
                  }
                ),
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  }
}

// ---- Community Section ----
module Community = {
  type props = {}

  let make = (_props: props) => {
    <section class="community-section">
      <div class="community-inner">
        <h2> {Node.text("Join the community")} </h2>
        <p>
          {Node.text(
            "Xote is open source and built for developers who value simplicity, type safety, and fine-grained reactivity.",
          )}
        </p>
        <div class="community-links">
          <a href="https://github.com/brnrdog/xote" target="_blank" class="btn btn-ghost">
            {Basefn.Icon.make({name: GitHub, size: Sm})}
            {Node.text(" GitHub")}
          </a>
          <a href="https://www.npmjs.com/package/xote" target="_blank" class="btn btn-ghost">
            {Basefn.Icon.make({name: Download, size: Sm})}
            {Node.text(" npm")}
          </a>
          {Router.link(
            ~to="/demos",
            ~attrs=[Node.attr("class", "btn btn-ghost")],
            ~children=[
              Basefn.Icon.make({name: Star, size: Sm}),
              Node.text(" Demos"),
            ],
            (),
          )}
        </div>
      </div>
    </section>
  }
}

// ---- Main page component ----
type props = {}

let make = (_props: props) => {
  <Layout children={Node.fragment([<Hero />, <Features />, <CodeDemo />, <Community />])} />
}
