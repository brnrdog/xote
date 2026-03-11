%%raw(`import './Basefn__Icon.css'`)

open Xote

// Type for icon data from lucide
type iconElement = array<(string, dict<string>)>

// External bindings for lucide icons
@module("lucide/dist/esm/icons/check.js") external check: iconElement = "default"
@module("lucide/dist/esm/icons/x.js") external x: iconElement = "default"
@module("lucide/dist/esm/icons/chevron-down.js") external chevronDown: iconElement = "default"
@module("lucide/dist/esm/icons/chevron-up.js") external chevronUp: iconElement = "default"
@module("lucide/dist/esm/icons/chevron-left.js") external chevronLeft: iconElement = "default"
@module("lucide/dist/esm/icons/chevron-right.js") external chevronRight: iconElement = "default"
@module("lucide/dist/esm/icons/search.js") external search: iconElement = "default"
@module("lucide/dist/esm/icons/menu.js") external menu: iconElement = "default"
@module("lucide/dist/esm/icons/house.js") external home: iconElement = "default"
@module("lucide/dist/esm/icons/user.js") external user: iconElement = "default"
@module("lucide/dist/esm/icons/settings.js") external settings: iconElement = "default"
@module("lucide/dist/esm/icons/info.js") external info: iconElement = "default"
@module("lucide/dist/esm/icons/circle-alert.js") external alertCircle: iconElement = "default"
@module("lucide/dist/esm/icons/triangle-alert.js")
external alertTriangle: iconElement = "default"
@module("lucide/dist/esm/icons/loader.js") external loader: iconElement = "default"
@module("lucide/dist/esm/icons/plus.js") external plus: iconElement = "default"
@module("lucide/dist/esm/icons/minus.js") external minus: iconElement = "default"
@module("lucide/dist/esm/icons/trash.js") external trash: iconElement = "default"
@module("lucide/dist/esm/icons/pencil.js") external edit: iconElement = "default"
@module("lucide/dist/esm/icons/copy.js") external copy: iconElement = "default"
@module("lucide/dist/esm/icons/external-link.js")
external externalLink: iconElement = "default"
@module("lucide/dist/esm/icons/download.js") external download: iconElement = "default"
@module("lucide/dist/esm/icons/upload.js") external upload: iconElement = "default"
@module("lucide/dist/esm/icons/heart.js") external heart: iconElement = "default"
@module("lucide/dist/esm/icons/star.js") external star: iconElement = "default"
@module("lucide/dist/esm/icons/sun.js") external sun: iconElement = "default"
@module("lucide/dist/esm/icons/moon.js") external moon: iconElement = "default"
@module("lucide/dist/esm/icons/github.js") external github: iconElement = "default"

// Icon name type
type name =
  | Check
  | X
  | ChevronDown
  | ChevronUp
  | ChevronLeft
  | ChevronRight
  | Search
  | Menu
  | Home
  | User
  | Settings
  | Info
  | AlertCircle
  | AlertTriangle
  | Loader
  | Plus
  | Minus
  | Trash
  | Edit
  | Copy
  | ExternalLink
  | Download
  | Upload
  | Heart
  | Star
  | Sun
  | Moon
  | GitHub

// Get icon data from name
let getIconData = (name: name): iconElement => {
  switch name {
  | Check => check
  | X => x
  | ChevronDown => chevronDown
  | ChevronUp => chevronUp
  | ChevronLeft => chevronLeft
  | ChevronRight => chevronRight
  | Search => search
  | Menu => menu
  | Home => home
  | User => user
  | Settings => settings
  | Info => info
  | AlertCircle => alertCircle
  | AlertTriangle => alertTriangle
  | Loader => loader
  | Plus => plus
  | Minus => minus
  | Trash => trash
  | Edit => edit
  | Copy => copy
  | ExternalLink => externalLink
  | Download => download
  | Upload => upload
  | Heart => heart
  | Star => star
  | Sun => sun
  | Moon => moon
  | GitHub => github
  }
}

// Size variants
type size = Sm | Md | Lg | Xl

let sizeToPixels = (size: size): string => {
  switch size {
  | Sm => "16"
  | Md => "24"
  | Lg => "32"
  | Xl => "48"
  }
}

// Helper to render SVG element attributes as a string
let renderAttrs = (attrs: dict<string>): string => {
  Dict.toArray(attrs)
  ->Array.map(((key, value)) => key ++ "=\"" ++ value ++ "\"")
  ->Array.join(" ")
}

// Convert icon data to SVG string
let iconToSvgInner = (elements: iconElement): string => {
  elements
  ->Array.map(((tag, attrs)) => {
    let attrStr = renderAttrs(attrs)

    switch tag {
    | "path" | "circle" | "line" | "rect" | "polyline" | "polygon" | "ellipse" =>
      "<" ++
      tag ++
      " " ++
      attrStr ++ " fill=\"none\" stroke=\"currentColor\" stroke-width=\"2\" stroke-linecap=\"round\" stroke-linejoin=\"round\" />"
    | _ => ""
    }
  })
  ->Array.join("")
}

// Counter for unique IDs
let iconIdCounter = ref(0)

// Helper to inject SVG HTML into an element by ID
%%raw(`
function injectIconHTML(id, html) {
  setTimeout(() => {
    const el = document.getElementById(id);
    if (el && !el.hasAttribute('data-svg-injected')) {
      el.innerHTML = html;
      el.setAttribute('data-svg-injected', 'true');
    }
  }, 0);
}
`)

@val external injectIconHTML: (string, string) => unit = "injectIconHTML"

@jsx.component
let make = (
  ~name: name,
  ~size: size=Md,
  ~class=ReactiveProp.static(""),
  ~color=ReactiveProp.static("currentColor"),
) => {
  let iconData = getIconData(name)
  let sizeStr = sizeToPixels(size)
  let svgInner = iconToSvgInner(iconData)

  let className = Computed.make(() => {
    "basefn-icon " ++ class->ReactiveProp.get
  })

  let style = Computed.make(() => {
    "color: " ++
    color->ReactiveProp.get ++
    "; width: " ++
    sizeStr ++
    "px; height: " ++
    sizeStr ++ "px; display: inline-flex;"
  })

  // Create complete SVG HTML
  let svgHtml = `<svg width="${sizeStr}" height="${sizeStr}" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg" style="width: 100%; height: 100%;">${svgInner}</svg>`

  // Generate unique ID
  iconIdCounter := iconIdCounter.contents + 1
  let iconId = "basefn-icon-" ++ Int.toString(iconIdCounter.contents)

  // Inject the HTML after render
  let _ = injectIconHTML(iconId, svgHtml)

  // Return a span element with the unique ID
  <span id={iconId} class={className} style />
}
