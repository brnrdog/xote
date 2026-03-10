open Zekr
open Xote

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
      | Route.Match(params) =>
        assertEqual(Dict.get(params, "id"), Some("42"))
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
  ],
)
