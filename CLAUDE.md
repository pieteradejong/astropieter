# CLAUDE.md — astropieter

Personal site (Astro, fully static) at https://padj.vercel.app. Decisions: `DECISIONS.md`. Hosting
and deploy: `DEPLOYMENT.md`.

## Commands

```sh
npm run dev                                  # dev server with live reload
./test.sh                                    # full suite: build, content, links, dev server, browser tests
./test.sh --offline                          # same, without network checks
./test.sh --live https://padj.vercel.app     # check what production is serving
./init.sh                                    # fresh clone: toolchain check, npm ci, .env, Chrome check
./run.sh [dev|build|preview|stop]            # dev server reachable from a phone on the same Wi-Fi
gh workflow run link-report.yml              # weekly broken-link report, on demand
gh workflow run ci.yml -f url=https://padj.vercel.app   # live check of production, on demand
gh run list --workflow ci.yml --limit 5       # the two GitHub checks: site / tests, site / live
```

## Gotchas

- **Pushing `main` is a production deploy.** Vercel builds on push, and it does not run
  `./test.sh`. Run the suite first. GitHub then runs it too (`ci.yml`, DECISIONS #10): `tests` on
  the push (`--offline`, Playwright's own Chromium) and `live` against padj.vercel.app after Vercel's
  `deployment_status`. A red `live` means visitors see a broken site: `vercel rollback`.
- **Projects: `demoUrl` is the only demo field** (`deploymentUrl` is retired, DECISIONS #3). Only
  list a demo that works: `test.sh` fails on a dead one (#4). The "Live demo" / "Source only"
  badge and the `/projects` filter derive from it (#5).
- Browser tests use an installed Chrome (`playwright.config.ts`). On this Mac it is at
  `/Applications/Chrome.app`, not the default path. No Playwright browser download is needed.
- `public/terra/` is a static page outside Astro: no footer, no analytics, no meta description.
  The dev server does not resolve `/terra/` to it; use `/terra/index.html` locally (the tests do).
- **Unlisted pages** `/qr/`, `/press/`, `/software/` are built but filtered out of the sitemap
  (`astro.config.mjs`, DECISIONS #9). `test.sh` fails if one shows up in `dist/sitemap-*.xml`.
- **`public/qr.svg` is static.** It encodes `https://padj.vercel.app/`; if the site moves to a
  custom domain, regenerate it (`qrencode -t SVG -l M -m 2 -o public/qr.svg '<url>'`, then strip
  the fixed `width`/`height` so it scales) and re-check with `zbarimg` (DECISIONS #7).
- **One phone breakpoint: `max-width: 767px`.** Don't add 375/480px rules; `--spacing-unit`
  already scales gutters. Post bodies are styled by the `is:global` block in `BlogPost.astro`,
  because rendered Markdown carries no scoped attribute. Keep `tests/mobile.spec.ts` green: every
  route at 320px with no horizontal overflow and no text under 12px (DECISIONS #8).
- `npm audit`: the `katex` advisory (low) has no upstream fix in `rehype-katex` 7; `test.sh` holds
  the audit at `--audit-level=moderate`.
