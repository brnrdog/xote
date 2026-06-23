/* TypeScript declarations generated from TypeScriptProp.res via genType. */

/* eslint-disable */
/* tslint:disable */

import type { t as Signal_t } from './Signal.js';

export abstract class t<a> { protected opaque: a; } /* simulate opaque types */

export const get: <a>(value:t<a>) => a;

export const static: <a>(value:a) => t<a>;

export const reactive: <a>(signal:Signal_t<a>) => t<a>;

export const signal: <T1>(_1:Signal_t<T1>) => t<T1>;
