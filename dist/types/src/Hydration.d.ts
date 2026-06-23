/* TypeScript declarations generated from TypeScriptHydration.res via genType. */

/* eslint-disable */
/* tslint:disable */

type Dom_element = Element;

import type { node as View_node } from './View.js';

export type hydrateOptions = { readonly renderId?: string; readonly onHydrated?: () => void };

export const hydrate: (component: () => View_node, container: Dom_element, options?: hydrateOptions) => void;

export const hydrateById: (component: () => View_node, containerId: string, options?: hydrateOptions) => void;
