/* The server half: attaches loaders and actions to pages and turns them into
   a `Request => promise<Response>` handler.

   A request is answered in one of two shapes:
   - a full HTML document (first load, or any request without JavaScript);
   - JSON (`StackPage.payload`) when the client asks for data with the
     `x-xote-data` header during a client-side navigation or submission.

   Rendering is synchronous and happens after the loader has resolved, so no
   render ever interleaves with another request's. */

open StackFetch

type loaderArgs = {
  params: Route.params,
  pathname: string,
  search: string,
  request: request,
}

type actionArgs = {
  params: Route.params,
  pathname: string,
  form: Dict.t<string>,
  request: request,
}

type actionResult =
  /* Success: go to this URL (POST/redirect/GET). */
  | Redirect(string)
  /* The submission was rejected: render the page again with this message. */
  | Invalid(string)

type route = {
  page: StackPage.any,
  load: loaderArgs => promise<JSON.t>,
  action: option<actionArgs => promise<actionResult>>,
}

/* Attaches a loader (and optionally an action) to a page. The loader must
 produce the page's data type. */
let route = (
  page: StackPage.t<'data>,
  ~loader: loaderArgs => promise<'data>,
  ~action: option<actionArgs => promise<actionResult>>=?,
): route => {
  page: StackPage.erase(page),
  load: async args => page.codec.encode(await loader(args)),
  action,
}

type options = {
  layout: View.node => View.node,
  scripts: array<string>,
  styles: array<string>,
}

let escapeHtml = (str: string) =>
  str
  ->String.replaceAll("&", "&amp;")
  ->String.replaceAll("<", "&lt;")
  ->String.replaceAll(">", "&gt;")
  ->String.replaceAll("\"", "&quot;")

/* JSON inside a <script> must not be able to close it. */
let scriptSafeJson = (json: JSON.t) =>
  JSON.stringify(json)
  ->String.replaceAll("<", "\\u003c")
  ->String.replaceAll(" ", "\\u2028")
  ->String.replaceAll(" ", "\\u2029")

/* A payload is plain data (a missing `error` is dropped by JSON.stringify). */
external payloadToJson: StackPage.payload => JSON.t = "%identity"

let html = (~status=200, body) =>
  Response.make(body, {status, headers: dict{"content-type": "text/html; charset=utf-8"}})

let json = (~status=200, body: JSON.t) =>
  Response.make(
    JSON.stringify(body),
    {status, headers: dict{"content-type": "application/json; charset=utf-8"}},
  )

let redirect = to => Response.make("", {status: 303, headers: dict{"location": to}})

let renderDocument = (options: options, ~status, payload: StackPage.payload, page) => {
  let current = Signal.make({
    StackPage.page,
    params: payload.params,
    data: payload.data,
    error: payload.error,
  })
  let app: StackPage.app = {pages: [], layout: options.layout}
  html(
    ~status,
    SSR.renderDocument(
      ~head=`<title>${escapeHtml(payload.title)}</title>`,
      ~styles=options.styles,
      ~scripts=options.scripts,
      ~stateScript=`<script id="__xote_payload" type="application/json">${scriptSafeJson(
          payloadToJson(payload),
        )}</script>`,
      StackPage.root(app, current),
    ),
  )
}

let handler = (routes: array<route>, options: options) => {
  let pages = routes->Array.map(r => r.page)

  async (request: request): response => {
    let url = Url.make(Request.url(request))
    let pathname = Url.pathname(url)
    let search = Url.search(url)
    let wantsData = request->Request.headers->Headers.get("x-xote-data")->Option.isSome

    /* Answers with a page in whichever shape the request asked for. */
    let respond = (~status=200, page: StackPage.any, params, data, error) => {
      let payload: StackPage.payload = {
        path: page.path,
        params,
        data,
        error,
        title: page.title(data),
      }
      wantsData
        ? json(~status, payloadToJson(payload))
        : renderDocument(options, ~status, payload, page)
    }

    let fail = (~status, ~title, ~message) =>
      wantsData
        ? json(~status, JSON.Encode.object(dict{"error": JSON.Encode.string(message)}))
        : respond(
            ~status,
            StackPage.messagePage(~title),
            Dict.make(),
            JSON.Encode.string(message),
            None,
          )

    switch StackPage.matchPage(pages, pathname) {
    | None => fail(~status=404, ~title="Not found", ~message=`Nothing lives at ${pathname}.`)
    | Some((page, params)) =>
      let route = routes->Array.find(r => r.page === page)->Option.getOrThrow
      let load = () => route.load({params, pathname, search, request})
      try {
        switch (Request.method(request), route.action) {
        | ("GET" | "HEAD", _) => respond(page, params, await load(), None)
        | ("POST", Some(action)) =>
          let form = StackFetch.parseForm(await Request.text(request))
          switch await action({params, pathname, form, request}) {
          | Redirect(to) =>
            wantsData
              ? json(JSON.Encode.object(dict{"redirect": JSON.Encode.string(to)}))
              : redirect(to)
          | Invalid(message) => respond(~status=422, page, params, await load(), Some(message))
          }
        | _ =>
          fail(~status=405, ~title="Method not allowed", ~message="This page does not accept that.")
        }
      } catch {
      | StackPage.NotFound =>
        fail(~status=404, ~title="Not found", ~message=`Nothing lives at ${pathname}.`)
      | error =>
        Console.error2("[xote] request failed", error)
        fail(
          ~status=500,
          ~title="Something went wrong",
          ~message="The server could not render this page.",
        )
      }
    }
  }
}
