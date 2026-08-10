#!/bin/sh
# Links the toolchain and Xote from the repo root into this standalone example
# so `npm run build` / `npm run verify` can resolve them. Idempotent.
set -e
cd "$(dirname "$0")"
mkdir -p node_modules node_modules/@rescript

link() {
  # link <target> <name>  (relative to example/node_modules)
  ln -sfn "$1" "node_modules/$2"
}

link ../../..                         xote
link ../..                            xote-tracked-ppx
link ../../../node_modules/rescript   rescript
link ../../../node_modules/rescript-signals rescript-signals
link ../../../node_modules/jsdom      jsdom
# @rescript/core and the platform binaries live under the @rescript scope
ln -sfn ../../../../node_modules/@rescript/core          node_modules/@rescript/core
ln -sfn ../../../../node_modules/@rescript/linux-x64     node_modules/@rescript/linux-x64 2>/dev/null || true

echo "example/ linked. Now: sh ../build.sh && npm run build && npm run verify"
