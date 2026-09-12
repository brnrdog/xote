/* Event payloads a host reports back.

 Every payload is the object the host sent, plus the `type` and `target` the
 shadow document adds. Records read structurally at runtime, so a host may send
 more fields than a payload type names without breaking anything. */

type press = {pageX: float, pageY: float}

type layout = {x: float, y: float, width: float, height: float}

type text = {value: string}

type scroll = {x: float, y: float}

type focus = {value: string}

/* The platform changed the navigation stack on its own — a back gesture or a
 back button — and `depth` is how many screens it is showing now. The app is
 expected to truncate to it; see `src/host/navigation.mjs`. */
type stackChange = {depth: int}

/* The renderer types every listener as `Dom.event => unit` because that is what
 a browser hands it. On a native host the payload is a plain object built by
 `ShadowDocument.dispatchEvent`, so the handler is re-typed on the way in — the
 one place the native layer reinterprets a core type. */
external handler: ('payload => unit) => Dom.event => unit = "%identity"
