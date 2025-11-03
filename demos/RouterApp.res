// RouterApp - Example demonstrating Xote routing capabilities

open Xote

// Initialize router at app start
Router.init()

// Page components
module HomePage = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "page home-page")],
      ~children=[
        Component.h1(~children=[Component.text("Welcome to Xote Router")], ()),
        Component.p(
          ~children=[
            Component.text(
              "This example demonstrates the routing capabilities of Xote. Navigate using the links above.",
            ),
          ],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "quick-links")],
          ~children=[
            Component.h2(~children=[Component.text("Quick Links:")], ()),
            Component.ul(
              ~children=[
                Component.li(
                  ~children=[Router.link(~to="/about", ~children=[Component.text("About")], ())],
                  (),
                ),
                Component.li(
                  ~children=[
                    Router.link(~to="/users/alice", ~children=[Component.text("User: Alice")], ()),
                  ],
                  (),
                ),
                Component.li(
                  ~children=[
                    Router.link(~to="/users/bob", ~children=[Component.text("User: Bob")], ()),
                  ],
                  (),
                ),
                Component.li(
                  ~children=[
                    Router.link(
                      ~to="/users/charlie",
                      ~children=[Component.text("User: Charlie")],
                      (),
                    ),
                  ],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module AboutPage = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "page about-page")],
      ~children=[
        Component.h1(~children=[Component.text("About Xote Router")], ()),
        Component.p(
          ~children=[
            Component.text(
              "Xote Router is a lightweight, signal-based routing solution for ReScript applications.",
            ),
          ],
          (),
        ),
        Component.h2(~children=[Component.text("Features:")], ()),
        Component.ul(
          ~children=[
            Component.li(
              ~children=[Component.text("Zero dependencies - uses only browser APIs")],
              (),
            ),
            Component.li(~children=[Component.text("Signal-based reactivity")], ()),
            Component.li(
              ~children=[Component.text("Pattern matching with dynamic parameters")],
              (),
            ),
            Component.li(~children=[Component.text("Declarative route definitions")], ()),
            Component.li(~children=[Component.text("Link component for SPA navigation")], ()),
          ],
          (),
        ),
        Component.p(
          ~children=[
            Router.link(~to="/", ~children=[Component.text("← Back to Home")], ()),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module UserPage = {
  let component = (~userId: string, ()) => {
    // Create reactive state for user data
    let displayName = Signal.make(String.toUpperCase(String.slice(userId, ~start=0, ~end=1)) ++
      String.sliceToEnd(userId, ~start=1))

    Component.div(
      ~attrs=[Component.attr("class", "page user-page")],
      ~children=[
        Component.h1(
          ~children=[
            Component.text("User Profile: "),
            Component.textSignal(() => Signal.get(displayName)),
          ],
          (),
        ),
        Component.div(
          ~attrs=[Component.attr("class", "user-info")],
          ~children=[
            Component.p(
              ~children=[
                Component.text("Username: "),
                Component.span(
                  ~attrs=[Component.attr("class", "username")],
                  ~children=[Component.text(userId)],
                  (),
                ),
              ],
              (),
            ),
            Component.p(
              ~children=[
                Component.text("This is a dynamic route that matches the pattern "),
                Component.span(
                  ~attrs=[Component.attr("class", "code")],
                  ~children=[Component.text("/users/:id")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        Component.h2(~children=[Component.text("Other Users:")], ()),
        Component.ul(
          ~children=[
            Component.li(
              ~children=[Router.link(~to="/users/alice", ~children=[Component.text("Alice")], ())],
              (),
            ),
            Component.li(
              ~children=[Router.link(~to="/users/bob", ~children=[Component.text("Bob")], ())],
              (),
            ),
            Component.li(
              ~children=[
                Router.link(~to="/users/charlie", ~children=[Component.text("Charlie")], ()),
              ],
              (),
            ),
          ],
          (),
        ),
        Component.p(
          ~children=[
            Router.link(~to="/", ~children=[Component.text("← Back to Home")], ()),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

module NotFoundPage = {
  let component = () => {
    Component.div(
      ~attrs=[Component.attr("class", "page not-found-page")],
      ~children=[
        Component.h1(~children=[Component.text("404 - Page Not Found")], ()),
        Component.p(
          ~children=[
            Component.text("The page you're looking for doesn't exist."),
          ],
          (),
        ),
        Component.p(
          ~children=[
            Router.link(~to="/", ~children=[Component.text("← Go Home")], ()),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

// Main app component with navigation and routing
module App = {
  let component = () => {
    // Current path signal for active link styling
    let currentPath = Computed.make(() => Signal.get(Router.location).pathname)

    Component.div(
      ~attrs=[Component.attr("class", "app")],
      ~children=[
        // Navigation bar
        Component.div(
          ~attrs=[Component.attr("class", "navbar")],
          ~children=[
            Component.div(
              ~attrs=[Component.attr("class", "nav-links")],
              ~children=[
                Router.link(
                  ~to="/",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      Signal.get(currentPath) == "/" ? "nav-link active" : "nav-link"
                    ),
                  ],
                  ~children=[Component.text("Home")],
                  (),
                ),
                Component.text(" | "),
                Router.link(
                  ~to="/about",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      Signal.get(currentPath) == "/about" ? "nav-link active" : "nav-link"
                    ),
                  ],
                  ~children=[Component.text("About")],
                  (),
                ),
                Component.text(" | "),
                Router.link(
                  ~to="/users/alice",
                  ~attrs=[
                    Component.computedAttr("class", () =>
                      String.startsWith(Signal.get(currentPath), "/users")
                        ? "nav-link active"
                        : "nav-link"
                    ),
                  ],
                  ~children=[Component.text("Users")],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
        // Main content area with routes
        Component.div(
          ~attrs=[Component.attr("class", "content")],
          ~children=[
            Router.routes([
              {pattern: "/", render: _params => HomePage.component()},
              {pattern: "/about", render: _params => AboutPage.component()},
              {
                pattern: "/users/:id",
                render: params => {
                  let userId = params->Dict.get("id")->Option.getOr("unknown")
                  UserPage.component(~userId, ())
                },
              },
            ]),
            // 404 fallback - shown when no routes match
            Component.signalFragment(
              Computed.make(() => {
                let loc = Signal.get(Router.location)
                let hasMatch =
                  Route.match("/", loc.pathname) != NoMatch ||
                  Route.match("/about", loc.pathname) != NoMatch ||
                  Route.match("/users/:id", loc.pathname) != NoMatch

                hasMatch ? [] : [NotFoundPage.component()]
              }),
            ),
          ],
          (),
        ),
        // Footer with current location info
        Component.div(
          ~attrs=[Component.attr("class", "footer")],
          ~children=[
            Component.p(
              ~children=[
                Component.text("Current path: "),
                Component.span(
                  ~attrs=[Component.attr("class", "code")],
                  ~children=[Component.textSignal(() => Signal.get(Router.location).pathname)],
                  (),
                ),
              ],
              (),
            ),
          ],
          (),
        ),
      ],
      (),
    )
  }
}

// Mount the app
Component.mountById(App.component(), "app")
