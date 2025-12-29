open Signals
module Component = Xote__Component
module ReactiveProp = Xote__ReactiveProp

/* ReScript JSX transform type aliases */
type element = Component.node

type component<'props> = 'props => element

type componentLike<'props, 'return> = 'props => 'return

/* JSX functions for component creation - all delegate to the component function */
let jsx = (component: component<'props>, props: 'props): element => component(props)

let jsxs = jsx

let jsxKeyed = (
  component: component<'props>,
  props: 'props,
  ~key: option<string>=?,
  _: unit,
): element => {
  let _ = key /* TODO: Implement key support for list reconciliation */
  jsx(component, props)
}

let jsxsKeyed = jsxKeyed

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
  /* Props type for HTML elements - accepts both raw values and ReactiveProp.t for flexibility
   * This allows ergonomic JSX like class="foo" while also supporting class={ReactiveProp.reactive(signal)}
   */
  type props<
    'id,
    'class,
    'style,
    'typ,
    'name,
    'value,
    'placeholder,
    'min,
    'max,
    'step,
    'pattern,
    'autoComplete,
    'accept,
    'forAttr,
    'href,
    'target,
    'src,
    'alt,
    'width,
    'height,
    'role,
    'ariaLabel,
    'disabled,
    'checked,
    'required,
    'readOnly,
    'multiple,
    'ariaHidden,
    'ariaExpanded,
    'ariaSelected,
  > = {
    /* Standard attributes - accept raw strings or ReactiveProp.t<string> */
    id?: 'id,
    class?: 'class,
    style?: 'style,
    /* Form/Input attributes */
    @as("type") type_?: 'typ,
    name?: 'name,
    value?: 'value,
    placeholder?: 'placeholder,
    disabled?: 'disabled,
    checked?: 'checked,
    required?: 'required,
    readOnly?: 'readOnly,
    maxLength?: int,
    minLength?: int,
    min?: 'min,
    max?: 'max,
    step?: 'step,
    pattern?: 'pattern,
    autoComplete?: 'autoComplete,
    multiple?: 'multiple,
    accept?: 'accept,
    rows?: int,
    cols?: int,
    /* Label attributes */
    @as("for") for_?: 'forAttr,
    /* Link attributes */
    href?: 'href,
    target?: 'target,
    /* Image attributes */
    src?: 'src,
    alt?: 'alt,
    width?: 'width,
    height?: 'height,
    /* Accessibility attributes */
    role?: 'role,
    tabIndex?: int,
    @as("aria-label") ariaLabel?: 'ariaLabel,
    @as("aria-hidden") ariaHidden?: 'ariaHidden,
    @as("aria-expanded") ariaExpanded?: 'ariaExpanded,
    @as("aria-selected") ariaSelected?: 'ariaSelected,
    /* Data attributes */
    data?: Obj.t,
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

  /* Helper to detect if a value is a ReactiveProp variant (checks for Static/Reactive tags) */
  let isReactiveProp = (value: 'a): bool => {
    %raw(`value && typeof value === 'object' && ('TAG' in value) && (value.TAG === 'Static' || value.TAG === 'Reactive')`)
  }

  /* Helper to convert string attribute value (supports raw string, ReactiveProp, Signal, or computed function) */
  let convertAttrValue = (key: string, value: 'a): (string, Component.attrValue) => {
    if isReactiveProp(value) {
      // It's a ReactiveProp variant - pattern match on it
      let rp: ReactiveProp.t<string> = Obj.magic(value)
      switch rp {
      | Static(s) => Component.attr(key, s)
      | Reactive(signal) => Component.signalAttr(key, signal)
      }
    } else if typeof(value) == #function {
      // It's a computed function (for backward compatibility)
      let f: unit => string = Obj.magic(value)
      Component.computedAttr(key, f)
    } else if typeof(value) == #object {
      // It's a raw signal (for backward compatibility)
      let sig: Signal.t<string> = Obj.magic(value)
      Component.signalAttr(key, sig)
    } else {
      // It's a raw string
      let s: string = Obj.magic(value)
      Component.attr(key, s)
    }
  }

  /* Helper to convert boolean attribute value (supports raw bool, ReactiveProp, Signal, or computed function) */
  let convertBoolAttrValue = (key: string, value: 'a): (string, Component.attrValue) => {
    if isReactiveProp(value) {
      // It's a ReactiveProp variant - pattern match on it
      let rp: ReactiveProp.t<bool> = Obj.magic(value)
      switch rp {
      | Static(b) => Component.attr(key, b ? "true" : "false")
      | Reactive(signal) => {
          let strSignal = Computed.make(() => Signal.get(signal) ? "true" : "false")
          Component.signalAttr(key, strSignal)
        }
      }
    } else if typeof(value) == #function {
      // It's a computed function that returns bool (for backward compatibility)
      let f: unit => bool = Obj.magic(value)
      Component.computedAttr(key, () => f() ? "true" : "false")
    } else if typeof(value) == #object {
      // It's a raw signal (for backward compatibility)
      let sig: Signal.t<bool> = Obj.magic(value)
      let strSignal = Computed.make(() => Signal.get(sig) ? "true" : "false")
      Component.signalAttr(key, strSignal)
    } else {
      // It's a raw bool
      let b: bool = Obj.magic(value)
      Component.attr(key, b ? "true" : "false")
    }
  }

  /* Helper to add optional attribute to attrs array */
  let addAttr = (attrs, opt, key, converter) => {
    switch opt {
    | Some(v) => attrs->Array.push(converter(key, v))
    | None => ()
    }
  }

  /* Helper to add optional int attribute */
  let addIntAttr = (attrs, opt, key) => {
    switch opt {
    | Some(v) => attrs->Array.push(Component.attr(key, Int.toString(v)))
    | None => ()
    }
  }

  /* Convert props to attrs array */
  let propsToAttrs = (props: props<_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _>): array<(string, Component.attrValue)> => {
    let attrs = []

    /* Standard attributes */
    addAttr(attrs, props.id, "id", convertAttrValue)
    addAttr(attrs, props.class, "class", convertAttrValue)
    addAttr(attrs, props.style, "style", convertAttrValue)

    /* Form/Input attributes */
    addAttr(attrs, props.type_, "type", convertAttrValue)
    addAttr(attrs, props.name, "name", convertAttrValue)
    addAttr(attrs, props.value, "value", convertAttrValue)
    addAttr(attrs, props.placeholder, "placeholder", convertAttrValue)
    addAttr(attrs, props.disabled, "disabled", convertBoolAttrValue)
    addAttr(attrs, props.checked, "checked", convertBoolAttrValue)
    addAttr(attrs, props.required, "required", convertBoolAttrValue)
    addAttr(attrs, props.readOnly, "readonly", convertBoolAttrValue)
    addIntAttr(attrs, props.maxLength, "maxlength")
    addIntAttr(attrs, props.minLength, "minlength")
    addAttr(attrs, props.min, "min", convertAttrValue)
    addAttr(attrs, props.max, "max", convertAttrValue)
    addAttr(attrs, props.step, "step", convertAttrValue)
    addAttr(attrs, props.pattern, "pattern", convertAttrValue)
    addAttr(attrs, props.autoComplete, "autocomplete", convertAttrValue)
    addAttr(attrs, props.multiple, "multiple", convertBoolAttrValue)
    addAttr(attrs, props.accept, "accept", convertAttrValue)
    addIntAttr(attrs, props.rows, "rows")
    addIntAttr(attrs, props.cols, "cols")

    /* Label attributes */
    addAttr(attrs, props.for_, "for", convertAttrValue)

    /* Link attributes */
    addAttr(attrs, props.href, "href", convertAttrValue)
    addAttr(attrs, props.target, "target", convertAttrValue)

    /* Image attributes */
    addAttr(attrs, props.src, "src", convertAttrValue)
    addAttr(attrs, props.alt, "alt", convertAttrValue)
    addAttr(attrs, props.width, "width", convertAttrValue)
    addAttr(attrs, props.height, "height", convertAttrValue)

    /* Accessibility attributes */
    addAttr(attrs, props.role, "role", convertAttrValue)
    addIntAttr(attrs, props.tabIndex, "tabindex")
    addAttr(attrs, props.ariaLabel, "aria-label", convertAttrValue)
    addAttr(attrs, props.ariaHidden, "aria-hidden", convertBoolAttrValue)
    addAttr(attrs, props.ariaExpanded, "aria-expanded", convertBoolAttrValue)
    addAttr(attrs, props.ariaSelected, "aria-selected", convertBoolAttrValue)

    /* Data attributes */
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
  let addEvent = (events, opt, eventName) => {
    switch opt {
    | Some(handler) => events->Array.push((eventName, handler))
    | None => ()
    }
  }

  /* Convert props to events array */
  let propsToEvents = (props: props<_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _>): array<(string, Dom.event => unit)> => {
    let events = []

    addEvent(events, props.onClick, "click")
    addEvent(events, props.onInput, "input")
    addEvent(events, props.onChange, "change")
    addEvent(events, props.onSubmit, "submit")
    addEvent(events, props.onFocus, "focus")
    addEvent(events, props.onBlur, "blur")
    addEvent(events, props.onKeyDown, "keydown")
    addEvent(events, props.onKeyUp, "keyup")
    addEvent(events, props.onMouseEnter, "mouseenter")
    addEvent(events, props.onMouseLeave, "mouseleave")

    events
  }

  /* Extract children from props */
  let getChildren = (props: props<_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _>): array<element> => {
    switch props.children {
    | Some(Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* Create an element from a tag string and props */
  let createElement = (tag: string, props: props<_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _>): element => {
    Component.Element({
      tag,
      attrs: propsToAttrs(props),
      events: propsToEvents(props),
      children: getChildren(props),
    })
  }

  /* JSX functions for HTML elements - all delegate to createElement */
  let jsx = (tag: string, props: props<_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _>): element => createElement(tag, props)

  let jsxs = jsx

  let jsxKeyed = (tag: string, props: props<_, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _>, ~key: option<string>=?, _: unit): element => {
    let _ = key
    jsx(tag, props)
  }

  let jsxsKeyed = jsxKeyed

  /* Element helper for ReScript JSX type checking */
  external someElement: element => option<element> = "%identity"
}
