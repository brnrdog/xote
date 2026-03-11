let target = (e: Dom.event) => Obj.magic(e)["target"]

let preventDefault = (e: Dom.event) => %raw(`e.preventDefault()`)

let stopPropagation = (e: Dom.event) => %raw(`e.stopPropagation()`)

let addEventListener = %raw(`function(a, b) { document.addEventListener(a, b) }`)

@set external setInnerHTML: (Dom.element, string) => unit = "setInnerHTML"
