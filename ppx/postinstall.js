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
 *   1. No prebuilt binary for this platform (or it does not run here — musl
 *      libc, emulation, damaged file), but ocamlopt is available: compile
 *      from the bundled ppx.ml source (build.sh).
 *   2. Otherwise: print instructions and exit 0. The install never fails —
 *      not even on an unexpected error, hence the top-level try/catch — since
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

/* The linux prebuilts are glibc-linked; on musl (e.g. Alpine) they would copy
 * fine and then die at exec time inside the ReScript build. Same probe
 * esbuild uses: the report header only carries glibcVersionRuntime on glibc. */
function isMuslLinux() {
  if (process.platform !== 'linux') return false;
  try {
    const report = process.report && process.report.getReport();
    return !(report && report.header && report.header.glibcVersionRuntime);
  } catch (_err) {
    return false;
  }
}

/* `ppx --help` exits 0 without needing an AST: proves the binary actually
 * loads and executes on this host (arch, libc, DLLs) — a copy can succeed
 * where an exec cannot. */
function runs(bin) {
  const run = spawnSync(bin, ['--help'], { stdio: 'ignore' });
  return !run.error && run.status === 0;
}

function installPrebuilt() {
  if (!fs.existsSync(prebuilt)) return false;
  if (isMuslLinux()) {
    console.warn(
      `xote: the prebuilt ${target} ppx binary is glibc-linked and this system uses musl; trying a source build instead.`,
    );
    return false;
  }
  fs.copyFileSync(prebuilt, dest);
  if (!isWindows) fs.chmodSync(dest, 0o755);
  if (!runs(dest)) {
    console.warn(`xote: prebuilt ppx binary for ${target} does not execute on this system; trying a source build instead.`);
    try {
      fs.unlinkSync(dest);
    } catch (_err) {
      /* leave a non-executing copy behind rather than fail the install */
    }
    return false;
  }
  console.log(`xote: installed prebuilt ppx binary for ${target}`);
  return true;
}

function buildFromSource() {
  const probe = spawnSync('ocamlopt', ['-version'], { stdio: 'ignore', shell: isWindows });
  if (probe.error || probe.status !== 0) return false;
  console.log(`xote: no usable prebuilt ppx binary for ${target}, compiling from source...`);
  const build = spawnSync('sh', [path.join(ppxDir, 'build.sh')], { stdio: 'inherit' });
  if (build.error) {
    /* stock Windows has ocamlopt via opam but no `sh` — say so instead of
     * silently falling through to the generic warning */
    console.warn('xote: build.sh needs a POSIX shell (`sh`); run it from Git Bash/WSL/Cygwin.');
    return false;
  }
  return build.status === 0 && fs.existsSync(dest) && runs(dest);
}

function main() {
  if (!installPrebuilt() && !buildFromSource()) {
    console.warn(
      [
        `xote: no ppx binary available for ${target}.`,
        'The @xote.component annotation needs it; the rest of Xote does not.',
        'To use it, install an OCaml compiler (ocamlopt) and run:',
        '  sh node_modules/xote/ppx/build.sh',
        'Supported prebuilt platforms: linux-x64, linux-arm64, darwin-x64, darwin-arm64, win32-x64 (glibc on linux).',
      ].join('\n'),
    );
  }
}

try {
  main();
} catch (err) {
  /* never fail the consumer's install over the optional ppx */
  console.warn(`xote: ppx postinstall failed (${err && err.message ? err.message : err}); continuing without the ppx binary.`);
  console.warn('To set it up manually: sh node_modules/xote/ppx/build.sh (needs ocamlopt).');
}
