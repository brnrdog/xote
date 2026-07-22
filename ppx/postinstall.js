#!/usr/bin/env node
/*
 * Selects the prebuilt @xote.component ppx binary for the current platform.
 *
 * The npm package ships one native binary per supported platform under
 * ppx/bin/ (built in CI, see .github/workflows/ppx-binaries.yml). This script
 * copies the matching one to ppx/ppx (ppx/ppx.exe on Windows), which is the
 * path consumers reference from their rescript.json:
 *
 *   "ppx-flags": ["xote/ppx/ppx"]
 *
 * Fallbacks, in order:
 *   1. No prebuilt binary for this platform, but ocamlopt is available:
 *      compile from the bundled ppx.ml source (build.sh).
 *   2. Otherwise: print instructions and exit 0. The install never fails —
 *      the ppx is only needed by projects that list it in their own
 *      ppx-flags, and Xote's published library sources compile without it.
 */
'use strict';

const fs = require('fs');
const path = require('path');
const { spawnSync } = require('child_process');

const ppxDir = __dirname;
const isWindows = process.platform === 'win32';
const target = `${process.platform}-${process.arch}`;
const prebuilt = path.join(ppxDir, 'bin', `ppx-${target}.exe`);
const dest = path.join(ppxDir, isWindows ? 'ppx.exe' : 'ppx');

function installPrebuilt() {
  if (!fs.existsSync(prebuilt)) return false;
  fs.copyFileSync(prebuilt, dest);
  if (!isWindows) fs.chmodSync(dest, 0o755);
  console.log(`xote: installed prebuilt ppx binary for ${target}`);
  return true;
}

function buildFromSource() {
  const probe = spawnSync('ocamlopt', ['-version'], { stdio: 'ignore', shell: isWindows });
  if (probe.error || probe.status !== 0) return false;
  console.log(`xote: no prebuilt ppx binary for ${target}, compiling from source...`);
  const build = spawnSync('sh', [path.join(ppxDir, 'build.sh')], { stdio: 'inherit' });
  return build.status === 0 && fs.existsSync(dest);
}

if (!installPrebuilt() && !buildFromSource()) {
  console.warn(
    [
      `xote: no ppx binary available for ${target}.`,
      'The @xote.component annotation needs it; the rest of Xote does not.',
      'To use it, install an OCaml compiler (ocamlopt) and run:',
      '  sh node_modules/xote/ppx/build.sh',
      'Supported prebuilt platforms: linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64.',
    ].join('\n'),
  );
}
