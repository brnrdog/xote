%%raw(`import './Basefn__Slider.css'`)

open Xote

@jsx.component
let make = (
  ~value: Signal.t<float>,
  ~onChange: option<float => unit>=?,
  ~min: float=0.0,
  ~max: float=100.0,
  ~step: float=1.0,
  ~label: option<string>=?,
  ~showValue: bool=true,
  ~disabled: bool=false,
  ~markers: option<array<string>>=?,
) => {
  let handleInput = evt => {
    let target = Obj.magic(evt)["target"]
    let newValue = Float.fromString(target["value"])->Option.getOr(0.0)
    Signal.set(value, newValue)
    switch onChange {
    | Some(callback) => callback(newValue)
    | None => ()
    }
  }

  <div class="basefn-slider">
    <div class="basefn-slider__wrapper">
      {switch (label, showValue) {
      | (Some(_), _) | (None, true) =>
        <div class="basefn-slider__header">
          {switch label {
          | Some(labelText) =>
            <span class="basefn-slider__label"> {Component.text(labelText)} </span>
          | None => <> </>
          }}
          {showValue
            ? <span class="basefn-slider__value">
                {Component.textSignal(() => Float.toString(Signal.get(value)))}
              </span>
            : <> </>}
        </div>
      | _ => <> </>
      }}
      <input
        type_="range"
        class="basefn-slider__input"
        min={Float.toString(min)}
        max={Float.toString(max)}
        step={Float.toString(step)}
        value={value}
        onInput={handleInput}
        disabled
      />
      {switch markers {
      | Some(markerLabels) =>
        <div class="basefn-slider__markers">
          {markerLabels
          ->Array.map(marker => {
            <span class="basefn-slider__marker"> {Component.text(marker)} </span>
          })
          ->Component.fragment}
        </div>
      | None => <> </>
      }}
    </div>
  </div>
}
