/*
 * Deterministic row data shared by every framework implementation.
 *
 * All four apps import this exact module, so the label strings, the id
 * sequence and the allocation pattern are byte-for-byte identical across
 * frameworks. The PRNG is a plain xorshift32 seeded at module load, which
 * makes a run reproducible without pulling in a dependency.
 */

const ADJECTIVES = [
  "pretty", "large", "big", "small", "tall", "short", "long", "handsome",
  "plain", "quaint", "clean", "elegant", "easy", "angry", "crazy", "helpful",
  "mushy", "odd", "unsightly", "adorable", "important", "inexpensive",
  "cheap", "expensive", "fancy",
];

const COLOURS = [
  "red", "yellow", "blue", "green", "pink", "brown", "purple", "brown",
  "white", "black", "orange",
];

const NOUNS = [
  "table", "chair", "house", "bbq", "desk", "car", "pony", "cookie",
  "sandwich", "burger", "pizza", "mouse", "keyboard",
];

const SEED = 0x2545f491;

let state = SEED;
let nextId = 1;

/* xorshift32 — same sequence in every implementation. */
function nextRandom(max) {
  state ^= state << 13;
  state >>>= 0;
  state ^= state >>> 17;
  state ^= state << 5;
  state >>>= 0;
  return state % max;
}

/* Reset the generator so repeated in-page runs stay comparable. */
export function resetData() {
  state = SEED;
  nextId = 1;
}

/* Build `count` rows of `{ id, label }`. Ids are globally increasing. */
export function buildData(count) {
  const rows = new Array(count);
  for (let i = 0; i < count; i++) {
    const label =
      ADJECTIVES[nextRandom(ADJECTIVES.length)] +
      " " +
      COLOURS[nextRandom(COLOURS.length)] +
      " " +
      NOUNS[nextRandom(NOUNS.length)];
    rows[i] = { id: nextId++, label };
  }
  return rows;
}
