open Signals
module Component = Xote__Component

/* ReScript JSX transform type aliases */
type element = Component.node

type component<'props> = 'props => element

type componentLike<'props, 'return> = 'props => 'return

/* JSX functions for component creation */
let jsx = (component: component<'props>, props: 'props): element => component(props)

let jsxs = (component: component<'props>, props: 'props): element => component(props)

let jsxKeyed = (
  component: component<'props>,
  props: 'props,
  ~key: option<string>=?,
  _: unit,
): element => {
  let _ = key /* TODO: Implement key support for list reconciliation */
  component(props)
}

let jsxsKeyed = (
  component: component<'props>,
  props: 'props,
  ~key: option<string>=?,
  _: unit,
): element => {
  let _ = key
  component(props)
}

/* Fragment support */
type fragmentProps = {children?: element}

let jsxFragment = (props: fragmentProps): element => {
  switch props.children {
  | Some(child) => child
  | None => Component.fragment([])
  }
}

/* Element converters for JSX expressions */
let array = (children: array<element>): element => Component.fragment(children)

let null = (): element => Component.text("")

/* Elements module for lowercase HTML tags */
module Elements = {
  /* Attribute value type that can be static, signal, or computed */
  @unboxed
  type rec attributeValue = Any('a): attributeValue

  /* Automatic conversion from string to attributeValue */
  external fromString: string => attributeValue = "%identity"

  /* Helper to convert a signal to an attributeValue */
  let signal = (s: Signals.Signal.t<string>): attributeValue => Any(s)

  /* Helper to convert a computed function to an attributeValue */
  let computed = (f: unit => string): attributeValue => Any(f)

  /* Props type for HTML elements - supports common attributes and events */
  type props<
    'id,
    'class,
    'style,
    'typ,
    'value,
    'placeholder,
    'href,
    'target,
    'data,
    'width,
    'height,
    'src,
    'fill,
    'viewBox,
    'stroke,
    'strokeWidth,
    'strokeLinecap,
    'strokeMiterlimit,
    'd,
  > = {
    /* Standard attributes - can be static strings or reactive values */
    id?: 'id,
    class?: 'class,
    width?: 'width,
    height?: 'height,
    src?: 'src,
    style?: 'style,
    fill?: 'fill,
    /* SVG attributes */
    viewBox?: 'viewBox,
    stroke?: 'stroke,
    strokeWidth?: 'strokeWidth,
    strokeLinecap?: 'strokeLinecap,
    strokeMiterlimit?: 'strokeMiterlimit,
    d?: 'd,
    /* Input attributes */
    @as("type") type_?: 'typ,
    value?: 'value,
    placeholder?: 'placeholder,
    disabled?: bool,
    checked?: bool,
    /* Link attributes */
    href?: 'href,
    target?: 'target,
    /* Data attributes */
    data?: 'data,
    /* Event handlers */
    onClick?: Dom.event => unit,
    onInput?: Dom.event => unit,
    onChange?: Dom.event => unit,
    onSubmit?: Dom.event => unit,
    onFocus?: Dom.event => unit,
    onBlur?: Dom.event => unit,
    onKeyDown?: Dom.event => unit,
    onKeyUp?: Dom.event => unit,
    onMouseEnter?: Dom.event => unit,
    onMouseLeave?: Dom.event => unit,
    /* Children */
    children?: element,
  }

  /* Helper to detect if a value is a signal (has an id property) */
  @get external hasId: 'a => option<int> = "id"

  /* Helper to convert any value to Component.attrValue */
  let convertAttrValue = (key: string, value: 'a): (string, Component.attrValue) => {
    // Check if it's a function (computed)
    if typeof(value) == #function {
      // It's a computed function
      let f: unit => string = Obj.magic(value)
      Component.computedAttr(key, f)
    } else if typeof(value) == #object && hasId(value)->Option.isSome {
      // It's a signal (has an id property)
      let sig: Signal.t<string> = Obj.magic(value)
      Component.signalAttr(key, sig)
    } else {
      // It's a static string
      let s: string = Obj.magic(value)
      Component.attr(key, s)
    }
  }

  /* Helper to add optional attribute to attrs array */
  let addAttr = (attrs, attrName, value) => {
    switch value {
    | Some(v) => attrs->Array.push(convertAttrValue(attrName, v))
    | None => ()
    }
  }

  /* Helper to add boolean attribute to attrs array */
  let addBoolAttr = (attrs, attrName, value) => {
    switch value {
    | Some(true) => attrs->Array.push(Component.attr(attrName, "true"))
    | _ => ()
    }
  }

  /* Convert props to attrs array */
  let propsToAttrs = (props): array<(string, Component.attrValue)> => {
    let attrs = []

    // Standard HTML attributes
    addAttr(attrs, "id", props.id)
    addAttr(attrs, "class", props.class)
    addAttr(attrs, "style", props.style)
    addAttr(attrs, "width", props.width)
    addAttr(attrs, "height", props.height)
    addAttr(attrs, "src", props.src)

    // Input attributes
    addAttr(attrs, "type", props.type_)
    addAttr(attrs, "value", props.value)
    addAttr(attrs, "placeholder", props.placeholder)
    addBoolAttr(attrs, "disabled", props.disabled)
    addBoolAttr(attrs, "checked", props.checked)

    // Link attributes
    addAttr(attrs, "href", props.href)
    addAttr(attrs, "target", props.target)

    // SVG attributes
    addAttr(attrs, "fill", props.fill)
    addAttr(attrs, "viewBox", props.viewBox)
    addAttr(attrs, "stroke", props.stroke)
    addAttr(attrs, "stroke-width", props.strokeWidth)
    addAttr(attrs, "stroke-linecap", props.strokeLinecap)
    addAttr(attrs, "stroke-miterlimit", props.strokeMiterlimit)
    addAttr(attrs, "d", props.d)

    // Data attributes
    switch props.data {
    | Some(_dataObj) => {
        let _ = %raw(`
          Object.entries(_dataObj).forEach(([key, value]) => {
            attrs.push(convertAttrValue("data-" + key, value))
          })
        `)
      }
    | None => ()
    }

    attrs
  }

  /* Helper to add optional event handler to events array */
  let addEvent = (events, eventName, handler) => {
    switch handler {
    | Some(h) => events->Array.push((eventName, h))
    | None => ()
    }
  }

  /* Convert props to events array */
  let propsToEvents = (props): array<(string, Dom.event => unit)> => {
    let events = []

    addEvent(events, "click", props.onClick)
    addEvent(events, "input", props.onInput)
    addEvent(events, "change", props.onChange)
    addEvent(events, "submit", props.onSubmit)
    addEvent(events, "focus", props.onFocus)
    addEvent(events, "blur", props.onBlur)
    addEvent(events, "keydown", props.onKeyDown)
    addEvent(events, "keyup", props.onKeyUp)
    addEvent(events, "mouseenter", props.onMouseEnter)
    addEvent(events, "mouseleave", props.onMouseLeave)

    events
  }

  /* Extract children from props */
  let getChildren = (props): array<element> => {
    switch props.children {
    | Some(Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* Create an element from a tag string and props */
  let createElement = (tag: string, props): element => {
    Component.Element({
      tag,
      attrs: propsToAttrs(props),
      events: propsToEvents(props),
      children: getChildren(props),
    })
  }

  /* JSX functions for HTML elements */
  let jsx = (tag: string, props): element => createElement(tag, props)

  let jsxs = (tag: string, props): element => createElement(tag, props)

  let jsxKeyed = (tag: string, props, ~key: option<string>=?, _: unit): element => {
    let _ = key
    createElement(tag, props)
  }

  let jsxsKeyed = (tag: string, props, ~key: option<string>=?, _: unit): element => {
    let _ = key
    createElement(tag, props)
  }

  /* Element helper for ReScript JSX type checking */
  external someElement: element => option<element> = "%identity"
}
