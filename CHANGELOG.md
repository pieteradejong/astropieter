# Changelog

All notable changes to this site. Format: [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
The site is unversioned (every push to `main` deploys), so entries are grouped by the session
that shipped them; `[Unreleased]` is what is on `main` but not yet deployed or not yet confirmed
live.

## [Unreleased]

### Fixed
- The Terra demo (`public/terra/index.html`) now honours `prefers-reduced-motion: reduce`: no auto
  orbit, and about four redraws a second instead of one per animation frame. Its browser tests run
  under that setting; on the CI runner's software WebGL the full-rate loop starved the main thread
  and the 375px test timed out (DECISIONS #14).
- `test.sh` started the dev server in the foreground and only passed when an AI agent was the
  parent process (Astro backgrounds on agent detection); in CI it blocked until the 20-minute
  timeout. The server is now started with `astro dev --background` (DECISIONS #12).
- Four "View on Amazon" links on `/reading/` pointed at pages that no longer exist (404); replaced
  with the publisher ISBN product pages. A dead link to a third-party blog was removed from the
  LaTeX test post. The weekly link report had failed every run since 2026-09-27 on these.
- Blog post body styles (`.prose` in `BlogPost.astro`) never reached rendered Markdown, because
  scoped styles do not match `<Content />` output. They are now global, so code blocks scroll,
  images fit and headings scale inside posts.
- Three pages nested a second `<main>` inside the layout's `<main>` (invalid HTML, double gutter).
- Project cards on `/projects/` were wider than a 320–375px screen (the grid's `1fr` min-content
  floor); five pages added a second gutter by reusing `.content-container` inside the layout.
- Contact form inputs were about 269px wide on a 375px phone (four nested paddings); the form now
  gets the full column, the message box has a real height, and the submit button spans the width
  on phones.
- The homepage hid the photo, name, Contact button and LinkedIn/GitHub links entirely under 768px.
  They now stack above the bio.

### Changed
- **Mobile layout pass** (DECISIONS #8). One phone breakpoint (`≤767px`) replaces the mix of
  375/480/768/1023. The blanket `div { overflow-x: auto }` rule is gone; code, tables and display
  math scroll inside their own box and long words wrap. Nav dropdown items, footer links, project
  links, book/lyric links and the card expand button are ≥44px tap targets. The dropdown opens
  under the header, truncates the name on 320px screens, moves focus into the menu and back on
  Escape. The About timeline stacks date-over-event on phones. Hover lifts only apply on devices
  that hover. Tags and the draft badge have a 12px floor.
- **Terra demo on phones** (`public/terra/index.html`): the chokepoint card is a bottom sheet
  instead of a 300px box over the title; the layer panel starts collapsed behind a 44px "Layers"
  button; HUD text has a 12px floor; a tap picks a cable (hover-only before); the tooltip stays on
  screen; the hint says "pinch to zoom" on touch devices.
- `/blog/latex_test/` is a draft (rendering test, not an essay). `/press/`, `/software/` and `/qr/`
  are built but excluded from the sitemap (DECISIONS #9).
- `.github/workflows/link-report.yml` excludes `genius.com` (403 bot wall in CI, 200 in a browser).
- `site / live` (`ci.yml`) was skipped on the first real deployment: Vercel names the GitHub
  environment `Production`, not `Production – padj`, once only one project is linked. The job
  now accepts both names.
- `DEPLOYMENT.md` records the retired SiteGround address (serves a June 2025 build until the plan
  ends in November 2026; nothing deploys there), the Node version precedence on Vercel, and the
  one-deployment-per-push check.
- `init.sh` checks Node ≥ 22.12, installs with `npm ci`, creates `.env` from `.env.example` and
  reports whether a Chrome for the browser tests was found. `run.sh` gained `build`, `preview` and
  `stop`.

### Added
- `.github/workflows/ci.yml` (DECISIONS #10): `site / tests` runs `./test.sh --offline` on every
  push and pull request; `site / live` runs `./test.sh --live https://padj.vercel.app` after Vercel
  reports a successful production deployment (and on demand with a URL). README badges for the
  three workflows.
- `/qr/`: a QR code for the site to show on a phone (DECISIONS #7). `public/qr.svg` is static,
  generated once with `qrencode`.
- `tests/mobile.spec.ts`: every route at 320/375/414px with no horizontal overflow, no text under
  12px, ≥44px chrome controls, ≥16px inputs; hamburger open/close/focus; horizontal nav at
  768/900/1024; Terra's phone layout. Runs in `./test.sh` and under `--live`.
- `test.sh`: outbound links on `/reading/` and `/about/` are fetched (fail on 4xx/5xx); unlisted
  pages must be out of the sitemap and still built; `/qr/` is a main route.
- `.env.example` (the one variable: `PUBLIC_WEB3FORMS_KEY`).
- `docs/CONTENT-REVIEW.md`: biography and wording inconsistencies for Pieter to settle.

### Removed
- `pbcopy` (a stray file holding an SSH public key for the cancelled SiteGround host).

## 2026-09 — Dependency refresh and content tests

- **Upgraded** `astro` 7.3.1 → 7.3.5, `@astrojs/mdx` 8.0.0 → 8.0.2, `@astrojs/markdown-remark`
  7.3.0 → 7.3.1. Every dependency is pinned exactly (no `^`).
- **Removed unused `katex` and `@astrojs/react`**; math is rendered by `rehype-katex`'s own katex.
- **KaTeX stylesheet fixed**: `BaseHead.astro` loaded the 0.15.1 stylesheet while math was
  rendered by 0.16.47. Now matched, with a verified SRI hash.
- **Display math fixed** in `LaTeX_test.md` and the information-theory draft (single-line `$$…$$`
  rendered inline).
- **Removed the `chrome-bookmarks` GitHub link** (private repo, visitors got a 404).
- **Added Playwright browser tests** (`tests/content.spec.ts`) and stronger dependency,
  math-pipeline and fixture-leak checks in `test.sh`.
- Hosting moved to Vercel (DECISIONS #1, #2); projects got hero images, a demo badge and filter
  (DECISIONS #3–#5); weekly link report (DECISIONS #6).

## 2026-08 — Astro 5 → 7 upgrade

- Upgraded from Astro 5.15.5 to 7.2.2 via `npx @astrojs/upgrade` and resolved every breaking
  change: removed unused `@astrojs/tailwind`; migrated content collections to the Content Layer
  API (`src/content.config.ts`, `glob()` loaders, `entry.id`, `render(entry)`); moved the
  remark/rehype KaTeX pipeline into `unified()` from `@astrojs/markdown-remark`.
- Fixed invalid `var()` inside `@media` conditions (LightningCSS hard-fails on them); several
  responsive breakpoints had been silently dead.
- Fixed `rss.xml.js` (`get` → `GET`; drafts were leaking into the feed).
- `npm audit fix` to 0 vulnerabilities. Local pre-commit hook rewritten to exact-match filenames.
- Added `test.sh`. Deploy credentials separated from the checked-in templates.
