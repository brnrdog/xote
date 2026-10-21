// Demos for the docs tutorial (/docs/tutorial). Each StepN module is the live
// version of the code shown for that step; module and helper names match the
// shown code where the step's code is self-contained.

// ---- Shared types & helpers ----

type tempUnit = Celsius | Fahrenheit | Kelvin

let symbolFor = unit =>
  switch unit {
  | Celsius => "°C"
  | Fahrenheit => "°F"
  | Kelvin => "K"
  }

let labelFor = unit =>
  switch unit {
  | Celsius => "Celsius"
  | Fahrenheit => "Fahrenheit"
  | Kelvin => "Kelvin"
  }

let classFor = unit =>
  switch unit {
  | Celsius => "temp-display temp-celsius"
  | Fahrenheit => "temp-display temp-fahrenheit"
  | Kelvin => "temp-display temp-kelvin"
  }

@get external target: Dom.event => {"value": string} = "target"

// ---- Step 1: a static display ----

module StaticDisplay = {
  @xote.component
  let make = (~value: float, ~unit: tempUnit) =>
    <div class={classFor(unit)}>
      <span class="temp-value"> {value->Float.toFixed(~digits=1)} </span>
      <span class="temp-unit"> {symbolFor(unit)} </span>
      <span class="temp-label"> {labelFor(unit)} </span>
    </div>
}

module Step1 = {
  @xote.component
  let make = () =>
    <div class="temp-row">
      <StaticDisplay value=22.0 unit=Celsius />
    </div>
}

// ---- The reactive display used from step 2 on ----
// Takes the signal itself: a component prop is read once, so passing
// `Signal.get(celsius)` would freeze the value.

module TemperatureDisplay = {
  @xote.component
  let make = (~value: Signal.t<float>, ~unit: tempUnit) =>
    <div class={classFor(unit)}>
      <span class="temp-value"> {Signal.get(value)->Float.toFixed(~digits=1)} </span>
      <span class="temp-unit"> {symbolFor(unit)} </span>
      <span class="temp-label"> {labelFor(unit)} </span>
    </div>
}

// ---- Step 2: one signal and a slider ----

module Step2 = {
  let celsius = Signal.make(22.0)

  let onSlide = evt =>
    switch Float.fromString(target(evt)["value"]) {
    | Some(value) => Signal.set(celsius, value)
    | None => ()
    }

  @xote.component
  let make = () =>
    <div class="tutorial-stage">
      <div class="temp-row">
        <TemperatureDisplay value=celsius unit=Celsius />
      </div>
      <label class="tutorial-slider">
        <span> {"Drag to change °C"} </span>
        <input
          type_="range"
          min="-20"
          max="40"
          step="0.5"
          value={Signal.get(celsius)->Float.toString}
          onInput=onSlide
        />
      </label>
    </div>
}

// ---- DOM inspector panel (used by Step 2) ----
// Uses a live MutationObserver on the stage to show the actual
// characterData mutations the reactive system emits.

module DomInspector = {
  type entry = {
    id: int,
    label: string,
    oldValue: string,
    newValue: string,
  }

  let idCounter = ref(0)
  let maxEntries = 6

  @val external getById: string => Nullable.t<Dom.element> = "document.getElementById"
  @val external queueMicrotask: (unit => unit) => unit = "queueMicrotask"

  let describeTextTarget = (target: 'a): string => {
    let parent: Nullable.t<'b> = (target->Obj.magic)["parentElement"]
    switch parent->Nullable.toOption {
    | Some(el) =>
      let tag: string = (el->Obj.magic)["tagName"]
      let tagLower = tag->String.toLowerCase
      let className: string = (el->Obj.magic)["className"]
      let firstClass =
        className
        ->String.split(" ")
        ->Array.find(s => s !== "")
        ->Option.getOr("")
      firstClass === "" ? tagLower : `${tagLower}.${firstClass}`
    | None => "#text"
    }
  }

  @xote.component
  let make = (~stageId: string) => {
    let entries = Signal.make([])

    if SSRContext.isClient {
      Effect.run(() => {
        let handler = records => {
          let fresh = records->Array.filterMap(mut => {
            let recType: string = (mut->Obj.magic)["type"]
            if recType === "characterData" {
              let target = (mut->Obj.magic)["target"]
              let oldValue: Nullable.t<string> = (mut->Obj.magic)["oldValue"]
              let newValue: string = (target->Obj.magic)["data"]
              let id = idCounter.contents
              idCounter := id + 1
              Some({
                id,
                label: describeTextTarget(target),
                oldValue: oldValue->Nullable.toOption->Option.getOr(""),
                newValue,
              })
            } else {
              None
            }
          })

          if Array.length(fresh) > 0 {
            Signal.update(entries, prev => {
              let combined = Array.concat(fresh->Array.toReversed, prev)
              combined->Array.slice(~start=0, ~end=maxEntries)
            })
          }
        }

        let mkObserver: ('a => unit) => 'b = %raw(`handler => new MutationObserver(handler)`)
        let observeFn: ('b, Dom.element, 'c) => unit = %raw(`(observer, el, init) => observer.observe(el, init)`)
        let disconnectFn: 'b => unit = %raw(`observer => observer.disconnect()`)
        let observer = mkObserver(handler)
        let disposed = ref(false)

        queueMicrotask(() => {
          if !disposed.contents {
            switch getById(stageId)->Nullable.toOption {
            | Some(el) =>
              observeFn(
                observer,
                el,
                {
                  "characterData": true,
                  "characterDataOldValue": true,
                  "subtree": true,
                },
              )
            | None => ()
            }
          }
        })

        Some(() => {
          disposed := true
          disconnectFn(observer)
        })
      })
    }

    <aside class="dom-inspector" ariaLabel="DOM mutations">
      <div class="dom-inspector-header">
        <span class="dom-inspector-title"> {View.text("DOM mutations")} </span>
        <span class="dom-inspector-hint">
          {View.text("live from MutationObserver")}
        </span>
      </div>
      <ol class="dom-inspector-list">
        {View.eachWithKey(
          entries,
          e => Int.toString(e.id),
          e =>
            <li class="dom-inspector-row">
              <span class="dom-inspector-target"> {View.text(e.label)} </span>
              <span class="dom-inspector-diff">
                <span class="dom-inspector-old"> {View.text(e.oldValue)} </span>
                <span class="dom-inspector-arrow"> {View.text("->")} </span>
                <span class="dom-inspector-new"> {View.text(e.newValue)} </span>
              </span>
            </li>,
        )}
      </ol>
      <p
        class={() =>
          Array.length(Signal.get(entries)) > 0
            ? "dom-inspector-empty is-hidden"
            : "dom-inspector-empty"}>
        {View.text("Drag the slider. Only the changed text nodes update.")}
      </p>
    </aside>
  }
}

// ---- Step 3: derived values with computeds ----

module Step3 = {
  let celsius = Signal.make(22.0)
  let fahrenheit = Computed.make(() => Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0)
  let kelvin = Computed.make(() => Signal.get(celsius) +. 273.15)

  let onSlide = evt =>
    switch Float.fromString(target(evt)["value"]) {
    | Some(value) => Signal.set(celsius, value)
    | None => ()
    }

  let stageId = "tutorial-step3-stage"

  @xote.component
  let make = () =>
    <div class="tutorial-step2">
      <div class="tutorial-stage" id=stageId>
        <div class="temp-row">
          <TemperatureDisplay value=celsius unit=Celsius />
          <TemperatureDisplay value=fahrenheit unit=Fahrenheit />
          <TemperatureDisplay value=kelvin unit=Kelvin />
        </div>
        <label class="tutorial-slider">
          <span> {"Drag to change °C"} </span>
          <input
            type_="range"
            min="-20"
            max="40"
            step="0.5"
            value={Signal.get(celsius)->Float.toString}
            onInput=onSlide
          />
        </label>
      </div>
      <DomInspector stageId />
    </div>
}

// ---- Step 4: live weather from an effect ----

type capital = {name: string, lat: float, lng: float}

let capitals = [
  {name: "Paris", lat: 48.8566, lng: 2.3522},
  {name: "Tokyo", lat: 35.6762, lng: 139.6503},
  {name: "Nairobi", lat: -1.2921, lng: 36.8219},
  {name: "Ottawa", lat: 45.4215, lng: -75.6972},
  {name: "Canberra", lat: -35.2809, lng: 149.13},
  {name: "Brasília", lat: -15.7939, lng: -47.8828},
  {name: "Cairo", lat: 30.0444, lng: 31.2357},
  {name: "Reykjavik", lat: 64.1466, lng: -21.9426},
]

let pickCapital = () => capitals->Array.getUnsafe(Math.Int.random(0, Array.length(capitals)))

type response
type currentWeather = {temperature: float}
type forecast = {current_weather: currentWeather}

@val external fetch: string => promise<response> = "fetch"
@send external json: response => promise<forecast> = "json"

let fetchTemperature = async (capital: capital) => {
  let url =
    "https://api.open-meteo.com/v1/forecast" ++
    `?latitude=${capital.lat->Float.toString}` ++
    `&longitude=${capital.lng->Float.toString}` ++ "&current_weather=true"
  let response = await fetch(url)
  let forecast = await json(response)
  forecast.current_weather.temperature
}

type status = Loading | Ready | Failed

module Step4 = {
  @xote.component
  let make = () => {
    // Start from a fixed capital so the server-rendered HTML and the first
    // client render agree; shuffling picks at random.
    let capital = Signal.make(capitals->Array.getUnsafe(0))
    let status = Signal.make(Loading)
    let celsius = Signal.make(0.0)
    let fahrenheit = Computed.make(() => Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0)
    let kelvin = Computed.make(() => Signal.get(celsius) +. 273.15)

    // The docs site renders this page on the server too; only fetch in the
    // browser. An app that only renders in the browser needs no guard.
    if SSRContext.isClient {
      Effect.run(() => {
        let current = Signal.get(capital)
        let stale = ref(false)
        Signal.set(status, Loading)

        fetchTemperature(current)
        ->Promise.thenResolve(temperature =>
          if !stale.contents {
            Signal.set(celsius, temperature)
            Signal.set(status, Ready)
          }
        )
        ->Promise.catch(_ => {
          if !stale.contents {
            Signal.set(status, Failed)
          }
          Promise.resolve()
        })
        ->ignore

        Some(() => stale := true)
      })
    }

    let shuffle = _ => Signal.set(capital, pickCapital())

    <div class="tutorial-stage">
      <div class="tutorial-capital">
        <span class="tutorial-capital-label"> {"Now in"} </span>
        <span class="tutorial-capital-name"> {Signal.get(capital).name} </span>
      </div>
      {switch Signal.get(status) {
      | Loading => <p class="tutorial-status"> {"Fetching the current weather…"} </p>
      | Failed => <p class="tutorial-status"> {"Couldn't reach the weather service."} </p>
      | Ready =>
        <div class="temp-row">
          <TemperatureDisplay value=celsius unit=Celsius />
          <TemperatureDisplay value=fahrenheit unit=Fahrenheit />
          <TemperatureDisplay value=kelvin unit=Kelvin />
        </div>
      }}
      <button class="btn-pill btn-soft tutorial-shuffle" onClick=shuffle>
        {"Try another capital"}
      </button>
    </div>
  }
}
