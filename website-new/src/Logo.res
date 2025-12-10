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

  <svg width=size height=size viewBox="0 0 96 96" fill="none" style={"color: " ++ color}>
    <path
      d="M48.1571 6.2439V43.5156V50.9108M48.1571 50.9108V89.3658M48.1571 50.9108C48.1571 50.9108 48.1571 67.5849 25.3799 73.688"
      stroke="#9370DB"
      strokeWidth="12.4878"
      strokeMiterlimit="16"
      strokeLinecap="round"
    />
    <path
      d="M41.6174 89.3658C41.6174 92.8143 44.4129 95.6097 47.8613 95.6097C51.3097 95.6097 54.1052 92.8143 54.1052 89.3658H47.8613H41.6174ZM47.8613 52.0941H54.1052V49H47.8613H41.6174V52.0941H47.8613ZM47.8613 89.3658H54.1052V52.0941H47.8613H41.6174V89.3658H47.8613Z"
      fill="#9370DB"
    />
    <path
      d="M70.6384 21.9217C47.8613 28.0248 47.8613 44.6989 47.8613 44.6989V6.2439"
      stroke="#4A9437"
      strokeWidth="12.4878"
      strokeMiterlimit="16"
      strokeLinecap="round"
    />
    <path
      d="M24.1967 47.657C44.0682 42.3324 51.411 53.0468 71.5259 47.657"
      stroke="#404047"
      strokeWidth="12.4878"
      strokeMiterlimit="16"
      strokeLinecap="round"
    />
  </svg>
}
