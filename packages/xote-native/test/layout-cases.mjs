/**
 * The trees the layout engine is checked against.
 *
 * Shared by the oracle (which lays them out in Chromium with real CSS flexbox
 * and records the answer) and by the fast test (which replays the recorded
 * answer without a browser). Cases are deterministic — the generated ones come
 * from a seeded PRNG — so the recorded fixture stays stable.
 */

const ROOT = { width: 320, height: 640 };

/** xorshift32: small, seeded, and identical on every run. */
function rng(seed) {
  let state = seed >>> 0 || 1;
  return () => {
    state ^= state << 13;
    state >>>= 0;
    state ^= state >> 17;
    state ^= state << 5;
    state >>>= 0;
    return state / 4294967296;
  };
}

const box = (style, children = []) => ({ style, children });

const curated = [
  ["column stacks and leaves slack", box({}, [box({ height: 40 }), box({ height: 60 })])],
  [
    "row places side by side",
    box({ flexDirection: "row" }, [box({ width: 40, height: 20 }), box({ width: 60, height: 20 })]),
  ],
  [
    "flex 1 fills the main axis",
    box({}, [box({ height: 30 }), box({ flex: 1 }), box({ height: 30 })]),
  ],
  [
    "two flex children split what is left",
    box({ flexDirection: "row" }, [box({ flex: 1 }), box({ flex: 1 })]),
  ],
  [
    "grow factors are proportional",
    box({ flexDirection: "row" }, [
      box({ flexGrow: 1, height: 10 }),
      box({ flexGrow: 3, height: 10 }),
    ]),
  ],
  [
    "shrink is weighted by basis",
    box({ flexDirection: "row", width: 100 }, [
      box({ width: 120, flexShrink: 1, height: 10 }),
      box({ width: 60, flexShrink: 1, height: 10 }),
    ]),
  ],
  ["padding insets the content box", box({ padding: 12 }, [box({ height: 20 })])],
  [
    "padding shorthands compose",
    box({ paddingHorizontal: 16, paddingTop: 8, paddingBottom: 4 }, [box({ height: 20 })]),
  ],
  [
    "longhand padding beats the shorthand",
    box({ paddingHorizontal: 16, paddingLeft: 2 }, [box({ height: 20 })]),
  ],
  ["margins push siblings apart", box({}, [box({ height: 20, margin: 10 }), box({ height: 20 })])],
  ["gap sits between children", box({ gap: 14 }, [box({ height: 20 }), box({ height: 20 })])],
  [
    "row gap and column gap are separate",
    box({ flexDirection: "row", columnGap: 9, rowGap: 30 }, [
      box({ width: 20, height: 20 }),
      box({ width: 20, height: 20 }),
    ]),
  ],
  [
    "justifyContent center",
    box({ flexDirection: "row", justifyContent: "center" }, [box({ width: 40, height: 20 })]),
  ],
  [
    "justifyContent flex-end",
    box({ flexDirection: "row", justifyContent: "flex-end" }, [box({ width: 40, height: 20 })]),
  ],
  [
    "justifyContent space-between",
    box({ flexDirection: "row", justifyContent: "space-between" }, [
      box({ width: 40, height: 20 }),
      box({ width: 40, height: 20 }),
      box({ width: 40, height: 20 }),
    ]),
  ],
  [
    "justifyContent space-around",
    box({ flexDirection: "row", justifyContent: "space-around" }, [
      box({ width: 40, height: 20 }),
      box({ width: 40, height: 20 }),
    ]),
  ],
  [
    "justifyContent space-evenly",
    box({ flexDirection: "row", justifyContent: "space-evenly" }, [
      box({ width: 40, height: 20 }),
      box({ width: 40, height: 20 }),
    ]),
  ],
  [
    "alignItems center on the cross axis",
    box({ flexDirection: "row", height: 100, alignItems: "center" }, [
      box({ width: 20, height: 20 }),
    ]),
  ],
  [
    "alignItems flex-end",
    box({ flexDirection: "row", height: 100, alignItems: "flex-end" }, [
      box({ width: 20, height: 20 }),
    ]),
  ],
  [
    "alignItems stretch is the default",
    box({ flexDirection: "row", height: 100 }, [box({ width: 20 })]),
  ],
  [
    "alignSelf overrides alignItems",
    box({ flexDirection: "row", height: 100, alignItems: "flex-start" }, [
      box({ width: 20, height: 20, alignSelf: "flex-end" }),
    ]),
  ],
  [
    "a column with no height is as tall as its content",
    box({ flexDirection: "row" }, [box({}, [box({ height: 20 }), box({ height: 25 })])]),
  ],
  [
    "stretch against an auto cross size uses the tallest item",
    box({ flexDirection: "row", alignItems: "stretch" }, [
      box({ width: 20, height: 40 }),
      box({ width: 20 }),
    ]),
  ],
  ["percentage width", box({ flexDirection: "row" }, [box({ width: "50%", height: 20 })])],
  ["percentage height", box({}, [box({ height: "25%" })])],
  [
    "min and max clamp a flexed child",
    box({ flexDirection: "row" }, [
      box({ flex: 1, maxWidth: 80, height: 10 }),
      box({ flex: 1, minWidth: 200, height: 10 }),
    ]),
  ],
  ["maxHeight clamps content", box({ maxHeight: 30 }, [box({ height: 100 })])],
  ["minHeight raises content", box({ minHeight: 90 }, [box({ height: 10 })])],
  [
    "row-reverse lays out backwards",
    box({ flexDirection: "row-reverse" }, [
      box({ width: 30, height: 10 }),
      box({ width: 50, height: 10 }),
    ]),
  ],
  [
    "column-reverse lays out backwards",
    box({ flexDirection: "column-reverse" }, [box({ height: 30 }), box({ height: 50 })]),
  ],
  [
    "borderWidth insets like padding",
    box({ borderWidth: 5, padding: 5 }, [box({ height: 20 })]),
  ],
  [
    "aspectRatio derives the missing side",
    box({ flexDirection: "row" }, [box({ width: 60, aspectRatio: 2 })]),
  ],
  [
    "absolute children sit in the padding box",
    box({ padding: 10 }, [
      box({ height: 20 }),
      box({ position: "absolute", top: 5, left: 7, width: 30, height: 30 }),
    ]),
  ],
  [
    "absolute with both edges is stretched",
    box({ padding: 10 }, [box({ position: "absolute", left: 0, right: 0, top: 0, height: 12 })]),
  ],
  [
    // Auto-sized against `boxW - left`, but a box tree's min-content is its
    // max-content, so shrink-to-fit lands on the content and overflows. (Text
    // is the case that actually narrows; the browser has no stand-in for the
    // engine's measure callback, so those live in `layout_test.mjs`.)
    "absolute auto width keeps its content width",
    box({ width: 300, height: 200 }, [
      box({ position: "absolute", left: 250, top: 0 }, [box({ width: 120, height: 10 })]),
    ]),
  ],
  [
    "absolute pinned only on the right sits its own width in from it",
    box({ width: 300, height: 200 }, [
      box({ position: "absolute", right: 250, top: 0 }, [box({ width: 40, height: 10 })]),
    ]),
  ],
  [
    "absolute pinned only on the bottom sits its own height up from it",
    box({ width: 300, height: 200 }, [
      box({ position: "absolute", left: 0, bottom: 30 }, [box({ width: 40, height: 25 })]),
    ]),
  ],
  [
    "nested three deep",
    box({ padding: 8, gap: 4 }, [
      box({ flexDirection: "row", gap: 6 }, [
        box({ flex: 1 }, [box({ height: 18 })]),
        box({ width: 44 }, [box({ height: 30 })]),
      ]),
      box({ flex: 1, padding: 6 }, [box({ flex: 1 })]),
    ]),
  ],
  [
    "the example screen's shape",
    box({ flex: 1, paddingHorizontal: 20, paddingTop: 64, gap: 20 }, [
      box({ height: 34 }),
      box({ flexDirection: "row", alignItems: "center", justifyContent: "space-between", gap: 12 }, [
        box({ width: 90, height: 20 }),
        box({ width: 84, height: 44 }),
      ]),
      box({ padding: 16, gap: 10 }, [
        box({ flexDirection: "row", justifyContent: "space-between" }, [
          box({ width: 60, height: 22 }),
          box({ width: 40, height: 18 }),
        ]),
        box({ flexDirection: "row", alignItems: "center", gap: 10, paddingVertical: 8 }, [
          box({ width: 18, height: 18 }),
          box({ flex: 1, height: 20 }),
        ]),
      ]),
    ]),
  ],
];

/** Randomised trees over the same vocabulary, to catch what the curated ones miss. */
function generated(count) {
  const random = rng(0x5eed);
  const pick = (list) => list[Math.floor(random() * list.length) % list.length];
  const maybe = (probability, value) => (random() < probability ? value : undefined);

  const style = (depth) => {
    const s = {};
    s.flexDirection = pick(["row", "column", "row-reverse", "column-reverse"]);
    const justify = maybe(
      0.6,
      pick(["flex-start", "center", "flex-end", "space-between", "space-around", "space-evenly"]),
    );
    if (justify) s.justifyContent = justify;
    const align = maybe(0.6, pick(["flex-start", "center", "flex-end", "stretch"]));
    if (align) s.alignItems = align;
    const gap = maybe(0.4, Math.floor(random() * 16));
    if (gap !== undefined) s.gap = gap;
    const padding = maybe(0.4, Math.floor(random() * 14));
    if (padding !== undefined) s.padding = padding;
    if (depth > 0) {
      const flex = maybe(0.35, Math.floor(random() * 3) + 1);
      if (flex !== undefined) s.flex = flex;
      else {
        const w = maybe(0.6, Math.floor(random() * 90) + 10);
        const h = maybe(0.6, Math.floor(random() * 90) + 10);
        if (w !== undefined) s.width = w;
        if (h !== undefined) s.height = h;
      }
      const margin = maybe(0.25, Math.floor(random() * 12));
      if (margin !== undefined) s.margin = margin;
      const alignSelf = maybe(0.2, pick(["flex-start", "center", "flex-end", "stretch"]));
      if (alignSelf) s.alignSelf = alignSelf;
    }
    return s;
  };

  const tree = (depth) => {
    const s = style(depth);
    if (depth >= 3 || random() < 0.3) return box(s);
    const children = [];
    const n = 1 + Math.floor(random() * 3);
    for (let i = 0; i < n; i++) children.push(tree(depth + 1));
    return box(s, children);
  };

  const cases = [];
  for (let i = 0; i < count; i++) {
    const root = tree(0);
    root.style.width = ROOT.width;
    root.style.height = ROOT.height;
    cases.push([`generated ${i}`, root]);
  }
  return cases;
}

export const rootSize = ROOT;

/* Every root gets the same fixed frame. Without one the browser would stretch
 it to the page and the engine would size it from its content, and the two
 would be answering different questions. */
export const cases = [...curated, ...generated(160)].map(([name, tree]) => ({
  name,
  tree: { ...tree, style: { width: ROOT.width, height: ROOT.height, ...tree.style } },
}));

/** Depth-first path of every node, so both sides can name the same box. */
export function walk(node, path = "0", out = []) {
  out.push({ path, node });
  (node.children || []).forEach((child, index) => walk(child, `${path}.${index}`, out));
  return out;
}
