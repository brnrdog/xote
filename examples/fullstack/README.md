# Fullstack xote (prototype)

A Remix/Next-style setup built on xote's `SSR` and `Hydration` modules: every
route has a **loader** (data for GET) and optionally an **action** (handles a
form POST). Pages are rendered on the server, hydrated in the browser, and
later navigations fetch only the page's data as JSON.

```sh
npm run fullstack:build   # compile ReScript, bundle the client
npm run fullstack:start   # http://localhost:3000
```

## How a request flows

| Request | Server answers with |
|---|---|
| `GET /notes` (first load, or no JavaScript) | Full HTML document, page data embedded as JSON, client script |
| `GET /notes` with `x-xote-data: 1` (client-side navigation) | The page's data as JSON |
| `POST /notes` (plain form) | Action runs → `303` redirect, or the page re-rendered with `422` and an error |
| `POST /notes` with `x-xote-data: 1` (enhanced form) | `{"redirect": ...}` or the page's data with the error |

Links and forms are plain `<a href>` and `<form method="post">`, so the app works
without JavaScript; the client takes them over once it is loaded. Add
`data-reload` to a link or form to opt out of that.

## Layout

```
framework/              the would-be library
  StackPage.res         pages (path + codec + view), the outlet, shared by both sides
  StackServer.res       loaders/actions → `Request => promise<Response>`
  StackClient.res       hydration, link/form interception, history
  StackFetch.res        Fetch API bindings
app/                    an example notes app
  NotesPages.res        the pages: URL, data codec, view (shared)
  NotesApp.res          layout + page list (shared)
  NotesServer.res       loaders and actions (server only)
  NotesDb.res           in-memory "database" (server only)
  NotesClient.res       browser entry
serve.mjs               Node adapter; on Bun: `Bun.serve({fetch: handler})`
```

A page is declared once and shared:

```rescript
let note = StackPage.make(~path="/notes/:id", ~codec=noteCodec, ~title=n => n.title, ({data}) =>
  <h1> {View.text(data.title)} </h1>
)
```

Its loader is attached on the server, where the type checker makes sure it
returns the page's data type:

```rescript
StackServer.route(NotesPages.note, ~loader=async ({params}) =>
  switch await NotesDb.find(params->Dict.getUnsafe("id")) {
  | Some(note) => note
  | None => throw(StackPage.NotFound)
  }
)
```

Because loaders and actions are attached only in `NotesServer`, the client
bundle never imports database code. No compiler step is needed to strip it, as
Next.js and Remix do.

## What's missing before this could become `xote/server`

- **Nested routes/layouts**: there is a single layout and a flat list of pages,
  with no per-segment loaders like Remix's nested routes.
- **The page re-renders on hydration**: the outlet is a `View.tracked` block,
  and hydration re-renders a `SignalFragment` rather than adopting the server's
  DOM. The layout is hydrated in place; the page content is rebuilt once.
- **No streaming**: loaders resolve before rendering starts. `View.Suspense`
  renders only its fallback on the server.
- **Build tooling**: you run `rescript` and `vite build` by hand. A Vite plugin
  could run the dev server, do HMR and fingerprint assets.
- **Request-scoped state**: this design avoids xote's global `SSRState` and
  `Router` state. Code that uses them would need them made per request.
