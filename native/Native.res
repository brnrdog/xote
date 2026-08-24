/* The function-based surface, for code that does not turn JSX on.

 These are thin wrappers over `View.element` with the tag names the host
 implements — everything JSX does, minus the syntax. */

module Style = NativeStyle

let build = (
  tag: string,
  ~style: option<NativeStyle.t>,
  ~styleSignal: option<Signal.t<NativeStyle.t>>,
  ~attrs: array<(string, View.attrValue)>,
  ~events: array<(string, Dom.event => unit)>,
  ~children: array<View.node>,
): View.node => {
  let resolved = []
  switch style {
  | Some(style) => resolved->Array.push(NativeProp.value("style", style))
  | None => ()
  }
  switch styleSignal {
  | Some(signal) => resolved->Array.push(NativeProp.signal("style", signal))
  | None => ()
  }
  attrs->Array.forEach(attr => resolved->Array.push(attr))
  View.element(tag, ~attrs=resolved, ~events, ~children, ())
}

let make = (
  tag: string,
  ~style=?,
  ~styleSignal=?,
  ~attrs=[],
  ~events=[],
  ~onPress=?,
  ~children=[],
  (),
): View.node => {
  let allEvents = switch onPress {
  | Some(handler) => events->Array.concat([("press", NativeEvent.handler(handler))])
  | None => events
  }
  build(tag, ~style, ~styleSignal, ~attrs, ~events=allEvents, ~children)
}

let view = (~style=?, ~styleSignal=?, ~attrs=[], ~events=[], ~onPress=?, ~children=[], ()) =>
  make("view", ~style?, ~styleSignal?, ~attrs, ~events, ~onPress?, ~children, ())

let text = (~style=?, ~styleSignal=?, ~attrs=[], ~events=[], ~onPress=?, ~children=[], ()) =>
  make("text", ~style?, ~styleSignal?, ~attrs, ~events, ~onPress?, ~children, ())

let image = (~source, ~style=?, ~styleSignal=?, ~attrs=[], ~events=[], ()) =>
  make(
    "image",
    ~style?,
    ~styleSignal?,
    ~attrs=attrs->Array.concat([NativeProp.value("source", source)]),
    ~events,
    (),
  )

let scroll = (~style=?, ~styleSignal=?, ~attrs=[], ~events=[], ~children=[], ()) =>
  make("scroll", ~style?, ~styleSignal?, ~attrs, ~events, ~children, ())

let input = (~style=?, ~styleSignal=?, ~attrs=[], ~events=[], ~onChangeText=?, ()) =>
  make(
    "input",
    ~style?,
    ~styleSignal?,
    ~attrs,
    ~events=switch onChangeText {
    | Some(handler) => events->Array.concat([("changeText", NativeEvent.handler(handler))])
    | None => events
    },
    (),
  )

let pressable = (~onPress, ~style=?, ~styleSignal=?, ~attrs=[], ~events=[], ~children=[], ()) =>
  make("pressable", ~style?, ~styleSignal?, ~attrs, ~events, ~onPress, ~children, ())
