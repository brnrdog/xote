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
    path: "/demos/counter",
    source: "https://github.com/brnrdog/xote/blob/main/demos/CounterApp.res",
  },
  {
    title: "Todo List",
    description: "Complete todo app with filters, computed values, and reactive lists",
    path: "/demos/todo",
    source: "https://github.com/brnrdog/xote/blob/main/demos/TodoApp.res",
  },
  {
    title: "Color Mixer",
    description: "RGB color mixing with live preview, format conversions, and palette variations",
    path: "/demos/color-mixer",
    source: "https://github.com/brnrdog/xote/blob/main/demos/ColorMixerApp.res",
  },
  {
    title: "Reaction Game",
    description: "Reflex testing game with timers, statistics, and computed averages",
    path: "/demos/reaction-game",
    source: "https://github.com/brnrdog/xote/blob/main/demos/ReactionGame.res",
  },
  {
    title: "Solitaire",
    description: "Classic Klondike Solitaire with click-to-move gameplay and win detection",
    path: "/demos/solitaire",
    source: "https://github.com/brnrdog/xote/blob/main/demos/SolitaireGame.res",
  },
  {
    title: "Memory Match",
    description: "2-player memory matching game with 10 progressive levels and score tracking",
    path: "/demos/memory-match",
    source: "https://github.com/brnrdog/xote/blob/main/demos/MatchGame.res",
  },
  {
    title: "Functional Bookstore",
    description: "E-commerce app with routing, cart management, checkout flow, and absurd FP-themed books",
    path: "/demos/bookstore",
    source: "https://github.com/brnrdog/xote/blob/main/demos/BookstoreApp.res",
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

// Info alert component
module InfoAlert = {
  type props = {}

  let make = (_props: props) => {
    <div class="alert-info">
      <h4> {Component.text("Running Demos Locally")} </h4>
      <p> {Component.text("To run these demos on your machine:")} </p>
      <ol>
        <li>
          {Component.text("Clone: ")}
          <code> {Component.text("git clone https://github.com/brnrdog/xote.git")} </code>
        </li>
        <li>
          {Component.text("Install: ")}
          <code> {Component.text("npm install")} </code>
        </li>
        <li>
          {Component.text("Compile: ")}
          <code> {Component.text("npm run res:dev")} </code>
        </li>
        <li>
          {Component.text("Dev server: ")}
          <code> {Component.text("npm run dev")} </code>
        </li>
      </ol>
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
          <InfoAlert />
          <div class="demos-grid">
            {Component.fragment(demos->Array.map(d => <DemoCard demo={d} />))}
          </div>
        </div>
      </div>
    }
  />
}
