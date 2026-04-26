// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../docs/CHANGELOG.md
// * To update: modify docs/CHANGELOG.md and run:
// *   npm run generate-repo-data
// ****************************************************

type inlineNodes = array<Node.node>

type releaseSection = {
  title: string,
  items: array<inlineNodes>,
}

type release = {
  version: string,
  url: string,
  date: string,
  id: string,
  sections: array<releaseSection>,
}

let sourceUrl = "https://github.com/brnrdog/xote/blob/main/docs/CHANGELOG.md"
let latestVersion = "6.2.0"
let latestReleaseDate = "2026-04-26"

let releases: array<release> = [
  {
    version: "6.2.0",
    url: "https://github.com/brnrdog/xote/compare/v6.1.2...v6.2.0",
    date: "2026-04-26",
    id: "release-6-2-0-2026-04-26",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("connect keyed JSX to reconciliation ("),
            <a href="https://github.com/brnrdog/xote/commit/6839f90c8ff0838ce65427715ba65af57a76cce3" target="_blank"> {Node.text("6839f90")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "Features",
        items: [
          [
            Node.text("add clearer api aliases ("),
            <a href="https://github.com/brnrdog/xote/commit/1bc01da9f3a871b38fae7f243fa2b99a2ce37690" target="_blank"> {Node.text("1bc01da")} </a>,
            Node.text(")")
          ],
          [
            Node.text("promote View and Prop as primary modules ("),
            <a href="https://github.com/brnrdog/xote/commit/5a1566fd13d1bd4af09dbce0b8e40bdf2a4cc948" target="_blank"> {Node.text("5a1566f")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "6.1.2",
    url: "https://github.com/brnrdog/xote/compare/v6.1.1...v6.1.2",
    date: "2026-04-25",
    id: "release-6-1-2-2026-04-25",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("defer initial select value until options mount ("),
            <a href="https://github.com/brnrdog/xote/commit/7dd1c7ff45100edd1f7f56e1db3acf517e7fed6e" target="_blank"> {Node.text("7dd1c7f")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "6.1.1",
    url: "https://github.com/brnrdog/xote/compare/v6.1.0...v6.1.1",
    date: "2026-04-25",
    id: "release-6-1-1-2026-04-25",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("defer initial select value until options mount ("),
            <a href="https://github.com/brnrdog/xote/commit/7dd1c7ff45100edd1f7f56e1db3acf517e7fed6e" target="_blank"> {Node.text("7dd1c7f")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "6.1.1",
    url: "https://github.com/brnrdog/xote/compare/v6.1.0...v6.1.1",
    date: "2026-04-21",
    id: "release-6-1-1-2026-04-21",
    sections: [
      {
        title: "Performance Improvements",
        items: [
          [
            Node.text("bump rescript-signals to ^3.1.0 ("),
            <a href="https://github.com/brnrdog/xote/commit/f9d3ef9a37acdc917dba35016e351fb82079fc17" target="_blank"> {Node.text("f9d3ef9")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "6.1.0",
    url: "https://github.com/brnrdog/xote/compare/v6.0.1...v6.1.0",
    date: "2026-04-10",
    id: "release-6-1-0-2026-04-10",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("add draggable, hidden, title, and other missing JSX props ("),
            <a href="https://github.com/brnrdog/xote/commit/e6de2bae6c586fa863a1b40bfe2132f52469e8ee" target="_blank"> {Node.text("e6de2ba")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "6.0.1",
    url: "https://github.com/brnrdog/xote/compare/v6.0.0...v6.0.1",
    date: "2026-04-09",
    id: "release-6-0-1-2026-04-09",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("add exports field to package.json ("),
            <a href="https://github.com/brnrdog/xote/commit/c57ed3271263fa759c743990a104a56833ecc343" target="_blank"> {Node.text("c57ed32")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "6.0.0",
    url: "https://github.com/brnrdog/xote/compare/v5.0.0...v6.0.0",
    date: "2026-04-08",
    id: "release-6-0-0-2026-04-08",
    sections: [
      {
        title: "",
        items: [
          [
            Node.text("refactor!: drop Xote__ prefix and use ReScript namespacing ("),
            <a href="https://github.com/brnrdog/xote/commit/08991c4499951e53054b491940d1908bb8d744cb" target="_blank"> {Node.text("08991c4")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "",
        items: [
          [
            Node.text("refactor!: rename Component module to Node ("),
            <a href="https://github.com/brnrdog/xote/commit/0bb235bfa2a0e81b23710304cf0c93e9286a8cbd" target="_blank"> {Node.text("0bb235b")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "",
        items: [
          [
            Node.text("refactor!: rename JSX module to XoteJSX ("),
            <a href="https://github.com/brnrdog/xote/commit/ee870d47abfa40e0c0eb5dbabd9aabeb82eedbb8" target="_blank"> {Node.text("ee870d4")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "",
        items: [
          [
            Node.text("refactor!: split HTML element builders into Html module ("),
            <a href="https://github.com/brnrdog/xote/commit/8ffd83f97ece1ef71640c3ab8cb9067140ab6542" target="_blank"> {Node.text("8ffd83f")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "",
        items: [
          [
            Node.text("refactor!: unify reactive node helpers under "),
            <code> {Node.text("signal")} </code>,
            Node.text(" prefix ("),
            <a href="https://github.com/brnrdog/xote/commit/b1a3ca7837f3e7e599cfc745518c526f10080bca" target="_blank"> {Node.text("b1a3ca7")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "BREAKING CHANGES",
        items: [
          [
            <code> {Node.text("Xote.Component")} </code>,
            Node.text(" is renamed to "),
            <code> {Node.text("Xote.Node")} </code>,
            Node.text(". Replace all "),
            <code> {Node.text("Component.text")} </code>,
            Node.text(", "),
            <code> {Node.text("Component.signalText")} </code>,
            Node.text(", "),
            <code> {Node.text("Component.element")} </code>,
            Node.text(", "),
            <code> {Node.text("Component.mount")} </code>,
            Node.text(", etc. with the equivalent "),
            <code> {Node.text("Node.*")} </code>,
            Node.text(" calls.")
          ],
          [
            Node.text("The JSX module is now "),
            <code> {Node.text("Xote.XoteJSX")} </code>,
            Node.text(". Consumers must update "),
            <code> {Node.text("rescript.json")} </code>,
            Node.text(": \"jsx\": { \"version\": 4, \"module\": \"XoteJSX\" }")
          ],
          [
            Node.text("Element builders moved from "),
            <code> {Node.text("Component")} </code>,
            Node.text(" to "),
            <code> {Node.text("Html")} </code>,
            Node.text(". Replace "),
            <code> {Node.text("Xote.Component.div(...)")} </code>,
            Node.text(" with "),
            <code> {Node.text("Xote.Html.div(...)")} </code>,
            Node.text(" (and the same for "),
            <code> {Node.text("span")} </code>,
            Node.text(", "),
            <code> {Node.text("button")} </code>,
            Node.text(", "),
            <code> {Node.text("input")} </code>,
            Node.text(", "),
            <code> {Node.text("h1")} </code>,
            Node.text("-"),
            <code> {Node.text("h3")} </code>,
            Node.text(", "),
            <code> {Node.text("p")} </code>,
            Node.text(", "),
            <code> {Node.text("ul")} </code>,
            Node.text(", "),
            <code> {Node.text("li")} </code>,
            Node.text(", "),
            <code> {Node.text("a")} </code>,
            Node.text(").")
          ],
          [
            Node.text("The JSX module path changes from "),
            <code> {Node.text("Xote__JSX")} </code>,
            Node.text(" to "),
            <code> {Node.text("Xote.JSX")} </code>,
            Node.text(". Consumers must update their "),
            <code> {Node.text("rescript.json")} </code>,
            Node.text(": \"jsx\": { \"version\": 4, \"module\": \"JSX\" }, \"compiler-flags\": "),
            Node.text("[\"-open Xote\"]")
          ],
          [
            <code> {Node.text("Xote.Component.textSignal")} </code>,
            Node.text(", "),
            <code> {Node.text("reactiveString")} </code>,
            Node.text(", "),
            <code> {Node.text("reactiveInt")} </code>,
            Node.text(", and "),
            <code> {Node.text("reactiveFloat")} </code>,
            Node.text(" are removed. Replace call sites with "),
            <code> {Node.text("signalText")} </code>,
            Node.text(", "),
            <code> {Node.text("signalInt")} </code>,
            Node.text(", and "),
            <code> {Node.text("signalFloat")} </code>,
            Node.text(" respectively.")
          ]
        ],
      }
    ],
  },
  {
    version: "5.0.0",
    url: "https://github.com/brnrdog/xote/compare/v4.16.1...v5.0.0",
    date: "2026-04-04",
    id: "release-5-0-0-2026-04-04",
    sections: [
      {
        title: "",
        items: [
          [
            Node.text("feat!: update to rescript-signals 2.0.0 ("),
            <a href="https://github.com/brnrdog/xote/commit/fb2c89785ea2323a05e33240f602bab66613a84e" target="_blank"> {Node.text("fb2c897")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "BREAKING CHANGES",
        items: [
          [
            Node.text("Effect.run now returns unit instead of a disposer. Use Effect.runWithDisposer when you need to manually dispose an effect.")
          ]
        ],
      }
    ],
  },
  {
    version: "4.16.1",
    url: "https://github.com/brnrdog/xote/compare/v4.16.0...v4.16.1",
    date: "2026-03-13",
    id: "release-4-16-1-2026-03-13",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("use createElementNS for SVG elements to fix logo rendering ("),
            <a href="https://github.com/brnrdog/xote/issues/61" target="_blank"> {Node.text("#61")} </a>,
            Node.text(") ("),
            <a href="https://github.com/brnrdog/xote/commit/7ffefe1953dfbc8524c4b83fc208e4d3767ba3df" target="_blank"> {Node.text("7ffefe1")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.16.0",
    url: "https://github.com/brnrdog/xote/compare/v4.15.3...v4.16.0",
    date: "2026-03-12",
    id: "release-4-16-0-2026-03-12",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("expose Router.initSSR for server-side route initialization ("),
            <a href="https://github.com/brnrdog/xote/commit/f232d0b1dba81725f6d23e2beaecca9e2905eb11" target="_blank"> {Node.text("f232d0b")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.15.3",
    url: "https://github.com/brnrdog/xote/compare/v4.15.2...v4.15.3",
    date: "2026-03-12",
    id: "release-4-15-3-2026-03-12",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("defer JSX component evaluation to render time via LazyComponent ("),
            <a href="https://github.com/brnrdog/xote/commit/e685fc149ad324f2846ef9ea62f6670d36519cde" target="_blank"> {Node.text("e685fc1")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.15.2",
    url: "https://github.com/brnrdog/xote/compare/v4.15.1...v4.15.2",
    date: "2026-03-12",
    id: "release-4-15-2-2026-03-12",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("ensure computed attributes are only updated within the effect context ("),
            <a href="https://github.com/brnrdog/xote/issues/49" target="_blank"> {Node.text("#49")} </a>,
            Node.text(") ("),
            <a href="https://github.com/brnrdog/xote/commit/ccf9905b4ab38e63317ad068c1a276febf0644c2" target="_blank"> {Node.text("ccf9905")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.15.1",
    url: "https://github.com/brnrdog/xote/compare/v4.15.0...v4.15.1",
    date: "2026-03-07",
    id: "release-4-15-1-2026-03-07",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("remove @rescript/core dependency and code formatting ("),
            <a href="https://github.com/brnrdog/xote/commit/774b81f37e816b98bc676384b0dab03b1f094dcc" target="_blank"> {Node.text("774b81f")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.15.0",
    url: "https://github.com/brnrdog/xote/compare/v4.14.0...v4.15.0",
    date: "2026-03-04",
    id: "release-4-15-0-2026-03-04",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("add support to common mouse events ("),
            <a href="https://github.com/brnrdog/xote/commit/3811d107b8c2afa911d94b51242205f1cc5d973d" target="_blank"> {Node.text("3811d10")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.14.0",
    url: "https://github.com/brnrdog/xote/compare/v4.13.0...v4.14.0",
    date: "2026-03-01",
    id: "release-4-14-0-2026-03-01",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("add server-side rendering with hydration ("),
            <a href="https://github.com/brnrdog/xote/commit/8a30af3421cbae9c33cfe19e6e8b42b7e2e0be6f" target="_blank"> {Node.text("8a30af3")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.13.0",
    url: "https://github.com/brnrdog/xote/compare/v4.12.0...v4.13.0",
    date: "2026-02-28",
    id: "release-4-13-0-2026-02-28",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("router:")} </strong>,
            Node.text(" add scroll restoration for navigation ("),
            <a href="https://github.com/brnrdog/xote/commit/a5b84344369a3cb8be713c5a60d050b9908173bc" target="_blank"> {Node.text("a5b8434")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.12.0",
    url: "https://github.com/brnrdog/xote/compare/v4.11.0...v4.12.0",
    date: "2026-02-28",
    id: "release-4-12-0-2026-02-28",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("jsx:")} </strong>,
            Node.text(" add support to contextmenu event ("),
            <a href="https://github.com/brnrdog/xote/issues/36" target="_blank"> {Node.text("#36")} </a>,
            Node.text(") ("),
            <a href="https://github.com/brnrdog/xote/commit/68c7ba28f73384b6f7f6d059eaeea4d8e94f6491" target="_blank"> {Node.text("68c7ba2")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.11.0",
    url: "https://github.com/brnrdog/xote/compare/v4.10.1...v4.11.0",
    date: "2026-01-22",
    id: "release-4-11-0-2026-01-22",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("update rescript from 1.3.0 to 1.3.3 ("),
            <a href="https://github.com/brnrdog/xote/commit/35c9a4e2e9f9cc631edf0847389a47a5887420ec" target="_blank"> {Node.text("35c9a4e")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.10.1",
    url: "https://github.com/brnrdog/xote/compare/v4.10.0...v4.10.1",
    date: "2026-01-10",
    id: "release-4-10-1-2026-01-10",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("ensures all router instances share same state ("),
            <a href="https://github.com/brnrdog/xote/commit/a754f96123f36add51e1a7c9893c4f5aa1462130" target="_blank"> {Node.text("a754f96")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.10.0",
    url: "https://github.com/brnrdog/xote/compare/v4.9.0...v4.10.0",
    date: "2026-01-10",
    id: "release-4-10-0-2026-01-10",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("router:")} </strong>,
            Node.text(" add base path option to router initialization ("),
            <a href="https://github.com/brnrdog/xote/commit/b54c6e99acd62a180a4166183f9d5ddb3cd37093" target="_blank"> {Node.text("b54c6e9")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.9.0",
    url: "https://github.com/brnrdog/xote/compare/v4.8.0...v4.9.0",
    date: "2026-01-06",
    id: "release-4-9-0-2026-01-06",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" add helpers for rendering reactive and static values ("),
            <a href="https://github.com/brnrdog/xote/commit/c4b7526d9c41945817453b523af133da8c105d7b" target="_blank"> {Node.text("c4b7526")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.8.0",
    url: "https://github.com/brnrdog/xote/compare/v4.7.0...v4.8.0",
    date: "2025-12-31",
    id: "release-4-8-0-2025-12-31",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("router:")} </strong>,
            Node.text(" add Link component ("),
            <a href="https://github.com/brnrdog/xote/commit/0e8d2152f478d30025c3886ca6047836628b9868" target="_blank"> {Node.text("0e8d215")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.7.0",
    url: "https://github.com/brnrdog/xote/compare/v4.6.0...v4.7.0",
    date: "2025-12-29",
    id: "release-4-7-0-2025-12-29",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("jsx:")} </strong>,
            Node.text(" allow ReactiveProp.t besides raw values ("),
            <a href="https://github.com/brnrdog/xote/commit/0e082f575199d97433d27a3aa58199ac3cd5cfee" target="_blank"> {Node.text("0e082f5")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("reactive-prop:")} </strong>,
            Node.text(" add helper functions for static and reactive ("),
            <a href="https://github.com/brnrdog/xote/commit/2e82b1a396b5e29ad11c7f76062f53130c1113aa" target="_blank"> {Node.text("2e82b1a")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.6.0",
    url: "https://github.com/brnrdog/xote/compare/v4.5.0...v4.6.0",
    date: "2025-12-29",
    id: "release-4-6-0-2025-12-29",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("expose ReactiveProp from Xote module ("),
            <a href="https://github.com/brnrdog/xote/commit/3704a6218cabe7a5e89b1c00bda17db989aa1a5c" target="_blank"> {Node.text("3704a62")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.5.0",
    url: "https://github.com/brnrdog/xote/compare/v4.4.3...v4.5.0",
    date: "2025-12-29",
    id: "release-4-5-0-2025-12-29",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("introduce ReactiveProp module ("),
            <a href="https://github.com/brnrdog/xote/commit/0dde3b81c3d2872455e20f110a2793e845179bcf" target="_blank"> {Node.text("0dde3b8")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.4.3",
    url: "https://github.com/brnrdog/xote/compare/v4.4.2...v4.4.3",
    date: "2025-12-20",
    id: "release-4-4-3-2025-12-20",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" boolean attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/60e11557f1d2b38560da593f153f4f5ea0267471" target="_blank"> {Node.text("60e1155")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.4.2",
    url: "https://github.com/brnrdog/xote/compare/v4.4.1...v4.4.2",
    date: "2025-12-20",
    id: "release-4-4-2-2025-12-20",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            <strong> {Node.text("jsx:")} </strong>,
            Node.text(" reactive support for boolean attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/c54ed60f174bd2049f27809f21f354546ba65912" target="_blank"> {Node.text("c54ed60")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.4.1",
    url: "https://github.com/brnrdog/xote/compare/v4.4.0...v4.4.1",
    date: "2025-12-20",
    id: "release-4-4-1-2025-12-20",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" attribute and property handling ("),
            <a href="https://github.com/brnrdog/xote/commit/c49cbc0d3b486c7a68b59a65671b139ae8b1eac5" target="_blank"> {Node.text("c49cbc0")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.4.0",
    url: "https://github.com/brnrdog/xote/compare/v4.3.1...v4.4.0",
    date: "2025-12-19",
    id: "release-4-4-0-2025-12-19",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("jsx:")} </strong>,
            Node.text(" add support to many other common attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/d3460d84012964c5dc6a5659f42ada62465a8e18" target="_blank"> {Node.text("d3460d8")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("jsx:")} </strong>,
            Node.text(" add support to name attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/07de33d9ac86c955efd1f04bc088217689288f08" target="_blank"> {Node.text("07de33d")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.3.1",
    url: "https://github.com/brnrdog/xote/compare/v4.3.0...v4.3.1",
    date: "2025-12-18",
    id: "release-4-3-1-2025-12-18",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("expose missing source files for rescript projects ("),
            <a href="https://github.com/brnrdog/xote/commit/4d93ebbe77260381ca7058562626697c42da1aa1" target="_blank"> {Node.text("4d93ebb")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.3.0",
    url: "https://github.com/brnrdog/xote/compare/v4.2.0...v4.3.0",
    date: "2025-12-15",
    id: "release-4-3-0-2025-12-15",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("update rescript-signals from 1.2.0 to 1.3.0 ("),
            <a href="https://github.com/brnrdog/xote/commit/f5f5c1bfd78dd2fedb89aa0bc6cfe26221b70f20" target="_blank"> {Node.text("f5f5c1b")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.2.0",
    url: "https://github.com/brnrdog/xote/compare/v4.1.1...v4.2.0",
    date: "2025-12-14",
    id: "release-4-2-0-2025-12-14",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" introduce keyedList for list reconciliation ("),
            <a href="https://github.com/brnrdog/xote/issues/24" target="_blank"> {Node.text("#24")} </a>,
            Node.text(") ("),
            <a href="https://github.com/brnrdog/xote/commit/96800dec3c9bbd32305643c0b36c74b993055650" target="_blank"> {Node.text("96800de")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.1.1",
    url: "https://github.com/brnrdog/xote/compare/v4.1.0...v4.1.1",
    date: "2025-12-14",
    id: "release-4-1-1-2025-12-14",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            <strong> {Node.text("components:")} </strong>,
            Node.text(" fix component disposal ("),
            <a href="https://github.com/brnrdog/xote/commit/adbfccefa088d87f0c00a38fd2b20792c911f4a0" target="_blank"> {Node.text("adbfcce")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.1.0",
    url: "https://github.com/brnrdog/xote/compare/v4.0.0...v4.1.0",
    date: "2025-12-05",
    id: "release-4-1-0-2025-12-05",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("update rescript-signals from v1.0.1 to v1.2.0 ("),
            <a href="https://github.com/brnrdog/xote/commit/d1f76d809d70cb95f5757aa0f4483f6f6768876c" target="_blank"> {Node.text("d1f76d8")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "4.0.0",
    url: "https://github.com/brnrdog/xote/compare/v3.0.0...v4.0.0",
    date: "2025-12-02",
    id: "release-4-0-0-2025-12-02",
    sections: [
      {
        title: "Code Refactoring",
        items: [
          [
            Node.text("move signals to rescript-signals ("),
            <a href="https://github.com/brnrdog/xote/commit/848b3b825e620c72cfb309ca7a170c7d16833043" target="_blank"> {Node.text("848b3b8")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "BREAKING CHANGES",
        items: [
          [
            Node.text("- Xote.Core.t -> Xote.Signal.t - Core.batch removed from API")
          ]
        ],
      }
    ],
  },
  {
    version: "3.0.0",
    url: "https://github.com/brnrdog/xote/compare/v2.0.0...v3.0.0",
    date: "2025-11-28",
    id: "release-3-0-0-2025-11-28",
    sections: [
      {
        title: "",
        items: [
          [
            Node.text("fix!: add cleanup callback support to effects ("),
            <a href="https://github.com/brnrdog/xote/commit/7aade4f3cb95a284169c42fa6771e31d33613b7c" target="_blank"> {Node.text("7aade4f")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "",
        items: [
          [
            Node.text("refactor!: simplify Computed API with internal tracking ("),
            <a href="https://github.com/brnrdog/xote/commit/5d9bc0130208b8ebdde90f1207ae101695a6b6af" target="_blank"> {Node.text("5d9bc01")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("add disposal support for computed observers ("),
            <a href="https://github.com/brnrdog/xote/commit/f2e8a177a37d87abc2477805a39e0eb896946664" target="_blank"> {Node.text("f2e8a17")} </a>,
            Node.text(")")
          ],
          [
            Node.text("add equality check to Signal.set to prevent unnecessary notifications ("),
            <a href="https://github.com/brnrdog/xote/commit/2680a195e8adfa9cf2ed3d3c5bb236044bf04027" target="_blank"> {Node.text("2680a19")} </a>,
            Node.text(")")
          ],
          [
            Node.text("convert recursive scheduler to iterative loop ("),
            <a href="https://github.com/brnrdog/xote/commit/0b69c76d40130fb436b9df4feae8e4785deccc88" target="_blank"> {Node.text("0b69c76")} </a>,
            Node.text(")")
          ],
          [
            Node.text("restore global tracking state on exceptions ("),
            <a href="https://github.com/brnrdog/xote/commit/a6e5b7030e59fb7e8323896ba1b02c44668a81f9" target="_blank"> {Node.text("a6e5b70")} </a>,
            Node.text(")")
          ],
          [
            Node.text("signal set structural equality check on objects with functions ("),
            <a href="https://github.com/brnrdog/xote/commit/803aaba12f75b7df660de1f11257b4eb1a3b4aa5" target="_blank"> {Node.text("803aaba")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "Features",
        items: [
          [
            Node.text("add automatic disposal for computed values ("),
            <a href="https://github.com/brnrdog/xote/commit/d2f04dbe630388aa75a369c3785c4aa4ff2050b3" target="_blank"> {Node.text("d2f04db")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "BREAKING CHANGES",
        items: [
          [
            Node.text("Computed.make now returns Core.t<'a> instead of (Core.t<'a>, unit => unit). Use Computed.dispose(signal) for manual disposal instead of calling the dispose function from the tuple. Before: let (signal, dispose) = Computed.make(() => ...) dispose() After: let signal = Computed.make(() => ...) Computed.dispose(signal) This aligns better with common patterns in other reactive libraries like Solid and Preact, providing a cleaner and more intuitive API.")
          ],
          [
            Node.text("Effect.run now expects functions to return option<unit => unit> instead of unit. All existing effects must be updated to return None or Some(cleanupFn).")
          ]
        ],
      }
    ],
  },
  {
    version: "2.0.0",
    url: "https://github.com/brnrdog/xote/compare/v1.3.3...v2.0.0",
    date: "2025-11-27",
    id: "release-2-0-0-2025-11-27",
    sections: [
      {
        title: "",
        items: [
          [
            Node.text("chore!: upgrade to ReScript v12.0.0 ("),
            <a href="https://github.com/brnrdog/xote/commit/b20b9e032cd62d6d2e1eea83adbe53ab412cea94" target="_blank"> {Node.text("b20b9e0")} </a>,
            Node.text("), closes "),
            <a href="https://github.com/brnrdog/xote/issues/function" target="_blank"> {Node.text("#function")} </a>,
            Node.text(" "),
            <a href="https://github.com/brnrdog/xote/issues/object" target="_blank"> {Node.text("#object")} </a>,
            Node.text(" "),
            <a href="https://github.com/brnrdog/xote/issues/function" target="_blank"> {Node.text("#function")} </a>
          ]
        ],
      },
      {
        title: "BREAKING CHANGES",
        items: [
          [
            Node.text("ReScript v12 introduces API changes that affect the typeof operator and configuration fields. Projects upgrading will need to: - Update rescript.json to use 'dependencies' and 'compiler-flags' instead of 'bs-dependencies' and 'bsc-flags'")
          ]
        ],
      }
    ],
  },
  {
    version: "1.3.3",
    url: "https://github.com/brnrdog/xote/compare/v1.3.2...v1.3.3",
    date: "2025-11-26",
    id: "release-1-3-3-2025-11-26",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("implement topological ordering to prevent scheduling glitches ("),
            <a href="https://github.com/brnrdog/xote/commit/51f1a8ca592c8e722e0a05d37017604e40547062" target="_blank"> {Node.text("51f1a8c")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.3.2",
    url: "https://github.com/brnrdog/xote/compare/v1.3.1...v1.3.2",
    date: "2025-11-24",
    id: "release-1-3-2-2025-11-24",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("automatic disposal of reactive observers to prevent memory leaks ("),
            <a href="https://github.com/brnrdog/xote/commit/befae8116f47347179f8d5bdfe6355b40942c79a" target="_blank"> {Node.text("befae81")} </a>,
            Node.text("), closes "),
            <a href="https://github.com/brnrdog/xote/issues/7" target="_blank"> {Node.text("#7")} </a>
          ],
          [
            Node.text("preserve signal fragment effect when disposing children ("),
            <a href="https://github.com/brnrdog/xote/commit/c3d530ccc344d58cc73aa209bbe02f0b87e7cd9a" target="_blank"> {Node.text("c3d530c")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.3.1",
    url: "https://github.com/brnrdog/xote/compare/v1.3.0...v1.3.1",
    date: "2025-11-21",
    id: "release-1-3-1-2025-11-21",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("preserve observer tracking context during nested execution ("),
            <a href="https://github.com/brnrdog/xote/commit/afb945059ca026072f777859e781fd086e88189b" target="_blank"> {Node.text("afb9450")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.3.0",
    url: "https://github.com/brnrdog/xote/compare/v1.2.1...v1.3.0",
    date: "2025-11-21",
    id: "release-1-3-0-2025-11-21",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("add support to data attributes in Xote.JSX ("),
            <a href="https://github.com/brnrdog/xote/commit/903c265352d5344118dd8a66d65b2ec20ab57042" target="_blank"> {Node.text("903c265")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.2.1",
    url: "https://github.com/brnrdog/xote/compare/v1.2.0...v1.2.1",
    date: "2025-11-19",
    id: "release-1-2-1-2025-11-19",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("enable reactivity for JSX element attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/0ea72353a6a6d26b38e1f7c1058d95f843d3e898" target="_blank"> {Node.text("0ea7235")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.2.0",
    url: "https://github.com/brnrdog/xote/compare/v1.1.0...v1.2.0",
    date: "2025-11-19",
    id: "release-1-2-0-2025-11-19",
    sections: [
      {
        title: "Features",
        items: [
          [
            Node.text("bump version to 1.2.0 ("),
            <a href="https://github.com/brnrdog/xote/commit/19425d976e540381ac85736b46b8a994c57f4fa8" target="_blank"> {Node.text("19425d9")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.1...v1.1.0",
    date: "2025-11-18",
    id: "release-1-1-0-2025-11-18",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("revert keyed list reconciliation ("),
            <a href="https://github.com/brnrdog/xote/commit/60aa2a093fdae4d26558c4d4aec4e2e9f9384964" target="_blank"> {Node.text("60aa2a0")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "Features",
        items: [
          [
            Node.text("add JSX support with generic transform ("),
            <a href="https://github.com/brnrdog/xote/commit/d71175dc0a2680996b7725ba3c781cdd8c706b49" target="_blank"> {Node.text("d71175d")} </a>,
            Node.text(")")
          ],
          [
            Node.text("change className to class in JSX props ("),
            <a href="https://github.com/brnrdog/xote/commit/251524249328cf06f78dfdfbcf348f1552e88e9f" target="_blank"> {Node.text("2515242")} </a>,
            Node.text(")")
          ],
          [
            Node.text("implement keyed list reconciliation for efficient updates ("),
            <a href="https://github.com/brnrdog/xote/commit/dd9c0b8c5d5473b1bdfc0aa8acc1dec8cec21999" target="_blank"> {Node.text("dd9c0b8")} </a>,
            Node.text(")")
          ],
          [
            Node.text("standardize JSX component naming convention ("),
            <a href="https://github.com/brnrdog/xote/commit/f68331613466a94004d34299b21b26c43bf43c0b" target="_blank"> {Node.text("f683316")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.0.1",
    url: "https://github.com/brnrdog/xote/compare/v1.0.0...v1.0.1",
    date: "2025-11-02",
    id: "release-1-0-1-2025-11-02",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("optimize build configuration and reduce bundle size ("),
            <a href="https://github.com/brnrdog/xote/commit/f9e50dc9ac713135de5cba589e49c4ff03fbaeb0" target="_blank"> {Node.text("f9e50dc")} </a>,
            Node.text(") # 1.0.0 (2025-11-02)")
          ]
        ],
      },
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("adjust build configuration and dist output ("),
            <a href="https://github.com/brnrdog/xote/commit/5dcca3beb89e25aa55c6fba7a4b67c59661d75bd" target="_blank"> {Node.text("5dcca3b")} </a>,
            Node.text(")")
          ],
          [
            Node.text("improve signal reactivity and add todo styling ("),
            <a href="https://github.com/brnrdog/xote/commit/495f0bb52eaa8de89214f957f30b078f07029569" target="_blank"> {Node.text("495f0bb")} </a>,
            Node.text(")")
          ],
          [
            Node.text("rescript build in release workflow ("),
            <a href="https://github.com/brnrdog/xote/commit/9b2fb1948b4f168de66da5fd96282ddcf82d8dca" target="_blank"> {Node.text("9b2fb19")} </a>,
            Node.text(")")
          ],
          [
            Node.text("version bump ("),
            <a href="https://github.com/brnrdog/xote/commit/2794ae697f5c3448d946b9fc5c7d1c0defa8be1a" target="_blank"> {Node.text("2794ae6")} </a>,
            Node.text(")")
          ],
          [
            Node.text("version bump for release ("),
            <a href="https://github.com/brnrdog/xote/commit/72fb74f2cf3d4a2389daf5363457d5d7ad4eaed1" target="_blank"> {Node.text("72fb74f")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "Features",
        items: [
          [
            Node.text("add Component system with automatic reactivity ("),
            <a href="https://github.com/brnrdog/xote/commit/38815ed3d1400c5511b790011d60081b317a69ac" target="_blank"> {Node.text("38815ed")} </a>,
            Node.text(")")
          ],
          [
            Node.text("add demo ("),
            <a href="https://github.com/brnrdog/xote/commit/cf3faf34c07d85a60d78d5f9539d2e2132f3b85a" target="_blank"> {Node.text("cf3faf3")} </a>,
            Node.text(")")
          ],
          [
            Node.text("bump version ("),
            <a href="https://github.com/brnrdog/xote/commit/5ac8b19a954d3fa10ce0f0d866f86fb74e3ad456" target="_blank"> {Node.text("5ac8b19")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" set reactivity to component element attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1" target="_blank"> {Node.text("57217e3")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" simplify signalText to accept function directly ("),
            <a href="https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3" target="_blank"> {Node.text("9a9d551")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" unify attrs and signalAttrs into single attrs parameter ("),
            <a href="https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc" target="_blank"> {Node.text("d8942d9")} </a>,
            Node.text(")")
          ],
          [
            Node.text("minimal signal implementation based on the TC39 proposal ("),
            <a href="https://github.com/brnrdog/xote/commit/9b78d0b62ba21c953d909459036246f334b6613e" target="_blank"> {Node.text("9b78d0b")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("router:")} </strong>,
            Node.text(" add signal-based routing with pattern matching ("),
            <a href="https://github.com/brnrdog/xote/commit/7bab79eb46fc35c9f90d09391bb71209485aa1d5" target="_blank"> {Node.text("7bab79e")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0",
    date: "2025-11-02",
    id: "release-1-1-0-2025-11-02",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" set reactivity to component element attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1" target="_blank"> {Node.text("57217e3")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" simplify signalText to accept function directly ("),
            <a href="https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3" target="_blank"> {Node.text("9a9d551")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" unify attrs and signalAttrs into single attrs parameter ("),
            <a href="https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc" target="_blank"> {Node.text("d8942d9")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("router:")} </strong>,
            Node.text(" add signal-based routing with pattern matching ("),
            <a href="https://github.com/brnrdog/xote/commit/7bab79eb46fc35c9f90d09391bb71209485aa1d5" target="_blank"> {Node.text("7bab79e")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0",
    date: "2025-11-01",
    id: "release-1-1-0-2025-11-01",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" set reactivity to component element attributes ("),
            <a href="https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1" target="_blank"> {Node.text("57217e3")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" simplify signalText to accept function directly ("),
            <a href="https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3" target="_blank"> {Node.text("9a9d551")} </a>,
            Node.text(")")
          ],
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" unify attrs and signalAttrs into single attrs parameter ("),
            <a href="https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc" target="_blank"> {Node.text("d8942d9")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0",
    date: "2025-10-31",
    id: "release-1-1-0-2025-10-31",
    sections: [
      {
        title: "Features",
        items: [
          [
            <strong> {Node.text("component:")} </strong>,
            Node.text(" add support to a tags ("),
            <a href="https://github.com/brnrdog/xote/commit/8ea09c19aaed9383b80d6cd15e61ae75113c6d73" target="_blank"> {Node.text("8ea09c1")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.0.3",
    url: "https://github.com/brnrdog/xote/compare/v1.0.2...v1.0.3",
    date: "2025-10-31",
    id: "release-1-0-3-2025-10-31",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("adjust build configuration and dist output ("),
            <a href="https://github.com/brnrdog/xote/commit/5dcca3beb89e25aa55c6fba7a4b67c59661d75bd" target="_blank"> {Node.text("5dcca3b")} </a>,
            Node.text(")")
          ],
          [
            Node.text("rescript build in release workflow ("),
            <a href="https://github.com/brnrdog/xote/commit/9b2fb1948b4f168de66da5fd96282ddcf82d8dca" target="_blank"> {Node.text("9b2fb19")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.0.2",
    url: "https://github.com/brnrdog/xote/compare/v1.0.1...v1.0.2",
    date: "2025-10-30",
    id: "release-1-0-2-2025-10-30",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("version bump ("),
            <a href="https://github.com/brnrdog/xote/commit/2794ae697f5c3448d946b9fc5c7d1c0defa8be1a" target="_blank"> {Node.text("2794ae6")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  },
  {
    version: "1.0.1",
    url: "https://github.com/brnrdog/xote/compare/v1.0.0...v1.0.1",
    date: "2025-10-30",
    id: "release-1-0-1-2025-10-30",
    sections: [
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("version bump for release ("),
            <a href="https://github.com/brnrdog/xote/commit/72fb74f2cf3d4a2389daf5363457d5d7ad4eaed1" target="_blank"> {Node.text("72fb74f")} </a>,
            Node.text(") # 1.0.0 (2025-10-30)")
          ]
        ],
      },
      {
        title: "Bug Fixes",
        items: [
          [
            Node.text("improve signal reactivity and add todo styling ("),
            <a href="https://github.com/brnrdog/xote/commit/495f0bb52eaa8de89214f957f30b078f07029569" target="_blank"> {Node.text("495f0bb")} </a>,
            Node.text(")")
          ]
        ],
      },
      {
        title: "Features",
        items: [
          [
            Node.text("add Component system with automatic reactivity ("),
            <a href="https://github.com/brnrdog/xote/commit/38815ed3d1400c5511b790011d60081b317a69ac" target="_blank"> {Node.text("38815ed")} </a>,
            Node.text(")")
          ],
          [
            Node.text("add demo ("),
            <a href="https://github.com/brnrdog/xote/commit/cf3faf34c07d85a60d78d5f9539d2e2132f3b85a" target="_blank"> {Node.text("cf3faf3")} </a>,
            Node.text(")")
          ],
          [
            Node.text("minimal signal implementation based on the TC39 proposal ("),
            <a href="https://github.com/brnrdog/xote/commit/9b78d0b62ba21c953d909459036246f334b6613e" target="_blank"> {Node.text("9b78d0b")} </a>,
            Node.text(")")
          ]
        ],
      }
    ],
  }
]
