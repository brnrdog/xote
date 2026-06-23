# Releasing

Releases are automated with [semantic-release](https://semantic-release.gitbook.io/) and triggered manually from the **Release** workflow (**Actions → Release → Run workflow**). The version is derived from the [Conventional Commit](https://www.conventionalcommits.org/) messages since the last release; semantic-release acts on whichever branch you run the workflow from. (`package.json` stays at `0.0.0` — it is not the source of truth.)

| Channel | Branch | npm dist-tag | Install |
| --- | --- | --- | --- |
| Stable | `main` | `latest` | `npm install xote` |
| Beta | `beta` | `beta` | `npm install xote@beta` |

- **Stable:** run the workflow on `main` → publishes the next version (e.g. `6.5.0`) under `latest`.
- **Beta (testing):** run the workflow on `beta` → publishes a pre-release (e.g. `6.5.0-beta.1`) under the `beta` dist-tag. This never moves `latest`, so only `npm install xote@beta` picks it up.

When a beta is ready to ship, merge `beta` into `main` and run the workflow on `main` to cut the stable release.
