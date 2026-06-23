/* TypeScript declarations generated from TypeScriptMdx.res via genType. */

/* eslint-disable */
/* tslint:disable */

import type { node as View_node } from './View.js';

export type children = unknown;

export type components = {[id: string]: (_1:unknown) => View_node};

export type props = { readonly components?: components };

export type document = (_1:props) => View_node;

export const component: <props>(make:((_1:props) => View_node)) => (_1:unknown) => View_node;

export const components: (entries:Array<[string, ((_1:unknown) => View_node)]>) => components;

export const render: (document: document, components?: components) => View_node;

export const childrenToNodes: (children:children) => View_node[];

export const childrenToText: (children:children) => string;
