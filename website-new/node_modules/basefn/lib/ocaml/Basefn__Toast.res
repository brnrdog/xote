%%raw(`import './Basefn__Toast.css'`)

open Xote

type variant = Info | Success | Warning | Error

type position = TopRight | TopLeft | BottomRight | BottomLeft

let variantToString = (variant: variant) => {
  switch variant {
  | Info => "info"
  | Success => "success"
  | Warning => "warning"
  | Error => "error"
  }
}

let positionToString = (position: position) => {
  switch position {
  | TopRight => "top-right"
  | TopLeft => "top-left"
  | BottomRight => "bottom-right"
  | BottomLeft => "bottom-left"
  }
}

@jsx.component
let make = (
  ~title: option<string>=?,
  ~message: string,
  ~variant: variant=Info,
  ~position: position=TopRight,
  ~isVisible: Signal.t<bool>,
  ~onClose: unit => unit,
  ~autoDismiss: bool=true,
  ~duration: int=3000,
) => {
  // Auto dismiss logic
  let _ = Effect.run(() => {
    if Signal.get(isVisible) && autoDismiss {
      let timeoutId = setTimeout(() => {
        Signal.set(isVisible, false)
        onClose()
      }, duration)
      Some(() => clearTimeout(timeoutId))
    } else {
      None
    }
  })

  let getToastClass = () => {
    let variantClass = "basefn-toast--" ++ variantToString(variant)
    "basefn-toast " ++ variantClass
  }

  let getContainerClass = () => {
    let posClass = "basefn-toast-container--" ++ positionToString(position)
    "basefn-toast-container " ++ posClass
  }

  let content = Computed.make(() => {
    if Signal.get(isVisible) {
      [
        <div class={getContainerClass()}>
          <div class={getToastClass()}>
            <div class="basefn-toast__content">
              {switch title {
              | Some(titleText) =>
                <div class="basefn-toast__title"> {Component.text(titleText)} </div>
              | None => <> </>
              }}
              <div class="basefn-toast__message"> {Component.text(message)} </div>
            </div>
            <button
              class="basefn-toast__close"
              onClick={_ => {
                Signal.set(isVisible, false)
                onClose()
              }}
            >
              {Component.text("\u00d7")}
            </button>
          </div>
        </div>,
      ]
    } else {
      []
    }
  })

  Component.signalFragment(content)
}
