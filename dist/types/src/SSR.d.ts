/* TypeScript declarations generated from TypeScriptSSR.res via genType. */

/* eslint-disable */
/* tslint:disable */

import type { node as View_node } from './View.js';

export type renderOptions = { readonly nonce?: string; readonly renderId?: string };

export const renderNodeToString: (node:View_node) => string;

export const renderToString: (component: () => View_node, options?: renderOptions) => string;

export const renderToStringWithRoot: (component: () => View_node, rootId?: string, options?: renderOptions) => string;

export const generateHydrationScript: (nonce?: string) => string;

export const renderDocument: (head: string | undefined, bodyAttrs: string | undefined, scripts: string[] | undefined, styles: string[] | undefined, stateScript: string | undefined, nonce: string | undefined, component: () => View_node) => string;
