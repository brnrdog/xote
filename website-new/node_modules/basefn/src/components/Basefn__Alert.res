%%raw(`import './Basefn__Alert.css'`)

open Xote

type variant = Info | Success | Warning | Error

let variantToString = (variant: variant) => {
  switch variant {
  | Info => "info"
  | Success => "success"
  | Warning => "warning"
  | Error => "error"
  }
}

@jsx.component
let make = (
  ~title: option<string>=?,
  ~message: Signal.t<string>,
  ~variant: variant=Info,
  ~dismissible: bool=false,
  ~onDismiss: option<unit => unit>=?,
) => {
  let isVisible = Signal.make(true)

  let handleDismiss = () => {
    Signal.set(isVisible, false)
    switch onDismiss {
    | Some(callback) => callback()
    | None => ()
    }
  }

  let getClassName = () => {
    let variantClass = "basefn-alert--" ++ variantToString(variant)
    "basefn-alert " ++ variantClass
  }

  // Use computed signal to reactively determine which nodes to render
  let content = Computed.make(() => {
    if Signal.get(isVisible) {
      [
        <div class={getClassName()}>
          <div class="basefn-alert__content">
            {switch title {
            | Some(titleText) =>
              <div class="basefn-alert__title"> {Component.text(titleText)} </div>
            | None => <> </>
            }}
            <div class="basefn-alert__message">
              {Component.textSignal(() => Signal.get(message))}
            </div>
          </div>
          {dismissible
            ? <button class="basefn-alert__dismiss" onClick={_ => handleDismiss()}>
                {Component.text("\u00d7")}
              </button>
            : <> </>}
        </div>,
      ]
    } else {
      []
    }
  })

  // Use signalFragment to reactively render the content
  Component.signalFragment(content)
}
