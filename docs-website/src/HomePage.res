// ---- Feature data ----
type feature = {
  number: string,
  title: string,
  description: string,
  linkText: option<string>,
  linkTo: option<string>,
}

let features: array<feature> = [
  {
    number: "01",
    title: "Fine-grained reactivity",
    description: "Signals, computeds, and effects recompute only what changed. No virtual DOM diff.",
    linkText: Some("Learn about signals"),
    linkTo: Some("/docs/core-concepts/signals"),
  },
  {
    number: "02",
    title: "Built-in router",
    description: "Signal-based client-side router with pattern matching and dynamic routes.",
    linkText: Some("Router overview"),
    linkTo: Some("/docs/router/overview"),
  },
  {
    number: "03",
    title: "JSX or function API",
    description: "Write components in JSX or plain ReScript. Both compile to the same lightweight nodes.",
    linkText: Some("Component docs"),
    linkTo: Some("/docs/components/overview"),
  },
  {
    number: "04",
    title: "Minimal footprint",
    description: "One runtime dependency. Tree-shakeable per module.",
    linkText: Some("Read the overview"),
    linkTo: Some("/docs/technical-overview"),
  },
]

module FeatureCard = {
  type props = {feature: feature}

  let make = (props: props) => {
    let {feature: f} = props
    <div class="feature-card">
      <div class="feature-card-number"> {Node.text(f.number)} </div>
      <h3> {Node.text(f.title)} </h3>
      <p> {Node.text(f.description)} </p>
      {switch (f.linkText, f.linkTo) {
      | (Some(text), Some(to)) =>
        Router.link(
          ~to,
          ~attrs=[Node.attr("class", "feature-card-link")],
          ~children=[Node.text(text ++ " \u2192")],
          (),
        )
      | _ => Node.fragment([])
      }}
    </div>
  }
}

module Hero = {
  type props = {}

  let make = (_props: props) => {
    <section class="hero">
      <h1 class="hero-display">
        {Node.text("A small UI library for ReScript, with fine-grained reactivity.")}
      </h1>
      <p class="hero-lead">
        {Node.text(
          "Build reactive interfaces with signals, computeds, and effects. Components are plain ReScript functions.",
        )}
      </p>
      <div class="hero-ctas">
        {Router.link(
          ~to="/docs",
          ~attrs=[Node.attr("class", "btn btn-primary")],
          ~children=[Node.text("Get started")],
          (),
        )}
        {Router.link(
          ~to="/docs/core-concepts/signals",
          ~attrs=[Node.attr("class", "btn-secondary-link")],
          ~children=[Node.text("Read the docs \u2192")],
          (),
        )}
      </div>
    </section>
  }
}

module Features = {
  type props = {}

  let make = (_props: props) => {
    <section class="features-section">
      <div class="features-heading">
        <h2> {Node.text("Features")} </h2>
      </div>
      <div class="features-grid">
        {Node.fragment(features->Array.map(f => <FeatureCard feature={f} />))}
      </div>
    </section>
  }
}

module CodeExample = {
  type props = {}

  let counterCode = `open Xote

let make = () => {
  let count = Signal.make(0)

  let increment = (_evt) => Signal.update(count, n => n + 1)
  let decrement = (_evt) => Signal.update(count, n => n - 1)

  <div class="counter">
    <div> {Node.signalText(() => Signal.get(count)->Int.toString)} </div>
    <button onClick={decrement}> {Node.text("-")} </button>
    <button onClick={increment}> {Node.text("+")} </button>
  </div>
}`

  let make = (_props: props) => {
    <section class="code-example-section">
      <h2> {Node.text("A brief example")} </h2>
      <div class="code-filename"> {Node.text("counter.res")} </div>
      <pre>
        <code> {SyntaxHighlight.highlight(counterCode)} </code>
      </pre>
    </section>
  }
}

module CommunityClose = {
  type props = {}

  let make = (_props: props) => {
    <section class="community-close">
      <a href="https://github.com/brnrdog/xote" target="_blank" class="btn btn-ghost">
        {Node.text("View on GitHub \u2197")}
      </a>
    </section>
  }
}

type props = {}

let make = (_props: props) => {
  <Layout
    children={Node.fragment([
      <Hero />,
      <Features />,
      <CodeExample />,
      <CommunityClose />,
    ])}
  />
}
