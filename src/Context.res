/* Values a component makes available to everything it renders, without passing
   them through the components in between.

   The scoping lives in the internal `RuntimeContext`: a provision is in place
   while the providing component's result renders, and every effect created in
   that subtree runs under it again later. */

type t<'a> = {default: 'a}

let make = (default: 'a): t<'a> => {default: default}

let use = (context: t<'a>): 'a =>
  switch RuntimeContext.lookup(Obj.magic(context)) {
  | Some(value) => Obj.magic(value)
  | None => context.default
  }

let provide = (context: t<'a>, value: 'a): unit =>
  RuntimeContext.provide(Obj.magic(context), Obj.magic(value))

let provider = (context: t<'a>, value: 'a, children: View.node): View.node => View.LazyComponent(
  () => {
    provide(context, value)
    children
  },
)

module Provider = {
  type props<'value> = {
    context: t<'value>,
    value: 'value,
    children?: View.node,
  }

  let make = (props: props<'value>): View.node => {
    provide(props.context, props.value)
    switch props.children {
    | Some(children) => children
    | None => View.fragment([])
    }
  }
}
