/* Runtime environment detection for code shared between server and client. */

/* True when running without a DOM (Node.js) */
let isServer: bool

/* Inverse of `isServer` */
let isClient: bool

/* Run `fn` only on the server; `None` on the client */
let onServer: (unit => 'a) => option<'a>

/* Run `fn` only on the client; `None` on the server */
let onClient: (unit => 'a) => option<'a>

/* Branch on the environment */
let match: (~server: unit => 'a, ~client: unit => 'a) => 'a
