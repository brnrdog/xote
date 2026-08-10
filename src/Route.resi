/* Pure route matching (no signals, no DOM).

   `match` is the single public entry point. The pattern parser and the compiled
   representation are implementation details, kept reachable for one release
   because `docs/TECHNICAL_OVERVIEW.md` documented them. */

/* Route parameter map, keyed by the `:name` segments of the pattern */
type params = Dict.t<string>

type matchResult =
  | Match(params)
  | NoMatch

/* Match a pathname against a pattern such as "/users/:id/posts/:postId" */
let match: (string, string) => matchResult

/* ============================================================================
 * Deprecated - removed in the next major release
 * ============================================================================ */

/* A parsed pattern segment: a literal, or a `:name` capture */
type segment =
  | Static(string)
  | Param(string)

@deprecated("Internal representation; use Route.match. Removed in the next major release.")
let parsePattern: string => array<segment>

@deprecated("Internal representation; use Route.match. Removed in the next major release.")
let matchPath: (array<segment>, string) => matchResult

@deprecated("Use Route.match. Removed in the next major release.")
let compile: string => array<segment>

@deprecated("Use Route.match. Removed in the next major release.")
let matchCompiled: (array<segment>, string) => matchResult

@deprecated("Use Route.match. Removed in the next major release.")
let matchPathname: (string, string) => matchResult
