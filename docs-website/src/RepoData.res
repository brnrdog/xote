// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../docs/CHANGELOG.md
// * To update: modify docs/CHANGELOG.md and run:
// *   npm run generate-repo-data
// ****************************************************

type inlineNodes = array<View.node>

// A link to an issue or a commit.
type reference = {label: string, url: string}

type change = {
  scope: option<string>,
  text: inlineNodes,
  refs: array<reference>,
}

type releaseSection = {
  title: string,
  changes: array<change>,
}

type release = {
  version: string,
  url: string,
  date: string,
  formattedDate: string,
  id: string,
  prerelease: bool,
  sections: array<releaseSection>,
}

let sourceUrl = "https://github.com/brnrdog/xote/blob/main/docs/CHANGELOG.md"
let latestVersion = "7.2.0-beta.2"
let latestReleaseDate = "2026-10-19"
let latestReleaseFormattedDate = "Oct 19, 2026"

let releases: array<release> = [
  {
    version: "7.2.0-beta.2",
    url: "https://github.com/brnrdog/xote/compare/v7.2.0-beta.1...v7.2.0-beta.2",
    date: "2026-10-19",
    formattedDate: "Oct 19, 2026",
    id: "release-7-2-0-beta-2-2026-10-19",
    prerelease: true,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("context"),
            text: [
              View.text("keep effects and boundaries to their own subtree")
            ],
            refs: [{label: "cf2cec7", url: "https://github.com/brnrdog/xote/commit/cf2cec73f384ae51ef3505677572d2a919ba82b7"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add Resource and View.Suspense")
            ],
            refs: [{label: "#173", url: "https://github.com/brnrdog/xote/issues/173"}, {label: "32ce93e", url: "https://github.com/brnrdog/xote/commit/32ce93e2eafbcbc3d33aab70d096b4a2242c0b33"}],
          },
          {
            scope: Some("context"),
            text: [
              View.text("add Context for values scoped to a subtree")
            ],
            refs: [{label: "edd5192", url: "https://github.com/brnrdog/xote/commit/edd5192d6ca89b5e76a62de60ba2cb94d77bc0b6"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add element refs, onMount and onCleanup")
            ],
            refs: [{label: "#170", url: "https://github.com/brnrdog/xote/issues/170"}, {label: "80e91d1", url: "https://github.com/brnrdog/xote/commit/80e91d107480f4a1f152dd52ebe671199bc1a496"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add View.ErrorBoundary")
            ],
            refs: [{label: "689bf18", url: "https://github.com/brnrdog/xote/commit/689bf18fe8567ce3ede2b4e33fc12c8dc81d7317"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add View.Portal")
            ],
            refs: [{label: "#174", url: "https://github.com/brnrdog/xote/issues/174"}, {label: "49979eb", url: "https://github.com/brnrdog/xote/commit/49979eb3a4d7b395395a8985ff80c8591aaa50d6"}],
          }
        ],
      },
      {
        title: "Performance Improvements",
        changes: [
          {
            scope: Some("jsx"),
            text: [
              View.text("walk only the props an element was given")
            ],
            refs: [{label: "d956450", url: "https://github.com/brnrdog/xote/commit/d956450659b54d9b93f9a96a1db8898a6fafeee4"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("own state per region and clone repeated shapes")
            ],
            refs: [{label: "9622940", url: "https://github.com/brnrdog/xote/commit/9622940525fe26b778d189eeb2c0faa426d09662"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("update reactive text in place")
            ],
            refs: [{label: "19ceee2", url: "https://github.com/brnrdog/xote/commit/19ceee29320a4fcf0309ab90dc67e0e39323b6da"}],
          }
        ],
      }
    ],
  },
  {
    version: "7.2.0-beta.1",
    url: "https://github.com/brnrdog/xote/compare/v7.1.0...v7.2.0-beta.1",
    date: "2026-09-19",
    formattedDate: "Sep 19, 2026",
    id: "release-7-2-0-beta-1-2026-09-19",
    prerelease: true,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("ppx,view"),
            text: [
              View.text("harden bare-child coercion, widen read detection, warn on ppx ABI mismatch")
            ],
            refs: [{label: "27fc5d0", url: "https://github.com/brnrdog/xote/commit/27fc5d03dd121eae5047af71878854efd86c39d5"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("close silent-reactivity gaps and fail fast on ABI mismatch")
            ],
            refs: [{label: "91f57c4", url: "https://github.com/brnrdog/xote/commit/91f57c4aee5b95001e49cccd110008304d9d6569"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("decompose control-flow branches when the condition is not reactive")
            ],
            refs: [{label: "5628084", url: "https://github.com/brnrdog/xote/commit/5628084eb36663c9606c584f5f80fd61a9bfcea7"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("decompose fragment bodies so nested reactive regions stay independent")
            ],
            refs: [{label: "d27a1a4", url: "https://github.com/brnrdog/xote/commit/d27a1a4a2954af51e2e6eaaca9fad804c077e3d1"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("decompose render callbacks so their bodies are treated as node position")
            ],
            refs: [{label: "cd48499", url: "https://github.com/brnrdog/xote/commit/cd4849907089696282eb31dc6a67263a2e89a692"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("don't double-thunk values already written as functions")
            ],
            refs: [{label: "219f897", url: "https://github.com/brnrdog/xote/commit/219f89725bcdb1baad1d34ce7917cc1c61cdd8e2"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("harden install path and CI for the prebuilt binaries")
            ],
            refs: [{label: "e814d2c", url: "https://github.com/brnrdog/xote/commit/e814d2cc2ab3a1986b918a17d9c5edd01fa1c9b5"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("harden install path and CI for the prebuilt binaries")
            ],
            refs: [{label: "8ca3364", url: "https://github.com/brnrdog/xote/commit/8ca3364e772e27de4e62f07f578f3a1edb4907ef"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("only thunk eager signal reads, not reads deferred in lambdas")
            ],
            refs: [{label: "3149c2f", url: "https://github.com/brnrdog/xote/commit/3149c2fc14de13f64609950603baf5250010a5be"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("reach JSX wherever it appears, including helper functions")
            ],
            refs: [{label: "b7855de", url: "https://github.com/brnrdog/xote/commit/b7855de109995cb534fbf184df01770459f1c9fc"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("recognize namespaced value components and decompose JSX in container props")
            ],
            refs: [{label: "34b3458", url: "https://github.com/brnrdog/xote/commit/34b34585c783ac7255eed97392b1572b9afeeadf"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("stop nested .gitignore from stripping prebuilt binaries out of the npm tarball")
            ],
            refs: [{label: "86c7588", url: "https://github.com/brnrdog/xote/commit/86c7588eb4f9683e0c4f109c52175a4784ff2529"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("track local reactive helpers so hidden reads stay fine-grained")
            ],
            refs: [{label: "648233c", url: "https://github.com/brnrdog/xote/commit/648233c580b399f92d1575b561123c83f7f93386"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("re-coerce non-scalar View.child thunks on every run")
            ],
            refs: [{label: "6bccab0", url: "https://github.com/brnrdog/xote/commit/6bccab0112c5ca4d6c9599dc62c917c925572ea9"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: Some("ppx"),
            text: [
              View.text("add @xote.component component-level annotation")
            ],
            refs: [{label: "1c10e77", url: "https://github.com/brnrdog/xote/commit/1c10e77e94dfe85d856b43ef5b24b8d46148477b"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("add @xote.component for fine-grained components")
            ],
            refs: [{label: "26ca857", url: "https://github.com/brnrdog/xote/commit/26ca8578c19fd4512ab8184edfce37dc0c72f757"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("add "),
              <code> {View.text("@xote.component")} </code>,
              View.text(" for fine-grained components")
            ],
            refs: [{label: "cd6b4d1", url: "https://github.com/brnrdog/xote/commit/cd6b4d16ce38abb243fd739df3a3f0a75982bdc7"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("alias-aware signal detection in tracked-block ppx")
            ],
            refs: [{label: "54ef22c", url: "https://github.com/brnrdog/xote/commit/54ef22c95b124e3cd59bef99c39e91264be400e7"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("fine-grain JSX wherever it appears, including helper functions")
            ],
            refs: [{label: "4638c91", url: "https://github.com/brnrdog/xote/commit/4638c91d3d70a23f08a6858a2085e00788df65fd"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("fine-grain JSX wherever it appears, including helper functions")
            ],
            refs: [{label: "d631140", url: "https://github.com/brnrdog/xote/commit/d631140d65a5bfe35a519f4240a722e5be3f4aa9"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("make the tracked ppx production-ready and opt-in")
            ],
            refs: [{label: "bac136a", url: "https://github.com/brnrdog/xote/commit/bac136a7da33fee8c55a4361ea91391d57e05f7f"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("prototype fine-grained tracked-block compilation")
            ],
            refs: [{label: "d591b8e", url: "https://github.com/brnrdog/xote/commit/d591b8ea733403a8fbc598a1fffbbaeeff0c9758"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("ship prebuilt binaries so @xote.component needs no toolchain")
            ],
            refs: [{label: "0f3d1b4", url: "https://github.com/brnrdog/xote/commit/0f3d1b46eb4a28009dfbb2216d59028a2d55b07f"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("ship prebuilt binaries so "),
              <code> {View.text("@xote.component")} </code>,
              View.text(" needs no toolchain")
            ],
            refs: [{label: "59672b2", url: "https://github.com/brnrdog/xote/commit/59672b2f222238e2a7e560f6fbbcc7d3d4149a73"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("ship prebuilt per-platform binaries and make @xote.component the standard setup")
            ],
            refs: [{label: "92dd208", url: "https://github.com/brnrdog/xote/commit/92dd2086772e37f1aeabb73b43ad975d76058d31"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("track only the condition in tracked control flow")
            ],
            refs: [{label: "f2639f3", url: "https://github.com/brnrdog/xote/commit/f2639f3f585ce4afd3d8d5f39e593b32467858db"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add tracked() auto-tracked reactive block ("),
              <a href="https://github.com/brnrdog/xote/commit/6697c809d4b18ca04b2aece14c4eccf768fd9a4a" target="_blank"> {View.text("6697c80")} </a>,
              View.text("), closes "),
              <a href="https://github.com/brnrdog/rescript-signals/issues/34" target="_blank"> {View.text("brnrdog/rescript-signals#34")} </a>
            ],
            refs: [],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add tracked() for auto-tracked reactive blocks")
            ],
            refs: [{label: "2427c6b", url: "https://github.com/brnrdog/xote/commit/2427c6bbb15a205fed42869b0c8f45c61e5a37d8"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add tracked() for auto-tracked reactive blocks")
            ],
            refs: [{label: "ae5c4e9", url: "https://github.com/brnrdog/xote/commit/ae5c4e97d67abc369bc5bd127fe40953ba2d043b"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("coerce bare JSX children so value primitives are optional")
            ],
            refs: [{label: "8b67a43", url: "https://github.com/brnrdog/xote/commit/8b67a4387cb175dcd5517d1ab2154b30a8a541b9"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("coerce bare JSX children so value primitives are optional")
            ],
            refs: [{label: "0721b84", url: "https://github.com/brnrdog/xote/commit/0721b84085768d26f2432090492caacef30f59b0"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("coerce bare JSX children so value primitives are optional")
            ],
            refs: [{label: "1586ef6", url: "https://github.com/brnrdog/xote/commit/1586ef64af02e6dfbdfef9fff1589394fecf7a28"}],
          }
        ],
      },
      {
        title: "Performance Improvements",
        changes: [
          {
            scope: Some("jsx"),
            text: [
              View.text("walk only the props an element was given")
            ],
            refs: [{label: "ac141b1", url: "https://github.com/brnrdog/xote/commit/ac141b1f3094048b259ffaf16b59929fbffbb09a"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("own state per region and clone repeated shapes")
            ],
            refs: [{label: "f0798d4", url: "https://github.com/brnrdog/xote/commit/f0798d45880d6572dcb9774c28a66a7ac79fd1a7"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("update reactive text in place")
            ],
            refs: [{label: "076774d", url: "https://github.com/brnrdog/xote/commit/076774daadc183ea248c9ac7ca64dc44167b9516"}],
          }
        ],
      }
    ],
  },
  {
    version: "7.1.0",
    url: "https://github.com/brnrdog/xote/compare/v7.0.0...v7.1.0",
    date: "2026-08-23",
    formattedDate: "Aug 23, 2026",
    id: "release-7-1-0-2026-08-23",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("effect"),
            text: [
              View.text("keep a disposed effect dead when its queued run fires")
            ],
            refs: [{label: "547e86c", url: "https://github.com/brnrdog/xote/commit/547e86cf490a4221175745928e2447e018407d25"}],
          },
          {
            scope: Some("effect"),
            text: [
              View.text("own effects created while a component renders")
            ],
            refs: [{label: "ef49150", url: "https://github.com/brnrdog/xote/commit/ef4915008b0dee33dacbdbc252f874f08545f159"}],
          },
          {
            scope: None,
            text: [
              View.text("enforce the public API boundary with interface files")
            ],
            refs: [{label: "b1d6ded", url: "https://github.com/brnrdog/xote/commit/b1d6ded889d74f711dfabc2db9386a717954dfc2"}],
          },
          {
            scope: Some("hydration"),
            text: [
              View.text("a hydrated keyed list never subscribed to its signal")
            ],
            refs: [{label: "7240c9d", url: "https://github.com/brnrdog/xote/commit/7240c9dcbfae53dab189f1050beff72b58e7ebcc"}],
          },
          {
            scope: Some("owner"),
            text: [
              View.text("restore the active scope when a component body throws")
            ],
            refs: [{label: "291d8e9", url: "https://github.com/brnrdog/xote/commit/291d8e9d41ae21b62b7543b82cccf26c9dcbb9aa"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("leave attrs and event handlers exactly as written")
            ],
            refs: [{label: "7946943", url: "https://github.com/brnrdog/xote/commit/79469433f8bc1aa53b0fe1348a5edd294d9a7bfa"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("leave the data object exactly as written")
            ],
            refs: [{label: "d9c88b2", url: "https://github.com/brnrdog/xote/commit/d9c88b2bc6285f8b4fe0cc0189f82acaf939926d"}],
          },
          {
            scope: None,
            text: [
              View.text("remove @rescript/core dependency")
            ],
            refs: [{label: "fa11c35", url: "https://github.com/brnrdog/xote/commit/fa11c35ae69d3dfb41f4c90ec6095f1c9126c9e6"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("make a component body its own reactive scope ("),
              <a href="https://github.com/brnrdog/xote/commit/3bab9b71c09345f0296758fbd6c89b5c4676a2e4" target="_blank"> {View.text("3bab9b7")} </a>,
              View.text("), closes "),
              <a href="https://github.com/brnrdog/xote/issues/17" target="_blank"> {View.text("#17")} </a>
            ],
            refs: [],
          },
          {
            scope: Some("render"),
            text: [
              View.text("release the computeds the library builds for a node")
            ],
            refs: [{label: "71ec379", url: "https://github.com/brnrdog/xote/commit/71ec379aa447680accfd7edc45076f54e3bd64ff"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("retire a replaced keyed row where it lives")
            ],
            refs: [{label: "0807262", url: "https://github.com/brnrdog/xote/commit/0807262780bd0e546129452bead566f14c2c501b"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("retire non-keyed children replaced by a keyed list")
            ],
            refs: [{label: "b56f802", url: "https://github.com/brnrdog/xote/commit/b56f80299153acb6cb21b09d25c3e43d7c085265"}],
          },
          {
            scope: Some("router"),
            text: [
              View.text("release a route region's computed with its node")
            ],
            refs: [{label: "f0cf2dc", url: "https://github.com/brnrdog/xote/commit/f0cf2dc7a976ebf573ac8cb56e718536171bbb81"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("include instructions for agents in the package")
            ],
            refs: [{label: "450e210", url: "https://github.com/brnrdog/xote/commit/450e210f3a9df0b2fa649efb73bb7d123784c98d"}],
          },
          {
            scope: None,
            text: [
              View.text("introduce MaybeSignal, deprecate Prop")
            ],
            refs: [{label: "f5da1e3", url: "https://github.com/brnrdog/xote/commit/f5da1e39496022d0b79f9d7064e134b38052ae60"}],
          },
          {
            scope: Some("jsx"),
            text: [
              View.text("add attrs escape hatch and removable attributes")
            ],
            refs: [{label: "d405274", url: "https://github.com/brnrdog/xote/commit/d4052741612e6771ad144dc04f529898bfef9558"}],
          },
          {
            scope: Some("maybe-signal"),
            text: [
              View.text("add fold and View.render, fix toSignal")
            ],
            refs: [{label: "#161", url: "https://github.com/brnrdog/xote/issues/161"}, {label: "4222f4d", url: "https://github.com/brnrdog/xote/commit/4222f4d3634c1598882efd78f550a976ebaafb42"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("add @xote.component for fine-grained components")
            ],
            refs: [{label: "1515c2c", url: "https://github.com/brnrdog/xote/commit/1515c2c499f438d4145b93dff7ea86d4d3ab82ca"}],
          },
          {
            scope: Some("ppx"),
            text: [
              View.text("ship prebuilt binaries so @xote.component needs no toolchain")
            ],
            refs: [{label: "0a55a1f", url: "https://github.com/brnrdog/xote/commit/0a55a1f4b536e387ed459861b838fc1e9637b987"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add tracked() blocks and coerce bare JSX children")
            ],
            refs: [{label: "c602626", url: "https://github.com/brnrdog/xote/commit/c6026265ce1e06fcc5d0a98f4193ca7329410619"}],
          }
        ],
      },
      {
        title: "Performance Improvements",
        changes: [
          {
            scope: Some("render"),
            text: [
              View.text("allocate an owner only when something registers")
            ],
            refs: [{label: "89a120b", url: "https://github.com/brnrdog/xote/commit/89a120bbd49a34a63c9ce604592c776af5f57a77"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("move only the rows a reorder actually displaces")
            ],
            refs: [{label: "0992cc4", url: "https://github.com/brnrdog/xote/commit/0992cc4b2ccf3cfeb37609135d4d6a6b43f14cdd"}],
          },
          {
            scope: Some("render"),
            text: [
              View.text("walk the disposal tree without snapshotting each node")
            ],
            refs: [{label: "046e51f", url: "https://github.com/brnrdog/xote/commit/046e51f8fe16282e391e1d6dc4db0e687be6f1ab"}],
          }
        ],
      }
    ],
  },
  {
    version: "7.0.0",
    url: "https://github.com/brnrdog/xote/compare/v6.4.0...v7.0.0",
    date: "2026-07-13",
    formattedDate: "Jul 13, 2026",
    id: "release-7-0-0-2026-07-13",
    prerelease: false,
    sections: [
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: remove deprecated modules and redundant API aliases")
            ],
            refs: [{label: "6745b54", url: "https://github.com/brnrdog/xote/commit/6745b54967f553014b753c35b03e8f3e3e7da82c"}],
          }
        ],
      },
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("docs"),
            text: [
              View.text("resolve accessibility issues")
            ],
            refs: [{label: "c8f2b45", url: "https://github.com/brnrdog/xote/commit/c8f2b4591476fc2e0a7caccf9d5dc9f6e6cfb9dc"}],
          },
          {
            scope: Some("router"),
            text: [
              View.text("scroll hash targets after navigation")
            ],
            refs: [{label: "8652f27", url: "https://github.com/brnrdog/xote/commit/8652f27e877cc3cecfc8cd7d506cf89f5bcb6654"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("handle empty value primitive props")
            ],
            refs: [{label: "e9ccdb1", url: "https://github.com/brnrdog/xote/commit/e9ccdb160ea322ce0bbdd67611864267762d1042"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add focused package entries")
            ],
            refs: [{label: "e2ee407", url: "https://github.com/brnrdog/xote/commit/e2ee407ee6ff109f7b99a17380df14bf8244b8b4"}],
          },
          {
            scope: None,
            text: [
              View.text("add mdx support to xote jsx runtime")
            ],
            refs: [{label: "e09d13f", url: "https://github.com/brnrdog/xote/commit/e09d13fa236b7a9652924bc3373b368efb2e1ba8"}],
          },
          {
            scope: Some("jsx"),
            text: [
              View.text("add conditional rendering primitives")
            ],
            refs: [{label: "ad7558f", url: "https://github.com/brnrdog/xote/commit/ad7558f4bef4ebf65ef9572ccef6ba46dce96c50"}],
          },
          {
            scope: Some("jsx"),
            text: [
              View.text("add list rendering primitives")
            ],
            refs: [{label: "d6958ec", url: "https://github.com/brnrdog/xote/commit/d6958ec867c65acf3af6d4ef65ee45652b525b58"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("add JSX value primitives")
            ],
            refs: [{label: "bc704c4", url: "https://github.com/brnrdog/xote/commit/bc704c49c725b580647b458111196f4841a23c80"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("render primitive children")
            ],
            refs: [{label: "04305a3", url: "https://github.com/brnrdog/xote/commit/04305a39f16b9a4feff4fcd510bcf0e951c6c6f9"}],
          },
          {
            scope: Some("view"),
            text: [
              View.text("support keyed rendering in For")
            ],
            refs: [{label: "46be19f", url: "https://github.com/brnrdog/xote/commit/46be19fc7f1af89397708029d7892ffff4f59ad4"}],
          }
        ],
      },
      {
        title: "BREAKING CHANGES",
        changes: [
          {
            scope: None,
            text: [
              View.text("- Remove the deprecated "),
              <code> {View.text("Node")} </code>,
              View.text(" module (use "),
              <code> {View.text("View")} </code>,
              View.text(") - Remove the deprecated "),
              <code> {View.text("ReactiveProp")} </code>,
              View.text(" module (use "),
              <code> {View.text("Prop")} </code>,
              View.text(") - Remove "),
              <code> {View.text("View.list")} </code>,
              View.text(" / "),
              <code> {View.text("View.keyedList")} </code>,
              View.text(" aliases (use "),
              <code> {View.text("View.each")} </code>,
              View.text(" / "),
              <code> {View.text("View.eachWithKey")} </code>,
              View.text(") - Remove "),
              <code> {View.text("SSRState.make")} </code>,
              View.text(" (use "),
              <code> {View.text("SSRState.signal")} </code>,
              View.text(") and "),
              <code> {View.text("SSRState.syncSignal")} </code>,
              View.text(" (use "),
              <code> {View.text("SSRState.sync")} </code>,
              View.text(") Also drops the "),
              <code> {View.text("Node")} </code>,
              View.text("/"),
              <code> {View.text("ReactiveProp")} </code>,
              View.text(" entries from "),
              <code> {View.text("rescript.json")} </code>,
              View.text(" "),
              <code> {View.text("sources.public")} </code>,
              View.text(" and the "),
              <code> {View.text("./node")} </code>,
              View.text(" / "),
              <code> {View.text("./reactive-prop")} </code>,
              View.text(" package exports, migrates in-repo examples/tests to the canonical names, and refreshes the README (favouring the Router/Route/Link component APIs in the Router section), CLAUDE.md, AGENTS.md, and the technical overview.")
            ],
            refs: [],
          }
        ],
      }
    ],
  },
  {
    version: "6.4.0",
    url: "https://github.com/brnrdog/xote/compare/v6.3.0...v6.4.0",
    date: "2026-05-20",
    formattedDate: "May 20, 2026",
    id: "release-6-4-0-2026-05-20",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("empty view keyed children")
            ],
            refs: [{label: "5fbe71b", url: "https://github.com/brnrdog/xote/commit/5fbe71bfa2dd15818c5f1c58c7bc76759adbcd0e"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add SVG attribute props to JSX Elements")
            ],
            refs: [{label: "63592e5", url: "https://github.com/brnrdog/xote/commit/63592e5d58bc581515b0bb707033f8d3246e1665"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.3.0",
    url: "https://github.com/brnrdog/xote/compare/v6.2.0...v6.3.0",
    date: "2026-05-12",
    formattedDate: "May 12, 2026",
    id: "release-6-3-0-2026-05-12",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add missing pointer event props")
            ],
            refs: [{label: "3a8f596", url: "https://github.com/brnrdog/xote/commit/3a8f596c2a516b0258e007e7080f07ac1d06ba47"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.2.0",
    url: "https://github.com/brnrdog/xote/compare/v6.1.2...v6.2.0",
    date: "2026-04-26",
    formattedDate: "Apr 26, 2026",
    id: "release-6-2-0-2026-04-26",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("connect keyed JSX to reconciliation")
            ],
            refs: [{label: "6839f90", url: "https://github.com/brnrdog/xote/commit/6839f90c8ff0838ce65427715ba65af57a76cce3"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add clearer api aliases")
            ],
            refs: [{label: "1bc01da", url: "https://github.com/brnrdog/xote/commit/1bc01da9f3a871b38fae7f243fa2b99a2ce37690"}],
          },
          {
            scope: None,
            text: [
              View.text("promote View and Prop as primary modules")
            ],
            refs: [{label: "5a1566f", url: "https://github.com/brnrdog/xote/commit/5a1566fd13d1bd4af09dbce0b8e40bdf2a4cc948"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.1.2",
    url: "https://github.com/brnrdog/xote/compare/v6.1.1...v6.1.2",
    date: "2026-04-25",
    formattedDate: "Apr 25, 2026",
    id: "release-6-1-2-2026-04-25",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("defer initial select value until options mount")
            ],
            refs: [{label: "7dd1c7f", url: "https://github.com/brnrdog/xote/commit/7dd1c7ff45100edd1f7f56e1db3acf517e7fed6e"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.1.1",
    url: "https://github.com/brnrdog/xote/compare/v6.1.0...v6.1.1",
    date: "2026-04-25",
    formattedDate: "Apr 25, 2026",
    id: "release-6-1-1-2026-04-25",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("defer initial select value until options mount")
            ],
            refs: [{label: "7dd1c7f", url: "https://github.com/brnrdog/xote/commit/7dd1c7ff45100edd1f7f56e1db3acf517e7fed6e"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.1.1",
    url: "https://github.com/brnrdog/xote/compare/v6.1.0...v6.1.1",
    date: "2026-04-21",
    formattedDate: "Apr 21, 2026",
    id: "release-6-1-1-2026-04-21",
    prerelease: false,
    sections: [
      {
        title: "Performance Improvements",
        changes: [
          {
            scope: None,
            text: [
              View.text("bump rescript-signals to ^3.1.0")
            ],
            refs: [{label: "f9d3ef9", url: "https://github.com/brnrdog/xote/commit/f9d3ef9a37acdc917dba35016e351fb82079fc17"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.1.0",
    url: "https://github.com/brnrdog/xote/compare/v6.0.1...v6.1.0",
    date: "2026-04-10",
    formattedDate: "Apr 10, 2026",
    id: "release-6-1-0-2026-04-10",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add draggable, hidden, title, and other missing JSX props")
            ],
            refs: [{label: "e6de2ba", url: "https://github.com/brnrdog/xote/commit/e6de2bae6c586fa863a1b40bfe2132f52469e8ee"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.0.1",
    url: "https://github.com/brnrdog/xote/compare/v6.0.0...v6.0.1",
    date: "2026-04-09",
    formattedDate: "Apr 9, 2026",
    id: "release-6-0-1-2026-04-09",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("add exports field to package.json")
            ],
            refs: [{label: "c57ed32", url: "https://github.com/brnrdog/xote/commit/c57ed3271263fa759c743990a104a56833ecc343"}],
          }
        ],
      }
    ],
  },
  {
    version: "6.0.0",
    url: "https://github.com/brnrdog/xote/compare/v5.0.0...v6.0.0",
    date: "2026-04-08",
    formattedDate: "Apr 8, 2026",
    id: "release-6-0-0-2026-04-08",
    prerelease: false,
    sections: [
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: drop Xote__ prefix and use ReScript namespacing")
            ],
            refs: [{label: "08991c4", url: "https://github.com/brnrdog/xote/commit/08991c4499951e53054b491940d1908bb8d744cb"}],
          }
        ],
      },
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: rename Component module to Node")
            ],
            refs: [{label: "0bb235b", url: "https://github.com/brnrdog/xote/commit/0bb235bfa2a0e81b23710304cf0c93e9286a8cbd"}],
          }
        ],
      },
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: rename JSX module to XoteJSX")
            ],
            refs: [{label: "ee870d4", url: "https://github.com/brnrdog/xote/commit/ee870d47abfa40e0c0eb5dbabd9aabeb82eedbb8"}],
          }
        ],
      },
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: split HTML element builders into Html module")
            ],
            refs: [{label: "8ffd83f", url: "https://github.com/brnrdog/xote/commit/8ffd83f97ece1ef71640c3ab8cb9067140ab6542"}],
          }
        ],
      },
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: unify reactive node helpers under "),
              <code> {View.text("signal")} </code>,
              View.text(" prefix")
            ],
            refs: [{label: "b1a3ca7", url: "https://github.com/brnrdog/xote/commit/b1a3ca7837f3e7e599cfc745518c526f10080bca"}],
          }
        ],
      },
      {
        title: "BREAKING CHANGES",
        changes: [
          {
            scope: None,
            text: [
              <code> {View.text("Xote.Component")} </code>,
              View.text(" is renamed to "),
              <code> {View.text("Xote.Node")} </code>,
              View.text(". Replace all "),
              <code> {View.text("Component.text")} </code>,
              View.text(", "),
              <code> {View.text("Component.signalText")} </code>,
              View.text(", "),
              <code> {View.text("Component.element")} </code>,
              View.text(", "),
              <code> {View.text("Component.mount")} </code>,
              View.text(", etc. with the equivalent "),
              <code> {View.text("Node.*")} </code>,
              View.text(" calls.")
            ],
            refs: [],
          },
          {
            scope: None,
            text: [
              View.text("The JSX module is now "),
              <code> {View.text("Xote.XoteJSX")} </code>,
              View.text(". Consumers must update "),
              <code> {View.text("rescript.json")} </code>,
              View.text(": \"jsx\": { \"version\": 4, \"module\": \"XoteJSX\" }")
            ],
            refs: [],
          },
          {
            scope: None,
            text: [
              View.text("Element builders moved from "),
              <code> {View.text("Component")} </code>,
              View.text(" to "),
              <code> {View.text("Html")} </code>,
              View.text(". Replace "),
              <code> {View.text("Xote.Component.div(...)")} </code>,
              View.text(" with "),
              <code> {View.text("Xote.Html.div(...)")} </code>,
              View.text(" (and the same for "),
              <code> {View.text("span")} </code>,
              View.text(", "),
              <code> {View.text("button")} </code>,
              View.text(", "),
              <code> {View.text("input")} </code>,
              View.text(", "),
              <code> {View.text("h1")} </code>,
              View.text("-"),
              <code> {View.text("h3")} </code>,
              View.text(", "),
              <code> {View.text("p")} </code>,
              View.text(", "),
              <code> {View.text("ul")} </code>,
              View.text(", "),
              <code> {View.text("li")} </code>,
              View.text(", "),
              <code> {View.text("a")} </code>,
              View.text(").")
            ],
            refs: [],
          },
          {
            scope: None,
            text: [
              View.text("The JSX module path changes from "),
              <code> {View.text("Xote__JSX")} </code>,
              View.text(" to "),
              <code> {View.text("Xote.JSX")} </code>,
              View.text(". Consumers must update their "),
              <code> {View.text("rescript.json")} </code>,
              View.text(": \"jsx\": { \"version\": 4, \"module\": \"JSX\" }, \"compiler-flags\": "),
              View.text("[\"-open Xote\"]")
            ],
            refs: [],
          },
          {
            scope: None,
            text: [
              <code> {View.text("Xote.Component.textSignal")} </code>,
              View.text(", "),
              <code> {View.text("reactiveString")} </code>,
              View.text(", "),
              <code> {View.text("reactiveInt")} </code>,
              View.text(", and "),
              <code> {View.text("reactiveFloat")} </code>,
              View.text(" are removed. Replace call sites with "),
              <code> {View.text("signalText")} </code>,
              View.text(", "),
              <code> {View.text("signalInt")} </code>,
              View.text(", and "),
              <code> {View.text("signalFloat")} </code>,
              View.text(" respectively.")
            ],
            refs: [],
          }
        ],
      }
    ],
  },
  {
    version: "5.0.0",
    url: "https://github.com/brnrdog/xote/compare/v4.16.1...v5.0.0",
    date: "2026-04-04",
    formattedDate: "Apr 4, 2026",
    id: "release-5-0-0-2026-04-04",
    prerelease: false,
    sections: [
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("feat!: update to rescript-signals 2.0.0")
            ],
            refs: [{label: "fb2c897", url: "https://github.com/brnrdog/xote/commit/fb2c89785ea2323a05e33240f602bab66613a84e"}],
          }
        ],
      },
      {
        title: "BREAKING CHANGES",
        changes: [
          {
            scope: None,
            text: [
              View.text("Effect.run now returns unit instead of a disposer. Use Effect.runWithDisposer when you need to manually dispose an effect.")
            ],
            refs: [],
          }
        ],
      }
    ],
  },
  {
    version: "4.16.1",
    url: "https://github.com/brnrdog/xote/compare/v4.16.0...v4.16.1",
    date: "2026-03-13",
    formattedDate: "Mar 13, 2026",
    id: "release-4-16-1-2026-03-13",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("use createElementNS for SVG elements to fix logo rendering")
            ],
            refs: [{label: "#61", url: "https://github.com/brnrdog/xote/issues/61"}, {label: "7ffefe1", url: "https://github.com/brnrdog/xote/commit/7ffefe1953dfbc8524c4b83fc208e4d3767ba3df"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.16.0",
    url: "https://github.com/brnrdog/xote/compare/v4.15.3...v4.16.0",
    date: "2026-03-12",
    formattedDate: "Mar 12, 2026",
    id: "release-4-16-0-2026-03-12",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("expose Router.initSSR for server-side route initialization")
            ],
            refs: [{label: "f232d0b", url: "https://github.com/brnrdog/xote/commit/f232d0b1dba81725f6d23e2beaecca9e2905eb11"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.15.3",
    url: "https://github.com/brnrdog/xote/compare/v4.15.2...v4.15.3",
    date: "2026-03-12",
    formattedDate: "Mar 12, 2026",
    id: "release-4-15-3-2026-03-12",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("defer JSX component evaluation to render time via LazyComponent")
            ],
            refs: [{label: "e685fc1", url: "https://github.com/brnrdog/xote/commit/e685fc149ad324f2846ef9ea62f6670d36519cde"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.15.2",
    url: "https://github.com/brnrdog/xote/compare/v4.15.1...v4.15.2",
    date: "2026-03-12",
    formattedDate: "Mar 12, 2026",
    id: "release-4-15-2-2026-03-12",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("ensure computed attributes are only updated within the effect context")
            ],
            refs: [{label: "#49", url: "https://github.com/brnrdog/xote/issues/49"}, {label: "ccf9905", url: "https://github.com/brnrdog/xote/commit/ccf9905b4ab38e63317ad068c1a276febf0644c2"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.15.1",
    url: "https://github.com/brnrdog/xote/compare/v4.15.0...v4.15.1",
    date: "2026-03-07",
    formattedDate: "Mar 7, 2026",
    id: "release-4-15-1-2026-03-07",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("remove @rescript/core dependency and code formatting")
            ],
            refs: [{label: "774b81f", url: "https://github.com/brnrdog/xote/commit/774b81f37e816b98bc676384b0dab03b1f094dcc"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.15.0",
    url: "https://github.com/brnrdog/xote/compare/v4.14.0...v4.15.0",
    date: "2026-03-04",
    formattedDate: "Mar 4, 2026",
    id: "release-4-15-0-2026-03-04",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add support to common mouse events")
            ],
            refs: [{label: "3811d10", url: "https://github.com/brnrdog/xote/commit/3811d107b8c2afa911d94b51242205f1cc5d973d"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.14.0",
    url: "https://github.com/brnrdog/xote/compare/v4.13.0...v4.14.0",
    date: "2026-03-01",
    formattedDate: "Mar 1, 2026",
    id: "release-4-14-0-2026-03-01",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add server-side rendering with hydration")
            ],
            refs: [{label: "8a30af3", url: "https://github.com/brnrdog/xote/commit/8a30af3421cbae9c33cfe19e6e8b42b7e2e0be6f"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.13.0",
    url: "https://github.com/brnrdog/xote/compare/v4.12.0...v4.13.0",
    date: "2026-02-28",
    formattedDate: "Feb 28, 2026",
    id: "release-4-13-0-2026-02-28",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("router"),
            text: [
              View.text("add scroll restoration for navigation")
            ],
            refs: [{label: "a5b8434", url: "https://github.com/brnrdog/xote/commit/a5b84344369a3cb8be713c5a60d050b9908173bc"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.12.0",
    url: "https://github.com/brnrdog/xote/compare/v4.11.0...v4.12.0",
    date: "2026-02-28",
    formattedDate: "Feb 28, 2026",
    id: "release-4-12-0-2026-02-28",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("jsx"),
            text: [
              View.text("add support to contextmenu event")
            ],
            refs: [{label: "#36", url: "https://github.com/brnrdog/xote/issues/36"}, {label: "68c7ba2", url: "https://github.com/brnrdog/xote/commit/68c7ba28f73384b6f7f6d059eaeea4d8e94f6491"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.11.0",
    url: "https://github.com/brnrdog/xote/compare/v4.10.1...v4.11.0",
    date: "2026-01-22",
    formattedDate: "Jan 22, 2026",
    id: "release-4-11-0-2026-01-22",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("update rescript from 1.3.0 to 1.3.3")
            ],
            refs: [{label: "35c9a4e", url: "https://github.com/brnrdog/xote/commit/35c9a4e2e9f9cc631edf0847389a47a5887420ec"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.10.1",
    url: "https://github.com/brnrdog/xote/compare/v4.10.0...v4.10.1",
    date: "2026-01-10",
    formattedDate: "Jan 10, 2026",
    id: "release-4-10-1-2026-01-10",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("ensures all router instances share same state")
            ],
            refs: [{label: "a754f96", url: "https://github.com/brnrdog/xote/commit/a754f96123f36add51e1a7c9893c4f5aa1462130"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.10.0",
    url: "https://github.com/brnrdog/xote/compare/v4.9.0...v4.10.0",
    date: "2026-01-10",
    formattedDate: "Jan 10, 2026",
    id: "release-4-10-0-2026-01-10",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("router"),
            text: [
              View.text("add base path option to router initialization")
            ],
            refs: [{label: "b54c6e9", url: "https://github.com/brnrdog/xote/commit/b54c6e99acd62a180a4166183f9d5ddb3cd37093"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.9.0",
    url: "https://github.com/brnrdog/xote/compare/v4.8.0...v4.9.0",
    date: "2026-01-06",
    formattedDate: "Jan 6, 2026",
    id: "release-4-9-0-2026-01-06",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("add helpers for rendering reactive and static values")
            ],
            refs: [{label: "c4b7526", url: "https://github.com/brnrdog/xote/commit/c4b7526d9c41945817453b523af133da8c105d7b"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.8.0",
    url: "https://github.com/brnrdog/xote/compare/v4.7.0...v4.8.0",
    date: "2025-12-31",
    formattedDate: "Dec 31, 2025",
    id: "release-4-8-0-2025-12-31",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("router"),
            text: [
              View.text("add Link component")
            ],
            refs: [{label: "0e8d215", url: "https://github.com/brnrdog/xote/commit/0e8d2152f478d30025c3886ca6047836628b9868"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.7.0",
    url: "https://github.com/brnrdog/xote/compare/v4.6.0...v4.7.0",
    date: "2025-12-29",
    formattedDate: "Dec 29, 2025",
    id: "release-4-7-0-2025-12-29",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("jsx"),
            text: [
              View.text("allow ReactiveProp.t besides raw values")
            ],
            refs: [{label: "0e082f5", url: "https://github.com/brnrdog/xote/commit/0e082f575199d97433d27a3aa58199ac3cd5cfee"}],
          },
          {
            scope: Some("reactive-prop"),
            text: [
              View.text("add helper functions for static and reactive")
            ],
            refs: [{label: "2e82b1a", url: "https://github.com/brnrdog/xote/commit/2e82b1a396b5e29ad11c7f76062f53130c1113aa"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.6.0",
    url: "https://github.com/brnrdog/xote/compare/v4.5.0...v4.6.0",
    date: "2025-12-29",
    formattedDate: "Dec 29, 2025",
    id: "release-4-6-0-2025-12-29",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("expose ReactiveProp from Xote module")
            ],
            refs: [{label: "3704a62", url: "https://github.com/brnrdog/xote/commit/3704a6218cabe7a5e89b1c00bda17db989aa1a5c"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.5.0",
    url: "https://github.com/brnrdog/xote/compare/v4.4.3...v4.5.0",
    date: "2025-12-29",
    formattedDate: "Dec 29, 2025",
    id: "release-4-5-0-2025-12-29",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("introduce ReactiveProp module")
            ],
            refs: [{label: "0dde3b8", url: "https://github.com/brnrdog/xote/commit/0dde3b81c3d2872455e20f110a2793e845179bcf"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.4.3",
    url: "https://github.com/brnrdog/xote/compare/v4.4.2...v4.4.3",
    date: "2025-12-20",
    formattedDate: "Dec 20, 2025",
    id: "release-4-4-3-2025-12-20",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("boolean attributes")
            ],
            refs: [{label: "60e1155", url: "https://github.com/brnrdog/xote/commit/60e11557f1d2b38560da593f153f4f5ea0267471"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.4.2",
    url: "https://github.com/brnrdog/xote/compare/v4.4.1...v4.4.2",
    date: "2025-12-20",
    formattedDate: "Dec 20, 2025",
    id: "release-4-4-2-2025-12-20",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("jsx"),
            text: [
              View.text("reactive support for boolean attributes")
            ],
            refs: [{label: "c54ed60", url: "https://github.com/brnrdog/xote/commit/c54ed60f174bd2049f27809f21f354546ba65912"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.4.1",
    url: "https://github.com/brnrdog/xote/compare/v4.4.0...v4.4.1",
    date: "2025-12-20",
    formattedDate: "Dec 20, 2025",
    id: "release-4-4-1-2025-12-20",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("attribute and property handling")
            ],
            refs: [{label: "c49cbc0", url: "https://github.com/brnrdog/xote/commit/c49cbc0d3b486c7a68b59a65671b139ae8b1eac5"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.4.0",
    url: "https://github.com/brnrdog/xote/compare/v4.3.1...v4.4.0",
    date: "2025-12-19",
    formattedDate: "Dec 19, 2025",
    id: "release-4-4-0-2025-12-19",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("jsx"),
            text: [
              View.text("add support to many other common attributes")
            ],
            refs: [{label: "d3460d8", url: "https://github.com/brnrdog/xote/commit/d3460d84012964c5dc6a5659f42ada62465a8e18"}],
          },
          {
            scope: Some("jsx"),
            text: [
              View.text("add support to name attributes")
            ],
            refs: [{label: "07de33d", url: "https://github.com/brnrdog/xote/commit/07de33d9ac86c955efd1f04bc088217689288f08"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.3.1",
    url: "https://github.com/brnrdog/xote/compare/v4.3.0...v4.3.1",
    date: "2025-12-18",
    formattedDate: "Dec 18, 2025",
    id: "release-4-3-1-2025-12-18",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("expose missing source files for rescript projects")
            ],
            refs: [{label: "4d93ebb", url: "https://github.com/brnrdog/xote/commit/4d93ebbe77260381ca7058562626697c42da1aa1"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.3.0",
    url: "https://github.com/brnrdog/xote/compare/v4.2.0...v4.3.0",
    date: "2025-12-15",
    formattedDate: "Dec 15, 2025",
    id: "release-4-3-0-2025-12-15",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("update rescript-signals from 1.2.0 to 1.3.0")
            ],
            refs: [{label: "f5f5c1b", url: "https://github.com/brnrdog/xote/commit/f5f5c1bfd78dd2fedb89aa0bc6cfe26221b70f20"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.2.0",
    url: "https://github.com/brnrdog/xote/compare/v4.1.1...v4.2.0",
    date: "2025-12-14",
    formattedDate: "Dec 14, 2025",
    id: "release-4-2-0-2025-12-14",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("introduce keyedList for list reconciliation")
            ],
            refs: [{label: "#24", url: "https://github.com/brnrdog/xote/issues/24"}, {label: "96800de", url: "https://github.com/brnrdog/xote/commit/96800dec3c9bbd32305643c0b36c74b993055650"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.1.1",
    url: "https://github.com/brnrdog/xote/compare/v4.1.0...v4.1.1",
    date: "2025-12-14",
    formattedDate: "Dec 14, 2025",
    id: "release-4-1-1-2025-12-14",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: Some("components"),
            text: [
              View.text("fix component disposal")
            ],
            refs: [{label: "adbfcce", url: "https://github.com/brnrdog/xote/commit/adbfccefa088d87f0c00a38fd2b20792c911f4a0"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.1.0",
    url: "https://github.com/brnrdog/xote/compare/v4.0.0...v4.1.0",
    date: "2025-12-05",
    formattedDate: "Dec 5, 2025",
    id: "release-4-1-0-2025-12-05",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("update rescript-signals from v1.0.1 to v1.2.0")
            ],
            refs: [{label: "d1f76d8", url: "https://github.com/brnrdog/xote/commit/d1f76d809d70cb95f5757aa0f4483f6f6768876c"}],
          }
        ],
      }
    ],
  },
  {
    version: "4.0.0",
    url: "https://github.com/brnrdog/xote/compare/v3.0.0...v4.0.0",
    date: "2025-12-02",
    formattedDate: "Dec 2, 2025",
    id: "release-4-0-0-2025-12-02",
    prerelease: false,
    sections: [
      {
        title: "Code Refactoring",
        changes: [
          {
            scope: None,
            text: [
              View.text("move signals to rescript-signals")
            ],
            refs: [{label: "848b3b8", url: "https://github.com/brnrdog/xote/commit/848b3b825e620c72cfb309ca7a170c7d16833043"}],
          }
        ],
      },
      {
        title: "BREAKING CHANGES",
        changes: [
          {
            scope: None,
            text: [
              View.text("- Xote.Core.t -> Xote.Signal.t - Core.batch removed from API")
            ],
            refs: [],
          }
        ],
      }
    ],
  },
  {
    version: "3.0.0",
    url: "https://github.com/brnrdog/xote/compare/v2.0.0...v3.0.0",
    date: "2025-11-28",
    formattedDate: "Nov 28, 2025",
    id: "release-3-0-0-2025-11-28",
    prerelease: false,
    sections: [
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("fix!: add cleanup callback support to effects")
            ],
            refs: [{label: "7aade4f", url: "https://github.com/brnrdog/xote/commit/7aade4f3cb95a284169c42fa6771e31d33613b7c"}],
          }
        ],
      },
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("refactor!: simplify Computed API with internal tracking")
            ],
            refs: [{label: "5d9bc01", url: "https://github.com/brnrdog/xote/commit/5d9bc0130208b8ebdde90f1207ae101695a6b6af"}],
          }
        ],
      },
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("add disposal support for computed observers")
            ],
            refs: [{label: "f2e8a17", url: "https://github.com/brnrdog/xote/commit/f2e8a177a37d87abc2477805a39e0eb896946664"}],
          },
          {
            scope: None,
            text: [
              View.text("add equality check to Signal.set to prevent unnecessary notifications")
            ],
            refs: [{label: "2680a19", url: "https://github.com/brnrdog/xote/commit/2680a195e8adfa9cf2ed3d3c5bb236044bf04027"}],
          },
          {
            scope: None,
            text: [
              View.text("convert recursive scheduler to iterative loop")
            ],
            refs: [{label: "0b69c76", url: "https://github.com/brnrdog/xote/commit/0b69c76d40130fb436b9df4feae8e4785deccc88"}],
          },
          {
            scope: None,
            text: [
              View.text("restore global tracking state on exceptions")
            ],
            refs: [{label: "a6e5b70", url: "https://github.com/brnrdog/xote/commit/a6e5b7030e59fb7e8323896ba1b02c44668a81f9"}],
          },
          {
            scope: None,
            text: [
              View.text("signal set structural equality check on objects with functions")
            ],
            refs: [{label: "803aaba", url: "https://github.com/brnrdog/xote/commit/803aaba12f75b7df660de1f11257b4eb1a3b4aa5"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add automatic disposal for computed values")
            ],
            refs: [{label: "d2f04db", url: "https://github.com/brnrdog/xote/commit/d2f04dbe630388aa75a369c3785c4aa4ff2050b3"}],
          }
        ],
      },
      {
        title: "BREAKING CHANGES",
        changes: [
          {
            scope: None,
            text: [
              View.text("Computed.make now returns Core.t<'a> instead of (Core.t<'a>, unit => unit). Use Computed.dispose(signal) for manual disposal instead of calling the dispose function from the tuple. Before: let (signal, dispose) = Computed.make(() => ...) dispose() After: let signal = Computed.make(() => ...) Computed.dispose(signal) This aligns better with common patterns in other reactive libraries like Solid and Preact, providing a cleaner and more intuitive API.")
            ],
            refs: [],
          },
          {
            scope: None,
            text: [
              View.text("Effect.run now expects functions to return option<unit => unit> instead of unit. All existing effects must be updated to return None or Some(cleanupFn).")
            ],
            refs: [],
          }
        ],
      }
    ],
  },
  {
    version: "2.0.0",
    url: "https://github.com/brnrdog/xote/compare/v1.3.3...v2.0.0",
    date: "2025-11-27",
    formattedDate: "Nov 27, 2025",
    id: "release-2-0-0-2025-11-27",
    prerelease: false,
    sections: [
      {
        title: "",
        changes: [
          {
            scope: None,
            text: [
              View.text("chore!: upgrade to ReScript v12.0.0 ("),
              <a href="https://github.com/brnrdog/xote/commit/b20b9e032cd62d6d2e1eea83adbe53ab412cea94" target="_blank"> {View.text("b20b9e0")} </a>,
              View.text("), closes "),
              <a href="https://github.com/brnrdog/xote/issues/function" target="_blank"> {View.text("#function")} </a>,
              View.text(" "),
              <a href="https://github.com/brnrdog/xote/issues/object" target="_blank"> {View.text("#object")} </a>,
              View.text(" "),
              <a href="https://github.com/brnrdog/xote/issues/function" target="_blank"> {View.text("#function")} </a>
            ],
            refs: [],
          }
        ],
      },
      {
        title: "BREAKING CHANGES",
        changes: [
          {
            scope: None,
            text: [
              View.text("ReScript v12 introduces API changes that affect the typeof operator and configuration fields. Projects upgrading will need to: - Update rescript.json to use 'dependencies' and 'compiler-flags' instead of 'bs-dependencies' and 'bsc-flags'")
            ],
            refs: [],
          }
        ],
      }
    ],
  },
  {
    version: "1.3.3",
    url: "https://github.com/brnrdog/xote/compare/v1.3.2...v1.3.3",
    date: "2025-11-26",
    formattedDate: "Nov 26, 2025",
    id: "release-1-3-3-2025-11-26",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("implement topological ordering to prevent scheduling glitches")
            ],
            refs: [{label: "51f1a8c", url: "https://github.com/brnrdog/xote/commit/51f1a8ca592c8e722e0a05d37017604e40547062"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.3.2",
    url: "https://github.com/brnrdog/xote/compare/v1.3.1...v1.3.2",
    date: "2025-11-24",
    formattedDate: "Nov 24, 2025",
    id: "release-1-3-2-2025-11-24",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("automatic disposal of reactive observers to prevent memory leaks ("),
              <a href="https://github.com/brnrdog/xote/commit/befae8116f47347179f8d5bdfe6355b40942c79a" target="_blank"> {View.text("befae81")} </a>,
              View.text("), closes "),
              <a href="https://github.com/brnrdog/xote/issues/7" target="_blank"> {View.text("#7")} </a>
            ],
            refs: [],
          },
          {
            scope: None,
            text: [
              View.text("preserve signal fragment effect when disposing children")
            ],
            refs: [{label: "c3d530c", url: "https://github.com/brnrdog/xote/commit/c3d530ccc344d58cc73aa209bbe02f0b87e7cd9a"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.3.1",
    url: "https://github.com/brnrdog/xote/compare/v1.3.0...v1.3.1",
    date: "2025-11-21",
    formattedDate: "Nov 21, 2025",
    id: "release-1-3-1-2025-11-21",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("preserve observer tracking context during nested execution")
            ],
            refs: [{label: "afb9450", url: "https://github.com/brnrdog/xote/commit/afb945059ca026072f777859e781fd086e88189b"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.3.0",
    url: "https://github.com/brnrdog/xote/compare/v1.2.1...v1.3.0",
    date: "2025-11-21",
    formattedDate: "Nov 21, 2025",
    id: "release-1-3-0-2025-11-21",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add support to data attributes in Xote.JSX")
            ],
            refs: [{label: "903c265", url: "https://github.com/brnrdog/xote/commit/903c265352d5344118dd8a66d65b2ec20ab57042"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.2.1",
    url: "https://github.com/brnrdog/xote/compare/v1.2.0...v1.2.1",
    date: "2025-11-19",
    formattedDate: "Nov 19, 2025",
    id: "release-1-2-1-2025-11-19",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("enable reactivity for JSX element attributes")
            ],
            refs: [{label: "0ea7235", url: "https://github.com/brnrdog/xote/commit/0ea72353a6a6d26b38e1f7c1058d95f843d3e898"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.2.0",
    url: "https://github.com/brnrdog/xote/compare/v1.1.0...v1.2.0",
    date: "2025-11-19",
    formattedDate: "Nov 19, 2025",
    id: "release-1-2-0-2025-11-19",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("bump version to 1.2.0")
            ],
            refs: [{label: "19425d9", url: "https://github.com/brnrdog/xote/commit/19425d976e540381ac85736b46b8a994c57f4fa8"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.1...v1.1.0",
    date: "2025-11-18",
    formattedDate: "Nov 18, 2025",
    id: "release-1-1-0-2025-11-18",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("revert keyed list reconciliation")
            ],
            refs: [{label: "60aa2a0", url: "https://github.com/brnrdog/xote/commit/60aa2a093fdae4d26558c4d4aec4e2e9f9384964"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add JSX support with generic transform")
            ],
            refs: [{label: "d71175d", url: "https://github.com/brnrdog/xote/commit/d71175dc0a2680996b7725ba3c781cdd8c706b49"}],
          },
          {
            scope: None,
            text: [
              View.text("change className to class in JSX props")
            ],
            refs: [{label: "2515242", url: "https://github.com/brnrdog/xote/commit/251524249328cf06f78dfdfbcf348f1552e88e9f"}],
          },
          {
            scope: None,
            text: [
              View.text("implement keyed list reconciliation for efficient updates")
            ],
            refs: [{label: "dd9c0b8", url: "https://github.com/brnrdog/xote/commit/dd9c0b8c5d5473b1bdfc0aa8acc1dec8cec21999"}],
          },
          {
            scope: None,
            text: [
              View.text("standardize JSX component naming convention")
            ],
            refs: [{label: "f683316", url: "https://github.com/brnrdog/xote/commit/f68331613466a94004d34299b21b26c43bf43c0b"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.0.1",
    url: "https://github.com/brnrdog/xote/compare/v1.0.0...v1.0.1",
    date: "2025-11-02",
    formattedDate: "Nov 2, 2025",
    id: "release-1-0-1-2025-11-02",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("optimize build configuration and reduce bundle size ("),
              <a href="https://github.com/brnrdog/xote/commit/f9e50dc9ac713135de5cba589e49c4ff03fbaeb0" target="_blank"> {View.text("f9e50dc")} </a>,
              View.text(") # 1.0.0 (2025-11-02)")
            ],
            refs: [],
          }
        ],
      },
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("adjust build configuration and dist output")
            ],
            refs: [{label: "5dcca3b", url: "https://github.com/brnrdog/xote/commit/5dcca3beb89e25aa55c6fba7a4b67c59661d75bd"}],
          },
          {
            scope: None,
            text: [
              View.text("improve signal reactivity and add todo styling")
            ],
            refs: [{label: "495f0bb", url: "https://github.com/brnrdog/xote/commit/495f0bb52eaa8de89214f957f30b078f07029569"}],
          },
          {
            scope: None,
            text: [
              View.text("rescript build in release workflow")
            ],
            refs: [{label: "9b2fb19", url: "https://github.com/brnrdog/xote/commit/9b2fb1948b4f168de66da5fd96282ddcf82d8dca"}],
          },
          {
            scope: None,
            text: [
              View.text("version bump")
            ],
            refs: [{label: "2794ae6", url: "https://github.com/brnrdog/xote/commit/2794ae697f5c3448d946b9fc5c7d1c0defa8be1a"}],
          },
          {
            scope: None,
            text: [
              View.text("version bump for release")
            ],
            refs: [{label: "72fb74f", url: "https://github.com/brnrdog/xote/commit/72fb74f2cf3d4a2389daf5363457d5d7ad4eaed1"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add Component system with automatic reactivity")
            ],
            refs: [{label: "38815ed", url: "https://github.com/brnrdog/xote/commit/38815ed3d1400c5511b790011d60081b317a69ac"}],
          },
          {
            scope: None,
            text: [
              View.text("add demo")
            ],
            refs: [{label: "cf3faf3", url: "https://github.com/brnrdog/xote/commit/cf3faf34c07d85a60d78d5f9539d2e2132f3b85a"}],
          },
          {
            scope: None,
            text: [
              View.text("bump version")
            ],
            refs: [{label: "5ac8b19", url: "https://github.com/brnrdog/xote/commit/5ac8b19a954d3fa10ce0f0d866f86fb74e3ad456"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("set reactivity to component element attributes")
            ],
            refs: [{label: "57217e3", url: "https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("simplify signalText to accept function directly")
            ],
            refs: [{label: "9a9d551", url: "https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("unify attrs and signalAttrs into single attrs parameter")
            ],
            refs: [{label: "d8942d9", url: "https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc"}],
          },
          {
            scope: None,
            text: [
              View.text("minimal signal implementation based on the TC39 proposal")
            ],
            refs: [{label: "9b78d0b", url: "https://github.com/brnrdog/xote/commit/9b78d0b62ba21c953d909459036246f334b6613e"}],
          },
          {
            scope: Some("router"),
            text: [
              View.text("add signal-based routing with pattern matching")
            ],
            refs: [{label: "7bab79e", url: "https://github.com/brnrdog/xote/commit/7bab79eb46fc35c9f90d09391bb71209485aa1d5"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0",
    date: "2025-11-02",
    formattedDate: "Nov 2, 2025",
    id: "release-1-1-0-2025-11-02",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("set reactivity to component element attributes")
            ],
            refs: [{label: "57217e3", url: "https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("simplify signalText to accept function directly")
            ],
            refs: [{label: "9a9d551", url: "https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("unify attrs and signalAttrs into single attrs parameter")
            ],
            refs: [{label: "d8942d9", url: "https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc"}],
          },
          {
            scope: Some("router"),
            text: [
              View.text("add signal-based routing with pattern matching")
            ],
            refs: [{label: "7bab79e", url: "https://github.com/brnrdog/xote/commit/7bab79eb46fc35c9f90d09391bb71209485aa1d5"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0",
    date: "2025-11-01",
    formattedDate: "Nov 1, 2025",
    id: "release-1-1-0-2025-11-01",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("set reactivity to component element attributes")
            ],
            refs: [{label: "57217e3", url: "https://github.com/brnrdog/xote/commit/57217e3951303033f4e29801bb24c85bc3313ad1"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("simplify signalText to accept function directly")
            ],
            refs: [{label: "9a9d551", url: "https://github.com/brnrdog/xote/commit/9a9d551b0f080ed2321597f9aeb85b41153890d3"}],
          },
          {
            scope: Some("component"),
            text: [
              View.text("unify attrs and signalAttrs into single attrs parameter")
            ],
            refs: [{label: "d8942d9", url: "https://github.com/brnrdog/xote/commit/d8942d9b4522a2f232d37970b8f55a8883999ecc"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.1.0",
    url: "https://github.com/brnrdog/xote/compare/v1.0.3...v1.1.0",
    date: "2025-10-31",
    formattedDate: "Oct 31, 2025",
    id: "release-1-1-0-2025-10-31",
    prerelease: false,
    sections: [
      {
        title: "Features",
        changes: [
          {
            scope: Some("component"),
            text: [
              View.text("add support to a tags")
            ],
            refs: [{label: "8ea09c1", url: "https://github.com/brnrdog/xote/commit/8ea09c19aaed9383b80d6cd15e61ae75113c6d73"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.0.3",
    url: "https://github.com/brnrdog/xote/compare/v1.0.2...v1.0.3",
    date: "2025-10-31",
    formattedDate: "Oct 31, 2025",
    id: "release-1-0-3-2025-10-31",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("adjust build configuration and dist output")
            ],
            refs: [{label: "5dcca3b", url: "https://github.com/brnrdog/xote/commit/5dcca3beb89e25aa55c6fba7a4b67c59661d75bd"}],
          },
          {
            scope: None,
            text: [
              View.text("rescript build in release workflow")
            ],
            refs: [{label: "9b2fb19", url: "https://github.com/brnrdog/xote/commit/9b2fb1948b4f168de66da5fd96282ddcf82d8dca"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.0.2",
    url: "https://github.com/brnrdog/xote/compare/v1.0.1...v1.0.2",
    date: "2025-10-30",
    formattedDate: "Oct 30, 2025",
    id: "release-1-0-2-2025-10-30",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("version bump")
            ],
            refs: [{label: "2794ae6", url: "https://github.com/brnrdog/xote/commit/2794ae697f5c3448d946b9fc5c7d1c0defa8be1a"}],
          }
        ],
      }
    ],
  },
  {
    version: "1.0.1",
    url: "https://github.com/brnrdog/xote/compare/v1.0.0...v1.0.1",
    date: "2025-10-30",
    formattedDate: "Oct 30, 2025",
    id: "release-1-0-1-2025-10-30",
    prerelease: false,
    sections: [
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("version bump for release ("),
              <a href="https://github.com/brnrdog/xote/commit/72fb74f2cf3d4a2389daf5363457d5d7ad4eaed1" target="_blank"> {View.text("72fb74f")} </a>,
              View.text(") # 1.0.0 (2025-10-30)")
            ],
            refs: [],
          }
        ],
      },
      {
        title: "Bug Fixes",
        changes: [
          {
            scope: None,
            text: [
              View.text("improve signal reactivity and add todo styling")
            ],
            refs: [{label: "495f0bb", url: "https://github.com/brnrdog/xote/commit/495f0bb52eaa8de89214f957f30b078f07029569"}],
          }
        ],
      },
      {
        title: "Features",
        changes: [
          {
            scope: None,
            text: [
              View.text("add Component system with automatic reactivity")
            ],
            refs: [{label: "38815ed", url: "https://github.com/brnrdog/xote/commit/38815ed3d1400c5511b790011d60081b317a69ac"}],
          },
          {
            scope: None,
            text: [
              View.text("add demo")
            ],
            refs: [{label: "cf3faf3", url: "https://github.com/brnrdog/xote/commit/cf3faf34c07d85a60d78d5f9539d2e2132f3b85a"}],
          },
          {
            scope: None,
            text: [
              View.text("minimal signal implementation based on the TC39 proposal")
            ],
            refs: [{label: "9b78d0b", url: "https://github.com/brnrdog/xote/commit/9b78d0b62ba21c953d909459036246f334b6613e"}],
          }
        ],
      }
    ],
  }
]
