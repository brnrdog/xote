import type { t as Signal_t } from "./Signal.js";

export type Json = unknown;
export type Codec_t<a> = {
  readonly encode: (value: a) => Json;
  readonly decode: (json: Json) => undefined | a;
};

export const Codec: {
  readonly int: Codec_t<number>;
  readonly float: Codec_t<number>;
  readonly string: Codec_t<string>;
  readonly bool: Codec_t<boolean>;
  readonly array: <a>(itemCodec: Codec_t<a>) => Codec_t<a[]>;
  readonly option: <a>(itemCodec: Codec_t<a>) => Codec_t<a | undefined>;
  readonly tuple2: <a, b>(codec1: Codec_t<a>, codec2: Codec_t<b>) => Codec_t<[a, b]>;
  readonly tuple3: <a, b, c>(codec1: Codec_t<a>, codec2: Codec_t<b>, codec3: Codec_t<c>) => Codec_t<[a, b, c]>;
  readonly dict: <a>(valueCodec: Codec_t<a>) => Codec_t<Record<string, a>>;
  readonly make: <a>(encode: (value: a) => Json, decode: (json: Json) => undefined | a) => Codec_t<a>;
};

export const register: <a>(id: string, signal: Signal_t<a>, codec: Codec_t<a>) => void;
export const clear: () => void;
export const generateScript: (nonce?: string) => string;
export const getClientState: () => Record<string, Json>;
export const restore: <a>(id: string, signal: Signal_t<a>, codec: Codec_t<a>) => void;
export const sync: <a>(id: string, signal: Signal_t<a>, codec: Codec_t<a>) => void;
export const make: <a>(id: string, initial: a, codec: Codec_t<a>) => Signal_t<a>;
export const signal: typeof make;
export const syncSignal: typeof sync;
