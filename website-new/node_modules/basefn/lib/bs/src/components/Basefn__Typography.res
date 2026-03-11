%%raw(`import './Basefn__Typography.css'`)

open Xote

type variant = H1 | H2 | H3 | H4 | H5 | H6 | P | Small | Lead | Muted | Code | Unstyled

type align = Left | Center | Right | Justify

let variantToTag = (variant: variant) => {
  switch variant {
  | H1 => "h1"
  | H2 => "h2"
  | H3 => "h3"
  | H4 => "h4"
  | H5 => "h5"
  | H6 => "h6"
  | P => "p"
  | Small => "small"
  | Lead => "p"
  | Muted => "p"
  | Code => "code"
  | Unstyled => "div"
  }
}

let variantToClass = (variant: variant) => {
  switch variant {
  | H1 => "basefn-typography--h1"
  | H2 => "basefn-typography--h2"
  | H3 => "basefn-typography--h3"
  | H4 => "basefn-typography--h4"
  | H5 => "basefn-typography--h5"
  | H6 => "basefn-typography--h6"
  | P => "basefn-typography--p"
  | Small => "basefn-typography--small"
  | Lead => "basefn-typography--lead"
  | Muted => "basefn-typography--muted"
  | Code => "basefn-typography--code"
  | Unstyled => "basefn-typography--unstyled"
  }
}

let alignToString = (align: align) => {
  switch align {
  | Left => "left"
  | Center => "center"
  | Right => "right"
  | Justify => "justify"
  }
}

@jsx.component
let make = (
  ~text: ReactiveProp.t<string>,
  ~variant: variant=P,
  ~align: option<align>=?,
  ~class: string="",
  ~style=?,
) => {
  let variantClass = variantToClass(variant)

  let class = {
    let baseClass = "basefn-typography " ++ variantClass
    let alignClass = switch align {
    | Some(a) => " basefn-typography--" ++ alignToString(a)
    | None => ""
    }
    let customClass = if class !== "" {
      " " ++ class
    } else {
      ""
    }
    baseClass ++ alignClass ++ customClass
  }

  let renderText = text =>
    switch text {
    | ReactiveProp.Reactive(text) => Component.SignalText(text)
    | ReactiveProp.Static(text) => Component.text(text)
    }

  switch variant {
  | H1 => <h1 class ?style> {renderText(text)} </h1>
  | H2 => <h2 class ?style> {renderText(text)} </h2>
  | H3 => <h3 class ?style> {renderText(text)} </h3>
  | H4 => <h4 class ?style> {renderText(text)} </h4>
  | H5 => <h5 class ?style> {renderText(text)} </h5>
  | H6 => <h6 class ?style> {renderText(text)} </h6>
  | P => <p class ?style> {renderText(text)} </p>
  | Small => <small class ?style> {renderText(text)} </small>
  | Lead => <p class ?style> {renderText(text)} </p>
  | Muted => <p class ?style> {renderText(text)} </p>
  | Code => <code class ?style> {renderText(text)} </code>
  | Unstyled => <div class ?style> {renderText(text)} </div>
  }
}
