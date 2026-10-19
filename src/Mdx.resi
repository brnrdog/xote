/***
Optional MDX integration.

Bridges the children shape produced by the MDX JSX runtime to Xote nodes. MDX
hands components untyped props, so this module is the typed boundary: wrap your
components with `component`, collect them with `components`, and render the
document with `render`.

## Examples

```rescript
// A typed component to use in place of MDX's default <h1>.
type headingProps = {children?: Mdx.children}
let heading = (props: headingProps) =>
  <h1 class="prose-heading">
    {switch props.children {
    | Some(children) => View.fragment(Mdx.childrenToNodes(children))
    | None => View.null()
    }}
  </h1>

let overrides = Mdx.components([("h1", Mdx.component(heading))])
```
*/

/**
Untyped children as handed over by the MDX runtime.

Opaque on purpose — the runtime may pass a single node, an array, or a
primitive. Turn it into something usable with `childrenToNodes` or
`childrenToText` rather than inspecting it.
*/
type children = Obj.t

/**
Component overrides, keyed by MDX element name.

Keys are the HTML element names MDX emits (`"h1"`, `"p"`, `"code"`, ...).
Anything not listed keeps its default rendering. Build one with `components`.
*/
type components = dict<Obj.t => View.node>

/**
Props every MDX document accepts.

`components` overrides how individual elements render; omitting it uses the
defaults.
*/
type props = {components?: components}

/**
A compiled MDX document: a component taking `props` and returning a node.

This is the type of the default export of an `.mdx` file compiled with the
Xote JSX runtime.
*/
type document = props => View.node

/**
Wraps a typed component so MDX can call it with untyped props.

MDX has no knowledge of ReScript types, so every override passes through here
before going into a `components` map.

## Examples

```rescript
type linkProps = {href?: string, children?: Mdx.children}

let link = (props: linkProps) =>
  <a href={props.href->Option.getOr("#")} class="prose-link">
    {switch props.children {
    | Some(children) => View.fragment(Mdx.childrenToNodes(children))
    | None => View.null()
    }}
  </a>

let untyped = Mdx.component(link)
```
*/
let component: ('props => View.node) => Obj.t => View.node

/**
Builds a component override map from name/component pairs.

## Examples

```rescript
type boxProps = {children?: Mdx.children}

let quote = (props: boxProps) =>
  <blockquote>
    {switch props.children {
    | Some(children) => View.fragment(Mdx.childrenToNodes(children))
    | None => View.null()
    }}
  </blockquote>

let overrides = Mdx.components([("blockquote", Mdx.component(quote))])
```
*/
let components: array<(string, Obj.t => View.node)> => components

/**
Renders an MDX document, optionally overriding its components.

## Examples

```rescript
let renderPost = (post: Mdx.document) => {
  // With the document's default elements.
  let plain = Mdx.render(post, ())

  // With overrides.
  let styled = Mdx.render(post, ~components=Mdx.components([]), ())

  View.fragment([plain, styled])
}
```
*/
let render: (document, ~components: components=?, unit) => View.node

/**
Converts MDX children into Xote nodes.

The usual first step inside a component override: MDX children are untyped, and
this turns them into an array you can place in `~children` or wrap in a
fragment.

## Examples

```rescript
type boxProps = {children?: Mdx.children}

let box = (props: boxProps) =>
  <div class="box">
    {switch props.children {
    | Some(children) => View.fragment(Mdx.childrenToNodes(children))
    | None => View.null()
    }}
  </div>
```
*/
let childrenToNodes: children => array<View.node>

/**
Flattens MDX children to plain text.

For overrides that need the raw content rather than rendered nodes — syntax
highlighting a code block, or deriving a heading's `id` from its text.

## Examples

```rescript
type codeProps = {children?: Mdx.children}

let code = (props: codeProps) => {
  let source = switch props.children {
  | Some(children) => Mdx.childrenToText(children)
  | None => ""
  }

  <pre> <code> {View.text(source)} </code> </pre>
}
```
*/
let childrenToText: children => string
