open Xote

// Feature data
type feature = {
  title: string,
  icon: string,
  description: string,
}

let features = [
  {
    title: "Zero Dependencies",
    icon: "📦",
    description: "Pure ReScript implementation with no runtime dependencies. Lightweight and efficient, Xote focuses on what matters most - reactivity.",
  },
  {
    title: "Fine-Grained Reactivity",
    icon: "⚡",
    description: "Direct DOM updates without a virtual DOM. Automatic dependency tracking means only what changed gets updated - no manual subscriptions needed.",
  },
  {
    title: "Based on TC39 Signals",
    icon: "🎯",
    description: "Aligned with the TC39 Signals proposal. Build with patterns that will feel familiar as JavaScript evolves to include native reactivity primitives.",
  },
]

module FeatureCard = {
  type props = {feature: feature}

  let make = (props: props) => {
    let {feature} = props
    <div class="feature-card">
      <div class="feature-icon"> {Component.text(feature.icon)} </div>
      <h3> {Component.text(feature.title)} </h3>
      <p> {Component.text(feature.description)} </p>
    </div>
  }
}

module Hero = {
  type props = {}

  let make = (_props: props) => {
    <section class="hero">
      <div class="hero-container">
        <div class="hero-logo">
          <Logo size=96 color="var(--secondary-color)" />
          <div class="logo"> {Component.text("xote")} </div>
        </div>
        <h1>
          {Component.text("Build user interfaces with ")}
          <span> {Component.text("fine-grained reactivity")} </span>
          {Component.text(" and a ")}
          <span> {Component.text("robust type system")} </span>
        </h1>
        <p class="hero-subtitle">
          {Component.text(
            "Xote brings signal-powered reactivity together with ReScript’s powerful type system to help you build fast, reliable user interfaces with confidence.",
          )}
        </p>
        <div class="hero-buttons">
          <Xote.Router.Link to="/docs" class="button button-primary">
            {Component.text("Get Started")}
          </Xote.Router.Link>
          <Router.Link to="/demos" class="button button-outline">
            {Component.text("View Demos")}
          </Router.Link>
        </div>
      </div>
    </section>
  }
}

// Helper bindings for DOM APIs
module DomHelpers = {
  // Event target value extraction
  type target = {value: string}
  @get external target: Dom.event => target = "target"
  let targetValue = (evt: Dom.event): string => target(evt).value

  // Timer functions
  @val external setInterval: (unit => unit, int) => int = "setInterval"
  @val external clearInterval: int => unit = "clearInterval"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"

  // Clipboard API
  type clipboard
  @val @scope("navigator") external clipboard: clipboard = "clipboard"
  @send external writeText: (clipboard, string) => Promise.t<unit> = "writeText"

  let copyToClipboard = (text: string): unit => {
    clipboard->writeText(text)->ignore
  }
}

// Counter Example Section
module CounterExample = {
  type props = {}

  module CounterApp = {
    type props = {}

    let make = (_props: props) => {
      let count = Signal.make(0)

      let increment = (_evt: Dom.event) => {
        Signal.update(count, n => n + 1)
      }

      let decrement = (_evt: Dom.event) => {
        Signal.update(count, n => n - 1)
      }

      let reset = (_evt: Dom.event) => {
        Signal.set(count, 0)
      }

      <div class="counter-app">
        <div class="counter-display">
          {Component.textSignal(() => Signal.get(count)->Int.toString)}
        </div>
        <div class="counter-buttons">
          <button onClick={decrement} class="counter-btn"> {Component.text("-")} </button>
          <button onClick={reset} class="counter-btn counter-btn-reset">
            {Component.text("Reset")}
          </button>
          <button onClick={increment} class="counter-btn"> {Component.text("+")} </button>
        </div>
      </div>
    }
  }

  module TemperatureApp = {
    type props = {}

    let make = (_props: props) => {
      let celsius = Signal.make(0.0)

      let fahrenheit = Computed.make(() => {
        Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0
      })

      let kelvin = Computed.make(() => {
        Signal.get(celsius) +. 273.15
      })

      let handleInput = (evt: Dom.event) => {
        let value = DomHelpers.targetValue(evt)
        switch value->Float.fromString {
        | Some(num) => Signal.set(celsius, num)
        | None => ()
        }
      }

      <div class="temp-app">
        <div class="temp-input-group">
          <label class="temp-label"> {Component.text("Celsius")} </label>
          {Component.input(
            ~attrs=[
              Component.attr("type", "number"),
              Component.attr("class", "temp-input"),
              Component.attr("placeholder", "0"),
            ],
            ~events=[("input", handleInput)],
            (),
          )}
        </div>
        <div class="temp-results">
          <div class="temp-result">
            <span class="temp-result-label"> {Component.text("Fahrenheit:")} </span>
            <span class="temp-result-value">
              {Component.textSignal(() => Signal.get(fahrenheit)->Float.toFixed(~digits=1))}
            </span>
          </div>
          <div class="temp-result">
            <span class="temp-result-label"> {Component.text("Kelvin:")} </span>
            <span class="temp-result-value">
              {Component.textSignal(() => Signal.get(kelvin)->Float.toFixed(~digits=1))}
            </span>
          </div>
        </div>
      </div>
    }
  }

  module TimerApp = {
    type props = {}

    let make = (_props: props) => {
      let isRunning = Signal.make(false)
      let seconds = Signal.make(0)

      // Effect to run the timer
      let _ = Effect.run(() => {
        if Signal.get(isRunning) {
          let id = DomHelpers.setInterval(() => Signal.update(seconds, s => s + 1), 1000)
          Some(() => DomHelpers.clearInterval(id))
        } else {
          None
        }
      })

      let toggleTimer = (_evt: Dom.event) => {
        Signal.update(isRunning, running => !running)
      }

      let resetTimer = (_evt: Dom.event) => {
        Signal.set(isRunning, false)
        Signal.set(seconds, 0)
      }

      <div class="timer-app">
        <div class="timer-display">
          {Component.textSignal(() => {
            let s = Signal.get(seconds)
            let mins = s / 60
            let secs = mod(s, 60)
            `${mins->Int.toString->String.padStart(2, "0")}:${secs
              ->Int.toString
              ->String.padStart(2, "0")}`
          })}
        </div>
        <div class="timer-buttons">
          <button onClick={toggleTimer} class="timer-btn timer-btn-primary">
            {Component.textSignal(() => Signal.get(isRunning) ? "Pause" : "Start")}
          </button>
          <button onClick={resetTimer} class="timer-btn"> {Component.text("Reset")} </button>
        </div>
      </div>
    }
  }

  let make = (_props: props) => {
    let activeTab = Signal.make("counter")

    let domHelpersSnippet = `// Helper bindings for DOM APIs
module DomHelpers = {
  // Event target value extraction
  type target = {value: string}
  @get external target: Dom.event => target = "target"
  let targetValue = (evt: Dom.event): string =>
    target(evt).value

  // Timer functions
  @val external setInterval: (unit => unit, int) => int = "setInterval"
  @val external clearInterval: int => unit = "clearInterval"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"

  // Clipboard API
  type clipboard
  @val @scope("navigator")
  external clipboard: clipboard = "clipboard"
  @send
  external writeText: (clipboard, string) => Promise.t<unit> = "writeText"

  let copyToClipboard = (text: string): unit => {
    clipboard->writeText(text)->ignore
  }
}`

    let counterSnippet = `open Xote

let make = () => {
  let count = Signal.make(0)

  let increment = (_evt) => {
    Signal.update(count, n => n + 1)
  }

  let decrement = (_evt) => {
    Signal.update(count, n => n - 1)
  }

  let reset = (_evt) => {
    Signal.set(count, 0)
  }

  <div class="counter-app">
    <div class="counter-display">
      {Component.textSignal(() =>
        Signal.get(count)->Int.toString
      )}
    </div>
    <div class="counter-buttons">
      <button onClick={decrement}>
        {Component.text("-")}
      </button>
      <button onClick={reset}>
        {Component.text("Reset")}
      </button>
      <button onClick={increment}>
        {Component.text("+")}
      </button>
    </div>
  </div>
}`

    let tempSnippet = `open Xote

let make = () => {
  let celsius = Signal.make(0.0)

  // Computed values automatically update
  let fahrenheit = Computed.make(() =>
    Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0
  )

  let kelvin = Computed.make(() =>
    Signal.get(celsius) +. 273.15
  )

  let handleInput = (evt) => {
    let value = DomHelpers.targetValue(evt)
    switch value->Float.fromString {
    | Some(num) => Signal.set(celsius, num)
    | None => ()
    }
  }

  <div class="temp-app">
    <div class="temp-input-group">
      <label class="temp-label">
        {Component.text("Celsius")}
      </label>
      {Component.input(
        ~attrs=[
          Component.attr("type", "number"),
          Component.attr("class", "temp-input"),
          Component.attr("placeholder", "0"),
        ],
        ~events=[("input", handleInput)],
        (),
      )}
    </div>
    <div class="temp-results">
      <div class="temp-result">
        <span class="temp-result-label">
          {Component.text("Fahrenheit:")}
        </span>
        <span class="temp-result-value">
          {Component.textSignal(() =>
            Signal.get(fahrenheit)
              ->Float.toFixed(~digits=1)
          )}
        </span>
      </div>
      <div class="temp-result">
        <span class="temp-result-label">
          {Component.text("Kelvin:")}
        </span>
        <span class="temp-result-value">
          {Component.textSignal(() =>
            Signal.get(kelvin)
              ->Float.toFixed(~digits=1)
          )}
        </span>
      </div>
    </div>
  </div>
}`

    let timerSnippet = `open Xote

let make = () => {
  let isRunning = Signal.make(false)
  let seconds = Signal.make(0)

  // Effect runs when isRunning changes
  let _ = Effect.run(() => {
    if Signal.get(isRunning) {
      let id = DomHelpers.setInterval(
        () => Signal.update(seconds, s => s + 1),
        1000
      )

      // Return cleanup function
      Some(() => DomHelpers.clearInterval(id))
    } else {
      None
    }
  })

  let toggle = (_evt) => {
    Signal.update(isRunning, r => !r)
  }

  let reset = (_evt) => {
    Signal.set(isRunning, false)
    Signal.set(seconds, 0)
  }

  <div class="timer-app">
    <div class="timer-display">
      {Component.textSignal(() => {
        let s = Signal.get(seconds)
        let mins = s / 60
        let secs = mod(s, 60)
        let pad = (n) => n->Int.toString
          ->String.padStart(2, "0")
        \`\${pad(mins)}:\${pad(secs)}\`
      })}
    </div>
    <div class="timer-buttons">
      <button
        onClick={toggle}
        class="timer-btn timer-btn-primary"
      >
        {Component.textSignal(() =>
          Signal.get(isRunning)
            ? "Pause"
            : "Start"
        )}
      </button>
      <button onClick={reset} class="timer-btn">
        {Component.text("Reset")}
      </button>
    </div>
  </div>
}`

    let setCounterTab = (_evt: Dom.event) => {
      Signal.set(activeTab, "counter")
    }

    let setTempTab = (_evt: Dom.event) => {
      Signal.set(activeTab, "temperature")
    }

    let setTimerTab = (_evt: Dom.event) => {
      Signal.set(activeTab, "timer")
    }

    let setDomHelpersTab = (_evt: Dom.event) => {
      Signal.set(activeTab, "domhelpers")
    }

    let copied = Signal.make(false)

    let handleCopy = (_evt: Dom.event) => {
      let currentSnippet = switch Signal.get(activeTab) {
      | "counter" => counterSnippet
      | "temperature" => tempSnippet
      | "timer" => timerSnippet
      | _ => domHelpersSnippet
      }

      DomHelpers.copyToClipboard(currentSnippet)
      Signal.set(copied, true)

      let _ = DomHelpers.setTimeout(() => {
        Signal.set(copied, false)
      }, 2000)
    }

    <section class="code-example">
      <div class="container">
        <h3> {Component.text("The Xote Trinity:")} </h3>
        <h2> {Component.text("Signals, Computeds and Effects")} </h2>
        <p class="section-subtitle">
          {Component.text(
            "Enable seamless reactivity with three powerful building blocks: signals, computeds, and effects. Together, they form a simple yet expressive system that keeps your data flowing, your state in sync, and your UI instantly responsive. Your mental model stays simple and predictable.",
          )}
        </p>
        <div class="code-preview">
          <div class="code-editor">
            <div class="editor-header">
              <div class="editor-tabs">
                {Component.element(
                  "div",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      Signal.get(activeTab) == "counter"
                        ? "editor-tab editor-tab-active"
                        : "editor-tab"
                    ),
                  ],
                  ~events=[("click", setCounterTab)],
                  ~children=[Component.text("Counter.res")],
                  (),
                )}
                {Component.element(
                  "div",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      Signal.get(activeTab) == "temperature"
                        ? "editor-tab editor-tab-active"
                        : "editor-tab"
                    ),
                  ],
                  ~events=[("click", setTempTab)],
                  ~children=[Component.text("Temperature.res")],
                  (),
                )}
                {Component.element(
                  "div",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      Signal.get(activeTab) == "timer"
                        ? "editor-tab editor-tab-active"
                        : "editor-tab"
                    ),
                  ],
                  ~events=[("click", setTimerTab)],
                  ~children=[Component.text("Timer.res")],
                  (),
                )}
                {Component.element(
                  "div",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      Signal.get(activeTab) == "domhelpers"
                        ? "editor-tab editor-tab-active"
                        : "editor-tab"
                    ),
                  ],
                  ~events=[("click", setDomHelpersTab)],
                  ~children=[Component.text("DomHelpers.res")],
                  (),
                )}
              </div>
            </div>
            <div class="editor-content-wrapper">
              {Component.button(
                ~attrs=[Component.attr("class", "copy-button")],
                ~events=[("click", handleCopy)],
                ~children=[Component.textSignal(() => Signal.get(copied) ? "Copied!" : "Copy")],
                (),
              )}
              <pre class="editor-content">
                <code>
                  {Component.signalFragment(
                    Computed.make(() => {
                      let tab = Signal.get(activeTab)
                      if tab == "counter" {
                        [SyntaxHighlight.highlight(counterSnippet)]
                      } else if tab == "temperature" {
                        [SyntaxHighlight.highlight(tempSnippet)]
                      } else if tab == "timer" {
                        [SyntaxHighlight.highlight(timerSnippet)]
                      } else {
                        [SyntaxHighlight.highlight(domHelpersSnippet)]
                      }
                    }),
                  )}
                </code>
              </pre>
            </div>
          </div>
          <div class="browser-preview">
            <div class="browser-header">
              <div class="browser-controls">
                <span class="browser-dot browser-dot-red" />
                <span class="browser-dot browser-dot-yellow" />
                <span class="browser-dot browser-dot-green" />
              </div>
              <div class="browser-url"> {Component.text("localhost:5173")} </div>
            </div>
            <div class="browser-content">
              {Component.signalFragment(
                Computed.make(() => {
                  let tab = Signal.get(activeTab)
                  if tab == "counter" {
                    [<CounterApp />]
                  } else if tab == "temperature" {
                    [<TemperatureApp />]
                  } else if tab == "timer" {
                    [<TimerApp />]
                  } else {
                    [
                      <div class="helpers-info">
                        <p>
                          {Component.text(
                            "This module contains external bindings for DOM APIs used in the examples.",
                          )}
                        </p>
                      </div>,
                    ]
                  }
                }),
              )}
            </div>
          </div>
        </div>
      </div>
    </section>
  }
}

// Features section
module Features = {
  type props = {}

  let make = (_props: props) => {
    <section class="features">
      <div class="features-grid">
        {Component.fragment(features->Array.map(f => <FeatureCard feature={f} />))}
      </div>
    </section>
  }
}

// Main homepage component
type props = {}

let make = (_props: props) => {
  <Layout children={Component.fragment([<Hero />, <CounterExample />])} />
}
