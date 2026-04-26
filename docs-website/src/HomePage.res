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
    linkText: Some("Components and router"),
    linkTo: Some("/docs/components/overview"),
  },
]

module FeatureCard = {
  type props = {feature: feature}

  let make = (props: props) => {
    let {feature: f} = props
    <div class="feature-card">
      <h3> {Node.text(f.title)} </h3>
      <p> {Node.text(f.description)} </p>
      {switch (f.linkText, f.linkTo) {
      | (Some(text), Some(to)) =>
        Node.element(
          "span",
          ~events=[
            (
              "click",
              _ => {
                let _ = %raw(`window.posthog && window.posthog.capture('feature_card_link_clicked', { destination: to, link_text: text })`)
              },
            ),
          ],
          ~children=[
            Router.link(
              ~to,
              ~attrs=[Node.attr("class", "feature-card-link")],
              ~children=[Node.text(text ++ " \u2192")],
              (),
            ),
          ],
          (),
        )
      | _ => Node.fragment([])
      }}
    </div>
  }
}

module HeroBackground = {
  type props = {}

  let cols = 56
  let rows = 20
  let size = 24

  let makeTriangles = () => {
    let out = []
    for r in 0 to rows - 1 {
      for c in 0 to cols - 1 {
        let x = c * size
        let y = r * size
        let x2 = x + size
        let y2 = y + size
        let sx = Int.toString(x)
        let sy = Int.toString(y)
        let sx2 = Int.toString(x2)
        let sy2 = Int.toString(y2)
        let upper = `${sx},${sy} ${sx2},${sy} ${sx},${sy2}`
        let lower = `${sx2},${sy} ${sx2},${sy2} ${sx},${sy2}`
        out
        ->Array.push(
          Node.element(
            "polygon",
            ~attrs=[Node.attr("points", upper), Node.attr("class", "hero-tri")],
            (),
          ),
        )
        ->ignore
        out
        ->Array.push(
          Node.element(
            "polygon",
            ~attrs=[Node.attr("points", lower), Node.attr("class", "hero-tri")],
            (),
          ),
        )
        ->ignore
      }
    }
    out
  }

  let make = (_props: props) => {
    let width = cols * size
    let height = rows * size
    let viewBox = `0 0 ${Int.toString(width)} ${Int.toString(height)}`

    let handleOver = (_evt: Dom.event) => {
      let _ = %raw(`(function(evt) {
        var svg = evt.currentTarget;
        if (!svg.__xoteFire) return;
        svg.__xoteHover = true;
        clearTimeout(svg.__xoteHoverEnd);
        svg.__xoteHoverEnd = setTimeout(function() { svg.__xoteHover = false; }, 600);
        var rect = svg.getBoundingClientRect();
        var vb = svg.viewBox && svg.viewBox.baseVal;
        if (!vb || !rect.width || !rect.height) return;
        var sx = vb.width / rect.width;
        var sy = vb.height / rect.height;
        var cx = (evt.clientX - rect.left) * sx;
        var cy = (evt.clientY - rect.top) * sy;
        var polys = svg.querySelectorAll('polygon.hero-tri');
        var nearest = null, nearestD2 = Infinity;
        for (var i = 0; i < polys.length; i++) {
          var p = polys[i];
          if (p.__xoteCx === undefined) {
            var pts = p.points, ax = 0, ay = 0, n = pts.numberOfItems;
            for (var j = 0; j < n; j++) {
              var pt = pts.getItem(j);
              ax += pt.x; ay += pt.y;
            }
            p.__xoteCx = ax / n;
            p.__xoteCy = ay / n;
          }
          var dx = p.__xoteCx - cx;
          var dy = p.__xoteCy - cy;
          var d2 = dx * dx + dy * dy;
          if (d2 < nearestD2) { nearestD2 = d2; nearest = p; }
        }
        svg.__xoteFire(nearest, true);
      })(_evt)`)
    }

    if SSRContext.isClient {
      Effect.run(() => {
        let _ = %raw(`(function(){
          var tries = 0;
          function init() {
            var svg = document.querySelector('.hero-bg-svg');
            if (!svg) { if (tries++ < 50) setTimeout(init, 100); return; }
            if (svg.__xoteFire) return;
            svg.__xoteFire = function(nearest, throttle, idle) {
              if (!nearest) return;
              var vb = svg.viewBox && svg.viewBox.baseVal;
              if (!vb) return;
              function activate(el, delay, ttl, accent) {
                clearTimeout(el.__xoteTimer);
                clearTimeout(el.__xoteDelay);
                el.__xoteDelay = setTimeout(function() {
                  el.classList.toggle('active-accent', !!accent);
                  el.classList.add('active');
                  el.__xoteTimer = setTimeout(function() {
                    el.classList.remove('active');
                    el.classList.remove('active-accent');
                  }, ttl);
                }, delay);
              }
              if (throttle && svg.__xoteLastRipple && performance.now() - svg.__xoteLastRipple < 140) {
                activate(nearest, 0, 600, Math.random() < 0.18);
                return;
              }
              svg.__xoteLastRipple = performance.now();
              var polys = svg.querySelectorAll('polygon.hero-tri');
              var cellVb = (vb.width / 42 + vb.height / 15) / 2;
              var maxRings = idle ? 5 : 3;
              var ringStep = cellVb * (idle ? 1.4 : 1.2);
              var ringDelay = idle ? 140 : 70;
              var ringDuration = idle ? 520 : 360;
              var biasAngle = idle ? Math.random() * Math.PI * 2 : 0;
              var biasStrength = idle ? 0.55 : 0;
              for (var k = 0; k < polys.length; k++) {
                var q = polys[k];
                if (q.__xoteCx === undefined) {
                  var pts = q.points, ax = 0, ay = 0, n = pts.numberOfItems;
                  for (var j = 0; j < n; j++) {
                    var pt = pts.getItem(j);
                    ax += pt.x; ay += pt.y;
                  }
                  q.__xoteCx = ax / n;
                  q.__xoteCy = ay / n;
                }
                var ddx = q.__xoteCx - nearest.__xoteCx;
                var ddy = q.__xoteCy - nearest.__xoteCy;
                var dist = Math.sqrt(ddx * ddx + ddy * ddy);
                var ring = Math.round(dist / ringStep);
                if (ring > maxRings) continue;
                var prob;
                if (idle) {
                  var dirWeight = 1;
                  if (dist > 0) {
                    var ang = Math.atan2(ddy, ddx);
                    var align = Math.cos(ang - biasAngle);
                    dirWeight = 1 + biasStrength * align;
                  }
                  prob = ring === 0 ? 1 : Math.max(0, (0.55 - ring * 0.09) * dirWeight);
                } else {
                  prob = ring === 0 ? 1 : 0.35 - ring * 0.08;
                }
                if (Math.random() > prob) continue;
                var jitter = (Math.random() - 0.5) * (idle ? 120 : 60);
                var ttl = ringDuration + ring * (idle ? 110 : 50) + Math.random() * (idle ? 320 : 160);
                var accentProb = idle ? 0.12 : 0.18;
                var accent = ring > 0 && Math.random() < accentProb;
                activate(q, ring * ringDelay + jitter, ttl, accent);
              }
            };
            (function tick() {
              var delay = 900 + Math.random() * 1600;
              setTimeout(function() {
                if (!document.body.contains(svg)) return;
                if (!svg.__xoteHover) {
                  var polys = svg.querySelectorAll('polygon.hero-tri');
                  if (polys.length) {
                    var seed = polys[Math.floor(Math.random() * polys.length)];
                    if (seed.__xoteCx === undefined) {
                      var pts = seed.points, ax = 0, ay = 0, n = pts.numberOfItems;
                      for (var j = 0; j < n; j++) {
                        var pt = pts.getItem(j);
                        ax += pt.x; ay += pt.y;
                      }
                      seed.__xoteCx = ax / n;
                      seed.__xoteCy = ay / n;
                    }
                    svg.__xoteFire(seed, false, true);
                  }
                }
                tick();
              }, delay);
            })();
          }
          init();
        })()`)
        None
      })
    }

    Node.element(
      "div",
      ~attrs=[Node.attr("class", "hero-bg"), Node.attr("aria-hidden", "true")],
      ~children=[
        Node.element(
          "svg",
          ~attrs=[
            Node.attr("viewBox", viewBox),
            Node.attr("preserveAspectRatio", "xMidYMid slice"),
            Node.attr("class", "hero-bg-svg"),
          ],
          ~events=[("mousemove", handleOver)],
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
        {Node.text("A ReScript Library for Interactive User Interfaces")}
      </h1>
      <p class="hero-lead">
        {Node.text(
          "Build components and web applications with fine-grained reactivity in a sound type system world.",
        )}
      </p>
      <div class="hero-ctas">
        {Node.element(
          "span",
          ~events=[
            (
              "click",
              _ => {
                let _ = %raw(`window.posthog && window.posthog.capture('get_started_clicked')`)
              },
            ),
          ],
          ~children=[
            Router.link(
              ~to="/docs",
              ~attrs=[Node.attr("class", "btn btn-primary")],
              ~children=[Node.text("Get started")],
              (),
            ),
          ],
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
      {Node.text(value->Float.toFixed(~digits=1))}
    </span>
    <span class="temp-unit">
      {Node.text(symbolFor(unit))}
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
      <span class="tutorial-step-number"> {Node.text(n)} </span>
      <div>
        <h3 class="tutorial-step-title"> {Node.text(title)} </h3>
        <p class="tutorial-step-blurb"> {Node.text(blurb)} </p>
      </div>
    </div>

  let codeBlock = (~filename, ~code) =>
    <div class="tutorial-code">
      <div class="tutorial-code-filename"> {Node.text(filename)} </div>
      <pre class="tutorial-code-pre">
        <code> {SyntaxHighlight.highlight(code)} </code>
      </pre>
    </div>

  let stage = (~caption, ~children) =>
    <figure class="tutorial-figure">
      <div class="tutorial-figure-stage"> {children} </div>
      <figcaption class="tutorial-figure-caption"> {Node.text(caption)} </figcaption>
    </figure>

  let make = (_props: props) => {
    <section class="tutorial-section">
      <div class="tutorial-step">
        {stepHeader(
          ~n="01",
          ~title="Build a presentational component",
          ~blurb="Components are plain functions. TemperatureDisplay takes a value and a unit and renders them in a styled card.",
        )}
        <div class="tutorial-step-body">
          {codeBlock(~filename="TemperatureDisplay.res", ~code=step1Code)}
          {stage(
            ~caption="Preview — TemperatureDisplay with a static value of 22 °C",
            ~children=<TutorialDemos.Step1 />,
          )}
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
          {stage(
            ~caption="Preview — a single signal drives three synchronized readouts",
            ~children=<TutorialDemos.Step2 />,
          )}
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
          {stage(
            ~caption="Preview — real weather from a random world capital (Open-Meteo)",
            ~children=<TutorialDemos.Step3 />,
          )}
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
        {Node.fragment(features->Array.map(f => <FeatureCard feature={f} />))}
      </div>
    </section>
  }
}

type props = {}

let make = (_props: props) => {
  <Layout
    children={Node.fragment([
      <Hero />,
      <Features />,
      <Tutorial />,
    ])}
  />
}
