// 404 Page component
module NotFoundPage = {
  type props = {}

  let make = (_props: props) => {
    <Layout
      children={
        <div class="not-found">
          <h1> {View.text("404")} </h1>
          <p> {View.text("The page you're looking for doesn't exist.")} </p>
          {Router.link(
            ~to="/",
            ~attrs=[View.attr("class", "btn btn-primary")],
            ~children=[View.text("Go Home")],
            (),
          )}
        </div>
      }
    />
  }
}

// Older docs URLs: send the reader on to the page's current URL, keeping any
// #anchor. The pre-rendered HTML for these paths redirects on its own; this
// covers client-side navigation and the dev server.
module Redirect = {
  type props = {to: string}

  @val @scope(("window", "location")) external currentHash: string = "hash"
  @val external setTimeout: (unit => unit, int) => int = "setTimeout"

  let make = (props: props) => {
    if SSRContext.isClient {
      let _ = setTimeout(() => Router.replace(props.to, ~hash=currentHash, ()), 0)
    }
    <Layout
      children={
        <div class="not-found">
          <p> {View.text("This page has moved.")} </p>
          {Router.link(
            ~to=props.to,
            ~attrs=[View.attr("class", "btn-pill btn-ink")],
            ~children=[View.text("Go to the new page")],
            (),
          )}
        </div>
      }
    />
  }
}

// Main app
module App = {
  type props = {}

  // The changelog's "On this page" lists its major versions.
  let changelogTocItems: array<DocsPage.TableOfContents.tocItem> =
    ChangelogContent.majors->Array.map(group => {
      let item: DocsPage.TableOfContents.tocItem = {
        text: `Xote ${Int.toString(group.number)}`,
        id: group.id,
        level: 2,
      }
      item
    })

  let docsPage = (page: DocsIndex.page): Router.routeConfig => {
    pattern: page.path,
    render: _params =>
      page.customToc ? <DocsPage page tocItems=changelogTocItems /> : <DocsPage page />,
  }

  let routes: array<Router.routeConfig> = Array.flat([
    [{Router.pattern: "/", render: _params => <HomePage />}],
    DocsIndex.pages->Array.map(docsPage),
    // "/docs/" with a trailing slash renders the introduction too.
    DocsIndex.find("/docs")->Option.mapOr([], page => [{...docsPage(page), pattern: "/docs/"}]),
    DocsIndex.redirects->Array.map(((from, to)): Router.routeConfig => {
      pattern: from,
      render: _params => <Redirect to />,
    }),
    [{Router.pattern: "*", render: _params => <NotFoundPage />}],
  ])

  let make = (_props: props) => Router.routes(routes)
}
