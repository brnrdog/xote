/* ============================================================================
 * SSR Context - Environment Detection and Utilities
 * ============================================================================ */

/* Runtime detection - true when running in Node.js (no DOM) */
let isServer: bool = %raw(`typeof document === 'undefined'`)

/* Convenience inverse */
let isClient: bool = !isServer

/* Execute function only on server, returns None on client */
let onServer = (fn: unit => 'a): option<'a> => {
  if isServer {
    Some(fn())
  } else {
    None
  }
}

/* Execute function only on client, returns None on server */
let onClient = (fn: unit => 'a): option<'a> => {
  if isClient {
    Some(fn())
  } else {
    None
  }
}

/* Execute different functions based on environment */
let match = (~server: unit => 'a, ~client: unit => 'a): 'a => {
  if isServer {
    server()
  } else {
    client()
  }
}
