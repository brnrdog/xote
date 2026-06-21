@genType
type attrValue

@genType
type node

type eventHandler = Dom.event => unit

@genType
let attr = (key: string, value: string): (string, attrValue) => Obj.magic(View.attr(key, value))

@genType
let signalAttr = (key: string, signal: TypeScriptSignal.t<string>): (string, attrValue) =>
  Obj.magic(View.signalAttr(key, Obj.magic(signal)))

@genType
let computedAttr = (key: string, compute: unit => string): (string, attrValue) =>
  Obj.magic(View.computedAttr(key, compute))

@genType
let text = (content: string): node => Obj.magic(View.text(content))

@genType
let signalText = (compute: unit => string): node =>
  Obj.magic(View.SignalText(Computed.make(compute)))

@genType
let signalInt = (compute: unit => int): node =>
  Obj.magic(View.SignalText(Computed.make(() => compute()->Int.toString)))

@genType
let signalFloat = (compute: unit => float): node =>
  Obj.magic(View.SignalText(Computed.make(() => compute()->Float.toString)))

@genType
let int = (value: int): node => Obj.magic(View.int(value))

@genType
let float = (value: float): node => Obj.magic(View.float(value))

@genType
let bool = (value: bool): node => Obj.magic(View.bool(value))

@genType
let fragment = (children: array<node>): node => Obj.magic(View.fragment(Obj.magic(children)))

@genType
let signalFragment = (signal: TypeScriptSignal.t<array<node>>): node =>
  Obj.magic(View.signalFragment(Obj.magic(signal)))

@genType
let each = (signal: TypeScriptSignal.t<array<'a>>, renderItem: 'a => node): node =>
  Obj.magic(View.each(Obj.magic(signal), item => Obj.magic(renderItem(item))))

@genType
let eachWithKey = (
  signal: TypeScriptSignal.t<array<'a>>,
  keyFn: 'a => string,
  renderItem: 'a => node,
): node =>
  Obj.magic(View.eachWithKey(Obj.magic(signal), keyFn, item => Obj.magic(renderItem(item))))

@genType
let element = (
  tag: string,
  ~attrs: array<(string, attrValue)>=[],
  ~events: array<(string, eventHandler)>=[],
  ~children: array<node>=[],
  (),
): node => {
  Obj.magic(View.element(tag, ~attrs=Obj.magic(attrs), ~events, ~children=Obj.magic(children), ()))
}

@genType
let null = (): node => Obj.magic(View.null())

@genType
let mount = (node: node, container: Dom.element): unit => {
  View.mount(Obj.magic(node), container)
}

@genType
let mountById = (node: node, containerId: string): unit => {
  View.mountById(Obj.magic(node), containerId)
}
