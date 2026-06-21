/* TypeScript declarations generated from TypeScriptHtml.res via genType. */

/* eslint-disable */
/* tslint:disable */

type Dom_event = Event;

import type { attrValue as View_attrValue } from './View.js';

import type { node as View_node } from './View.js';

export type attrs = Array<[string, View_attrValue]>;

export type events = Array<[string, (_1:Dom_event) => void]>;

export type children = View_node[];

export const div: (attrs?: attrs, events?: events, children?: children) => View_node;

export const span: (attrs?: attrs, events?: events, children?: children) => View_node;

export const button: (attrs?: attrs, events?: events, children?: children) => View_node;

export const input: (attrs?: attrs, events?: events) => View_node;

export const h1: (attrs?: attrs, events?: events, children?: children) => View_node;

export const h2: (attrs?: attrs, events?: events, children?: children) => View_node;

export const h3: (attrs?: attrs, events?: events, children?: children) => View_node;

export const p: (attrs?: attrs, events?: events, children?: children) => View_node;

export const ul: (attrs?: attrs, events?: events, children?: children) => View_node;

export const li: (attrs?: attrs, events?: events, children?: children) => View_node;

export const a: (attrs?: attrs, events?: events, children?: children) => View_node;
