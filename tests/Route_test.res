open! Zekr

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

let suite = Zekr.suite(
  "Route",
  [
    test("matches exact root path", () => {
      switch Route.match("/", "/") {
      | Route.Match(params) => assertEqual(Dict.keysToArray(params)->Array.length, 0)
      | Route.NoMatch => Fail("Expected Match for /")
      }
    }),
    test("matches exact static path", () => {
      switch Route.match("/about", "/about") {
      | Route.Match(params) => assertEqual(Dict.keysToArray(params)->Array.length, 0)
      | Route.NoMatch => Fail("Expected Match for /about")
      }
    }),
    test("returns NoMatch for different static paths", () => {
      switch Route.match("/about", "/contact") {
      | Route.Match(_) => Fail("Expected NoMatch")
      | Route.NoMatch => Pass
      }
    }),
    test("returns NoMatch for different segment count", () => {
      switch Route.match("/users/:id", "/users") {
      | Route.Match(_) => Fail("Expected NoMatch for /users vs /users/:id")
      | Route.NoMatch => Pass
      }
    }),
    test("extracts single route parameter", () => {
      switch Route.match("/users/:id", "/users/42") {
      | Route.Match(params) => assertEqual(Dict.get(params, "id"), Some("42"))
      | Route.NoMatch => Fail("Expected Match for /users/42")
      }
    }),
    test("extracts multiple route parameters", () => {
      switch Route.match("/users/:id/posts/:postId", "/users/1/posts/5") {
      | Route.Match(params) =>
        combineResults([
          assertEqual(Dict.get(params, "id"), Some("1")),
          assertEqual(Dict.get(params, "postId"), Some("5")),
        ])
      | Route.NoMatch => Fail("Expected Match for /users/1/posts/5")
      }
    }),
    test("matches multi-segment static path", () => {
      switch Route.match("/app/settings/profile", "/app/settings/profile") {
      | Route.Match(_) => Pass
      | Route.NoMatch => Fail("Expected Match for /app/settings/profile")
      }
    }),
    test("does not match partial static path", () => {
      switch Route.match("/app/settings", "/app/settings/profile") {
      | Route.Match(_) => Fail("Expected NoMatch for partial path")
      | Route.NoMatch => Pass
      }
    }),
    test("Router.link keeps search and hash separate from pathname", () => {
      Router.init()
      let {container} = Dom.render("")
      View.mount(
        Router.link(
          ~to="/docs/api/signal?tab=read#signal-get",
          ~children=[View.text("Signal.get")],
          (),
        ),
        container,
      )

      let link = Dom.Query.getByText(container, "Signal.get")
      let hrefResult = assertEqual(getAttr(link, "href"), "/docs/api/signal?tab=read#signal-get")

      Dom.Event.click(link)
      let current = Signal.peek(Router.location())

      combineResults([
        hrefResult,
        assertEqual(current.pathname, "/docs/api/signal"),
        assertEqual(current.search, "?tab=read"),
        assertEqual(current.hash, "#signal-get"),
      ])
    }),
    test("Router.link scrolls to hash targets after navigation", () => {
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

      assertTrue(called.contents)
    }),
  ],
  ~afterEach=() => {
    restoreMicrotask()
    cleanupGlobalContainers()
    Dom.cleanup()
  },
)
