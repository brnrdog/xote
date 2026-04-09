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

  Node.element(
    "div",
    ~attrs=[Node.attr("style", "width: " ++ size ++ "px; display: inline-flex;")],
    ~children=[
      Node.element(
        "svg",
        ~attrs=[
          Node.attr("viewBox", "0 0 37 52"),
          Node.attr("fill", "none"),
          Node.attr("preserveAspectRatio", "xMidYMid meet"),
          Node.attr("style", "color: " ++ color),
          Node.attr("width", "100%"),
          Node.attr("height", "100%"),
        ],
        ~children=[
          Node.element(
            "path",
            ~attrs=[
              Node.attr(
                "d",
                "M18.4755 30.3333V26.3939M18.4755 30.3333L2.47549 42.9394M18.4755 30.3333V52",
              ),
              Node.attr("stroke", "currentColor"),
              Node.attr("stroke-width", "8"),
            ],
            (),
          ),
          Node.element(
            "path",
            ~attrs=[
              Node.attr("d", "M18.4755 25.6061V21.6667L34.4755 9.06061"),
              Node.attr("stroke", "currentColor"),
              Node.attr("stroke-width", "8"),
            ],
            (),
          ),
          Node.element(
            "path",
            ~attrs=[
              Node.attr("d", "M18.4755 26.3939V23.4101V0"),
              Node.attr("stroke", "currentColor"),
              Node.attr("stroke-width", "8"),
            ],
            (),
          ),
          Node.element(
            "path",
            ~attrs=[
              Node.attr("d", "M18.4755 25.6061V28.5899V52"),
              Node.attr("stroke", "currentColor"),
              Node.attr("stroke-width", "8"),
            ],
            (),
          ),
          Node.element(
            "path",
            ~attrs=[
              Node.attr("d", "M34.4755 26L2.47549 26"),
              Node.attr("stroke", "currentColor"),
              Node.attr("stroke-width", "8"),
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
