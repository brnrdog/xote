%%raw(`import './Basefn__ThemeToggle.css'`)

open Xote

@jsx.component
let make = (~size: [#Sm | #Md | #Lg]=#Md) => {
  let theme = Basefn__Theme.currentTheme

  let handleClick = e => {
    Basefn__Dom.preventDefault(e)->ignore
    Basefn__Dom.stopPropagation(e)->ignore
    Basefn__Theme.toggleTheme()
  }

  let icon = Computed.make(() => {
    switch Signal.get(theme) {
    | Light => [<Basefn__Icon name={Sun} />]
    | Dark => [<Basefn__Icon name={Moon} />]
    }
  })

  <Basefn__Tooltip content="Toggle theme" position={Bottom}>
    <Basefn__Button
      variant=Ghost onClick={handleClick} class={"basefn-theme-toggle"->ReactiveProp.static}
    >
      {Component.signalFragment(icon)}
    </Basefn__Button>
  </Basefn__Tooltip>
}
