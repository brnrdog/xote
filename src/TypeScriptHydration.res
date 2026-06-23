@genType
type hydrateOptions = {
  renderId?: string,
  onHydrated?: unit => unit,
}

@genType
let hydrate = (
  component: unit => TypeScriptView.node,
  container: Dom.element,
  ~options: option<hydrateOptions>=?,
): unit =>
  switch options {
  | Some(options) => Hydration.hydrate(() => Obj.magic(component()), container, ~options=Obj.magic(options))
  | None => Hydration.hydrate(() => Obj.magic(component()), container)
  }

@genType
let hydrateById = (
  component: unit => TypeScriptView.node,
  containerId: string,
  ~options: option<hydrateOptions>=?,
): unit =>
  switch options {
  | Some(options) =>
    Hydration.hydrateById(() => Obj.magic(component()), containerId, ~options=Obj.magic(options))
  | None => Hydration.hydrateById(() => Obj.magic(component()), containerId)
  }
