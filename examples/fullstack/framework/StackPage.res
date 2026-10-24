/* A page: a URL pattern, the codec for the data its loader produces, and the
   view that renders that data.

   This module is shared by server and client. It deliberately knows nothing
   about loaders or actions — those are attached on the server
   (`StackServer.route`), so database code never reaches the client bundle.
   The `'data` type parameter is what ties the two halves together: the server
   can only attach a loader that returns the page's data type. */

module Codec = SSRState.Codec

/* What a view receives. `error` is set when an action rejected a submission
 (`StackServer.Invalid`), so the page can show it next to the form. */
type props<'data> = {
  data: 'data,
  params: Route.params,
  error: option<string>,
}

type t<'data> = {
  path: string,
  codec: Codec.t<'data>,
  title: 'data => string,
  view: props<'data> => View.node,
}

let make = (~path, ~codec, ~title=_ => "Xote", view): t<'data> => {path, codec, title, view}

/* A page with its data type erased, so pages of different types fit in one
   array. Data crosses this boundary as JSON, which is also the form it
   travels in between server and client. */
type any = {
  path: string,
  title: JSON.t => string,
  render: (JSON.t, Route.params, option<string>) => View.node,
}

exception DecodeError(string)

let erase = (page: t<'data>): any => {
  let decode = json =>
    switch page.codec.decode(json) {
    | Some(data) => data
    | None => throw(DecodeError(`Page ${page.path}: data does not match its codec`))
    }
  {
    path: page.path,
    title: json => page.title(decode(json)),
    /* A LazyComponent, so the view body runs untracked: signals the page reads
     subscribe its own effects, not the outlet that swaps pages. */
    render: (json, params, error) => View.LazyComponent(
      () => page.view({data: decode(json), params, error}),
    ),
  }
}

let matchPage = (pages: array<any>, pathname): option<(any, Route.params)> =>
  pages->Array.findMap(page =>
    switch Route.match(page.path, pathname) {
    | Match(params) => Some((page, params))
    | NoMatch => None
    }
  )

/* A page for 404s and failures, rendered inside the layout. Its data is the
 message; its path, `*`, never matches a URL. */
let messagePage = (~title): any =>
  erase(
    make(
      ~path="*",
      ~codec=Codec.string,
      ~title=_ => title,
      ({data}) =>
        <section class="message">
          <h1> {View.text(title)} </h1>
          <p> {View.text(data)} </p>
        </section>,
    ),
  )

/* Thrown by a loader or action when the resource does not exist. */
exception NotFound

/* What the server sends for a page: as JSON to client-side navigations, and
 embedded in the document on a full load. */
type payload = {
  path: string,
  params: Dict.t<string>,
  data: JSON.t,
  error: option<string>,
  title: string,
}

/* The page currently on screen. */
type current = {
  page: any,
  params: Route.params,
  data: JSON.t,
  error: option<string>,
}

/* An application: its pages, and the layout every page renders inside. */
type app = {
  pages: array<any>,
  layout: View.node => View.node,
}

/* The node pages render into. Reading `current` inside `tracked` makes it the
   only dependency: a navigation swaps the page, disposing the previous one's
   effects, while the layout around it stays. */
let outlet = (current: Signal.t<current>) =>
  View.tracked(() => {
    let {page, params, data, error} = Signal.get(current)
    page.render(data, params, error)
  })

/* The whole tree, identical on server and client so hydration lines up. */
let root = (app: app, current) => () => app.layout(outlet(current))

/* True while a client-side navigation or submission is in flight. Never set
 on the server, so it renders as `false` there. */
let pending = Signal.make(false)
