/* TypeScript declarations generated from TypeScriptView.res via genType. */

/* eslint-disable */
/* tslint:disable */

type Dom_element = Element;
type Dom_event = Event;

import type { t as Signal_t } from './Signal.js';

export abstract class attrValue { protected opaque: any; } /* simulate opaque types */

export abstract class node { protected opaque: any; } /* simulate opaque types */

export type eventHandler = (_1:Dom_event) => void;

export const attr: (key:string, value:string) => [string, attrValue];

export const signalAttr: (key:string, signal:Signal_t<string>) => [string, attrValue];

export const computedAttr: (key:string, compute:(() => string)) => [string, attrValue];

export const text: (content:string) => node;

export const signalText: (compute:(() => string)) => node;

export const signalInt: (compute:(() => number)) => node;

export const signalFloat: (compute:(() => number)) => node;

export const int: (value:number) => node;

export const float: (value:number) => node;

export const bool: (value:boolean) => node;

export const fragment: (children:node[]) => node;

export const signalFragment: (signal:Signal_t<node[]>) => node;

export const each: <a>(signal:Signal_t<a[]>, renderItem:((_1:a) => node)) => node;

export const eachWithKey: <a>(signal:Signal_t<a[]>, keyFn:((_1:a) => string), renderItem:((_1:a) => node)) => node;

export const element: (tag: string, attrs?: Array<[string, attrValue]>, events?: Array<[string, eventHandler]>, children?: node[]) => node;

export const $$null: () => node;

export const mount: (node:node, container:Dom_element) => void;

export const mountById: (node:node, containerId:string) => void;
