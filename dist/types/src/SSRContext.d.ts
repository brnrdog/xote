/* TypeScript declarations generated from TypeScriptSSRContext.res via genType. */

/* eslint-disable */
/* tslint:disable */

export const isServer: boolean;

export const isClient: boolean;

export const onServer: <T1>(_1:(() => T1)) => (undefined | T1);

export const onClient: <T1>(_1:(() => T1)) => (undefined | T1);

export const match: <a>(server:(() => a), client:(() => a)) => a;
