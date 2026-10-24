/* Minimal bindings to the Fetch API (`Request`, `Response`, `URL`).

   The server handler is written against these web-standard types, so the same
   handler runs on Bun (`Bun.serve({fetch})`), Deno, edge runtimes, or Node
   through a small adapter (see `serve.mjs`). */

type request
type response
type headers

module Request = {
  @get external method: request => string = "method"
  @get external url: request => string = "url"
  @get external headers: request => headers = "headers"
  @send external text: request => promise<string> = "text"
}

module Headers = {
  @send @return(nullable) external get: (headers, string) => option<string> = "get"
}

module Response = {
  type init = {status?: int, headers?: Dict.t<string>}
  @new external make: (string, init) => response = "Response"
  @get external status: response => int = "status"
  @get external ok: response => bool = "ok"
  @send external json: response => promise<JSON.t> = "json"
}

type requestInit = {
  method?: string,
  body?: string,
  headers: Dict.t<string>,
}

@val external fetch: (string, requestInit) => promise<response> = "fetch"

module Url = {
  type t
  @new external make: (string, ~base: string=?) => t = "URL"
  @get external pathname: t => string = "pathname"
  @get external search: t => string = "search"
  @get external origin: t => string = "origin"
}

/* `application/x-www-form-urlencoded` body (or query string) to a dict. When a
 key repeats, the last value wins. */
let parseForm: string => Dict.t<string> = %raw(`function (body) {
  return Object.fromEntries(new URLSearchParams(body))
}`)

let encodeForm: Dict.t<string> => string = %raw(`function (fields) {
  return new URLSearchParams(fields).toString()
}`)
