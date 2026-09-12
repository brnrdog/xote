/* Mounting a Xote app onto a native host.

 The host installs itself first (`install(host)` in `host/runtime.mjs`), which
 puts the shadow document in place of `document`. From there `View.mount` is the
 same call a web app makes — the renderer cannot tell the difference. */

type root = Dom.element

@module("./host/runtime.mjs") external createRoot: string => root = "createRoot"

@module("./host/runtime.mjs") external flushBatch: unit => array<Obj.t> = "flush"

@module("./host/runtime.mjs")
external dispatchEvent: (int, string, Obj.t) => unit = "dispatchEvent"

let mount = (node: View.node, ~root: string="root"): unit => View.mount(node, createRoot(root))

/* Push whatever the last synchronous burst produced across the bridge now,
 rather than waiting for the microtask. Tests and server-driven hosts want it;
 an app running normally does not. */
let flush = (): unit => flushBatch()->ignore
