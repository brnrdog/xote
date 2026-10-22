// Which documentation layer is showing: the short human-first page or the
// complete agent-first version of the same page. The choice is remembered per
// visitor and can be forced with `?layer=agent` so tools can link to it.

@val @scope("localStorage") external getItem: string => Nullable.t<string> = "getItem"
@val @scope("localStorage") external setItem: (string, string) => unit = "setItem"
@val external setTimeout: (unit => unit, int) => int = "setTimeout"

type t = Human | Agent

let toString = layer =>
  switch layer {
  | Human => "human"
  | Agent => "agent"
  }

let fromQuery = (search: string) =>
  if search->String.includes("layer=agent") {
    Some(Agent)
  } else if search->String.includes("layer=human") {
    Some(Human)
  } else {
    None
  }

let stored = () =>
  if SSRContext.isClient {
    switch getItem("xote-docs-layer")->Nullable.toOption {
    | Some("agent") => Agent
    | _ => Human
    }
  } else {
    Human
  }

let current = Signal.make(Human)

// Restore the stored choice after hydration has matched the server markup,
// which always renders the human layer.
if SSRContext.isClient {
  let _ = setTimeout(() => {
    let search: string = %raw(`window.location.search`)
    Signal.set(current, fromQuery(search)->Option.getOr(stored()))
  }, 0)
}

let set = layer => {
  Signal.set(current, layer)
  if SSRContext.isClient {
    setItem("xote-docs-layer", toString(layer))
  }
  PostHog.capture("docs_layer_switched", ~properties={"layer": toString(layer)})
}

let isAgent = () => Signal.get(current) == Agent

// The pill switch shown in the docs header.
module Switch = {
  type props = {}

  let make = (_props: props) => {
    let option = (layer, label, extraClass) =>
      View.element(
        "button",
        ~attrs=[
          View.attr("type", "button"),
          View.computedAttr("class", () =>
            "layer-option" ++ extraClass ++ (Signal.get(current) == layer ? " active" : "")
          ),
          View.computedAttr("aria-pressed", () => Signal.get(current) == layer ? "true" : "false"),
        ],
        ~events=[("click", _ => set(layer))],
        ~children=[View.text(label)],
        (),
      )

    <div class="layer-switch" role="group" ariaLabel="Documentation layer">
      {option(Human, "◎ For humans", "")}
      {option(Agent, ">_ for agents", " layer-option-agent")}
    </div>
  }
}
