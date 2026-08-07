#!/bin/sh
# Links the toolchain and the repo itself into this fixture so `rescript build`
# resolves `xote` the way an installed consumer would. Idempotent.
#
# The point of the fixture is its rescript.json: it declares only `["xote"]`,
# as the README tells consumers to. rescript-signals is deliberately NOT linked
# as a declared dependency, so any public signature that leaks a type owned by
# it fails to compile here.
set -e
cd "$(dirname "$0")"
root=../..

mkdir -p node_modules node_modules/@rescript

ln -sfn ../$root                          node_modules/xote
ln -sfn ../$root/node_modules/rescript     node_modules/rescript
ln -sfn ../../$root/node_modules/@rescript/core node_modules/@rescript/core

echo "tests/consumer linked. Now: npx rescript build"
