/**
 * Generates sourcemaps for ReScript-compiled JavaScript files.
 *
 * Since ReScript doesn't natively support sourcemap generation, this script
 * creates sourcemaps by matching top-level declarations (functions, let bindings)
 * between .res and .js files by name, then mapping lines proportionally within
 * each declaration block.
 *
 * Adapted from https://github.com/brnrdog/zekr
 *
 * Usage: node scripts/generate-sourcemaps.mjs [dir...]
 *   Defaults to scanning "src" if no directories are specified.
 */

import { SourceMapGenerator } from "source-map";
import fs from "fs";
import path from "path";

/**
 * Extract top-level declarations from a ReScript (.res) file.
 * Returns an array of { name, startLine, endLine } objects.
 */
function parseResDeclarations(source) {
  const lines = source.split("\n");
  const declarations = [];
  let current = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    // Match top-level let bindings: `let name = ...`
    const letMatch = line.match(/^let (\w+)\s*=/);
    // Match module declarations: `module Name = {`
    const moduleMatch = line.match(/^module (\w+)\s*=/);

    if (letMatch || moduleMatch) {
      if (current) {
        current.endLine = lineNum - 1;
        declarations.push(current);
      }
      const name = letMatch ? letMatch[1] : moduleMatch[1];
      current = { name, startLine: lineNum, endLine: lines.length };
    }
  }

  if (current) {
    current.endLine = lines.length;
    declarations.push(current);
  }

  return declarations;
}

/**
 * Extract top-level declarations from a compiled JavaScript (.js) file.
 * Returns an array of { name, startLine, endLine } objects.
 */
function parseJsDeclarations(source) {
  const lines = source.split("\n");
  const declarations = [];
  let current = null;

  for (let i = 0; i < lines.length; i++) {
    const line = lines[i];
    const lineNum = i + 1;

    // Match function declarations: `function name(` or `async function name(`
    const funcMatch = line.match(/^(?:async\s+)?function (\w+)\s*\(/);
    // Match let/var bindings: `let name = {` or `let name = [`
    const letMatch = line.match(/^let (\w+)\s*=/);

    if (funcMatch || letMatch) {
      if (current) {
        current.endLine = lineNum - 1;
        declarations.push(current);
      }
      const name = funcMatch ? funcMatch[1] : letMatch[1];
      current = { name, startLine: lineNum, endLine: lines.length };
    }
  }

  if (current) {
    current.endLine = lines.length;
    declarations.push(current);
  }

  return declarations;
}

/**
 * Generate a sourcemap for a single .js/.res file pair.
 */
function generateSourceMap(jsPath, resPath) {
  const jsSource = fs.readFileSync(jsPath, "utf-8");
  const resSource = fs.readFileSync(resPath, "utf-8");

  const jsLines = jsSource.split("\n");
  const resLines = resSource.split("\n");

  const jsDecls = parseJsDeclarations(jsSource);
  const resDecls = parseResDeclarations(resSource);

  // Build a lookup of ReScript declarations by name
  const resByName = new Map();
  for (const decl of resDecls) {
    resByName.set(decl.name, decl);
  }

  const resFileName = path.basename(resPath);
  const jsFileName = path.basename(jsPath);

  const generator = new SourceMapGenerator({
    file: jsFileName,
  });

  // Embed the ReScript source content so tools can display it
  generator.setSourceContent(resFileName, resSource);

  // Track which JS lines have been mapped
  const mappedJsLines = new Set();

  // For each JS declaration, find the matching ReScript declaration and map lines
  for (const jsDecl of jsDecls) {
    const resDecl = resByName.get(jsDecl.name);
    if (!resDecl) continue;

    const jsLen = jsDecl.endLine - jsDecl.startLine + 1;
    const resLen = resDecl.endLine - resDecl.startLine + 1;

    for (let offset = 0; offset < jsLen; offset++) {
      const jsLine = jsDecl.startLine + offset;
      // Map proportionally into the ReScript range
      const resOffset = Math.round((offset / Math.max(jsLen - 1, 1)) * (resLen - 1));
      const resLine = resDecl.startLine + resOffset;

      mappedJsLines.add(jsLine);
      generator.addMapping({
        generated: { line: jsLine, column: 0 },
        original: { line: resLine, column: 0 },
        source: resFileName,
      });
    }
  }

  // Map remaining JS lines (imports, exports, etc.) to the nearest ReScript line
  for (let jsLine = 1; jsLine <= jsLines.length; jsLine++) {
    if (mappedJsLines.has(jsLine)) continue;

    const line = jsLines[jsLine - 1];
    // Skip empty lines, comments, and the export block
    if (
      !line.trim() ||
      line.startsWith("//") ||
      line.startsWith("import ") ||
      line.startsWith("export ")
    ) {
      continue;
    }

    // Find the closest mapped line and use its mapping
    let closestMapped = null;
    let closestDist = Infinity;
    for (const mapped of mappedJsLines) {
      const dist = Math.abs(mapped - jsLine);
      if (dist < closestDist) {
        closestDist = dist;
        closestMapped = mapped;
      }
    }

    if (closestMapped !== null) {
      // Look up what the closest mapped line points to - approximate with proportional mapping
      const proportion = jsLine / jsLines.length;
      const resLine = Math.max(1, Math.min(resLines.length, Math.round(proportion * resLines.length)));

      generator.addMapping({
        generated: { line: jsLine, column: 0 },
        original: { line: resLine, column: 0 },
        source: resFileName,
      });
    }
  }

  return generator.toString();
}

/**
 * Find all .js/.res file pairs in the given directories and generate sourcemaps.
 */
function processDirectory(dir) {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  let count = 0;

  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      count += processDirectory(fullPath);
      continue;
    }

    // Support both .js (ReScript <12) and .res.mjs (ReScript 12+) output formats
    const isResMjs = entry.name.endsWith(".res.mjs");
    const isJs = entry.name.endsWith(".js") && !entry.name.endsWith(".res.mjs");
    if (!isResMjs && !isJs) continue;

    const resPath = isResMjs
      ? fullPath.replace(/\.res\.mjs$/, ".res")
      : fullPath.replace(/\.js$/, ".res");
    if (!fs.existsSync(resPath)) continue;

    const sourceMap = generateSourceMap(fullPath, resPath);
    const mapPath = fullPath + ".map";

    fs.writeFileSync(mapPath, sourceMap);

    // Append sourceMappingURL to the JS file if not already present
    const jsContent = fs.readFileSync(fullPath, "utf-8");
    const sourceMappingComment = `//# sourceMappingURL=${entry.name}.map`;
    if (!jsContent.includes("sourceMappingURL")) {
      fs.writeFileSync(fullPath, jsContent.trimEnd() + "\n" + sourceMappingComment + "\n");
    }

    count++;
  }

  return count;
}

// Main
const dirs = process.argv.slice(2);
if (dirs.length === 0) {
  dirs.push("src");
}

let total = 0;
for (const dir of dirs) {
  if (!fs.existsSync(dir)) {
    console.error(`Directory not found: ${dir}`);
    process.exit(1);
  }
  total += processDirectory(dir);
}

console.log(`Generated ${total} sourcemap(s)`);
