open Xote

%%raw(`import './Basefn__Button.css'`)

type variant = Primary | Secondary | Ghost

let variantToString = (variant: variant) => {
  switch variant {
  | Primary => "primary"
  | Secondary => "secondary"
  | Ghost => "ghost"
  }
}

@jsx.component
let make = (
  ~children=Xote__JSX.null(),
  ~class=ReactiveProp.static(""),
  ~disabled=ReactiveProp.static(false),
  ~label=ReactiveProp.static(""),
  ~onClick=evt => {
    Basefn__Dom.preventDefault(evt)
  },
  ~variant: variant=Primary,
) => {
  let class = Computed.make(() => {
    let variantClass = "basefn-button--" ++ variantToString(variant)
    "basefn-button " ++ variantClass ++ " " ++ class->ReactiveProp.get
  })

  <button class disabled onClick> {children} </button>
}
