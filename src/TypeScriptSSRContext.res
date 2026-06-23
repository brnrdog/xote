@genType
let isServer = SSRContext.isServer

@genType
let isClient = SSRContext.isClient

@genType
let onServer = SSRContext.onServer

@genType
let onClient = SSRContext.onClient

@genType
let match = (~server: unit => 'a, ~client: unit => 'a): 'a =>
  SSRContext.match(~server, ~client)
