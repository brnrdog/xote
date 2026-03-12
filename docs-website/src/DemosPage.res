open Xote

// Demo data type
type demo = {
  title: string,
  description: string,
  path: string,
  source: string,
}

let demos = [
  {
    title: "Counter",
    description: "Simple reactive counter with signals and event handlers",
    path: "/docs/demos/counter",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/CounterDemo.res",
  },
  {
    title: "Todo List",
    description: "Complete todo app with filters, computed values, and reactive lists",
    path: "/docs/demos/todo",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/TodoDemo.res",
  },
  {
    title: "Color Mixer",
    description: "RGB color mixing with live preview, format conversions, and palette variations",
    path: "/docs/demos/color-mixer",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/ColorMixerDemo.res",
  },
  {
    title: "Reaction Game",
    description: "Reflex testing game with timers, statistics, and computed averages",
    path: "/docs/demos/reaction-game",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/ReactionGameDemo.res",
  },
  {
    title: "Solitaire",
    description: "Classic Klondike Solitaire with click-to-move gameplay and win detection",
    path: "/docs/demos/solitaire",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/SolitaireDemo.res",
  },
  {
    title: "Memory Match",
    description: "2-player memory matching game with 10 progressive levels and score tracking",
    path: "/docs/demos/memory-match",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/MatchGameDemo.res",
  },
  {
    title: "Functional Bookstore",
    description: "E-commerce app with navigation, cart management, checkout flow, and absurd FP-themed books",
    path: "/docs/demos/bookstore",
    source: "https://github.com/brnrdog/xote/blob/main/docs-website/src/demos/BookstoreDemo.res",
  },
]

// Demo card component
module DemoCard = {
  type props = {demo: demo}

  let make = (props: props) => {
    let {demo} = props
    <div class="demo-card">
      <div class="demo-card-header">
        <h3> {Component.text(demo.title)} </h3>
      </div>
      <div class="demo-card-body">
        <p> {Component.text(demo.description)} </p>
      </div>
      <div class="demo-card-footer">
        {Router.link(
          ~to=demo.path,
          ~attrs=[Component.attr("class", "btn btn-primary")],
          ~children=[
            Component.text("Try Demo "),
            Basefn.Icon.make({name: ChevronRight, size: Sm}),
          ],
          (),
        )}
        <a href={demo.source} target="_blank" class="btn btn-ghost">
          {Basefn.Icon.make({name: GitHub, size: Sm})}
          {Component.text(" Source")}
        </a>
      </div>
    </div>
  }
}

// Main demos page component
type props = {}

let make = (_props: props) => {
  <Layout
    children={
      <div>
        <section class="demos-hero">
          <h1> {Component.text("Demos")} </h1>
          <p>
            {Component.text("Interactive examples showcasing Xote's capabilities")}
          </p>
        </section>
        <div class="demos-container">
          <div class="demos-grid">
            {Component.fragment(demos->Array.map(d => <DemoCard demo={d} />))}
          </div>
        </div>
      </div>
    }
  />
}
