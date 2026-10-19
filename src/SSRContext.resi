/***
Runtime environment detection for code shared between server and client.

Use these instead of testing for `window` by hand, so the same component can be
rendered by `SSR` and hydrated by `Hydration` without branching on globals.

## Examples

```rescript
let readPreferredTheme = () =>
  SSRContext.match(~server=() => "light", ~client=() => "dark")
```
*/

/**
True when running without a DOM (Node.js).

A constant, resolved once at module initialization, so it is safe to branch on
at the top level.

## Examples

```rescript
let label = SSRContext.isServer ? "server" : "browser"
```
*/
let isServer: bool

/**
True when running in a browser. The inverse of `isServer`.

## Examples

```rescript
SSRContext.isClient == !SSRContext.isServer
```
*/
let isClient: bool

/**
Runs `fn` only on the server, returning `Some` of its result. `None` on the
client.

## Examples

```rescript
let secret = SSRContext.onServer(() => "read from the environment")
// On the server: Some("read from the environment"). In the browser: None.
```
*/
let onServer: (unit => 'a) => option<'a>

/**
Runs `fn` only on the client, returning `Some` of its result. `None` on the
server.

The natural home for DOM access, which would throw during server rendering.

## Examples

```rescript
let width = SSRContext.onClient(() => 1024)
// In the browser: Some(1024). On the server: None.
```
*/
let onClient: (unit => 'a) => option<'a>

/**
Branches on the environment, running exactly one of the two callbacks.

Unlike `onServer`/`onClient` this is total — both branches return `'a`, so
there is no option to unwrap.

## Examples

```rescript
let baseUrl = SSRContext.match(
  ~server=() => "http://localhost:3000",
  ~client=() => "",
)
```
*/
let match: (~server: unit => 'a, ~client: unit => 'a) => 'a
