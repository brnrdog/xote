// Pure route matching logic (no signals, no DOM)

// Route parameter map
type params = Dict.t<string>

// Match result
type matchResult =
  | Match(params)
  | NoMatch

// Route segment - either static or dynamic parameter
type segment =
  | Static(string)
  | Param(string)

// Parse a route pattern like "/users/:id/posts/:postId"
// Returns array of segments, where dynamic segments are marked
let parsePattern = (pattern: string): array<segment> => {
  pattern
  ->String.split("/")
  ->Array.filterMap(seg => {
    if seg == "" {
      None
    } else if String.startsWith(seg, ":") {
      Some(Param(String.sliceToEnd(seg, ~start=1)))
    } else {
      Some(Static(seg))
    }
  })
}

// Match a pathname against a parsed pattern
let matchPath = (pattern: array<segment>, pathname: string): matchResult => {
  let pathSegments =
    pathname
    ->String.split("/")
    ->Array.filter(s => s != "")

  // Length must match
  if Array.length(pattern) != Array.length(pathSegments) {
    NoMatch
  } else {
    let params = Dict.make()
    let matches = pattern->Array.everyWithIndex((seg, idx) => {
      let pathSeg = pathSegments->Array.getUnsafe(idx)
      switch seg {
      | Static(expected) => pathSeg == expected
      | Param(name) => {
          params->Dict.set(name, pathSeg)
          true
        }
      }
    })

    matches ? Match(params) : NoMatch
  }
}

// Convenience: match a pattern string against pathname
let match = (pattern: string, pathname: string): matchResult => {
  matchPath(parsePattern(pattern), pathname)
}
