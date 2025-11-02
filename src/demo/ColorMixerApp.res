open Xote

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
  Core.batch(() => {
    Signal.set(red, Int.fromFloat(Math.random() *. 255.0))
    Signal.set(green, Int.fromFloat(Math.random() *. 255.0))
    Signal.set(blue, Int.fromFloat(Math.random() *. 255.0))
  })
}

module ColorSlider = {
  let component = (~label: string, ~value: Core.t<int>, ~color: string, ~onChange, ()) => {
    Component.div(
      ~attrs=[Component.attr("class", "space-y-2")],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "flex items-center justify-between")],
          ~children=[
            Component.span(
              ~attrs=[
                Component.attr("class", "text-sm font-semibold text-stone-700 dark:text-stone-300"),
              ],
              ~children=[Component.text(label)],
              (),
            ),
            Component.span(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-sm font-mono font-bold text-stone-900 dark:text-white w-12 text-right",
                ),
              ],
              ~children=[Component.textSignal(() => Signal.get(value)->Int.toString)],
              (),
            ),
          ],
          (),
        ),
        Component.input(
          ~attrs=[
            Component.attr("type", "range"),
            Component.attr("min", "0"),
            Component.attr("max", "255"),
            Component.computedAttr("value", () => Signal.get(value)->Int.toString),
            Component.attr(
              "class",
              "w-full h-2 rounded-lg appearance-none cursor-pointer " ++ color,
            ),
          ],
          ~events=[("input", onChange)],
          (),
        ),
      ],
      (),
    )
  }
}

module ColorPreview = {
  let component = () => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "rounded-2xl border-4 border-stone-200 dark:border-stone-700 overflow-hidden shadow-xl",
        ),
      ],
      ~children=[
        Component.div(
          ~attrs=[
            Component.attr("class", "h-48 md:h-64 relative transition-colors duration-200"),
            Component.computedAttr("style", () =>
              `background-color: ${Signal.get(rgbColor)}; transition: background-color 0.2s ease`
            ),
          ],
          ~children=[
            Component.div(
              ~attrs=[
                Component.attr(
                  "class",
                  "absolute inset-0 flex items-center justify-center bg-black/10",
                ),
              ],
              ~children=[
                Component.div(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "bg-white dark:bg-stone-800 px-6 py-3 rounded-xl shadow-lg backdrop-blur",
                    ),
                  ],
                  ~children=[
                    Component.p(
                      ~attrs=[
                        Component.attr(
                          "class",
                          "font-mono font-bold text-xl text-stone-900 dark:text-white",
                        ),
                      ],
                      ~children=[Component.textSignal(() => Signal.get(hexColor))],
                      (),
                    ),
                  ],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module ColorInfo = {
  let colorValueRow = (label: string, value: Core.t<string>) => {
    Component.div(
      ~attrs=[
        Component.attr(
          "class",
          "flex items-center justify-between p-3 bg-stone-50 dark:bg-stone-700/50 rounded-lg",
        ),
      ],
      ~children=[
        Component.span(
          ~attrs=[
            Component.attr("class", "text-sm font-medium text-stone-600 dark:text-stone-400"),
          ],
          ~children=[Component.text(label)],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "flex items-center gap-2")],
          ~children=[
            Component.span(
              ~attrs=[
                Component.attr("class", "text-sm font-mono text-stone-900 dark:text-white"),
              ],
              ~children=[Component.textSignal(() => Signal.get(value))],
              (),
            ),
            Component.button(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-xs px-2 py-1 bg-stone-200 dark:bg-stone-600 hover:bg-stone-300 dark:hover:bg-stone-500 rounded transition-colors",
                ),
              ],
              ~events=[("click", _evt => copyToClipboard(Signal.get(value)))],
              ~children=[Component.text("Copy")],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }

  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "space-y-2")],
      ~children=[
        Component.h3(
          ~attrs=[
            Component.attr("class", "text-lg font-bold text-stone-900 dark:text-white mb-3"),
          ],
          ~children=[Component.text("Color Values")],
          (),
        ),
        colorValueRow("HEX", hexColor),
        colorValueRow("RGB", rgbColor),
        colorValueRow("HSL", hslColor),
      ],
      (),
    )
  }
}

module ColorPalette = {
  let paletteItem = (label: string, color: Core.t<string>) => {
    Component.div(
      ~attrs=[Component.attr("class", "text-center space-y-2")],
      ~children=[
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "h-20 rounded-lg border-2 border-stone-200 dark:border-stone-700 cursor-pointer hover:scale-105 transition-transform",
            ),
            Component.computedAttr("style", () => `background-color: ${Signal.get(color)}`),
          ],
          ~events=[("click", _evt => copyToClipboard(Signal.get(color)))],
          (),
        ),
        Component.p(
          ~attrs=[
            Component.attr("class", "text-xs font-medium text-stone-600 dark:text-stone-400"),
          ],
          ~children=[Component.text(label)],
          (),
        ),
      ],
      (),
    )
  }

  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "space-y-3")],
      ~children=[
        Component.h3(
          ~attrs=[
            Component.attr("class", "text-lg font-bold text-stone-900 dark:text-white"),
          ],
          ~children=[Component.text("Color Variations")],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "grid grid-cols-3 gap-3")],
          ~children=[
            paletteItem("Lighter", lighterColor),
            paletteItem("Current", rgbColor),
            paletteItem("Darker", darkerColor),
          ],
          (),
        ),
        paletteItem("Complementary", complementaryColor),
      ],
      (),
    )
  }
}

module SavedColors = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "space-y-3")],
      ~children=[
        Component.div(
          ~attrs=[Component.attr("class", "flex items-center justify-between")],
          ~children=[
            Component.h3(
              ~attrs=[
                Component.attr("class", "text-lg font-bold text-stone-900 dark:text-white"),
              ],
              ~children=[Component.text("Saved Colors")],
              (),
            ),
            Component.button(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-xs px-3 py-1.5 bg-stone-900 dark:bg-stone-700 hover:bg-stone-700 dark:hover:bg-stone-600 text-white rounded-lg transition-colors",
                ),
              ],
              ~events=[("click", saveColor)],
              ~children=[Component.text("+ Save Current")],
              (),
            ),
          ],
          (),
        ),
        Component.signalFragment(
          Computed.make(() => {
            let colors = Signal.get(savedColors)
            if Array.length(colors) == 0 {
              [
                Component.p(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-sm text-stone-500 dark:text-stone-500 text-center py-4",
                    ),
                  ],
                  ~children=[Component.text("No saved colors yet")],
                  (),
                ),
              ]
            } else {
              [
                Component.div(
                  ~attrs=[Component.attr("class", "grid grid-cols-4 gap-2")],
                  ~children=[
                    Component.list(
                      savedColors,
                      color => {
                        Component.div(
                          ~attrs=[
                            Component.attr(
                              "class",
                              "h-12 rounded-lg border-2 border-stone-200 dark:border-stone-700 cursor-pointer hover:scale-105 transition-transform",
                            ),
                            Component.attr("style", `background-color: ${color}`),
                            Component.attr("title", color),
                          ],
                          ~events=[("click", _evt => copyToClipboard(color))],
                          (),
                        )
                      },
                    ),
                  ],
                  (),
                ),
              ]
            }
          }),
        ),
      ],
      (),
    )
  }
}

module ColorMixerApp = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "max-w-4xl mx-auto p-4 md:p-6 space-y-6")],
      ~children=[
        // Header
        Component.div(
          ~attrs=[Component.attr("class", "mb-6")],
          ~children=[
            Component.h1(
              ~attrs=[
                Component.attr(
                  "class",
                  "text-2xl md:text-3xl font-bold text-stone-900 dark:text-white mb-2",
                ),
              ],
              ~children=[Component.text("Color Mixer")],
              (),
            ),
            Component.p(
              ~attrs=[
                Component.attr("class", "text-sm md:text-base text-stone-600 dark:text-stone-400"),
              ],
              ~children=[
                Component.text("Mix colors with RGB sliders and explore variations in real-time"),
              ],
              (),
            ),
          ],
          (),
        ),
        // Color Preview
        ColorPreview.component(),
        // RGB Sliders
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6 space-y-4",
            ),
          ],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "flex items-center justify-between mb-4")],
              ~children=[
                Component.h2(
                  ~attrs=[
                    Component.attr("class", "text-xl font-bold text-stone-900 dark:text-white"),
                  ],
                  ~children=[Component.text("RGB Mixer")],
                  (),
                ),
                Component.button(
                  ~attrs=[
                    Component.attr(
                      "class",
                      "text-sm px-4 py-2 bg-stone-200 dark:bg-stone-700 hover:bg-stone-300 dark:hover:bg-stone-600 rounded-lg transition-colors",
                    ),
                  ],
                  ~events=[("click", randomColor)],
                  ~children=[Component.text("🎲 Random")],
                  (),
                ),
              ],
              (),
            ),
            ColorSlider.component(
              ~label="Red",
              ~value=red,
              ~color="bg-red-500",
              ~onChange=updateRed,
              (),
            ),
            ColorSlider.component(
              ~label="Green",
              ~value=green,
              ~color="bg-green-500",
              ~onChange=updateGreen,
              (),
            ),
            ColorSlider.component(
              ~label="Blue",
              ~value=blue,
              ~color="bg-blue-500",
              ~onChange=updateBlue,
              (),
            ),
          ],
          (),
        ),
        // Two column layout for info and palette
        Component.div(
          ~attrs=[Component.attr("class", "grid md:grid-cols-2 gap-6")],
          ~children=[
            Component.div(
              ~attrs=[
                Component.attr(
                  "class",
                  "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6",
                ),
              ],
              ~children=[ColorInfo.component()],
              (),
            ),
            Component.div(
              ~attrs=[
                Component.attr(
                  "class",
                  "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6",
                ),
              ],
              ~children=[ColorPalette.component()],
              (),
            ),
          ],
          (),
        ),
        // Saved colors
        Component.div(
          ~attrs=[
            Component.attr(
              "class",
              "bg-white dark:bg-stone-800 rounded-2xl border-2 border-stone-200 dark:border-stone-700 p-6",
            ),
          ],
          ~children=[SavedColors.component()],
          (),
        ),
      ],
      (),
    )
  }
}
