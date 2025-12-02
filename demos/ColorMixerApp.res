module Signal = Xote.Signal
module Computed = Xote.Computed
module Component = Xote.Component

// Color channel signals (0-255)
let red = Signal.make(100)
let green = Signal.make(150)
let blue = Signal.make(200)

// Saved colors history
let savedColors = Signal.make([])

// Utility functions for color conversions
let toHex = (value: int) => {
  let hex = %raw(`value.toString(16)`)
  String.length(hex) == 1 ? "0" ++ hex : hex
}

let rgbToHsl = (r: int, g: int, b: int) => {
  let r = Int.toFloat(r) /. 255.0
  let g = Int.toFloat(g) /. 255.0
  let b = Int.toFloat(b) /. 255.0

  let max = Math.max(r, Math.max(g, b))
  let min = Math.min(r, Math.min(g, b))
  let delta = max -. min

  let l = (max +. min) /. 2.0

  if delta == 0.0 {
    (0.0, 0.0, l)
  } else {
    let s = delta /. (1.0 -. Math.abs(2.0 *. l -. 1.0))

    let h = if max == r {
      mod_float((g -. b) /. delta, 6.0)
    } else if max == g {
      (b -. r) /. delta +. 2.0
    } else {
      (r -. g) /. delta +. 4.0
    }

    let h = h *. 60.0
    let h = h < 0.0 ? h +. 360.0 : h

    (h, s, l)
  }
}

// Computed color values
let hexColor = Computed.make(() => {
  let r = Signal.get(red)
  let g = Signal.get(green)
  let b = Signal.get(blue)
  "#" ++ toHex(r) ++ toHex(g) ++ toHex(b)
})

let rgbColor = Computed.make(() => {
  let r = Signal.get(red)
  let g = Signal.get(green)
  let b = Signal.get(blue)
  `rgb(${Int.toString(r)}, ${Int.toString(g)}, ${Int.toString(b)})`
})

let hslColor = Computed.make(() => {
  let r = Signal.get(red)
  let g = Signal.get(green)
  let b = Signal.get(blue)
  let (h, s, l) = rgbToHsl(r, g, b)
  `hsl(${Float.toFixed(h, ~digits=0)}°, ${Float.toFixed(s *. 100.0, ~digits=0)}%, ${Float.toFixed(
      l *. 100.0,
      ~digits=0,
    )}%)`
})

// Computed color variations
let lighterColor = Computed.make(() => {
  let r = Signal.get(red)
  let g = Signal.get(green)
  let b = Signal.get(blue)
  let lighten = (v: int) => Math.Int.min(255, v + 50)
  `rgb(${Int.toString(lighten(r))}, ${Int.toString(lighten(g))}, ${Int.toString(lighten(b))})`
})

let darkerColor = Computed.make(() => {
  let r = Signal.get(red)
  let g = Signal.get(green)
  let b = Signal.get(blue)
  let darken = (v: int) => Math.Int.max(0, v - 50)
  `rgb(${Int.toString(darken(r))}, ${Int.toString(darken(g))}, ${Int.toString(darken(b))})`
})

let complementaryColor = Computed.make(() => {
  let r = Signal.get(red)
  let g = Signal.get(green)
  let b = Signal.get(blue)
  let complement = (v: int) => 255 - v
  `rgb(${Int.toString(complement(r))}, ${Int.toString(complement(g))}, ${Int.toString(
      complement(b),
    )})`
})

// Event handlers
let updateRed = (evt: Dom.event) => {
  let value = %raw(`evt.target.value`)
  Signal.set(red, Int.fromString(value)->Option.getOr(0))
}

let updateGreen = (evt: Dom.event) => {
  let value = %raw(`evt.target.value`)
  Signal.set(green, Int.fromString(value)->Option.getOr(0))
}

let updateBlue = (evt: Dom.event) => {
  let value = %raw(`evt.target.value`)
  Signal.set(blue, Int.fromString(value)->Option.getOr(0))
}

let copyToClipboard = (text: string) => {
  %raw(`navigator.clipboard.writeText(text)`)
}

let saveColor = (_evt: Dom.event) => {
  let color = Signal.get(hexColor)
  Signal.update(savedColors, colors => {
    // Only save if not already in history and limit to 8 colors
    if !Array.includes(colors, color) {
      let newColors = Array.concat([color], colors)
      Array.slice(newColors, ~start=0, ~end=8)
    } else {
      colors
    }
  })
}

let randomColor = (_evt: Dom.event) => {
  Signal.set(red, Int.fromFloat(Math.random() *. 255.0))
  Signal.set(green, Int.fromFloat(Math.random() *. 255.0))
  Signal.set(blue, Int.fromFloat(Math.random() *. 255.0))
}

module ColorSlider = {
  type props = {
    label: string,
    value: Signal.t<int>,
    color: string,
    onChange: Dom.event => unit,
  }

  let component = (props: props) => {
    <div class="space-y-2">
      <div class="flex items-center justify-between">
        <span class="text-sm font-semibold text-stone-700 dark:text-stone-300">
          {Component.text(props.label)}
        </span>
        <span class="text-sm font-mono font-bold text-stone-900 dark:text-white w-12 text-right">
          {Component.textSignal(() => Signal.get(props.value)->Int.toString)}
        </span>
      </div>
      <input
        type_="range"
        value={() => Signal.get(props.value)->Int.toString}
        class={"w-full h-2 rounded-lg appearance-none cursor-pointer " ++ props.color}
        onInput={props.onChange}
      />
    </div>
  }
}

module ColorPreview = {
  let component = () => {
    <div
      class="rounded-2xl border-4 border-stone-200 dark:border-stone-700 overflow-hidden shadow-xl"
    >
      <div
        class="h-48 md:h-64 relative transition-colors duration-200"
        style={() =>
          `background-color: ${Signal.get(rgbColor)}; transition: background-color 0.2s ease`}
      >
        <div class="absolute inset-0 flex items-center justify-center bg-black/10">
          <div class="bg-white dark:bg-stone-800 px-6 py-3 rounded-xl shadow-lg backdrop-blur">
            <p class="font-mono font-bold text-xl text-stone-900 dark:text-white">
              {Component.textSignal(() => Signal.get(hexColor))}
            </p>
          </div>
        </div>
      </div>
    </div>
  }
}

module ColorInfo = {
  type colorValueRowProps = {
    label: string,
    value: Signal.t<string>,
  }

  let colorValueRow = (props: colorValueRowProps) => {
    <div class="flex items-center justify-between p-3 bg-stone-50 dark:bg-stone-700/50 rounded-lg">
      <span class="text-sm font-medium text-stone-600 dark:text-stone-400">
        {Component.text(props.label)}
      </span>
      <div class="flex items-center gap-2">
        <span class="text-sm font-mono text-stone-900 dark:text-white">
          {Component.textSignal(() => Signal.get(props.value))}
        </span>
        <button
          class="text-xs px-2 py-1 bg-stone-200 dark:bg-stone-600 hover:bg-stone-300 dark:hover:bg-stone-500 rounded transition-colors"
          onClick={_evt => copyToClipboard(Signal.get(props.value))}
        >
          {Component.text("Copy")}
        </button>
      </div>
    </div>
  }

  let component = () => {
    <div class="space-y-2">
      <h3 class="text-lg font-bold text-stone-900 dark:text-white mb-3">
        {Component.text("Color Values")}
      </h3>
      {colorValueRow({label: "HEX", value: hexColor})}
      {colorValueRow({label: "RGB", value: rgbColor})}
      {colorValueRow({label: "HSL", value: hslColor})}
    </div>
  }
}

module ColorPalette = {
  type paletteItemProps = {
    label: string,
    color: Signal.t<string>,
  }

  let paletteItem = (props: paletteItemProps) => {
    <div class="text-center space-y-2">
      <div
        class="h-20 rounded-lg border-2 border-stone-200 dark:border-stone-700 cursor-pointer hover:scale-105 transition-transform"
        style={() => `background-color: ${Signal.get(props.color)}`}
        onClick={_evt => copyToClipboard(Signal.get(props.color))}
      />
      <p class="text-xs font-medium text-stone-600 dark:text-stone-400">
        {Component.text(props.label)}
      </p>
    </div>
  }

  let component = () => {
    <div class="space-y-3">
      <h3 class="text-lg font-bold text-stone-900 dark:text-white">
        {Component.text("Color Variations")}
      </h3>
      <div class="grid grid-cols-3 gap-3">
        {paletteItem({label: "Lighter", color: lighterColor})}
        {paletteItem({label: "Current", color: rgbColor})}
        {paletteItem({label: "Darker", color: darkerColor})}
      </div>
      {paletteItem({label: "Complementary", color: complementaryColor})}
    </div>
  }
}

module SavedColors = {
  let component = () => {
    <div class="space-y-3">
      <div class="flex items-center justify-between">
        <h3 class="text-lg font-bold text-stone-900 dark:text-white">
          {Component.text("Saved Colors")}
        </h3>
        <button
          class="text-xs px-3 py-1.5 bg-stone-900 dark:bg-stone-700 hover:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg transition-colors"
          onClick={saveColor}
        >
          {Component.text("+ Save Current")}
        </button>
      </div>
      {
        let savedColorsSignal = Computed.make(() => {
          let colors = Signal.get(savedColors)
          if Array.length(colors) == 0 {
            [
              <p class="text-sm text-stone-500 dark:text-stone-500 text-center py-4">
                {Component.text("No saved colors yet")}
              </p>,
            ]
          } else {
            [
              <div class="grid grid-cols-4 gap-2">
                {Component.list(savedColors, color => {
                  <div
                    class="h-12 rounded-lg border-2 border-stone-200 dark:border-stone-700 cursor-pointer hover:scale-105 transition-transform"
                    style={`background-color: ${color}`}
                    onClick={_evt => copyToClipboard(color)}
                  />
                })}
              </div>,
            ]
          }
        })
        Component.signalFragment(savedColorsSignal)
      }
    </div>
  }
}

module ColorMixerApp = {
  let component = () => {
    <div class="max-w-4xl mx-auto p-4 md:p-6 space-y-6">
      // Header
      <div class="mb-6">
        <h1 class="text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-2">
          {Component.text("Color Mixer")}
        </h1>
        <p class="text-sm md:text-base text-stone-600 dark:text-stone-400">
          {Component.text("Mix colors with RGB sliders and explore variations in real-time")}
        </p>
      </div>

      // Color Preview
      {ColorPreview.component()}

      // RGB Sliders
      <div
        class="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6 space-y-4"
      >
        <div class="flex items-center justify-between mb-4">
          <h2 class="text-xl font-bold text-stone-900 dark:text-white">
            {Component.text("RGB Mixer")}
          </h2>
          <button
            class="text-sm px-4 py-2 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 rounded-lg transition-colors"
            onClick={randomColor}
          >
            {Component.text("🎲 Random")}
          </button>
        </div>
        {ColorSlider.component({
          label: "Red",
          value: red,
          color: "bg-red-500",
          onChange: updateRed,
        })}
        {ColorSlider.component({
          label: "Green",
          value: green,
          color: "bg-green-500",
          onChange: updateGreen,
        })}
        {ColorSlider.component({
          label: "Blue",
          value: blue,
          color: "bg-blue-500",
          onChange: updateBlue,
        })}
      </div>

      // Two column layout for info and palette
      <div class="grid md:grid-cols-2 gap-6">
        <div
          class="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6"
        >
          {ColorInfo.component()}
        </div>
        <div
          class="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6"
        >
          {ColorPalette.component()}
        </div>
      </div>

      // Saved colors
      <div
        class="bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6"
      >
        {SavedColors.component()}
      </div>
    </div>
  }
}
