%%raw(`import './Basefn__AlertDialog.css'`)

open Xote

type variant = Default | Destructive

let variantToString = (variant: variant) => {
  switch variant {
  | Default => "default"
  | Destructive => "destructive"
  }
}

@jsx.component
let make = (
  ~isOpen: Signal.t<bool>,
  ~title: string,
  ~description: string,
  ~confirmLabel: string="Confirm",
  ~cancelLabel: string="Cancel",
  ~onConfirm: unit => unit,
  ~onCancel: unit => unit,
  ~variant: variant=Default,
  ~closeOnBackdrop: bool=false,
) => {
  let handleBackdropClick = evt => {
    if closeOnBackdrop {
      let target = Obj.magic(evt)["target"]
      let currentTarget = Obj.magic(evt)["currentTarget"]
      if target === currentTarget {
        onCancel()
      }
    }
  }

  let handleCancel = _ => {
    Signal.set(isOpen, false)
    onCancel()
  }

  let handleConfirm = _ => {
    Signal.set(isOpen, false)
    onConfirm()
  }

  let getConfirmButtonClass = () => {
    let baseClass = "basefn-alert-dialog__confirm"
    let variantClass = " basefn-alert-dialog__confirm--" ++ variantToString(variant)
    baseClass ++ variantClass
  }

  let content = Computed.make(() => {
    if Signal.get(isOpen) {
      [
        <div class="basefn-alert-dialog-backdrop" onClick={handleBackdropClick}>
          <div class="basefn-alert-dialog" role="alertdialog">
            <div class="basefn-alert-dialog__header">
              <h2 class="basefn-alert-dialog__title"> {Component.text(title)} </h2>
            </div>
            <div class="basefn-alert-dialog__body">
              <p class="basefn-alert-dialog__description"> {Component.text(description)} </p>
            </div>
            <div class="basefn-alert-dialog__footer">
              <button class="basefn-alert-dialog__cancel" onClick={handleCancel}>
                {Component.text(cancelLabel)}
              </button>
              <button class={getConfirmButtonClass()} onClick={handleConfirm}>
                {Component.text(confirmLabel)}
              </button>
            </div>
          </div>
        </div>,
      ]
    } else {
      []
    }
  })

  Component.signalFragment(content)
}
