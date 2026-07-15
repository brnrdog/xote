%%raw(`import "./setup.mjs"`)

open! Zekr
open Types

let getAttr = (el, key: string): string => {
  ignore(el)
  ignore(key)
  %raw(`el.getAttribute(key)`)
}

let useImmediateMicrotask = (): unit => {
  let _: unit = %raw(`
    (() => {
      if (!globalThis.__xoteOriginalQueueMicrotask) {
        globalThis.__xoteOriginalQueueMicrotask = globalThis.queueMicrotask;
      }
      globalThis.queueMicrotask = callback => callback();
    })()
  `)
}

let restoreMicrotask = (): unit => {
  let _: unit = %raw(`
    (() => {
      if (globalThis.__xoteOriginalQueueMicrotask) {
        globalThis.queueMicrotask = globalThis.__xoteOriginalQueueMicrotask;
        delete globalThis.__xoteOriginalQueueMicrotask;
      }
    })()
  `)
}

let cleanupGlobalContainers = (): unit => {
  let _: unit = %raw(`
    document.querySelectorAll("[data-router-test]").forEach(element => element.remove())
  `)
}

let makeGlobalContainer = () => {
  %raw(`
    (() => {
      const container = document.createElement("div");
      container.setAttribute("data-router-test", "true");
      document.body.appendChild(container);
      return container;
    })()
  `)
}

let querySelector = (el, selector: string) => {
  ignore(el)
  ignore(selector)
  %raw(`el.querySelector(selector)`)
}

let clickElement = el => {
  ignore(el)
  let _: unit = %raw(`el.click()`)
}

let setScrollIntoView = (el, called: ref<bool>): unit => {
  ignore(el)
  ignore(called)
  let _: unit = %raw(`el.scrollIntoView = () => { called.contents = true }`)
}

let suite = Suite.make(
  "Route",
  [
    Test.make("matches exact root path", () => {
      switch Route.match("/", "/") {
      | Route.Match(params) => Assert.equal(Dict.keysToArray(params)->Array.length, 0)
      | Route.NoMatch => Fail("Expected Match for /")
      }
    }),
    Test.make("matches exact static path", () => {
      switch Route.match("/about", "/about") {
      | Route.Match(params) => Assert.equal(Dict.keysToArray(params)->Array.length, 0)
      | Route.NoMatch => Fail("Expected Match for /about")
      }
    }),
    Test.make("returns NoMatch for different static paths", () => {
      switch Route.match("/about", "/contact") {
      | Route.Match(_) => Fail("Expected NoMatch")
      | Route.NoMatch => Pass
      }
    }),
    Test.make("returns NoMatch for different segment count", () => {
      switch Route.match("/users/:id", "/users") {
      | Route.Match(_) => Fail("Expected NoMatch for /users vs /users/:id")
      | Route.NoMatch => Pass
      }
    }),
    Test.make("extracts single route parameter", () => {
      switch Route.match("/users/:id", "/users/42") {
      | Route.Match(params) => Assert.equal(Dict.get(params, "id"), Some("42"))
      | Route.NoMatch => Fail("Expected Match for /users/42")
      }
    }),
    Test.make("extracts multiple route parameters", () => {
      switch Route.match("/users/:id/posts/:postId", "/users/1/posts/5") {
      | Route.Match(params) =>
        Assert.combineResults([
          Assert.equal(Dict.get(params, "id"), Some("1")),
          Assert.equal(Dict.get(params, "postId"), Some("5")),
        ])
      | Route.NoMatch => Fail("Expected Match for /users/1/posts/5")
      }
    }),
    Test.make("matches multi-segment static path", () => {
      switch Route.match("/app/settings/profile", "/app/settings/profile") {
      | Route.Match(_) => Pass
      | Route.NoMatch => Fail("Expected Match for /app/settings/profile")
      }
    }),
    Test.make("does not match partial static path", () => {
      switch Route.match("/app/settings", "/app/settings/profile") {
      | Route.Match(_) => Fail("Expected NoMatch for partial path")
      | Route.NoMatch => Pass
      }
    }),
    Test.make("Router.link keeps search and hash separate from pathname", () => {
      Router.init()
      let {container} = DomTesting.render("")
      View.mount(
        Router.link(
          ~to="/docs/api/signal?tab=read#signal-get",
          ~children=[View.text("Signal.get")],
          (),
        ),
        container,
      )

      let link = DomTesting.Query.getByText(container, "Signal.get")
      let hrefResult = Assert.equal(getAttr(link, "href"), "/docs/api/signal?tab=read#signal-get")

      DomTesting.Event.click(link)
      let current = Signal.peek(Router.location())

      Assert.combineResults([
        hrefResult,
        Assert.equal(current.pathname, "/docs/api/signal"),
        Assert.equal(current.search, "?tab=read"),
        Assert.equal(current.hash, "#signal-get"),
      ])
    }),
    Test.make("Router.Link keeps search and hash separate from pathname", () => {
      Router.init()
      let {container} = DomTesting.render("")
      let clicked = ref(false)

      View.mount(
        <Router.Link
          to="/docs/api/computed?tab=derive#computed-make"
          class="api-link"
          onClick={_evt => clicked := true}>
          {View.text("Computed.make")}
        </Router.Link>,
        container,
      )

      let link = DomTesting.Query.getByText(container, "Computed.make")
      let hrefResult = Assert.equal(
        getAttr(link, "href"),
        "/docs/api/computed?tab=derive#computed-make",
      )

      DomTesting.Event.click(link)
      let current = Signal.peek(Router.location())

      Assert.combineResults([
        hrefResult,
        Assert.equal(getAttr(link, "class"), "api-link"),
        Assert.isTrue(clicked.contents),
        Assert.equal(current.pathname, "/docs/api/computed"),
        Assert.equal(current.search, "?tab=derive"),
        Assert.equal(current.hash, "#computed-make"),
      ])
    }),
    Test.make("Router.link scrolls to hash targets after navigation", () => {
      Router.init()
      useImmediateMicrotask()
      let container = makeGlobalContainer()
      View.mount(
        Html.div(
          ~children=[
            Router.link(
              ~to="/docs/api/signal#signal-get",
              ~children=[View.text("Signal.get")],
              (),
            ),
            Html.h2(~attrs=[View.attr("id", "signal-get")], ~children=[View.text("Target")], ()),
          ],
          (),
        ),
        container,
      )

      let called = ref(false)
      let target = querySelector(container, "#signal-get")
      setScrollIntoView(target, called)

      let link = querySelector(container, "a")
      clickElement(link)
      restoreMicrotask()

      Assert.isTrue(called.contents)
    }),
    Test.make("Router.Link scrolls to encoded hash targets after navigation", () => {
      Router.init()
      useImmediateMicrotask()
      let container = makeGlobalContainer()
      View.mount(
        <div>
          <Router.Link to="/docs/api/view#view%20text">
            {View.text("View.Text")}
          </Router.Link>
          <h2 id="view text"> {View.text("Target")} </h2>
        </div>,
        container,
      )

      let called = ref(false)
      let target = querySelector(container, "#view\\ text")
      setScrollIntoView(target, called)

      let link = querySelector(container, "a")
      clickElement(link)
      restoreMicrotask()

      let current = Signal.peek(Router.location())

      Assert.combineResults([
        Assert.isTrue(called.contents),
        Assert.equal(current.pathname, "/docs/api/view"),
        Assert.equal(current.hash, "#view%20text"),
      ])
    }),
  ],
  ~afterEach=() => {
    restoreMicrotask()
    cleanupGlobalContainers()
    DomTesting.cleanup()
  },
)
