// ---- Shared types & bindings ----

type tempUnit = Celsius | Fahrenheit | Kelvin

let symbolFor = u =>
  switch u {
  | Celsius => "°C"
  | Fahrenheit => "°F"
  | Kelvin => "K"
  }

let unitClass = u =>
  switch u {
  | Celsius => "temp-display temp-celsius"
  | Fahrenheit => "temp-display temp-fahrenheit"
  | Kelvin => "temp-display temp-kelvin"
  }

let unitLabel = u =>
  switch u {
  | Celsius => "Celsius"
  | Fahrenheit => "Fahrenheit"
  | Kelvin => "Kelvin"
  }

// ---- TemperatureDisplay (reactive-ready) ----
// Takes a thunk so the value can be driven by signals or computeds.

module TemperatureDisplay = {
  @xote.component
  let make = (~value: unit => float, ~unit: tempUnit) =>
    <div class={unitClass(unit)}>
      <span class="temp-value">
        <View.Text> {() => value()->Float.toFixed(~digits=1)} </View.Text>
      </span>
      <span class="temp-unit"> <View.Text> {symbolFor(unit)} </View.Text> </span>
      <span class="temp-label"> <View.Text> {unitLabel(unit)} </View.Text> </span>
    </div>
}

// ---- Step 1: static display ----

module Step1 = {
  @xote.component
  let make = () =>
    <div class="temp-row">
      <TemperatureDisplay value={() => 22.0} unit=Celsius />
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
        class={Prop.reactive(
          Computed.make(() =>
            Array.length(Signal.get(entries)) > 0
              ? "dom-inspector-empty is-hidden"
              : "dom-inspector-empty"
          ),
        )}>
        {View.text("Drag the slider. Only the changed text nodes update.")}
      </p>
    </aside>
  }
}

// ---- Step 2: one signal, derived computeds ----

module Step2 = {
  let celsius = Signal.make(22.0)
  let fahrenheit = Computed.make(() => Signal.get(celsius) *. 9.0 /. 5.0 +. 32.0)
  let kelvin = Computed.make(() => Signal.get(celsius) +. 273.15)

  let onSlide = (evt: Dom.event) => {
    let target: {"value": string} = (evt->Obj.magic)["target"]
    switch Float.fromString(target["value"]) {
    | Some(n) => Signal.set(celsius, n)
    | None => ()
    }
  }

  let stageId = "tutorial-step2-stage"

  @xote.component
  let make = () =>
    <div class="tutorial-step2">
      <div class="tutorial-stage" id=stageId>
        <div class="temp-row">
          <TemperatureDisplay value={() => Signal.get(celsius)} unit=Celsius />
          <TemperatureDisplay value={() => Signal.get(fahrenheit)} unit=Fahrenheit />
          <TemperatureDisplay value={() => Signal.get(kelvin)} unit=Kelvin />
        </div>
        <label class="tutorial-slider">
          <span> {View.text("Drag to change °C")} </span>
          <input
            type_="range"
            min="-20"
            max="40"
            step="0.5"
            value={Signal.peek(celsius)->Float.toString}
            onInput={onSlide}
          />
        </label>
      </div>
      <DomInspector stageId />
    </div>
}

// ---- Step 3: fetch live weather for a random capital ----

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

let pickRandomCapital = () => {
  let n = Math.random() *. Array.length(capitals)->Int.toFloat
  let idx = Float.toInt(Math.floor(n))
  capitals->Array.getUnsafe(idx)
}

@val external fetch: string => promise<'a> = "fetch"

module Step3 = {
  type status = Loading | Ready(float) | Failed(string)

  let capital = Signal.make(pickRandomCapital())
  let status = Signal.make(Loading)

  let fetchWeather = (c: capital) => {
    Signal.set(status, Loading)
    let url =
      `https://api.open-meteo.com/v1/forecast?latitude=${Float.toString(
          c.lat,
        )}&longitude=${Float.toString(c.lng)}&current_weather=true`

    fetch(url)
    ->Promise.then(res => (res->Obj.magic)["json"]())
    ->Promise.then(json => {
      let weather = (json->Obj.magic)["current_weather"]
      let temp: Nullable.t<float> = (weather->Obj.magic)["temperature"]
      switch temp->Nullable.toOption {
      | Some(t) => Signal.set(status, Ready(t))
      | None => Signal.set(status, Failed("No data"))
      }
      Promise.resolve()
    })
    ->Promise.catch(_ => {
      Signal.set(status, Failed("Network error"))
      Promise.resolve()
    })
    ->ignore
  }

  if SSRContext.isClient {
    Effect.run(() => {
      let c = Signal.get(capital)
      fetchWeather(c)
      None
    })
  }

  let shuffle = (_evt: Dom.event) => Signal.set(capital, pickRandomCapital())

  let formatFor = (convert: float => float) => () =>
    switch Signal.get(status) {
    | Ready(c) => convert(c)->Float.toFixed(~digits=1)
    | _ => "-"
    }

  let displayCelsius = formatFor(c => c)
  let displayFahrenheit = formatFor(c => c *. 9.0 /. 5.0 +. 32.0)
  let displayKelvin = formatFor(c => c +. 273.15)

  let card = (~unit, ~text) =>
    <div class={unitClass(unit)}>
      <span class="temp-value"> <View.Text> {text} </View.Text> </span>
      <span class="temp-unit"> <View.Text> {symbolFor(unit)} </View.Text> </span>
      <span class="temp-label"> <View.Text> {unitLabel(unit)} </View.Text> </span>
    </div>

  let statusText = () =>
    switch Signal.get(status) {
    | Loading => "Fetching current weather..."
    | Failed(msg) => "Error: " ++ msg
    | Ready(_) => " "
    }

  @xote.component
  let make = () =>
    <div class="tutorial-stage">
      <div class="tutorial-capital">
        <span class="tutorial-capital-label"> {View.text("Now in")} </span>
        <span class="tutorial-capital-name">
          <View.Text> {() => Signal.get(capital).name} </View.Text>
        </span>
      </div>
      <div class="temp-row">
        {card(~unit=Celsius, ~text=displayCelsius)}
        {card(~unit=Fahrenheit, ~text=displayFahrenheit)}
        {card(~unit=Kelvin, ~text=displayKelvin)}
      </div>
      <div class="tutorial-status"> <View.Text> {statusText} </View.Text> </div>
      <button class="btn btn-ghost tutorial-shuffle" onClick={shuffle}>
        {View.text("Try another capital")}
      </button>
    </div>
}
