type props = {color?: string, size?: int}

let make = (props: props) => {
  let color = switch props.color {
  | Some(c) => c
  | None => "var(--primary-color)"
  }

  let size = switch props.size {
  | None => "24"
  | Some(number) => number->Int.toString
  }

  <div style={"width: " ++ size ++ "px"}>
    <svg viewBox="0 0 37 52" fill="none" preserveAspectRatio="xMidYMid meet" style={color}>
      <path
        d="M18.4755 30.3333V26.3939M18.4755 30.3333L2.47549 42.9394M18.4755 30.3333V52"
        stroke="currentColor"
        strokeWidth={8}
      />
      <path d="M18.4755 25.6061V21.6667L34.4755 9.06061" stroke="currentColor" strokeWidth={8} />
      <path d="M18.4755 26.3939V23.4101V0" stroke="currentColor" strokeWidth={8} />
      <path d="M18.4755 25.6061V28.5899V52" stroke="currentColor" strokeWidth={8} />
      <path d="M34.4755 26L2.47549 26" stroke="currentColor" strokeWidth={8} />
    </svg>
  </div>
}
