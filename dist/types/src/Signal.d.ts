/* TypeScript declarations generated from TypeScriptSignal.res via genType. */

/* eslint-disable */
/* tslint:disable */

export abstract class t<a> { protected opaque: a; } /* simulate opaque types */

export const defaultEquals: <T1>(_1:T1, _2:T1) => boolean;

export const neverEquals: <T1>(_1:T1, _2:T1) => boolean;

export const make: <a>(initialValue: a, name?: string, equals?: (_1: a, _2: a) => boolean) => t<a>;

export const makeForComputed: <a>(initialValue: a, name?: string) => t<a>;

export const get: <a>(signal:t<a>) => a;

export const peek: <a>(signal:t<a>) => a;

export const set: <a>(signal:t<a>, newValue:a) => void;

export const update: <a>(signal:t<a>, fn:((_1:a) => a)) => void;

export const batch: <T1>(_1:(() => T1)) => T1;

export const untrack: <T1>(_1:(() => T1)) => T1;
