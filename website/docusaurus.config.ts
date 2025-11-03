import {themes as prismThemes} from 'prism-react-renderer';
import type {Config} from '@docusaurus/types';
import type * as Preset from '@docusaurus/preset-classic';

// This runs in Node.js - Don't use client-side code here (browser APIs, JSX...)

const config: Config = {
  title: 'Xote',
  tagline: 'Lightweight, zero-dependency UI library for ReScript with fine-grained reactivity',
  favicon: 'img/favicon.ico',

  // Future flags, see https://docusaurus.io/docs/api/docusaurus-config#future
  future: {
    v4: true, // Improve compatibility with the upcoming Docusaurus v4
  },

  // Set the production url of your site here
  url: 'https://brnrdog.github.io',
  // Set the /<baseUrl>/ pathname under which your site is served
  // For GitHub pages deployment, it is often '/<projectName>/'
  baseUrl: '/xote/',

  // GitHub pages deployment config.
  // If you aren't using GitHub pages, you don't need these.
  organizationName: 'brnrdog', // Usually your GitHub org/user name.
  projectName: 'xote', // Usually your repo name.

  onBrokenLinks: 'throw',

  // Even if you don't use internationalization, you can use this field to set
  // useful metadata like html lang. For example, if your site is Chinese, you
  // may want to replace "en" with "zh-Hans".
  i18n: {
    defaultLocale: 'en',
    locales: ['en'],
  },

  presets: [
    [
      'classic',
      {
        docs: {
          sidebarPath: './sidebars.ts',
          // Please change this to your repo.
          // Remove this to remove the "edit this page" links.
          editUrl:
            'https://github.com/brnrdog/xote/tree/main/website/',
        },
        blog: false,
        theme: {
          customCss: './src/css/custom.css',
        },
      } satisfies Preset.Options,
    ],
  ],

  themeConfig: {
    // Replace with your project's social card
    image: 'img/docusaurus-social-card.jpg',
    colorMode: {
      respectPrefersColorScheme: true,
    },
    navbar: {
      title: 'Xote',
      logo: {
        alt: 'Xote Logo',
        src: 'img/logo.svg',
      },
      items: [
        {
          type: 'docSidebar',
          sidebarId: 'tutorialSidebar',
          position: 'left',
          label: 'Docs',
        },
        {to: '/demos', label: 'Demos', position: 'left'},
        {
          href: 'https://www.npmjs.com/package/xote',
          label: 'npm',
          position: 'right',
        },
        {
          href: 'https://github.com/brnrdog/xote',
          label: 'GitHub',
          position: 'right',
        },
      ],
    },
    footer: {
      style: 'dark',
      links: [
        {
          title: 'Docs',
          items: [
            {
              label: 'Getting Started',
              to: '/docs/intro',
            },
            {
              label: 'API Reference',
              to: '/docs/api/signals',
            },
          ],
        },
        {
          title: 'Resources',
          items: [
            {
              label: 'Demos',
              to: '/demos',
            },
            {
              label: 'GitHub',
              href: 'https://github.com/brnrdog/xote',
            },
            {
              label: 'npm',
              href: 'https://www.npmjs.com/package/xote',
            },
          ],
        },
        {
          title: 'More',
          items: [
            {
              label: 'ReScript',
              href: 'https://rescript-lang.org/',
            },
            {
              label: 'TC39 Signals Proposal',
              href: 'https://github.com/tc39/proposal-signals',
            },
          ],
        },
      ],
      copyright: `Copyright © ${new Date().getFullYear()} Xote. Built with Docusaurus.`,
    },
    prism: {
      theme: prismThemes.github,
      darkTheme: prismThemes.dracula,
      additionalLanguages: ['ocaml', 'reason'],
    },
  } satisfies Preset.ThemeConfig,
};

export default config;
