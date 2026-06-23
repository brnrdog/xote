type attrs = array<(string, TypeScriptView.attrValue)>
type events = array<(string, Dom.event => unit)>
type children = array<TypeScriptView.node>

@genType
let div = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.div(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let span = (
  ~attrs: attrs=[],
  ~events: events=[],
  ~children: children=[],
  (),
): TypeScriptView.node =>
  Obj.magic(Html.span(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let button = (
  ~attrs: attrs=[],
  ~events: events=[],
  ~children: children=[],
  (),
): TypeScriptView.node =>
  Obj.magic(Html.button(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let input = (~attrs: attrs=[], ~events: events=[], ()): TypeScriptView.node =>
  Obj.magic(Html.input(~attrs=Obj.magic(attrs), ~events, ()))

@genType
let h1 = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.h1(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let h2 = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.h2(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let h3 = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.h3(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let p = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.p(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let ul = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.ul(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let li = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.li(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))

@genType
let a = (~attrs: attrs=[], ~events: events=[], ~children: children=[], ()): TypeScriptView.node =>
  Obj.magic(Html.a(~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))
