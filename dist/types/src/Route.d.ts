/* TypeScript declarations generated from TypeScriptRoute.res via genType. */

/* eslint-disable */
/* tslint:disable */

export type params = {[id: string]: string};

export abstract class segment { protected opaque: any; } /* simulate opaque types */

export type matchResult = "NoMatch" | { TAG: "Match"; _0: params };

export const parsePattern: (pattern:string) => segment[];

export const matchPath: (pattern:segment[], pathname:string) => matchResult;

export const match: (pattern:string, pathname:string) => matchResult;

export const compile: (_1:string) => segment[];

export const matchCompiled: (_1:segment[], _2:string) => matchResult;

export const matchPathname: (_1:string, _2:string) => matchResult;
