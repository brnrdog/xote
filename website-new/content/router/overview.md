# Router Overview

Xote includes a built-in signal-based router for building single-page applications (SPAs). The router uses the browser's History API and provides both imperative and declarative navigation.

## Features

- Signal-based reactive routing
- Browser History API integration
- Pattern matching with dynamic parameters
- Imperative navigation (push/replace)
- Declarative routing components
- SPA navigation links (no page reload)
- Zero dependencies

## Quick Start

### 1. Initialize the Router

Call `Router.init()` once at application startup:

```rescript
open Xote

Router.init()
```

This sets the initial location from the browser URL and adds a popstate listener for back/forward button support.

### 2. Define Routes

Use `Router.routes()` to define your application routes:

```rescript
let app = () => {
  <div>
    {Router.routes([
      {
        pattern: "/",
        render: _params => <HomePage />
      },
      {
        pattern: "/about",
        render: _params => <AboutPage />
      },
      {
        pattern: "/users/:id",
        render: params => <UserPage userId={params->Dict.get("id")} />
      },
    ])}
  </div>
}

Component.mountById(app(), "app")
```

### 3. Navigate

Use `Router.push()` or `Router.link()` to navigate:

```rescript
// Imperative navigation
let goToAbout = (_evt: Dom.event) => {
  Router.push("/about", ())
}

// Declarative links
Router.link(
  ~to="/about",
  ~children=[Component.text("About")],
  ()
)
```

## The Location Signal

`Router.location` is a signal containing the current route information:

```rescript
type location = {
  pathname: string,  // e.g., "/users/123"
  search: string,    // e.g., "?sort=name"
  hash: string,      // e.g., "#section"
}
```

Read it like any signal:

```rescript
Effect.run(() => {
  let currentLocation = Signal.get(Router.location)
  Console.log2("Current path:", currentLocation.pathname)
})
```

## Route Patterns

Patterns support static segments and dynamic parameters:

### Static Routes

```rescript
{pattern: "/", render: _params => <HomePage />}
{pattern: "/about", render: _params => <AboutPage />}
{pattern: "/contact", render: _params => <ContactPage />}
```

### Dynamic Parameters

Use `:param` syntax for dynamic segments:

```rescript
{pattern: "/users/:id", render: params =>
  switch params->Dict.get("id") {
  | Some(id) => <UserPage userId={id} />
  | None => <NotFoundPage />
  }
}

{pattern: "/posts/:postId/comments/:commentId", render: params => {
  let postId = params->Dict.get("postId")
  let commentId = params->Dict.get("commentId")
  <CommentPage postId={postId} commentId={commentId} />
}}
```

## Navigation Methods

### `Router.push()`

Navigate to a new route with a new history entry:

```rescript
Router.push("/users/123", ())

// With query string
Router.push("/search", ~search="?q=xote", ())

// With hash
Router.push("/docs", ~hash="#installation", ())
```

### `Router.replace()`

Navigate without creating a new history entry:

```rescript
Router.replace("/login", ())
```

This replaces the current history entry, so clicking the back button will skip this route.

## Navigation Links

Create links that navigate without page reload:

```rescript
Router.link(
  ~to="/about",
  ~children=[Component.text("About Us")],
  ()
)

// With attributes
Router.link(
  ~to="/users/123",
  ~attrs=[Component.attr("class", "user-link")],
  ~children=[Component.text("View User")],
  ()
)
```

## Complete Example

```rescript
open Xote

// Initialize router
Router.init()

// Page components
let homePage = () => {
  <div>
    <h1> {Component.text("Home")} </h1>
    {Router.link(~to="/about", ~children=[Component.text("About")], ())}
  </div>
}

let aboutPage = () => {
  <div>
    <h1> {Component.text("About")} </h1>
    {Router.link(~to="/", ~children=[Component.text("Home")], ())}
  </div>
}

// Main app
let app = () => {
  <div>
    <nav>
      {Router.link(~to="/", ~children=[Component.text("Home")], ())}
      {Component.text(" | ")}
      {Router.link(~to="/about", ~children=[Component.text("About")], ())}
    </nav>
    <hr />
    {Router.routes([
      {pattern: "/", render: _params => homePage()},
      {pattern: "/about", render: _params => aboutPage()},
    ])}
  </div>
}

Component.mountById(app(), "app")
```

## How It Works

1. **Initialization:** Router.init() reads the current URL and sets up the location signal
2. **History Integration:** Listens to popstate events for back/forward navigation
3. **Pattern Matching:** Routes use simple string-based matching with :param syntax
4. **Reactive Rendering:** Route components are wrapped in SignalFragment + Computed
5. **Link Handling:** Router.link() intercepts clicks and calls Router.push() instead of following the href

## Best Practices

- **Initialize once:** Call Router.init() at the top level, not in components
- **Order routes carefully:** More specific routes should come before generic ones
- **Handle 404s:** Add a catch-all route at the end for unmatched paths
- **Use links for navigation:** Prefer Router.link() over manual Router.push() calls
- **Extract parameters safely:** Use Option methods when accessing route parameters

## Next Steps

- Try the [Demos](/demos) to see routing in action
- Learn about [Signals](/docs/core-concepts/signals) for reactive state
- Explore [Components](/docs/components/overview) for building UIs
