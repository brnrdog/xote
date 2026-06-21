/* TypeScript declarations generated from TypeScriptComputed.res via genType. */

/* eslint-disable */
/* tslint:disable */

import type { t as Signal_t } from './Signal.js';

export const makeWithoutEquals: <a>(compute: () => a, name?: string) => Signal_t<a>;

export const makeWithEquals: <a>(compute: () => a, equalsFn: (_1: a, _2: a) => boolean, name?: string) => Signal_t<a>;

export const make: <a>(compute: () => a, name?: string, equals?: (_1: a, _2: a) => boolean) => Signal_t<a>;

export const dispose: <a>(signal:Signal_t<a>) => void;
