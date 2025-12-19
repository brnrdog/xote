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

  /* Props type for HTML elements - supports common attributes and events
   * String-like attributes use polymorphic types to accept strings, signals, or computed functions
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
  > = {
    /* Standard attributes - can be static strings, signals, or computed values */
    id?: 'id,
    class?: 'class,
    style?: 'style,
    /* Form/Input attributes */
    @as("type") type_?: 'typ,
    name?: 'name,
    value?: 'value,
    placeholder?: 'placeholder,
    disabled?: bool,
    checked?: bool,
    required?: bool,
    readOnly?: bool,
    maxLength?: int,
    minLength?: int,
    min?: 'min,
    max?: 'max,
    step?: 'step,
    pattern?: 'pattern,
    autoComplete?: 'autoComplete,
    multiple?: bool,
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
    @as("aria-hidden") ariaHidden?: bool,
    @as("aria-expanded") ariaExpanded?: bool,
    @as("aria-selected") ariaSelected?: bool,
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

  /* Convert props to attrs array */
  let propsToAttrs = (
    props: props<
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
    >,
  ): array<(string, Component.attrValue)> => {
    let attrs = []

    /* Standard attributes */
    switch props.id {
    | Some(v) => attrs->Array.push(convertAttrValue("id", v))
    | None => ()
    }

    switch props.class {
    | Some(v) => attrs->Array.push(convertAttrValue("class", v))
    | None => ()
    }

    switch props.style {
    | Some(v) => attrs->Array.push(convertAttrValue("style", v))
    | None => ()
    }

    /* Form/Input attributes */
    switch props.type_ {
    | Some(v) => attrs->Array.push(convertAttrValue("type", v))
    | None => ()
    }

    switch props.name {
    | Some(v) => attrs->Array.push(convertAttrValue("name", v))
    | None => ()
    }

    switch props.value {
    | Some(v) => attrs->Array.push(convertAttrValue("value", v))
    | None => ()
    }

    switch props.placeholder {
    | Some(v) => attrs->Array.push(convertAttrValue("placeholder", v))
    | None => ()
    }

    switch props.disabled {
    | Some(true) => attrs->Array.push(Component.attr("disabled", "true"))
    | _ => ()
    }

    switch props.checked {
    | Some(true) => attrs->Array.push(Component.attr("checked", "true"))
    | _ => ()
    }

    switch props.required {
    | Some(true) => attrs->Array.push(Component.attr("required", "true"))
    | _ => ()
    }

    switch props.readOnly {
    | Some(true) => attrs->Array.push(Component.attr("readonly", "true"))
    | _ => ()
    }

    switch props.maxLength {
    | Some(v) => attrs->Array.push(Component.attr("maxlength", Int.toString(v)))
    | None => ()
    }

    switch props.minLength {
    | Some(v) => attrs->Array.push(Component.attr("minlength", Int.toString(v)))
    | None => ()
    }

    switch props.min {
    | Some(v) => attrs->Array.push(convertAttrValue("min", v))
    | None => ()
    }

    switch props.max {
    | Some(v) => attrs->Array.push(convertAttrValue("max", v))
    | None => ()
    }

    switch props.step {
    | Some(v) => attrs->Array.push(convertAttrValue("step", v))
    | None => ()
    }

    switch props.pattern {
    | Some(v) => attrs->Array.push(convertAttrValue("pattern", v))
    | None => ()
    }

    switch props.autoComplete {
    | Some(v) => attrs->Array.push(convertAttrValue("autocomplete", v))
    | None => ()
    }

    switch props.multiple {
    | Some(true) => attrs->Array.push(Component.attr("multiple", "true"))
    | _ => ()
    }

    switch props.accept {
    | Some(v) => attrs->Array.push(convertAttrValue("accept", v))
    | None => ()
    }

    switch props.rows {
    | Some(v) => attrs->Array.push(Component.attr("rows", Int.toString(v)))
    | None => ()
    }

    switch props.cols {
    | Some(v) => attrs->Array.push(Component.attr("cols", Int.toString(v)))
    | None => ()
    }

    /* Label attributes */
    switch props.for_ {
    | Some(v) => attrs->Array.push(convertAttrValue("for", v))
    | None => ()
    }

    /* Link attributes */
    switch props.href {
    | Some(v) => attrs->Array.push(convertAttrValue("href", v))
    | None => ()
    }

    switch props.target {
    | Some(v) => attrs->Array.push(convertAttrValue("target", v))
    | None => ()
    }

    /* Image attributes */
    switch props.src {
    | Some(v) => attrs->Array.push(convertAttrValue("src", v))
    | None => ()
    }

    switch props.alt {
    | Some(v) => attrs->Array.push(convertAttrValue("alt", v))
    | None => ()
    }

    switch props.width {
    | Some(v) => attrs->Array.push(convertAttrValue("width", v))
    | None => ()
    }

    switch props.height {
    | Some(v) => attrs->Array.push(convertAttrValue("height", v))
    | None => ()
    }

    /* Accessibility attributes */
    switch props.role {
    | Some(v) => attrs->Array.push(convertAttrValue("role", v))
    | None => ()
    }

    switch props.tabIndex {
    | Some(v) => attrs->Array.push(Component.attr("tabindex", Int.toString(v)))
    | None => ()
    }

    switch props.ariaLabel {
    | Some(v) => attrs->Array.push(convertAttrValue("aria-label", v))
    | None => ()
    }

    switch props.ariaHidden {
    | Some(true) => attrs->Array.push(Component.attr("aria-hidden", "true"))
    | Some(false) => attrs->Array.push(Component.attr("aria-hidden", "false"))
    | None => ()
    }

    switch props.ariaExpanded {
    | Some(true) => attrs->Array.push(Component.attr("aria-expanded", "true"))
    | Some(false) => attrs->Array.push(Component.attr("aria-expanded", "false"))
    | None => ()
    }

    switch props.ariaSelected {
    | Some(true) => attrs->Array.push(Component.attr("aria-selected", "true"))
    | Some(false) => attrs->Array.push(Component.attr("aria-selected", "false"))
    | None => ()
    }

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

  /* Convert props to events array */
  let propsToEvents = (
    props: props<
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
    >,
  ): array<(string, Dom.event => unit)> => {
    let events = []

    switch props.onClick {
    | Some(handler) => events->Array.push(("click", handler))
    | None => ()
    }

    switch props.onInput {
    | Some(handler) => events->Array.push(("input", handler))
    | None => ()
    }

    switch props.onChange {
    | Some(handler) => events->Array.push(("change", handler))
    | None => ()
    }

    switch props.onSubmit {
    | Some(handler) => events->Array.push(("submit", handler))
    | None => ()
    }

    switch props.onFocus {
    | Some(handler) => events->Array.push(("focus", handler))
    | None => ()
    }

    switch props.onBlur {
    | Some(handler) => events->Array.push(("blur", handler))
    | None => ()
    }

    switch props.onKeyDown {
    | Some(handler) => events->Array.push(("keydown", handler))
    | None => ()
    }

    switch props.onKeyUp {
    | Some(handler) => events->Array.push(("keyup", handler))
    | None => ()
    }

    switch props.onMouseEnter {
    | Some(handler) => events->Array.push(("mouseenter", handler))
    | None => ()
    }

    switch props.onMouseLeave {
    | Some(handler) => events->Array.push(("mouseleave", handler))
    | None => ()
    }

    events
  }

  /* Extract children from props */
  let getChildren = (
    props: props<
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
    >,
  ): array<element> => {
    switch props.children {
    | Some(Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* Create an element from a tag string and props */
  let createElement = (
    tag: string,
    props: props<
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
    >,
  ): element => {
    Component.Element({
      tag,
      attrs: propsToAttrs(props),
      events: propsToEvents(props),
      children: getChildren(props),
    })
  }

  /* JSX functions for HTML elements */
  let jsx = (
    tag: string,
    props: props<
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
    >,
  ): element => createElement(tag, props)

  let jsxs = (
    tag: string,
    props: props<
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
    >,
  ): element => createElement(tag, props)

  let jsxKeyed = (
    tag: string,
    props: props<
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
    >,
    ~key: option<string>=?,
    _: unit,
  ): element => {
    let _ = key
    createElement(tag, props)
  }

  let jsxsKeyed = (
    tag: string,
    props: props<
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
    >,
    ~key: option<string>=?,
    _: unit,
  ): element => {
    let _ = key
    createElement(tag, props)
  }

  /* Element helper for ReScript JSX type checking */
  external someElement: element => option<element> = "%identity"
}
