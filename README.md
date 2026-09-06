# Pieter de Jong - Personal website

Currently deployed at: https://pieterd38.sg-host.com/

**This is my main online presence**, aside from [my LinkedIn](https://www.linkedin.com/in/pieteradejong/) and [my GitHub](https://github.com/pieteradejong). The Internet is a large place, and standing out is both critical and hard. This is where I aim to do so.

# Goals
* Marketing: put myself out there.
* Connect: Find like-minded, share ideas, potentially work together, etc.

# Website 'Table of contents':

* Blog - I like to write
* About Me - Personal background, history, what sets me apart from the crowd.
* Reading: I love to read, and seek out fellow readers.
* Contact: self-evident.


# Maintenance / deployment
For hosting I use [Siteground](https://www.siteground.com/), and for DNS I use [iwantmyname](https://iwantmyname.com/). 

I use the React-based `Astro.js` framework for development; the for web development standard process of `npm run astro dev` that monitors files for changes so you see all changes reflected immediately on `localhost`; and a custom `.sh` script to use `rsync` to build the site and sync all changes to my Siteground server. 


## rsync script
I run this `$ astrosync` from anywhere to build + sync my site to prod:

```bash
astrosync() {
  cd <local_astropieter_dir>
  npm run astro build
  rsync -av --delete -e <ssh_key> <local_build_dir> <server_host>
}
```

# TODO 
Stuff I would like to add in the future:
* Top priorities: content, quality, and loading speed.
* auto translate to any language, especially Spanish and Dutch. Classic Latin and Classic Greek would be cool too.
* Low-friction contact methods.
* Inline programming code, e.g. `Python`.
* If/when my content becomes good enough, a micro-payment "tip jar".

# Astro Blog

A modern, fast blog built with Astro.js featuring static search capabilities.

## Features

- 🚀 Built with Astro.js for optimal performance
- 📝 Markdown and MDX support
- 🔍 Static search functionality with Pagefind
- 📱 Responsive design
- 🎨 Clean, professional styling
- 📊 LaTeX support for mathematical content
- 🔄 Easy deployment with included scripts

## Quick Start

1. Clone the repository:
```bash
git clone https://github.com/yourusername/astropieter.git
cd astropieter
```

2. Run the initialization script:
```bash
chmod +x init.sh
./init.sh
```

3. Start the development server:
```bash
npm run dev
```

## Local Development

To run the site locally:

1. Make sure you have Node.js 22.12+ installed (required by Astro 6+; see [Upgrade Reqs](#upgrade-reqs))
2. Clone the repository and navigate to it:
```bash
git clone https://github.com/yourusername/astropieter.git
cd astropieter
```

3. Install dependencies:
```bash
npm install
```

4. Start the development server:
```bash
npm run dev
```

The site will be available at `http://localhost:4321` (or another port if 4321 is in use).

Key development commands:
- `npm run dev` - Start development server with hot reloading (Astro 7 runs this as a background daemon — manage it with `npx astro dev status` / `stop` / `logs`)
- `npm run build` - Build the site for production
- `npm run preview` - Preview the production build locally

## Testing

Run `./test.sh` for a comprehensive check before deploying: build health, dependency audit, content-collection/draft correctness, RSS feed validity, KaTeX rendering, and a live dev-server smoke test across all main routes. See [Changelog](#changelog) for what it covers in detail.

## Deployment

`deploy.sh` is **gitignored** and never committed — not because it holds secrets (it holds none), but so each machine keeps its own copy. Credentials live only in `.deploy-env`, which is also gitignored. See `DEPLOYMENT.md` for full setup instructions.

1. Copy the templates and fill in your own values:
```bash
cp deploy.sh.example deploy.sh
cp .deploy-env.example .deploy-env
chmod +x deploy.sh
```
2. Run the deployment script:
```bash
./deploy.sh
```

`deploy.sh` is the single deploy path: it validates config, builds, aborts on any failure, then rsyncs `dist/` to the host. The `astrosync` shell function is a thin wrapper that calls it, so either command does the same safe thing.

## Project Structure

```
.
├── src/
│   ├── components/       # Reusable components
│   ├── content/          # Content collections: blog/ and projects/ (markdown/MDX)
│   ├── content.config.ts # Content collection schemas (Content Layer API)
│   ├── layouts/          # Page layouts
│   ├── pages/            # Astro pages
│   └── styles/           # Global styles
├── public/               # Static assets
├── init.sh               # Initialization script
├── test.sh               # Comprehensive pre-deploy test suite
├── deploy.sh.example      # Deployment script template (copy to deploy.sh)
├── deploy.sh              # Deployment script — gitignored, per-machine copy
└── DEPLOYMENT.md          # Full deployment setup instructions
```

## Content Pipeline

How a markdown file becomes a page. `entry.id` is the slugified filename, so `LaTeX_test.md` becomes `/blog/latex_test/`.

```mermaid
flowchart TD
  MD["src/content/blog/*.md"] --> LOADER["content.config.ts<br/>glob loader + zod schema"]
  PMD["src/content/projects/*.md"] --> PLOADER["content.config.ts<br/>projects collection"]

  LOADER --> IDX["blog/index.astro<br/>draft filter (DEV-aware)<br/>sort pubDate desc"]
  LOADER --> POST["blog/[...slug].astro<br/>draft filter (DEV-aware)<br/>render(entry)"]
  LOADER --> RSS["rss.xml.js &mdash; GET()<br/>drafts always excluded"]

  POST --> LAYOUT["layouts/BlogPost.astro<br/>re-queries blog, NO draft filter"]
  LAYOUT --> NAV["SeriesNav.astro<br/>via getSeriesInfo()"]

  PLOADER --> PIDX["projects.astro<br/>sort by order"]
  PLOADER --> PDET["projects/[slug].astro<br/>render(entry)"]

  IDX --> D1["dist/blog/index.html"]
  NAV --> D2["dist/blog/&lt;id&gt;/index.html"]
  RSS --> D3["dist/rss.xml"]
  PIDX --> D4["dist/projects/index.html"]
  PDET --> D5["dist/projects/&lt;id&gt;/index.html"]
```

### Known inconsistency: draft filtering

The `draft` flag is honoured in three different ways, which is worth knowing before adding a fourth consumer:

| Consumer | Behaviour |
|---|---|
| `blog/index.astro`, `blog/[...slug].astro` | DEV-aware — drafts visible in `astro dev`, excluded from the production build |
| `rss.xml.js` | always excludes drafts, in dev and prod alike |
| `layouts/BlogPost.astro` | **no draft filter at all** |

`BlogPost.astro` re-queries the whole `blog` collection to build series navigation, so `SeriesNav` prev/next links can point at draft posts that have no generated page in production. Not currently fixed — recorded here so it isn't rediscovered from scratch.

## Upgrade Reqs

Requirements/notes for upgrading Astro across major versions (last reviewed: Astro 5 → 7, Aug 2026):

- **Node 22.12+** required starting in Astro v6 (drops Node 18/20 support)
- **Env vars**: `import.meta.env` values are always inlined and no longer type-coerced (Astro v6); private env vars must be read via `process.env` explicitly
- **Images**: default image service crops by default and never upscales (Astro v6)
- **Routing**: file-extension endpoints can't be accessed with a trailing slash (Astro v6)
- **Removed in v6**: legacy Content Collections API (v2 format), `Astro.glob()`, `<ViewTransitions />` (use `<ClientRouter />`), CJS config files
- **Deprecated in v6**: `Astro` global in `getStaticPaths()`, `astro:schema` import (use `astro/zod`), session driver strings
- **Dependency bumps in v6**: Vite 7, Zod 4 (`z.email()` instead of `z.string().email()`), Shiki 4
- **New Rust-based compiler in v7**: stricter HTML — unclosed tags now error, invalid HTML no longer auto-corrected. Audit `.md`/`.mdx` content for malformed tags.
- **Whitespace in v7**: `compressHTML` default changed from `true` to `'jsx'`, affecting spacing between inline elements
- **Vite 8** upgrade in v7 — check custom plugins/config for compatibility
- **Markdown in v7**: new "Sätteri" pipeline replaces remark/rehype by default. This project uses `remark-math` + `rehype-katex` for LaTeX — install `@astrojs/markdown-remark` to keep the remark/rehype pipeline working
- **`@astrojs/db` removed** entirely in v7 (not used in this project)

Recommended upgrade path: run `npx @astrojs/upgrade` to update Astro and official integrations together, then fix any compiler errors surfaced during build.

## Changelog

### Astro 5 → 7 upgrade (Aug 2026)

Upgraded the site from Astro 5.15.5 to 7.2.2 via `npx @astrojs/upgrade`, then resolved every breaking change it surfaced:

- **Removed `@astrojs/tailwind`** — it was an unused dependency (never imported in `astro.config.mjs`, no Tailwind config or `@tailwind` usage anywhere) and the sole blocker preventing `npm install` from resolving cleanly against Astro 7.
- **Content collections migrated to the Content Layer API** — moved `src/content/config.ts` → `src/content.config.ts`, added `glob()` loaders per collection (`astro/loaders`), switched schema imports to `astro/zod`. The legacy config format was hard-removed in Astro v6.
- **`entry.slug` → `entry.id`, `entry.render()` → `render(entry)`** — Content Layer API entries no longer expose `.slug` or a `.render()` method. Updated every usage across blog/project detail pages, `rss.xml.js`, `blog/index.astro`, `projects.astro`, `BlogPost.astro`, `SeriesNav.astro`, and `utils/series.ts`.
- **Markdown pipeline** — moved `remarkPlugins`/`rehypePlugins` (used for KaTeX via `remark-math` + `rehype-katex`) into `unified({...})` from the new `@astrojs/markdown-remark` package, since Astro v7 replaced the default markdown pipeline.
- **CSS media queries fixed** — `@media (max-width: var(--mobile-cutoff))` and similar are invalid CSS (custom properties aren't allowed in media-query conditions). The stricter LightningCSS minifier bundled with Astro 7 now hard-fails the build on this instead of silently ignoring it. Replaced with literal breakpoint values (`375px`, `768px`) in `global.css` and 6 components — this also fixed several responsive breakpoints that were silently dead before (the media queries never matched anything).
- **`rss.xml.js` fixed** — the endpoint handler was `export function get()` (lowercase), which Astro no longer recognizes as a route handler (must be `GET`); the feed was silently broken. Also added draft-post filtering to the feed, since drafts were leaking into RSS even though they were correctly excluded from the blog index.
- **`npm audit fix`** — resolved a moderate (`mdast-util-to-hast`) and a high (`sharp`/libvips) vulnerability pulled in transitively by the upgraded packages. 0 vulnerabilities remain.
- **Local pre-commit hook fixed** (`.git/hooks/pre-commit`, not tracked in git) — it used to `grep` staged filenames for the substring `deploy.sh`, which false-positived on deleting `deploy.sh` from tracking and on unrelated files like `deploy.sh.example`. Rewrote it to exact-match filenames and to only check added/modified files, not deletions.
- **Added `test.sh`** — a comprehensive test suite covering: Node/dependency health, `npm audit`, production build correctness (no errors/warnings), presence of every expected page, correct draft-post inclusion/exclusion, RSS feed validity (well-formed XML, no drafts, no `undefined` fields), KaTeX rendering, and a live dev-server smoke test across all main routes (Astro 7's `astro dev` now self-daemonizes in the background, managed via `astro dev status`/`stop`/`logs` — the script accounts for this).
- **Deploy script separated from templates** — `deploy.sh` (real SSH credentials) is now gitignored and kept local-only; `deploy.sh.example`, `.deploy-env.example`, and `DEPLOYMENT.md` are the checked-in, credential-free templates.

Verified with a clean `npm run build`, `./test.sh` (52/52 checks passing), and manual route checks in both dev and production builds.

## Customization

### Styling

All styles use CSS variables defined in `src/styles/global.css`. Key variables:
- `--accent`: Primary accent color (used for links)
- `--non-link-text`: Color for non-interactive text
- `--card-bg`: Background color for cards
- `--border`: Border color
- `--mobile-cutoff`: Breakpoint for mobile devices

## Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## License

MIT License - see LICENSE file for details
