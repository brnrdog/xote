open Xote

type props = {color?: string, size?: int}

let make = (props: props) => {
  let color = switch props.color {
  | Some(c) => c
  | None => "var(--text-accent)"
  }

  let size = switch props.size {
  | None => "24"
  | Some(number) => number->Int.toString
  }

  Component.element(
    "div",
    ~attrs=[Component.attr("style", "width: " ++ size ++ "px; display: inline-flex;")],
    ~children=[
      Component.element(
        "svg",
        ~attrs=[
          Component.attr("viewBox", "0 0 37 52"),
          Component.attr("fill", "none"),
          Component.attr("preserveAspectRatio", "xMidYMid meet"),
          Component.attr("style", "color: " ++ color),
          Component.attr("width", "100%"),
          Component.attr("height", "100%"),
        ],
        ~children=[
          Component.element(
            "path",
            ~attrs=[
              Component.attr(
                "d",
                "M18.4755 30.3333V26.3939M18.4755 30.3333L2.47549 42.9394M18.4755 30.3333V52",
              ),
              Component.attr("stroke", "currentColor"),
              Component.attr("stroke-width", "8"),
            ],
            (),
          ),
          Component.element(
            "path",
            ~attrs=[
              Component.attr("d", "M18.4755 25.6061V21.6667L34.4755 9.06061"),
              Component.attr("stroke", "currentColor"),
              Component.attr("stroke-width", "8"),
            ],
            (),
          ),
          Component.element(
            "path",
            ~attrs=[
              Component.attr("d", "M18.4755 26.3939V23.4101V0"),
              Component.attr("stroke", "currentColor"),
              Component.attr("stroke-width", "8"),
            ],
            (),
          ),
          Component.element(
            "path",
            ~attrs=[
              Component.attr("d", "M18.4755 25.6061V28.5899V52"),
              Component.attr("stroke", "currentColor"),
              Component.attr("stroke-width", "8"),
            ],
            (),
          ),
          Component.element(
            "path",
            ~attrs=[
              Component.attr("d", "M34.4755 26L2.47549 26"),
              Component.attr("stroke", "currentColor"),
              Component.attr("stroke-width", "8"),
            ],
            (),
          ),
        ],
        (),
      ),
    ],
    (),
  )
}
