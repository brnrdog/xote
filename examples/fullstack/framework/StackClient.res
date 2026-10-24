/* The client half: hydrates the server's document, then takes over links,
   forms and the back button, fetching page data as JSON instead of whole
   documents.

   Without JavaScript every link and form still works — they are ordinary
   GETs and POSTs the server answers with HTML. */

open StackFetch

@val external document: Dom.document = "document"
@scope("window") @val external scrollTo: (int, int) => unit = "scrollTo"
@scope(("window", "location")) @val external currentHref: string = "href"
@scope(("window", "location")) @val external assign: string => unit = "assign"
@scope("history") @val external pushState: (Nullable.t<'a>, string, string) => unit = "pushState"
@set external setTitle: (Dom.document, string) => unit = "title"
@send
external addEventListener: (Dom.document, string, Dom.event => unit) => unit = "addEventListener"
@scope("window") @val
external addWindowListener: (string, Dom.event => unit) => unit = "addEventListener"
@send external preventDefault: Dom.event => unit = "preventDefault"

let readPayload: unit => option<StackPage.payload> = %raw(`function () {
  const el = document.getElementById("__xote_payload")
  return el ? JSON.parse(el.textContent) : undefined
}`)

external jsonToPayload: JSON.t => StackPage.payload = "%identity"
let field: (JSON.t, string) => option<string> = %raw(`function (json, key) {
  return json && typeof json[key] === "string" ? json[key] : undefined
}`)

/* The same-origin URL a click should navigate to on the client, if any. A
   click with a modifier key, a link with a target or a download, and links
   marked `data-reload` are left to the browser. */
let linkTarget: Dom.event => option<string> = %raw(`function (event) {
  if (event.defaultPrevented || event.button !== 0) return undefined
  if (event.metaKey || event.ctrlKey || event.shiftKey || event.altKey) return undefined
  const link = event.target.closest && event.target.closest("a[href]")
  if (!link || link.target || link.hasAttribute("download") || link.hasAttribute("data-reload")) return undefined
  const url = new URL(link.href, location.href)
  if (url.origin !== location.origin) return undefined
  if (url.pathname === location.pathname && url.search === location.search && url.hash) return undefined
  return url.pathname + url.search
}`)

/* A POST form submission to take over: its URL and urlencoded body,
 including the button that submitted it. */
let formSubmission: Dom.event => option<(string, string)> = %raw(`function (event) {
  const form = event.target
  if (event.defaultPrevented || !(form instanceof HTMLFormElement)) return undefined
  if ((form.getAttribute("method") || "get").toLowerCase() !== "post") return undefined
  if (form.hasAttribute("data-reload")) return undefined
  const url = new URL(form.getAttribute("action") || location.href, location.href)
  if (url.origin !== location.origin) return undefined
  const body = new URLSearchParams(new FormData(form, event.submitter))
  return [url.pathname + url.search, body.toString()]
}`)

let start = (app: StackPage.app) =>
  switch readPayload() {
  | None => Console.error("[xote] no page payload in the document; not hydrating")
  | Some(initial) =>
    let pageFor = (payload: StackPage.payload) =>
      payload.path == "*"
        ? Some(StackPage.messagePage(~title=payload.title))
        : app.pages->Array.find(p => p.path == payload.path)

    let toCurrent = (payload: StackPage.payload) =>
      pageFor(payload)->Option.map(page => {
        StackPage.page,
        params: payload.params,
        data: payload.data,
        error: payload.error,
      })

    let current = Signal.make(
      toCurrent(initial)->Option.getOr(
        toCurrent({...initial, path: "*", data: JSON.Encode.string("")})->Option.getOrThrow,
      ),
    )

    /* Only the latest request may update the screen. */
    let latest = ref(0)

    let show = (payload: StackPage.payload) =>
      switch toCurrent(payload) {
      | Some(next) =>
        Signal.set(current, next)
        setTitle(document, payload.title)
        true
      | None => false
      }

    let rec request = async (~url, ~init, ~push) => {
      latest := latest.contents + 1
      let id = latest.contents
      Signal.set(StackPage.pending, true)
      try {
        let response = await fetch(url, init)
        let body = await Response.json(response)
        if id == latest.contents {
          Signal.set(StackPage.pending, false)
          switch field(body, "redirect") {
          | Some(to) => await navigate(to, ~push=true)
          | None =>
            let payload = jsonToPayload(body)

            /* A 422 re-renders the page in place with the action's error. */
            if (Response.ok(response) || Response.status(response) == 422) && show(payload) {
              if push {
                pushState(Nullable.null, "", url)
                scrollTo(0, 0)
              }
            } else {
              /* Anything unexpected: let the server answer with a document. */
              assign(url)
            }
          }
        }
      } catch {
      | _ => assign(url)
      }
    }
    and navigate = (url, ~push) => request(~url, ~init={headers: dict{"x-xote-data": "1"}}, ~push)

    Hydration.hydrateById(StackPage.root(app, current), "root")

    document->addEventListener("click", event =>
      switch linkTarget(event) {
      | Some(url) =>
        preventDefault(event)
        navigate(url, ~push=true)->ignore
      | None => ()
      }
    )

    document->addEventListener("submit", event =>
      switch formSubmission(event) {
      | Some((url, body)) =>
        preventDefault(event)
        request(
          ~url,
          ~init={
            method: "POST",
            body,
            headers: dict{
              "x-xote-data": "1",
              "content-type": "application/x-www-form-urlencoded",
            },
          },
          ~push=false,
        )->ignore
      | None => ()
      }
    )

    addWindowListener("popstate", _ => {
      let url = Url.make(currentHref)
      navigate(Url.pathname(url) ++ Url.search(url), ~push=false)->ignore
    })
  }
