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
      (g -. b) /. delta % 6.0
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

let copyToClipboard = (_text: string) => {
  let _ = %raw(`navigator.clipboard.writeText(_text)`)
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
  @jsx.component
  let make = (~label: string, ~value: Signal.t<int>, ~onChange: Dom.event => unit) => {
    <div class="color-demo-slider-group">
      <div class="color-demo-slider-label">
        <span> {View.text(label)} </span>
        <span class="color-demo-slider-value">
          <View.Int> {value} </View.Int>
        </span>
      </div>
      <input
        type_="range"
        min="0"
        max="255"
        class="demo-input-range"
        value={() => Signal.get(value)->Int.toString}
        onInput={onChange}
      />
    </div>
  }
}

module ColorPreview = {
  @jsx.component
  let make = () => {
    <div class="color-demo-preview">
      <div
        style={() =>
          `background-color: ${Signal.get(rgbColor)}; transition: background-color 0.2s ease; width: 100%; height: 100%; display: flex; align-items: center; justify-content: center;`}
      >
        <div class="color-demo-hex-overlay">
          {View.signalText(() => Signal.get(hexColor))}
        </div>
      </div>
    </div>
  }
}

module ColorInfo = {
  module ColorValueRow = {
    @jsx.component
    let make = (~label: string, ~value: Signal.t<string>) => {
      <div class="color-demo-value-row">
        <span> {View.text(label)} </span>
        <div>
          <span> <View.Text> {value} </View.Text> </span>
          <button
            class="demo-btn demo-btn-secondary"
            onClick={_evt => copyToClipboard(Signal.get(value))}
          >
            {View.text("Copy")}
          </button>
        </div>
      </div>
    }
  }

  @jsx.component
  let make = () => {
    <div>
      <h3> {View.text("Color Values")} </h3>
      <ColorValueRow label="HEX" value={hexColor} />
      <ColorValueRow label="RGB" value={rgbColor} />
      <ColorValueRow label="HSL" value={hslColor} />
    </div>
  }
}

module ColorPalette = {
  module PaletteItem = {
    @jsx.component
    let make = (~label: string, ~color: Signal.t<string>) => {
      <div class="color-demo-palette-wrapper">
        <div
          class="color-demo-palette-swatch"
          style={() => `background-color: ${Signal.get(color)}`}
          onClick={_evt => copyToClipboard(Signal.get(color))}
        />
        <p class="color-demo-palette-label"> {View.text(label)} </p>
      </div>
    }
  }

  @jsx.component
  let make = () => {
    <div>
      <h3> {View.text("Color Variations")} </h3>
      <div class="demo-grid-3">
        <PaletteItem label="Lighter" color={lighterColor} />
        <PaletteItem label="Current" color={rgbColor} />
        <PaletteItem label="Darker" color={darkerColor} />
      </div>
      <div style="margin-top: 0.75rem;">
        <PaletteItem label="Complementary" color={complementaryColor} />
      </div>
    </div>
  }
}

module SavedColors = {
  @jsx.component
  let make = () => {
    let hasSavedColors = Computed.make(() => Signal.get(savedColors)->Array.length > 0)

    <div>
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 0.75rem;">
        <h3> {View.text("Saved Colors")} </h3>
        <button class="demo-btn demo-btn-primary" onClick={saveColor}>
          {View.text("+ Save Current")}
        </button>
      </div>
      <View.Show
        when_={Prop.signal(hasSavedColors)}
        fallback={
          <p style="text-align: center; padding: 1rem 0; opacity: 0.6;">
            {View.text("No saved colors yet")}
          </p>
        }>
        <div class="color-demo-saved-grid">
          <View.For
            each={Prop.signal(savedColors)}
            render={color =>
              <div
                class="color-demo-palette-item"
                style={`background-color: ${color}`}
                onClick={_evt => copyToClipboard(color)}
              />
            }
          />
        </div>
      </View.Show>
    </div>
  }
}

@jsx.component
let make = () => {
  <div class="demo-container">
    // Color Preview
    <ColorPreview />

    // RGB Sliders
    <div class="demo-section">
      <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 1rem;">
        <h2> {View.text("RGB Mixer")} </h2>
        <button class="demo-btn demo-btn-secondary" onClick={randomColor}>
          {View.text("Random")}
        </button>
      </div>
      <ColorSlider label="Red" value={red} onChange={updateRed} />
      <ColorSlider label="Green" value={green} onChange={updateGreen} />
      <ColorSlider label="Blue" value={blue} onChange={updateBlue} />
    </div>

    // Two column layout for info and palette
    <div class="demo-grid-2">
      <div class="demo-section">
        <ColorInfo />
      </div>
      <div class="demo-section">
        <ColorPalette />
      </div>
    </div>

    // Saved colors
    <div class="demo-section">
      <SavedColors />
    </div>
  </div>
}
