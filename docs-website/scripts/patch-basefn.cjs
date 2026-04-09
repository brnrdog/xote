#!/usr/bin/env node

/**
 * Patch basefn's rescript.json to fix JSX module resolution.
 *
 * basefn 1.11.0 uses "module": "Xote.XoteJSX" in its JSX config, but the
 * ReScript compiler doesn't resolve dot-qualified JSX module names. This
 * script rewrites it to use "XoteJSX" with "-open Xote" in compiler flags,
 * matching the pattern used by the docs-website itself.
 */

const fs = require('fs');
const path = require('path');

const configPath = path.join(__dirname, '../node_modules/basefn/rescript.json');

if (!fs.existsSync(configPath)) {
  // basefn not installed yet — nothing to patch
  process.exit(0);
}

const config = JSON.parse(fs.readFileSync(configPath, 'utf8'));

if (config.jsx && config.jsx.module === 'Xote.XoteJSX') {
  config.jsx.module = 'XoteJSX';

  const flags = config['compiler-flags'] || [];
  if (!flags.includes('-open Xote')) {
    flags.push('-open Xote');
  }
  config['compiler-flags'] = flags;

  fs.writeFileSync(configPath, JSON.stringify(config, null, 2) + '\n');
  console.log('Patched basefn rescript.json: JSX module → XoteJSX, added -open Xote');
}
