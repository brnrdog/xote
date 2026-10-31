#!/bin/sh
# Links the toolchain and Xote from the repo root into this fixture, and builds
# the ppx it compiles through, so the lens tests run against the repo's own
# Xote. Idempotent. Needs ocamlopt (for the ppx), like `npm run ppx:test`.
set -e
cd "$(dirname "$0")"
mkdir -p node_modules node_modules/@rescript

link() {
  ln -sfn "$1" "node_modules/$2"
}

link ../../../..                         xote
link ../../../../ppx                     xote-tracked-ppx
link ../../../../node_modules/rescript   rescript
link ../../../../node_modules/rescript-signals rescript-signals
for platform in ../../../../node_modules/@rescript/*; do
  ln -sfn "../$platform" "node_modules/@rescript/$(basename "$platform")"
done

sh ../../../ppx/build.sh >/dev/null
