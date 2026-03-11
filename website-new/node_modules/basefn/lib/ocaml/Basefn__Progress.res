%%raw(`import './Basefn__Progress.css'`)

open Xote

type size = Sm | Md | Lg

type variant = Default | Primary | Success | Warning | Error

let sizeToString = (size: size) => {
  switch size {
  | Sm => "sm"
  | Md => "md"
  | Lg => "lg"
  }
}

let variantToString = (variant: variant) => {
  switch variant {
  | Default => "default"
  | Primary => "primary"
  | Success => "success"
  | Warning => "warning"
  | Error => "error"
  }
}

@jsx.component
let make = (
  ~value: Signal.t<float>,
  ~max: float=100.0,
  ~size: size=Md,
  ~variant: variant=Primary,
  ~showLabel: bool=false,
  ~label: option<string>=?,
  ~indeterminate: bool=false,
) => {
  let getProgressClass = () => {
    let sizeClass = "basefn-progress--" ++ sizeToString(size)
    "basefn-progress " ++ sizeClass
  }

  let getBarClass = () => {
    let variantClass = "basefn-progress__bar--" ++ variantToString(variant)
    let animatedClass = indeterminate ? " basefn-progress__bar--animated" : ""
    "basefn-progress__bar " ++ variantClass ++ animatedClass
  }

  let getPercentage = () => {
    let currentValue = Signal.get(value)
    let percent = currentValue /. max *. 100.0
    let clamped = if percent > 100.0 {
      100.0
    } else if percent < 0.0 {
      0.0
    } else {
      percent
    }
    Float.toString(clamped)
  }

  <>
    <div class={getProgressClass()}>
      <div
        class={getBarClass()}
        style={Computed.make(() => {
          if indeterminate {
            "width: 30%"
          } else {
            "width: " ++ getPercentage() ++ "%"
          }
        })}
      />
    </div>
    {showLabel || label->Option.isSome
      ? <div class="basefn-progress__label">
          <span>
            {Component.text(
              switch label {
              | Some(labelText) => labelText
              | None => "Progress"
              },
            )}
          </span>
          {!indeterminate ? {Component.textSignal(() => getPercentage() ++ "%")} : <> </>}
        </div>
      : <> </>}
  </>
}
