#!/usr/bin/env node
/**
 * Generates src/DocsIndex.res from docs.pages.mjs: every docs page with its
 * MDX document, its h2–h4 headings (for the table of contents and search),
 * agent-layer facts, and redirects from older URLs. Heading ids are made with
 * the same slugger rehype-slug uses, so they match the anchors on the page.
 *
 * Usage: node scripts/generate-docs-index.mjs
 */
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'
import GithubSlugger from 'github-slugger'
import { sections, redirects } from '../docs.pages.mjs'

const __dirname = path.dirname(fileURLToPath(import.meta.url))
const docsDir = path.join(__dirname, '..', 'src', 'docs')
const outputPath = path.join(__dirname, '..', 'src', 'DocsIndex.res')

const mdxPath = file => path.join(docsDir, `${file}.mdx`)
// A page's agent layer, when written: src/docs/agent/<File>.mdx. Its heading
// ids carry an "agent-" prefix (added by a rehype plugin in vite.config.js)
// so they never collide with the human layer's ids on the same page.
const agentPath = file => path.join(docsDir, 'agent', `${file}.mdx`)
const hasAgent = file => Boolean(file) && fs.existsSync(agentPath(file))

// Plain text of a Markdown heading, the way rehype-slug sees it.
function headingText(markdown) {
  return markdown
    .replace(/`([^`]*)`/g, '$1')
    .replace(/\[([^\]]*)\]\([^)]*\)/g, '$1')
    .replace(/(\*\*|__|\*|_)(.*?)\1/g, '$2')
    .trim()
}

function headingsOf(file, { agent = false } = {}) {
  const source = fs.readFileSync(agent ? agentPath(file) : mdxPath(file), 'utf-8')
  const slugger = new GithubSlugger()
  const headings = []
  let inFence = false
  let inTemplate = false
  for (const line of source.split('\n')) {
    if (/^\s*```/.test(line)) inFence = !inFence
    // Code inside a DocsExamplePanel `code={`...`}` template literal.
    const ticks = (line.match(/(?<!\\)`/g) ?? []).length
    if (/code=\{`/.test(line)) inTemplate = ticks % 2 === 1
    else if (inTemplate && ticks % 2 === 1) inTemplate = false
    if (inFence || inTemplate) continue
    const match = /^(#{1,6})\s+(.+?)\s*#*\s*$/.exec(line)
    if (!match) continue
    const text = headingText(match[2])
    const id = (agent ? 'agent-' : '') + slugger.slug(text)
    const level = match[1].length
    if (level >= 2 && level <= 4) headings.push({ text, id, level })
  }
  return headings
}

const str = value => JSON.stringify(value)
const option = value => (value === undefined || value === null ? 'None' : `Some(${value})`)
const docName = file => file.charAt(0).toLowerCase() + file.slice(1)

// Pages whose MDX file does not exist yet are left out, with a warning, so a
// page can be registered before it is written.
const present = sections.map(section => ({
  ...section,
  pages: section.pages.filter(page => {
    if (page.file && !fs.existsSync(mdxPath(page.file))) {
      console.warn(`  skipped ${page.path}: src/docs/${page.file}.mdx not found`)
      return false
    }
    return true
  }),
}))

const files = new Set()
for (const section of present)
  for (const page of section.pages) {
    if (page.file) files.add(page.file)
    if (page.agent?.api) files.add(page.agent.api)
  }

const agentFiles = [...files].filter(hasAgent).sort()

const imports = [
  ...[...files]
    .sort()
    .map(file => `@module("./docs/${file}.mdx") external ${docName(file)}: Mdx.document = "default"`),
  ...agentFiles.map(
    file => `@module("./docs/agent/${file}.mdx") external ${docName(file)}Agent: Mdx.document = "default"`,
  ),
].join('\n')

// The page that renders a given MDX file, for links to API reference pages.
const pathOfFile = Object.fromEntries(
  present.flatMap(section => section.pages.filter(p => p.file).map(p => [p.file, p.path])),
)

const pageEntry = (page, label) => {
  const headings = page.file
    ? headingsOf(page.file)
        .map(h => `          {text: ${str(h.text)}, id: ${str(h.id)}, level: ${h.level}},`)
        .join('\n')
    : ''
  const agentHeadings = hasAgent(page.file)
    ? headingsOf(page.file, { agent: true })
        .map(h => `          {text: ${str(h.text)}, id: ${str(h.id)}, level: ${h.level}},`)
        .join('\n')
    : ''
  const agent = page.agent
    ? `{moduleName: ${str(page.agent.module)}, boundary: ${str(page.agent.boundary)}, entry: ${str(page.agent.entry)}, api: ${option(page.agent.api && docName(page.agent.api))}, apiPath: ${option(page.agent.api && str(pathOfFile[page.agent.api]))}}`
    : undefined
  return `      {
        title: ${str(page.title)},
        pageTitle: ${str(page.pageTitle ?? page.title)},
        path: ${str(page.path)},
        section: ${str(label)},
        lead: ${str(page.lead ?? '')},
        document: ${option(page.file && docName(page.file))},
        headings: [
${headings}
        ],
        agentDocument: ${option(hasAgent(page.file) ? `${docName(page.file)}Agent` : null)},
        agentHeadings: [
${agentHeadings}
        ],
        agentOnly: ${page.agentOnly ? 'true' : 'false'},
        customToc: ${page.customToc ? 'true' : 'false'},
        agent: ${option(agent)},
      },`
}

const body = present
  .map(
    section => `  {
    label: ${str(section.label)},
    pages: [
${section.pages.map(page => pageEntry(page, section.label)).join('\n')}
    ],
  },`,
  )
  .join('\n')

const redirectEntries = Object.entries(redirects)
  .map(([from, to]) => `  (${str(from)}, ${str(to)}),`)
  .join('\n')

const output = `// Generated by scripts/generate-docs-index.mjs from docs.pages.mjs. Do not edit.

${imports}

type heading = {text: string, id: string, level: int}

type agentFacts = {
  moduleName: string,
  boundary: string,
  entry: string,
  api: option<Mdx.document>,
  apiPath: option<string>,
}

type page = {
  title: string,
  pageTitle: string,
  path: string,
  section: string,
  lead: string,
  document: option<Mdx.document>,
  headings: array<heading>,
  // The agent layer's own content and headings, when the page has one.
  agentDocument: option<Mdx.document>,
  agentHeadings: array<heading>,
  agentOnly: bool,
  customToc: bool,
  agent: option<agentFacts>,
}

type section = {label: string, pages: array<page>}

let sections: array<section> = [
${body}
]

let pages = sections->Array.flatMap(section => section.pages)

let find = (path: string) => pages->Array.find(page => page.path == path)

// Older URL -> current URL.
let redirects: array<(string, string)> = [
${redirectEntries}
]
`

fs.writeFileSync(outputPath, output)
const count = present.reduce((n, s) => n + s.pages.length, 0)
console.log(`Generated ${path.relative(process.cwd(), outputPath)} (${count} pages)`)
