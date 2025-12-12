#!/usr/bin/env node

/**
 * Generate ReScript documentation components from Markdown files
 *
 * This script converts markdown files in content/ to ReScript
 * components in src/docs/ with proper Xote JSX syntax.
 */

const fs = require('fs');
const path = require('path');
const { glob } = require('glob');

const CONTENT_DIR = path.join(__dirname, '../content');
const OUTPUT_DIR = path.join(__dirname, '../src/docs');

// Mapping from markdown file paths to output component names
const FILE_MAPPING = {
  'getting-started/introduction.md': 'IntroDoc.res',
  'core-concepts/signals.md': 'SignalsDoc.res',
  'core-concepts/computed.md': 'ComputedDoc.res',
  'core-concepts/effects.md': 'EffectsDoc.res',
  'core-concepts/batching.md': 'BatchingDoc.res',
  'components/overview.md': 'ComponentsDoc.res',
  'router/overview.md': 'RouterDoc.res',
  'api-reference/signals.md': 'ApiSignalsDoc.res',
  'comparisons/react.md': 'ReactComparisonDoc.res',
  'advanced/technical-overview.md': 'TechnicalOverviewDoc.res'
};

/**
 * Escape special characters for ReScript strings
 */
function escapeForReScript(text) {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/`/g, '\\`')
    .replace(/\$/g, '\\$');
}

/**
 * Convert markdown to Xote component nodes
 */
function convertMarkdownToNodes(markdown) {
  const lines = markdown.split('\n');
  const nodes = [];
  let i = 0;
  let inCodeBlock = false;
  let codeBlockContent = [];
  let codeBlockLang = '';
  let inBlockquote = false;
  let blockquoteContent = [];
  let inTable = false;
  let tableLines = [];

  while (i < lines.length) {
    const line = lines[i];

    // Code blocks
    if (line.startsWith('```')) {
      if (!inCodeBlock) {
        inCodeBlock = true;
        codeBlockLang = line.slice(3).trim();
        codeBlockContent = [];
      } else {
        // End of code block
        nodes.push({
          type: 'pre',
          children: [{
            type: 'code',
            text: codeBlockContent.join('\n')
          }]
        });
        inCodeBlock = false;
        codeBlockContent = [];
      }
      i++;
      continue;
    }

    if (inCodeBlock) {
      codeBlockContent.push(line);
      i++;
      continue;
    }

    // Blockquotes (info boxes)
    if (line.startsWith('> ')) {
      if (!inBlockquote) {
        inBlockquote = true;
        blockquoteContent = [];
      }
      blockquoteContent.push(line.slice(2));
      i++;
      continue;
    } else if (inBlockquote && line.trim() === '') {
      // Continue blockquote on empty line
      i++;
      continue;
    } else if (inBlockquote) {
      // End of blockquote
      nodes.push({ type: 'blockquote', text: blockquoteContent.join('\n') });
      inBlockquote = false;
      blockquoteContent = [];
      // Don't increment i, process this line
      continue;
    }

    // Tables
    if (line.startsWith('|')) {
      if (!inTable) {
        inTable = true;
        tableLines = [];
      }
      tableLines.push(line);
      i++;
      continue;
    } else if (inTable) {
      // End of table
      nodes.push({ type: 'table', lines: tableLines });
      inTable = false;
      tableLines = [];
      // Don't increment i, process this line
      continue;
    }

    // Headings
    if (line.startsWith('# ')) {
      nodes.push({ type: 'h1', text: line.slice(2) });
    } else if (line.startsWith('## ')) {
      nodes.push({ type: 'h2', text: line.slice(3) });
    } else if (line.startsWith('### ')) {
      nodes.push({ type: 'h3', text: line.slice(4) });
    } else if (line.startsWith('#### ')) {
      nodes.push({ type: 'h4', text: line.slice(5) });
    }
    // Horizontal rule
    else if (line === '---') {
      nodes.push({ type: 'hr' });
    }
    // Lists
    else if (line.startsWith('- ')) {
      const items = [];
      while (i < lines.length && lines[i].startsWith('- ')) {
        items.push(lines[i].slice(2));
        i++;
      }
      nodes.push({ type: 'ul', items });
      continue;
    }
    // Ordered lists
    else if (/^\d+\. /.test(line)) {
      const items = [];
      while (i < lines.length && /^\d+\. /.test(lines[i])) {
        items.push(lines[i].replace(/^\d+\. /, ''));
        i++;
      }
      nodes.push({ type: 'ol', items });
      continue;
    }
    // Paragraphs
    else if (line.trim() !== '') {
      nodes.push({ type: 'p', text: line });
    }

    i++;
  }

  return nodes;
}

/**
 * Parse inline markdown (bold, code, links)
 */
function parseInlineMarkdown(text) {
  const parts = [];
  let current = '';
  let i = 0;

  while (i < text.length) {
    // Bold text **text**
    if (text[i] === '*' && text[i + 1] === '*') {
      if (current) {
        parts.push({ type: 'text', value: current });
        current = '';
      }
      i += 2;
      let boldText = '';
      while (i < text.length && !(text[i] === '*' && text[i + 1] === '*')) {
        boldText += text[i];
        i++;
      }
      parts.push({ type: 'strong', value: boldText });
      i += 2;
      continue;
    }

    // Code `code`
    if (text[i] === '`') {
      if (current) {
        parts.push({ type: 'text', value: current });
        current = '';
      }
      i++;
      let codeText = '';
      while (i < text.length && text[i] !== '`') {
        codeText += text[i];
        i++;
      }
      parts.push({ type: 'code', value: codeText });
      i++;
      continue;
    }

    // Links [text](url)
    if (text[i] === '[') {
      if (current) {
        parts.push({ type: 'text', value: current });
        current = '';
      }
      i++;
      let linkText = '';
      while (i < text.length && text[i] !== ']') {
        linkText += text[i];
        i++;
      }
      i++; // Skip ]
      if (text[i] === '(') {
        i++; // Skip (
        let url = '';
        while (i < text.length && text[i] !== ')') {
          url += text[i];
          i++;
        }
        i++; // Skip )
        parts.push({ type: 'link', text: linkText, url });
      }
      continue;
    }

    current += text[i];
    i++;
  }

  if (current) {
    parts.push({ type: 'text', value: current });
  }

  return parts;
}

/**
 * Generate JSX for inline content
 */
function generateInlineJSX(text) {
  const parts = parseInlineMarkdown(text);
  if (parts.length === 1 && parts[0].type === 'text') {
    return `{Component.text("${escapeForReScript(parts[0].value)}")}`;
  }

  const elements = parts.map(part => {
    switch (part.type) {
      case 'text':
        return `{Component.text("${escapeForReScript(part.value)}")}`;
      case 'strong':
        return `<strong> {Component.text("${escapeForReScript(part.value)}")} </strong>`;
      case 'code':
        return `<code> {Component.text("${escapeForReScript(part.value)}")} </code>`;
      case 'link':
        if (part.url.startsWith('/')) {
          return `{Router.link(~to="${part.url}", ~children=[Component.text("${escapeForReScript(part.text)}")], ())}`;
        } else {
          return `<a href="${part.url}" target="_blank"> {Component.text("${escapeForReScript(part.text)}")} </a>`;
        }
      default:
        return '';
    }
  });

  return elements.join('\n      ');
}

/**
 * Parse table markdown
 */
function parseTable(lines) {
  // Extract rows
  const rows = lines.filter(line => line.trim() !== '' && !line.includes('---'));

  if (rows.length === 0) return null;

  const headers = rows[0].split('|').map(h => h.trim()).filter(h => h);
  const bodyRows = rows.slice(1).map(row =>
    row.split('|').map(cell => cell.trim()).filter(cell => cell !== '')
  );

  return { headers, bodyRows };
}

/**
 * Generate ReScript JSX from nodes
 */
function generateJSX(nodes) {
  return nodes.map(node => {
    switch (node.type) {
      case 'h1':
        return `    <h1> {Component.text("${escapeForReScript(node.text)}")} </h1>`;
      case 'h2':
        return `    <h2> {Component.text("${escapeForReScript(node.text)}")} </h2>`;
      case 'h3':
        return `    <h3> ${generateInlineJSX(node.text)} </h3>`;
      case 'h4':
        return `    <h4> {Component.text("${escapeForReScript(node.text)}")} </h4>`;
      case 'p':
        return `    <p>\n      ${generateInlineJSX(node.text)}\n    </p>`;
      case 'blockquote':
        return `    <div class="info-box">\n      <p>\n        ${generateInlineJSX(node.text)}\n      </p>\n    </div>`;
      case 'pre':
        const codeText = escapeForReScript(node.children[0].text);
        return `    <pre>\n      <code>\n        {Component.text(\`${codeText}\`)}\n      </code>\n    </pre>`;
      case 'ul':
        const ulItems = node.items.map(item =>
          `      <li>\n        ${generateInlineJSX(item)}\n      </li>`
        ).join('\n');
        return `    <ul>\n${ulItems}\n    </ul>`;
      case 'ol':
        const olItems = node.items.map(item =>
          `      <li>\n        ${generateInlineJSX(item)}\n      </li>`
        ).join('\n');
        return `    <ol>\n${olItems}\n    </ol>`;
      case 'table':
        const table = parseTable(node.lines);
        if (!table) return '';

        const headerCells = table.headers.map(h =>
          `          <th> ${generateInlineJSX(h)} </th>`
        ).join('\n');

        const bodyRowsJSX = table.bodyRows.map(row => {
          const cells = row.map(cell =>
            `          <td> ${generateInlineJSX(cell)} </td>`
          ).join('\n');
          return `        <tr>\n${cells}\n        </tr>`;
        }).join('\n');

        return `    <table>\n      <thead>\n        <tr>\n${headerCells}\n        </tr>\n      </thead>\n      <tbody>\n${bodyRowsJSX}\n      </tbody>\n    </table>`;
      case 'hr':
        return `    <hr />`;
      default:
        return '';
    }
  }).join('\n');
}

/**
 * Convert markdown file to ReScript component
 */
function convertMarkdownToComponent(markdownPath, outputPath) {
  const markdown = fs.readFileSync(markdownPath, 'utf-8');
  const nodes = convertMarkdownToNodes(markdown);
  const jsx = generateJSX(nodes);

  const componentName = path.basename(outputPath, '.res');

  const component = `// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ${path.relative(path.dirname(outputPath), markdownPath)}
// * To update: modify the markdown file and run:
// *   npm run generate-api-docs
// ****************************************************

open Xote

let content = () => {
  <div>
${jsx}
  </div>
}
`;

  fs.writeFileSync(outputPath, component, 'utf-8');
  console.log(`✓ Generated ${path.relative(process.cwd(), outputPath)}`);
}

/**
 * Main function
 */
function main() {
  if (!fs.existsSync(CONTENT_DIR)) {
    console.error(`Error: Content directory not found: ${CONTENT_DIR}`);
    process.exit(1);
  }

  if (!fs.existsSync(OUTPUT_DIR)) {
    fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  }

  console.log(`Generating documentation components...\n`);

  let count = 0;
  for (const [relativePath, outputName] of Object.entries(FILE_MAPPING)) {
    const markdownPath = path.join(CONTENT_DIR, relativePath);
    const outputPath = path.join(OUTPUT_DIR, outputName);

    if (!fs.existsSync(markdownPath)) {
      console.warn(`⚠ Warning: Markdown file not found: ${relativePath}`);
      continue;
    }

    convertMarkdownToComponent(markdownPath, outputPath);
    count++;
  }

  console.log(`\n✓ Generated ${count} component(s)`);
}

main();
