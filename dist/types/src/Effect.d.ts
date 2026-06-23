/* TypeScript declarations generated from TypeScriptEffect.res via genType. */

/* eslint-disable */
/* tslint:disable */

export type disposer = { readonly dispose: () => void };

export const runWithDisposer: (fn: () => undefined | (() => void), name?: string) => disposer;

export const run: (fn: () => undefined | (() => void), name?: string) => void;
