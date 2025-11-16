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
  @ignore _: unit,
): element => {
  let _ = key /* TODO: Implement key support for list reconciliation */
  component(props)
}

let jsxsKeyed = (
  component: component<'props>,
  props: 'props,
  ~key: option<string>=?,
  @ignore _: unit,
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
  /* Props type for HTML elements - supports common attributes and events */
  type props = {
    /* Standard attributes */
    id?: string,
    class?: string,
    style?: string,
    /* Input attributes */
    @as("type") type_?: string,
    value?: string,
    placeholder?: string,
    disabled?: bool,
    checked?: bool,
    /* Link attributes */
    href?: string,
    target?: string,
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

  /* Convert props to attrs array */
  let propsToAttrs = (props: props): array<(string, Component.attrValue)> => {
    let attrs = []

    switch props.id {
    | Some(v) => attrs->Array.push(Component.attr("id", v))
    | None => ()
    }

    switch props.class {
    | Some(v) => attrs->Array.push(Component.attr("class", v))
    | None => ()
    }

    switch props.style {
    | Some(v) => attrs->Array.push(Component.attr("style", v))
    | None => ()
    }

    switch props.type_ {
    | Some(v) => attrs->Array.push(Component.attr("type", v))
    | None => ()
    }

    switch props.value {
    | Some(v) => attrs->Array.push(Component.attr("value", v))
    | None => ()
    }

    switch props.placeholder {
    | Some(v) => attrs->Array.push(Component.attr("placeholder", v))
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

    switch props.href {
    | Some(v) => attrs->Array.push(Component.attr("href", v))
    | None => ()
    }

    switch props.target {
    | Some(v) => attrs->Array.push(Component.attr("target", v))
    | None => ()
    }

    attrs
  }

  /* Convert props to events array */
  let propsToEvents = (props: props): array<(string, Dom.event => unit)> => {
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
  let getChildren = (props: props): array<element> => {
    switch props.children {
    | Some(Fragment(children)) => children
    | Some(child) => [child]
    | None => []
    }
  }

  /* Create an element from a tag string and props */
  let createElement = (tag: string, props: props): element => {
    Component.Element({
      tag,
      attrs: propsToAttrs(props),
      events: propsToEvents(props),
      children: getChildren(props),
    })
  }

  /* JSX functions for HTML elements */
  let jsx = (tag: string, props: props): element => createElement(tag, props)

  let jsxs = (tag: string, props: props): element => createElement(tag, props)

  let jsxKeyed = (tag: string, props: props, ~key: option<string>=?, @ignore _: unit): element => {
    let _ = key
    createElement(tag, props)
  }

  let jsxsKeyed = (tag: string, props: props, ~key: option<string>=?, @ignore _: unit): element => {
    let _ = key
    createElement(tag, props)
  }

  /* Element helper for ReScript JSX type checking */
  external someElement: element => option<element> = "%identity"
}
