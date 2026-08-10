#!/bin/sh
# Compiles the fine-grained @tracked ppx to a native binary using the system
# OCaml compiler. ReScript 12 hands a ppx an OCaml 4.06 parsetree; ppx.ml
# vendors those exact AST types, so the only build dependency is ocamlopt
# (any recent OCaml works — tested with 4.14).
set -e
cd "$(dirname "$0")"
ocamlopt -w -a-31 ppx.ml -o ppx
rm -f ppx.cmi ppx.cmx ppx.o
echo "built $(pwd)/ppx"
