/* prepublishOnly guard: refuse to publish a tarball without the prebuilt ppx
 * binaries. They exist only in the release workflow (built per-platform and
 * downloaded into ppx/bin/), so a manual `npm publish` from a dev checkout
 * would otherwise silently ship a package where every consumer without an
 * OCaml toolchain gets the degraded no-ppx path. */
import { existsSync, statSync } from 'node:fs';

const targets = ['linux-x64', 'linux-arm64', 'darwin-x64', 'darwin-arm64', 'win32-x64'];
const missing = targets.filter(t => {
  const p = `ppx/bin/ppx-${t}.exe`;
  return !existsSync(p) || statSync(p).size === 0;
});

if (missing.length > 0) {
  console.error(
    `xote: refusing to publish without prebuilt ppx binaries (missing: ${missing.join(', ')}).\n` +
      'Publish via .github/workflows/release.yml, which builds them per platform and downloads them into ppx/bin/.',
  );
  process.exit(1);
}
console.log('xote: all prebuilt ppx binaries present.');
