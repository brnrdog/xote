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
    title: "Sound type system",
    description: "ReScript catches invalid states at compile time with exhaustive matching and stronger null-safety by default.",
    linkText: Some("Read the introduction"),
    linkTo: Some("/docs"),
  },
  {
    number: "03",
    title: "Minimal footprint",
    description: "A small runtime, tree-shakeable modules, and built-in primitives instead of a stack of add-on packages.",
    linkText: Some("Read the overview"),
    linkTo: Some("/docs/technical-overview"),
  },
  {
    number: "04",
    title: "JSX support + built-in router",
    description: "Write components in JSX and handle routing with first-party primitives instead of stitching the basics together yourself.",
    linkText: Some("View and router"),
    linkTo: Some("/docs/view/overview"),
  },
]

module FeatureCard = {
  type props = {feature: feature}

  let make = (props: props) => {
    let {feature: f} = props
    <div class="feature-card">
      <h3> {View.text(f.title)} </h3>
      <p> {View.text(f.description)} </p>
      {switch (f.linkText, f.linkTo) {
      | (Some(text), Some(to)) =>
        View.element(
          "span",
          ~events=[
            (
              "click",
              _ =>
                PostHog.capture(
                  "feature_card_link_clicked",
                  ~properties={"destination": to, "link_text": text},
                ),
            ),
          ],
          ~children=[
            Router.link(
              ~to,
              ~attrs=[View.attr("class", "feature-card-link")],
              ~children=[View.text(text ++ " \u2192")],
              (),
            ),
          ],
          (),
        )
      | _ => View.fragment([])
      }}
    </div>
  }
}

module HeroBackground = {
  type props = {}
  type rect
  type svgViewBox
  type svgViewBoxBase
  type classList
  type triangleTemplate = {
    id: string,
    points: string,
    cx: float,
    cy: float,
  }
  type triangleState = {
    element: Dom.element,
    cx: float,
    cy: float,
    mutable delayTimeout: option<int>,
    mutable activeTimeout: option<int>,
  }

  let cols = 56
  let rows = 20
  let size = 24
  let svgId = "hero-bg-svg"
  let hoverIdleMs = 600.
  let throttleMs = 140.
  let tau = 6.283185307179586

  @val external getById: string => Nullable.t<Dom.element> = "document.getElementById"
  @val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"
  @val external setTimeout: (unit => unit, float) => int = "setTimeout"
  @val external clearTimeout: int => unit = "clearTimeout"
  @val @scope("performance") external performanceNow: unit => float = "now"
  @val @scope("document.body") external bodyContains: Dom.element => bool = "contains"

  @send
  external addEventListener: (Dom.element, string, Dom.event => unit) => unit = "addEventListener"
  @send
  external removeEventListener: (Dom.element, string, Dom.event => unit) => unit =
    "removeEventListener"
  @send external getBoundingClientRect: Dom.element => rect = "getBoundingClientRect"
  @send external queryWithin: (Dom.element, string) => Nullable.t<Dom.element> = "querySelector"
  @get external rectLeft: rect => float = "left"
  @get external rectTop: rect => float = "top"
  @get external rectWidth: rect => float = "width"
  @get external rectHeight: rect => float = "height"
  @get external clientX: Dom.event => float = "clientX"
  @get external clientY: Dom.event => float = "clientY"
  @get external viewBox: Dom.element => svgViewBox = "viewBox"
  @get external baseVal: svgViewBox => svgViewBoxBase = "baseVal"
  @get external viewBoxWidth: svgViewBoxBase => float = "width"
  @get external viewBoxHeight: svgViewBoxBase => float = "height"
  @get external classList: Dom.element => classList = "classList"
  @send external addClass: (classList, string) => unit = "add"
  @send external removeClass: (classList, string) => unit = "remove"
  @send external toggleClass: (classList, string, bool) => unit = "toggle"

  let clearTimer = (timerRef: ref<option<int>>) => {
    switch timerRef.contents {
    | Some(id) =>
      clearTimeout(id)
      timerRef := None
    | None => ()
    }
  }

  let clearTriangleTimers = (triangle: triangleState) => {
    switch triangle.delayTimeout {
    | Some(id) =>
      clearTimeout(id)
      triangle.delayTimeout = None
    | None => ()
    }
    switch triangle.activeTimeout {
    | Some(id) =>
      clearTimeout(id)
      triangle.activeTimeout = None
    | None => ()
    }
  }

  let resetTriangle = (triangle: triangleState) => {
    clearTriangleTimers(triangle)
    let classes = triangle.element->classList
    classes->removeClass("active")
    classes->removeClass("active-accent")
  }

  let activateTriangle = (~triangle, ~delayMs, ~ttlMs, ~accent) => {
    clearTriangleTimers(triangle)
    let safeDelay = Math.max(0., delayMs)
    let delayId = setTimeout(() => {
      triangle.delayTimeout = None
      let classes = triangle.element->classList
      classes->toggleClass("active-accent", accent)
      classes->addClass("active")
      let activeId = setTimeout(() => {
        triangle.activeTimeout = None
        classes->removeClass("active")
        classes->removeClass("active-accent")
      }, ttlMs)
      triangle.activeTimeout = Some(activeId)
    }, safeDelay)
    triangle.delayTimeout = Some(delayId)
  }

  let makeTriangleTemplates = (): array<triangleTemplate> => {
    let out = []
    for r in 0 to rows - 1 {
      for c in 0 to cols - 1 {
        let x = c * size
        let y = r * size
        let x2 = x + size
        let y2 = y + size
        let fx = Int.toFloat(x)
        let fy = Int.toFloat(y)
        let fx2 = Int.toFloat(x2)
        let fy2 = Int.toFloat(y2)
        let sx = Int.toString(x)
        let sy = Int.toString(y)
        let sx2 = Int.toString(x2)
        let sy2 = Int.toString(y2)
        let cellId = `${Int.toString(r)}-${Int.toString(c)}`
        out->Array.push({
          id: `${cellId}-upper`,
          points: `${sx},${sy} ${sx2},${sy} ${sx},${sy2}`,
          cx: (fx +. fx2 +. fx) /. 3.,
          cy: (fy +. fy +. fy2) /. 3.,
        })
        ->ignore
        out->Array.push({
          id: `${cellId}-lower`,
          points: `${sx2},${sy} ${sx2},${sy2} ${sx},${sy2}`,
          cx: (fx2 +. fx2 +. fx) /. 3.,
          cy: (fy +. fy2 +. fy2) /. 3.,
        })
        ->ignore
      }
    }
    out
  }

  let triangleTemplates = makeTriangleTemplates()
  let width = cols * size
  let height = rows * size
  let viewBoxValue = `0 0 ${Int.toString(width)} ${Int.toString(height)}`

  let hydrateTriangles = (svg: Dom.element): array<triangleState> =>
    triangleTemplates
    ->Array.filterMap(template => {
      let selector = `[data-tri-id="${template.id}"]`
      switch svg->queryWithin(selector)->Nullable.toOption {
      | Some(element) =>
        Some({
          element,
          cx: template.cx,
          cy: template.cy,
          delayTimeout: None,
          activeTimeout: None,
        })
      | None => None
      }
    })

  let findNearestTriangle = (~triangles, ~cx, ~cy) => {
    let nearest: ref<option<triangleState>> = ref(None)
    let nearestD2 = ref(0.)
    triangles->Array.forEach(triangle => {
      let dx = triangle.cx -. cx
      let dy = triangle.cy -. cy
      let d2 = dx *. dx +. dy *. dy
      switch nearest.contents {
      | Some(_) =>
        if d2 < nearestD2.contents {
          nearest := Some(triangle)
          nearestD2 := d2
        }
      | None =>
        nearest := Some(triangle)
        nearestD2 := d2
      }
    })
    nearest.contents
  }

  let triggerRipple = (~triangles, ~seed, ~vbWidth, ~vbHeight, ~throttle, ~idle, ~lastRippleAt) => {
    let now = performanceNow()
    let shouldPropagate =
      if throttle {
        switch lastRippleAt.contents {
        | Some(last) if now -. last < throttleMs =>
          activateTriangle(
            ~triangle=seed,
            ~delayMs=0.,
            ~ttlMs=600.,
            ~accent=Math.random() < 0.18,
          )
          false
        | _ =>
          lastRippleAt := Some(now)
          true
        }
      } else {
        lastRippleAt := Some(now)
        true
      }

    if shouldPropagate {
      let cellVb = (vbWidth /. 42. +. vbHeight /. 15.) /. 2.
      let maxRings = idle ? 5 : 3
      let ringStep = cellVb *. (idle ? 1.4 : 1.2)
      let ringDelay = idle ? 140. : 70.
      let ringDuration = idle ? 520. : 360.
      let biasAngle = idle ? Math.random() *. tau : 0.
      let biasStrength = idle ? 0.55 : 0.

      triangles->Array.forEach(triangle => {
        let dx = triangle.cx -. seed.cx
        let dy = triangle.cy -. seed.cy
        let dist = Math.sqrt(dx *. dx +. dy *. dy)
        let ring = Int.fromFloat(Math.round(dist /. ringStep))
        if ring <= maxRings {
          let probability =
            if idle {
              let directionWeight =
                if dist > 0. {
                  let angle = Math.atan2(~y=dy, ~x=dx)
                  let alignment = Math.cos(angle -. biasAngle)
                  1. +. biasStrength *. alignment
                } else {
                  1.
                }
              if ring == 0 {
                1.
              } else {
                Math.max(0., (0.55 -. Int.toFloat(ring) *. 0.09) *. directionWeight)
              }
            } else if ring == 0 {
              1.
            } else {
              0.35 -. Int.toFloat(ring) *. 0.08
            }

          if Math.random() <= probability {
            let jitter = (Math.random() -. 0.5) *. (idle ? 120. : 60.)
            let ttl =
              ringDuration +.
              Int.toFloat(ring) *. (idle ? 110. : 50.) +.
              Math.random() *. (idle ? 320. : 160.)
            let accentProbability = idle ? 0.12 : 0.18
            let accent = ring > 0 && Math.random() < accentProbability
            activateTriangle(
              ~triangle,
              ~delayMs=Int.toFloat(ring) *. ringDelay +. jitter,
              ~ttlMs=ttl,
              ~accent,
            )
          }
        }
      })
    }
  }

  let makeTriangles = () =>
    triangleTemplates->Array.map(template =>
      View.element(
        "polygon",
        ~attrs=[
          View.attr("points", template.points),
          View.attr("class", "hero-tri"),
          View.attr("data-tri-id", template.id),
        ],
        (),
      )
    )

  let make = (_props: props) => {
    if SSRContext.isClient {
      Effect.run(() => {
        let disposed = ref(false)
        let hoverActive = ref(false)
        let hoverEndTimer: ref<option<int>> = ref(None)
        let idleTimer: ref<option<int>> = ref(None)
        let lastRippleAt: ref<option<float>> = ref(None)
        let mouseMoveHandler: ref<option<Dom.event => unit>> = ref(None)
        let boundSvg: ref<option<Dom.element>> = ref(None)
        let triangles: ref<array<triangleState>> = ref([])

        let scheduleIdle = ref(() => ())
        let cleanup = () => {
          disposed := true
          clearTimer(hoverEndTimer)
          clearTimer(idleTimer)
          triangles.contents->Array.forEach(resetTriangle)
          switch (boundSvg.contents, mouseMoveHandler.contents) {
          | (Some(svg), Some(handler)) => svg->removeEventListener("mousemove", handler)
          | _ => ()
          }
          hoverActive := false
          boundSvg := None
          mouseMoveHandler := None
          triangles := []
        }

        scheduleIdle := () => {
          clearTimer(idleTimer)
          let delay = 900. +. Math.random() *. 1600.
          idleTimer := Some(setTimeout(() => {
            idleTimer := None
            switch boundSvg.contents {
            | Some(svg) if !disposed.contents && bodyContains(svg) =>
              if !hoverActive.contents {
                let readyTriangles = triangles.contents
                let triangleCount = Array.length(readyTriangles)
                if triangleCount > 0 {
                  let index = Int.fromFloat(Math.floor(Math.random() *. Int.toFloat(triangleCount)))
                  switch readyTriangles->Array.get(index) {
                  | Some(seed) =>
                    triggerRipple(
                      ~triangles=readyTriangles,
                      ~seed,
                      ~vbWidth=svg->viewBox->baseVal->viewBoxWidth,
                      ~vbHeight=svg->viewBox->baseVal->viewBoxHeight,
                      ~throttle=false,
                      ~idle=true,
                      ~lastRippleAt,
                    )
                  | None => ()
                  }
                }
              }
              scheduleIdle.contents()
            | _ => ()
            }
          }, delay))
        }

        queueMicrotask(() => {
          if !disposed.contents {
            switch getById(svgId)->Nullable.toOption {
            | Some(svg) =>
              let readyTriangles = hydrateTriangles(svg)
              triangles := readyTriangles
              boundSvg := Some(svg)

              let handler = (evt: Dom.event) => {
                hoverActive := true
                clearTimer(hoverEndTimer)
                hoverEndTimer := Some(setTimeout(() => {
                  hoverEndTimer := None
                  hoverActive := false
                }, hoverIdleMs))

                let rect = svg->getBoundingClientRect
                let width = rect->rectWidth
                let height = rect->rectHeight
                if width > 0. && height > 0. {
                  let vb = svg->viewBox->baseVal
                  let cx = (evt->clientX -. rect->rectLeft) *. (vb->viewBoxWidth /. width)
                  let cy = (evt->clientY -. rect->rectTop) *. (vb->viewBoxHeight /. height)
                  switch findNearestTriangle(~triangles=readyTriangles, ~cx, ~cy) {
                  | Some(seed) =>
                    triggerRipple(
                      ~triangles=readyTriangles,
                      ~seed,
                      ~vbWidth=vb->viewBoxWidth,
                      ~vbHeight=vb->viewBoxHeight,
                      ~throttle=true,
                      ~idle=false,
                      ~lastRippleAt,
                    )
                  | None => ()
                  }
                }
              }

              mouseMoveHandler := Some(handler)
              svg->addEventListener("mousemove", handler)
              scheduleIdle.contents()
            | None => ()
            }
          }
        })

        Some(cleanup)
      })
    }

    View.element(
      "div",
      ~attrs=[View.attr("class", "hero-bg"), View.attr("aria-hidden", "true")],
      ~children=[
        View.element(
          "svg",
          ~attrs=[
            View.attr("id", svgId),
            View.attr("viewBox", viewBoxValue),
            View.attr("preserveAspectRatio", "xMidYMid slice"),
            View.attr("class", "hero-bg-svg"),
          ],
          ~children=makeTriangles(),
          (),
        ),
      ],
      (),
    )
  }
}

module Hero = {
  type props = {}

  let make = (_props: props) => {
    <section class="hero">
      <HeroBackground />
      <h1 class="hero-display">
        {View.text("A ReScript Library for Interactive User Interfaces")}
      </h1>
      <p class="hero-lead">
        {View.text(
          "Build components and web applications with fine-grained reactivity in a sound type system world.",
        )}
      </p>
      <div class="hero-ctas">
        {View.element(
          "span",
          ~events=[("click", _ => PostHog.capture("get_started_clicked"))],
          ~children=[
            Router.link(
              ~to="/docs",
              ~attrs=[View.attr("class", "btn btn-primary")],
              ~children=[View.text("Get started")],
              (),
            ),
          ],
          (),
        )}
        {Router.link(
          ~to="/docs/core-concepts/signals",
          ~attrs=[View.attr("class", "btn-secondary-link")],
          ~children=[View.text("Read the docs \u2192")],
          (),
        )}
      </div>
    </section>
  }
}

module Tutorial = {
  type props = {}

  let step1Code = `type tempUnit = Celsius | Fahrenheit | Kelvin

let symbolFor = u =>
  switch u {
  | Celsius => "°C"
  | Fahrenheit => "°F"
  | Kelvin => "K"
  }

@jsx.component
let make = (~value: float, ~unit: tempUnit) =>
  <div class="temp-display">
    <span class="temp-value">
      <View.Text> {value->Float.toFixed(~digits=1)} </View.Text>
    </span>
    <span class="temp-unit">
      <View.Text> {symbolFor(unit)} </View.Text>
    </span>
  </div>`

  let step2Code = `let celsius = Signal.make(22.0)

let fahrenheit = Computed.make(() =>
  Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0
)
let kelvin = Computed.make(() =>
  Signal.get(celsius) +. 273.15
)

@jsx.component
let make = () =>
  <div class="temp-row">
    <TemperatureDisplay
      value={() => Signal.get(celsius)} unit=Celsius
    />
    <TemperatureDisplay
      value={() => Signal.get(fahrenheit)} unit=Fahrenheit
    />
    <TemperatureDisplay
      value={() => Signal.get(kelvin)} unit=Kelvin
    />
  </div>`

  let step3Code = `let capital = Signal.make(pickRandomCapital())
let celsius = Signal.make(None)

let fahrenheit = Computed.make(() =>
  switch Signal.get(celsius) {
  | Some(c) => Some(c *. 9.0 /. 5.0 +. 32.0)
  | None => None
  }
)

Effect.run(() => {
  let c = Signal.get(capital)
  Signal.set(celsius, None)

  let url =
    \`https://api.open-meteo.com/v1/forecast?\` ++
    \`latitude=\${c.lat}&longitude=\${c.lng}\` ++
    \`&current_weather=true\`

  fetch(url)
  ->Promise.then(r => r->Response.json)
  ->Promise.then(json => {
    Signal.set(celsius, Some(json["current_weather"]["temperature"]))
    Promise.resolve()
  })
  ->ignore

  None
})`

  let stepHeader = (~n, ~title, ~blurb) =>
    <div class="tutorial-step-head">
      <span class="tutorial-step-number"> {View.text(n)} </span>
      <div>
        <h3 class="tutorial-step-title"> {View.text(title)} </h3>
        <p class="tutorial-step-blurb"> {View.text(blurb)} </p>
      </div>
    </div>

  let codeBlock = (~filename, ~code) =>
    <div class="tutorial-code">
      <div class="tutorial-code-filename"> {View.text(filename)} </div>
      <pre class="tutorial-code-pre">
        <code> {SyntaxHighlight.highlight(code)} </code>
      </pre>
    </div>

  let make = (_props: props) => {
    <section class="tutorial-section">
      <div class="tutorial-step">
        {stepHeader(
          ~n="01",
          ~title="Build a presentational view",
          ~blurb="Views are plain functions. TemperatureDisplay takes a value and a unit and renders them in a styled card.",
        )}
        <div class="tutorial-step-body">
          {codeBlock(~filename="TemperatureDisplay.res", ~code=step1Code)}
        </div>
      </div>
      <div class="tutorial-step">
        {stepHeader(
          ~n="02",
          ~title="Add reactivity with signals and computeds",
          ~blurb="One signal holds the Celsius value. Computeds derive Fahrenheit and Kelvin automatically. Move the slider — the display updates without re-rendering the tree.",
        )}
        <div class="tutorial-step-body">
          {codeBlock(~filename="TemperatureDashboard.res", ~code=step2Code)}
        </div>
      </div>
      <div class="tutorial-step">
        {stepHeader(
          ~n="03",
          ~title="Fetch live data in an effect",
          ~blurb="An effect tracks the selected capital and fetches the current temperature from the Open-Meteo API. When the capital changes, the effect re-runs and the dashboard re-renders.",
        )}
        <div class="tutorial-step-body">
          {codeBlock(~filename="CapitalWeather.res", ~code=step3Code)}
        </div>
      </div>
    </section>
  }
}

module Features = {
  type props = {}

  let make = (_props: props) => {
    <section class="features-section">
      <div class="features-grid">
        {View.fragment(features->Array.map(f => <FeatureCard feature={f} />))}
      </div>
    </section>
  }
}

type props = {}

let make = (_props: props) => {
  <Layout
    children={View.fragment([
      <Hero />,
      <Features />,
      <Tutorial />,
    ])}
  />
}
