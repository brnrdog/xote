@genType
type params = Dict.t<string>

@genType
type segment

@genType
type matchResult =
  | Match(params)
  | NoMatch

@genType
let parsePattern = (pattern: string): array<segment> => Obj.magic(Route.parsePattern(pattern))

@genType
let matchPath = (pattern: array<segment>, pathname: string): matchResult =>
  Obj.magic(Route.matchPath(Obj.magic(pattern), pathname))

@genType
let match = (pattern: string, pathname: string): matchResult =>
  Obj.magic(Route.match(pattern, pathname))

@genType
let compile = parsePattern

@genType
let matchCompiled = matchPath

@genType
let matchPathname = match
