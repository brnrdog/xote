/* Optional MDX integration.

   Bridges the children shape produced by the MDX JSX runtime to Xote nodes. */

/* Untyped children as handed over by the MDX runtime */
type children = Obj.t

/* Component overrides, keyed by MDX element name */
type components = dict<Obj.t => View.node>

type props = {components?: components}

type document = props => View.node

/* Wrap a typed component so MDX can call it with untyped props */
let component: ('props => View.node) => Obj.t => View.node

/* Build a component override map */
let components: array<(string, Obj.t => View.node)> => components

/* Render an MDX document, optionally overriding its components */
let render: (document, ~components: components=?, unit) => View.node

/* Convert MDX children into Xote nodes */
let childrenToNodes: children => array<View.node>

/* Flatten MDX children to plain text (syntax highlighting, heading ids, ...) */
let childrenToText: children => string
