#!/bin/sh
# Compiles the fine-grained @xote.component ppx to a native binary using the
# system OCaml compiler. ReScript 12 hands a ppx an OCaml 4.06 parsetree;
# ppx.ml vendors those exact AST types, so the only build dependency is
# ocamlopt (any recent OCaml works — tested with 4.14).
#
# Usage: build.sh [output-path]
#   output-path is relative to this directory and defaults to ./ppx.
#   CI passes bin/ppx-<platform>-<arch>.exe to produce the prebuilt binaries
#   shipped in the npm package.
set -e
cd "$(dirname "$0")"
out="${1:-ppx}"
mkdir -p "$(dirname "$out")"
ocamlopt -w -a-31 ppx.ml -o "$out"
rm -f ppx.cmi ppx.cmx ppx.o
echo "built $(pwd)/$out"
