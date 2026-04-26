// Bindings for the PostHog browser SDK.
//
// `analytics.js` initializes posthog-js on the client only, which assigns the
// instance to `window.posthog`. We bind to that global so this module never
// imports posthog-js directly — keeping it out of the SSR bundle.

type instance

@val @scope("window")
external instance: Nullable.t<instance> = "posthog"

@send external _capture: (instance, string) => unit = "capture"
@send external _captureWith: (instance, string, 'props) => unit = "capture"

let capture = (event, ~properties=?) =>
  switch instance->Nullable.toOption {
  | Some(ph) =>
    switch properties {
    | Some(p) => _captureWith(ph, event, p)
    | None => _capture(ph, event)
    }
  | None => ()
  }
