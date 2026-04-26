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

  View.element(
    "div",
    ~attrs=[View.attr("style", "width: " ++ size ++ "px; display: inline-flex;")],
    ~children=[
      View.element(
        "svg",
        ~attrs=[
          View.attr("viewBox", "0 0 37 52"),
          View.attr("fill", "none"),
          View.attr("preserveAspectRatio", "xMidYMid meet"),
          View.attr("style", "color: " ++ color),
          View.attr("width", "100%"),
          View.attr("height", "100%"),
        ],
        ~children=[
          View.element(
            "path",
            ~attrs=[
              View.attr(
                "d",
                "M18.4755 30.3333V26.3939M18.4755 30.3333L2.47549 42.9394M18.4755 30.3333V52",
              ),
              View.attr("stroke", "currentColor"),
              View.attr("stroke-width", "8"),
            ],
            (),
          ),
          View.element(
            "path",
            ~attrs=[
              View.attr("d", "M18.4755 25.6061V21.6667L34.4755 9.06061"),
              View.attr("stroke", "currentColor"),
              View.attr("stroke-width", "8"),
            ],
            (),
          ),
          View.element(
            "path",
            ~attrs=[
              View.attr("d", "M18.4755 26.3939V23.4101V0"),
              View.attr("stroke", "currentColor"),
              View.attr("stroke-width", "8"),
            ],
            (),
          ),
          View.element(
            "path",
            ~attrs=[
              View.attr("d", "M18.4755 25.6061V28.5899V52"),
              View.attr("stroke", "currentColor"),
              View.attr("stroke-width", "8"),
            ],
            (),
          ),
          View.element(
            "path",
            ~attrs=[
              View.attr("d", "M34.4755 26L2.47549 26"),
              View.attr("stroke", "currentColor"),
              View.attr("stroke-width", "8"),
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
