/* TypeScript declarations generated from TypeScriptRouter.res via genType. */

/* eslint-disable */
/* tslint:disable */

import type { attrValue as View_attrValue } from './View.js';

import type { node as View_node } from './View.js';

import type { params as Route_params } from './Route.js';

import type { t as Signal_t } from './Signal.js';

export type location = {
  readonly pathname: string; 
  readonly search: string; 
  readonly hash: string
};

export type routeConfig = { readonly pattern: string; readonly render: (_1:Route_params) => View_node };

export const init: (basePath?: string) => void;

export const initSSR: (basePath?: string, pathname?: string, search?: string, hash?: string) => void;

export const location: () => Signal_t<location>;

export const push: (pathname: string, search?: string, hash?: string) => void;

export const replace: (pathname: string, search?: string, hash?: string) => void;

export const route: (pattern:string, render:((_1:Route_params) => View_node)) => View_node;

export const routes: (configs:routeConfig[]) => View_node;

export const link: (to: string, attrs?: Array<[string, View_attrValue]>, children?: View_node[]) => View_node;

export const normalizeBasePath: (_1:string) => string;

export const stripBasePath: (_1:string) => string;

export const addBasePath: (_1:string) => string;
