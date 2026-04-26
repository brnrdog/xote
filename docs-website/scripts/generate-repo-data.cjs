#!/usr/bin/env node

const fs = require('fs')
const path = require('path')

const ROOT_DIR = path.join(__dirname, '..', '..')
const CHANGELOG_PATH = path.join(ROOT_DIR, 'docs', 'CHANGELOG.md')
const OUTPUT_PATH = path.join(__dirname, '..', 'src', 'RepoData.res')
const CHANGELOG_SOURCE_URL =
  'https://github.com/brnrdog/xote/blob/main/docs/CHANGELOG.md'

function escapeForReScript(text) {
  return text
    .replace(/\\/g, '\\\\')
    .replace(/\r/g, '')
    .replace(/\n/g, '\\n')
    .replace(/"/g, '\\"')
    .replace(/`/g, '\\`')
    .replace(/\$/g, '\\$')
}

function slugify(text) {
  return text
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
}

function parseInlineMarkdown(text) {
  const parts = []
  let current = ''
  let i = 0

  while (i < text.length) {
    if (text[i] === '*' && text[i + 1] === '*') {
      if (current) {
        parts.push({ type: 'text', value: current })
        current = ''
      }
      i += 2
      let boldText = ''
      while (i < text.length && !(text[i] === '*' && text[i + 1] === '*')) {
        boldText += text[i]
        i++
      }
      parts.push({ type: 'strong', value: boldText })
      i += 2
      continue
    }

    if (text[i] === '`') {
      if (current) {
        parts.push({ type: 'text', value: current })
        current = ''
      }
      i++
      let codeText = ''
      while (i < text.length && text[i] !== '`') {
        codeText += text[i]
        i++
      }
      parts.push({ type: 'code', value: codeText })
      i++
      continue
    }

    if (text[i] === '[') {
      if (current) {
        parts.push({ type: 'text', value: current })
        current = ''
      }
      i++
      let linkText = ''
      while (i < text.length && text[i] !== ']') {
        linkText += text[i]
        i++
      }
      i++
      if (text[i] === '(') {
        i++
        let url = ''
        while (i < text.length && text[i] !== ')') {
          url += text[i]
          i++
        }
        i++
        parts.push({ type: 'link', text: linkText, url })
        continue
      }
      current += `[${linkText}]`
      continue
    }

    current += text[i]
    i++
  }

  if (current) {
    parts.push({ type: 'text', value: current })
  }

  return parts
}

function inlinePartToRescript(part) {
  switch (part.type) {
    case 'text':
      return `Node.text("${escapeForReScript(part.value)}")`
    case 'strong':
      return `<strong> {Node.text("${escapeForReScript(part.value)}")} </strong>`
    case 'code':
      return `<code> {Node.text("${escapeForReScript(part.value)}")} </code>`
    case 'link':
      return `<a href="${escapeForReScript(part.url)}" target="_blank"> {Node.text("${escapeForReScript(part.text)}")} </a>`
    default:
      return 'Node.text("")'
  }
}

function inlineTextToRescript(text, indent) {
  const parts = parseInlineMarkdown(text)
  if (parts.length === 0) {
    return `${indent}Node.text("")`
  }

  return parts
    .map(part => `${indent}${inlinePartToRescript(part)}`)
    .join(',\n')
}

function ensureSection(release, currentSection) {
  if (currentSection) {
    return currentSection
  }

  const section = { title: '', items: [] }
  release.sections.push(section)
  return section
}

function pushItem(section, itemParts) {
  const text = itemParts.join(' ').replace(/\s+/g, ' ').trim()
  if (text !== '') {
    section.items.push(text)
  }
}

function parseChangelog(markdown) {
  const lines = markdown.split(/\r?\n/)
  const releases = []
  let currentRelease = null
  let currentSection = null
  let currentItem = null

  const flushItem = () => {
    if (currentRelease && currentItem) {
      const section = ensureSection(currentRelease, currentSection)
      pushItem(section, currentItem)
    }
    currentItem = null
  }

  for (const line of lines) {
    const releaseMatch = line.match(/^#{1,2} \[([^\]]+)\]\(([^)]+)\) \((\d{4}-\d{2}-\d{2})\)$/)
    if (releaseMatch) {
      flushItem()
      currentRelease = {
        version: releaseMatch[1],
        url: releaseMatch[2],
        date: releaseMatch[3],
        id: `release-${slugify(releaseMatch[1])}-${releaseMatch[3]}`,
        sections: [],
      }
      releases.push(currentRelease)
      currentSection = null
      continue
    }

    if (!currentRelease) {
      continue
    }

    const sectionMatch = line.match(/^### (.+)$/)
    if (sectionMatch) {
      flushItem()
      currentSection = {
        title: sectionMatch[1].trim(),
        items: [],
      }
      currentRelease.sections.push(currentSection)
      continue
    }

    const bulletMatch = line.match(/^\* (.+)$/)
    if (bulletMatch) {
      flushItem()
      currentItem = [bulletMatch[1].trim()]
      continue
    }

    if (currentItem && line.trim() !== '') {
      currentItem.push(line.trim())
    }
  }

  flushItem()

  return releases
}

function generateRepoData(releases) {
  if (releases.length === 0) {
    throw new Error('No releases found in docs/CHANGELOG.md')
  }

  const latest = releases[0]
  const releaseEntries = releases
    .map(release => {
      const sections = release.sections
        .map(section => {
          const items = section.items
            .map(
              item => `          [\n${inlineTextToRescript(item, '            ')}\n          ]`,
            )
            .join(',\n')

          return `      {\n        title: "${escapeForReScript(section.title)}",\n        items: [\n${items}\n        ],\n      }`
        })
        .join(',\n')

      return `  {\n    version: "${escapeForReScript(release.version)}",\n    url: "${escapeForReScript(release.url)}",\n    date: "${escapeForReScript(release.date)}",\n    id: "${escapeForReScript(release.id)}",\n    sections: [\n${sections}\n    ],\n  }`
    })
    .join(',\n')

  return `// ****************************************************
// * THIS FILE IS GENERATED - DO NOT EDIT MANUALLY! *
// * Generated from: ../../docs/CHANGELOG.md
// * To update: modify docs/CHANGELOG.md and run:
// *   npm run generate-repo-data
// ****************************************************

type inlineNodes = array<Node.node>

type releaseSection = {
  title: string,
  items: array<inlineNodes>,
}

type release = {
  version: string,
  url: string,
  date: string,
  id: string,
  sections: array<releaseSection>,
}

let sourceUrl = "${CHANGELOG_SOURCE_URL}"
let latestVersion = "${escapeForReScript(latest.version)}"
let latestReleaseDate = "${escapeForReScript(latest.date)}"

let releases: array<release> = [
${releaseEntries}
]
`
}

function main() {
  const markdown = fs.readFileSync(CHANGELOG_PATH, 'utf-8')
  const releases = parseChangelog(markdown)
  const output = generateRepoData(releases)

  fs.writeFileSync(OUTPUT_PATH, output, 'utf-8')
  console.log(`✓ Generated ${path.relative(process.cwd(), OUTPUT_PATH)}`)
}

main()
