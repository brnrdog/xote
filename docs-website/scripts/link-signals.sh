#!/bin/sh
# Links a rescript-signals checkout that has Signals.Debug (the devtools debug
# hooks, not yet released) into this site and into the Xote package it builds
# against, then rebuilds both. Leaves package.json and the lockfiles alone; a
# plain `npm install` in either directory puts the published release back.
#
#   npm run devtools:link
#   RESCRIPT_SIGNALS=/path/to/rescript-signals npm run devtools:link
set -e
cd "$(dirname "$0")/.."

checkout="${RESCRIPT_SIGNALS:-../../rescript-signals}"
package="$checkout/packages/rescript-signals"
if [ ! -f "$package/src/signals/Debug.res" ]; then
  echo "no Signals.Debug under $package"
  echo "clone the branch with the hooks next to this repository, or point RESCRIPT_SIGNALS at it:"
  echo "  git clone -b brnrdog/nice-pascal-9c7ixn https://github.com/brnrdog/rescript-signals"
  exit 1
fi
package="$(cd "$package" && pwd)"

echo "linking $package"
# npm rewrites a yarn.lock it finds even with --no-save; keep this one as it was.
cp yarn.lock yarn.lock.devtools-link
trap 'mv yarn.lock.devtools-link yarn.lock' EXIT
(cd .. && npm install --no-save --no-audit --no-fund "$package")
npm install --no-save --no-audit --no-fund "$package"

echo "rebuilding Xote and the site"
(cd .. && npx rescript)
npm run ppx:build
npx rescript
echo "done: npm run dev:devtools, or npm run lens -- render CounterDemo"
