# CLAUDE.md — astropieter

Personal site (Astro, fully static) at https://padj.vercel.app. Decisions: `DECISIONS.md`. Hosting
and deploy: `DEPLOYMENT.md`.

## Commands

```sh
npm run dev                                  # dev server with live reload
./test.sh                                    # full suite: build, content, links, dev server, browser tests
./test.sh --offline                          # same, without network checks
./test.sh --live https://padj.vercel.app     # check what production is serving
gh workflow run link-report.yml              # weekly broken-link report, on demand
```

## Gotchas

- **Pushing `main` is a production deploy.** Vercel builds on push, and it does not run
  `./test.sh`. Run the suite first.
- **Projects: `demoUrl` is the only demo field** (`deploymentUrl` is retired, DECISIONS #3). Only
  list a demo that works: `test.sh` fails on a dead one (#4). The "Live demo" / "Source only"
  badge and the `/projects` filter derive from it (#5).
- Browser tests use an installed Chrome (`playwright.config.ts`). On this Mac it is at
  `/Applications/Chrome.app`, not the default path. No Playwright browser download is needed.
- `public/terra/` is a static page outside Astro: no footer, no analytics, no meta description.
