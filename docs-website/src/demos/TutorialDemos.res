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
  @jsx.component
  let make = (~value: unit => float, ~unit: tempUnit) =>
    <div class={unitClass(unit)}>
      <span class="temp-value">
        {Node.signalText(() => value()->Float.toFixed(~digits=1))}
      </span>
      <span class="temp-unit"> {Node.text(symbolFor(unit))} </span>
      <span class="temp-label"> {Node.text(unitLabel(unit))} </span>
    </div>
}

// ---- Step 1: static display ----

module Step1 = {
  @jsx.component
  let make = () =>
    <div class="temp-row">
      <TemperatureDisplay value={() => 22.0} unit=Celsius />
    </div>
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

  @jsx.component
  let make = () =>
    <div class="tutorial-stage">
      <div class="temp-row">
        <TemperatureDisplay value={() => Signal.get(celsius)} unit=Celsius />
        <TemperatureDisplay value={() => Signal.get(fahrenheit)} unit=Fahrenheit />
        <TemperatureDisplay value={() => Signal.get(kelvin)} unit=Kelvin />
      </div>
      <label class="tutorial-slider">
        <span> {Node.text("Drag to change °C")} </span>
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

// Minimal fetch bindings
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
    | _ => "—"
    }

  let displayCelsius = formatFor(c => c)
  let displayFahrenheit = formatFor(c => c *. 9.0 /. 5.0 +. 32.0)
  let displayKelvin = formatFor(c => c +. 273.15)

  let card = (~unit, ~text) =>
    <div class={unitClass(unit)}>
      <span class="temp-value"> {Node.signalText(text)} </span>
      <span class="temp-unit"> {Node.text(symbolFor(unit))} </span>
      <span class="temp-label"> {Node.text(unitLabel(unit))} </span>
    </div>

  let statusText = () =>
    switch Signal.get(status) {
    | Loading => "Fetching current weather…"
    | Failed(msg) => "Error: " ++ msg
    | Ready(_) => "\u00a0"
    }

  @jsx.component
  let make = () =>
    <div class="tutorial-stage">
      <div class="tutorial-capital">
        <span class="tutorial-capital-label"> {Node.text("Now in")} </span>
        <span class="tutorial-capital-name">
          {Node.signalText(() => Signal.get(capital).name)}
        </span>
      </div>
      <div class="temp-row">
        {card(~unit=Celsius, ~text=displayCelsius)}
        {card(~unit=Fahrenheit, ~text=displayFahrenheit)}
        {card(~unit=Kelvin, ~text=displayKelvin)}
      </div>
      <div class="tutorial-status"> {Node.signalText(statusText)} </div>
      <button class="btn btn-ghost tutorial-shuffle" onClick={shuffle}>
        {Node.text("Try another capital \u2197")}
      </button>
    </div>
}
