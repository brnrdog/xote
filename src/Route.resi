/***
Pure route matching: no signals, no DOM.

`match` is the single public entry point. The pattern parser and the compiled
representation are implementation details, kept reachable for one release
because `docs/TECHNICAL_OVERVIEW.md` documented them.

## Examples

```rescript
let id = switch Route.match("/users/:id", "/users/42") {
| Match(params) => Dict.get(params, "id")
| NoMatch => None
}

id == Some("42")
```
*/

/**
Route parameters, keyed by the `:name` segments of the pattern.

A pattern of `"/users/:id/posts/:postId"` matched against
`"/users/7/posts/3"` yields `{"id": "7", "postId": "3"}`. Values are always
strings — parse them yourself.

## Examples

```rescript
let params: Route.params = Dict.fromArray([("id", "42")])
Dict.get(params, "id") == Some("42")
Dict.get(params, "missing") == None
```
*/
type params = Dict.t<string>

/**
The outcome of `match`: captured parameters, or no match.

`Match` carries the parameter map even when the pattern has no `:name`
segments, in which case the dict is empty.
*/
type matchResult =
  | Match(params)
  | NoMatch

/**
Matches a pathname against a pattern.

The pattern is a `/`-separated list of literal segments and `:name` captures,
such as `"/users/:id/posts/:postId"`. Matching is exact: every segment must
line up, so `"/users/:id"` does not match `"/users/42/edit"`.

## Examples

```rescript
// A capture.
let id = switch Route.match("/users/:id", "/users/42") {
| Match(params) => Dict.get(params, "id")
| NoMatch => None
}
id == Some("42")

// Several captures.
let postId = switch Route.match("/users/:id/posts/:postId", "/users/7/posts/3") {
| Match(params) => Dict.get(params, "postId")
| NoMatch => None
}
postId == Some("3")

// A literal pattern matches with an empty parameter map.
Route.match("/about", "/about") == Match(Dict.make())

// Segment counts must line up.
Route.match("/users/:id", "/users/42/edit") == NoMatch
```
*/
let match: (string, string) => matchResult

/* ============================================================================
 * Deprecated - removed in the next major release
 * ============================================================================ */

/** A parsed pattern segment: a literal, or a `:name` capture. */
type segment =
  | Static(string)
  | Param(string)

/** Deprecated: internal representation. Use `Route.match`. */
@deprecated("Internal representation; use Route.match. Removed in the next major release.")
let parsePattern: string => array<segment>

/** Deprecated: internal representation. Use `Route.match`. */
@deprecated("Internal representation; use Route.match. Removed in the next major release.")
let matchPath: (array<segment>, string) => matchResult

/** Deprecated: use `Route.match`. */
@deprecated("Use Route.match. Removed in the next major release.")
let compile: string => array<segment>

/** Deprecated: use `Route.match`. */
@deprecated("Use Route.match. Removed in the next major release.")
let matchCompiled: (array<segment>, string) => matchResult

/** Deprecated: use `Route.match`. */
@deprecated("Use Route.match. Removed in the next major release.")
let matchPathname: (string, string) => matchResult
