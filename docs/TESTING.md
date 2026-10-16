# Testing

One entry point: `./test.sh`. Run it before every push to `main` — pushing deploys,
and Vercel does not run it for you. GitHub does, after the fact: `.github/workflows/ci.yml`
runs `./test.sh --offline` on every push and pull request (check **site / tests**) and
`./test.sh --live https://padj.vercel.app` once Vercel reports the production deployment
(check **site / live**). The network-dependent sections stay out of the push check so a
third-party outage cannot turn the repo red; the weekly link report covers them.

```bash
./test.sh              # everything
./test.sh --offline    # skip the checks that need the network
```

## Three verdicts, not two

| | Meaning | Exit code |
|---|---|---|
| ✓ **pass** | Checked and correct. | — |
| ✗ **fail** | Broken. The run exits non-zero. | 1 |
| ! **warn** | A real gap that is known and accepted for now. Reported every run, never fails the build. | 0 |
| – **skip** | Could not be determined, usually no network. | 0 |

The warn tier exists so the suite can report true things — no Open Graph tags,
no project screenshots — without failing on them every run until they are fixed.
A suite that always fails is a suite nobody reads. **Warnings are a worklist,
not noise: the intent is for the count to go down.**

## What it covers

Eleven sections, ~93 passing checks.

**Environment** — Node ≥ 22.12 (Astro 7's floor), `node_modules` present.

**Dependency health** — `npm audit` with nothing moderate or worse (low advisories with
no non-breaking fix warn; today that is `katex` via `rehype-katex` 7), no legacy `src/content/config.ts`,
no unused `@astrojs/tailwind`, no lowercase route handlers (`get` instead of
`GET`, which silently broke RSS once), no `var()` inside a `@media` condition
(invalid CSS that LightningCSS now hard-errors on).

**Production build** — exits clean, no `[ERROR]`, no deprecation warnings.

**Build output** — every expected page exists; every published post and project
has a detail page; every draft is *absent* from the production build; the
`build-commit` stamp in `dist/index.html` is HEAD.

**RSS feed** — well-formed XML, no drafts, no `undefined` values.

**KaTeX** — a published post that uses math actually renders `class="katex"` markup, and
the CDN stylesheet version matches the renderer's katex. With no published math post (the
LaTeX test post is a draft) this warns; the browser fixtures still cover the pipeline.

**Theme integrity** — the section that keeps the design system honest. The
shipped CSS bundle must contain *no color outside the sixteen terracotta tokens*
(eight light, eight dark) and no face outside the three `--pub-font-*` roles.
Also: both palettes present, `color-scheme` declared, no shadows or gradients
(the BRIEF forbids both), all three token sheets present, `data-pub-theme` on
`<html>` in both layouts, eight woff2 files with eight `@font-face` rules, and
the fonts' OFL notice shipping alongside them.

There is a source-side twin: **no raw hex in any component or page**. That single
check is what made dark mode safe to enable — the palette had been held back for
months on the belief that scoped styles still hardcoded light colors, and nobody
could cheaply prove otherwise.

**Color contrast** — computes WCAG ratios from the theme file itself, for both
palettes, on every text/ground pair. Fails below 4.5:1. The bright accent is
knowingly 3.95:1 and is restricted to decoration, so it is held to the 3:1
non-text threshold instead.

**Project content quality** — reads each entry's frontmatter and body and
reports filler phrasing ("demonstrates", "showcasing", "comprehensive",
"ability to build" …), thin descriptions, empty bodies, entries with no
image, and entries with no `githubUrl` (a warning: the showcase rules in
`PORTFOLIO.md` say a shown project links its source, and the one current
exception is recorded there). The banned list was built from phrases actually
present in this repo, not from a style guide.

**Accessibility** — every `<img>` has alt text, `<html>` has a lang, every
visible form field has a label.

**Metadata and SEO** — canonical URLs all point at the configured host; every
Astro page has a title and description; Open Graph and Twitter card tags;
sitemap generated, with the unlisted pages (`/press/`, `/software/`, `/qr/`) kept
out of it and still built. Pages served verbatim from `public/` are checked separately,
since they never pass through `BaseHead` and the fix lives in the source file.

**Payload weight** — the README calls loading speed a top priority, so weight is
a check rather than a note. Flags any shipped file over 1 MB, an oversized total
build, and any Astro starter placeholder still shipping.

**Repository hygiene** — `.vercel/` gitignored, `site` not left on a dead host,
LICENSE present, working tree clean, branch level with its remote, and **no
ignored directory holding source that is not in git**. That last one is the
`preview-terracotta/` lesson: a complete restyle lived in a gitignored folder,
in exactly one copy, invisible to every tool, for as long as it did because
nothing looked.

**Deployment pipeline** — static checks of the wiring that the first real CI runs
got wrong (DECISIONS #11–#14): `ci.yml` exists, its live job accepts both names
Vercel gives the GitHub environment and waits for a successful deployment, every
job has a timeout, both `test.sh` modes are wired, `engines.node` and the CI Node
major agree, third-party actions are pinned by SHA, `test.sh` itself starts the
dev server with `--background`, and nothing that ships or that a reader follows
names the retired SiteGround host.

**Outbound link integrity** — every `githubUrl` and `demoUrl` in project
frontmatter is fetched. Internal demos must exist as a real page in the build. A
host that does not answer is distinguished from the network being down, because
a demo link that hangs reads to a visitor exactly like one that is broken. Then
every absolute link on the built `/reading/` and `/about/` pages is fetched with
a browser user-agent: 4xx/5xx fails, no answer warns, and the bot walls the weekly
workflow excludes (LinkedIn, genius.com) are skipped here too. The weekly lychee
job (`link-report.yml`) remains the backstop for every other page.

**Dev server smoke test** — starts Astro on :4322 with `--background` (and fails
if the command has not detached within 60 s, instead of hanging as it once did in
CI), checks every main route returns 200, and confirms drafts *are* reachable in dev.

**Browser tests** (Playwright on the installed Chrome, against that dev server):

- `tests/content.spec.ts` — every Markdown/GFM construct, inline and display math in
  `.md` and `.mdx`, the KaTeX stylesheet and fonts actually applied, project heroes
  loading, and every post free of math errors, leaked LaTeX and console or network
  errors. Fixtures are draft posts, never built for production.
- `tests/mobile.spec.ts` — every main route at 320, 375 and 414px: the page is no
  wider than the viewport and no element sticks out past the right edge (code,
  tables and display math may scroll inside their own box); no visible text under
  12px; nav, footer, form buttons and button-links ≥44px tall, form fields ≥40px,
  prose links ≥24px; inputs ≥16px so iOS does not zoom. The hamburger opens a menu
  of full-width ≥44px links directly under the header, moves focus in, and Escape
  closes it and restores focus; the name truncates on a 320px screen; the horizontal
  nav fits at 768, 900 and 1024px. Terra at 375px: the layer panel is behind a
  ≥44px Layers button and the chokepoint card is a bottom sheet below the title.
  Terra under `prefers-reduced-motion`: auto orbit off and at most a few redraws a
  second (the Terra layout tests run under that setting, because the full-rate
  WebGL loop starves the main thread on a CI runner); without it, auto orbit on.

Under `--live`, the content tests that need no fixtures and the whole mobile suite
run against production, plus: every route answers, the canonical host, the
`build-commit` stamp equals `origin/main` (a deploy that is missing, failed or
still building is a failure; local work that is not live is a warning), the
analytics script and API, and the Vercel project's link to this repo's `main`.

## What it does not cover

- **Visual regression.** Nothing renders the page and looks at it. The theme
  checks prove the right tokens ship, not that the layout is right.
- **JavaScript behaviour.** The project-card expand/collapse is untested (the
  hamburger menu and the Terra layer toggle are).
- **The terra page's content.** `public/terra/index.html` is a self-contained
  artifact served verbatim; its phone layout, layer toggle and reduced-motion mode
  are tested, the globe itself is not.
- **Cross-browser rendering.** Mobile layout is covered (above), but only in Chrome;
  Safari on iOS is not exercised. `./run.sh` serves on the LAN for a real-phone check.
- **The live site, unless asked.** The default run checks `dist/` and a local dev
  server. `./test.sh --live <url>` checks what Vercel is actually serving.

## Gotchas when editing this file

Two bugs bit during its construction, both worth knowing:

1. **`grep -c` counts lines, not matches.** The production CSS is minified onto
   one line, so eight `@font-face` rules and three `<label>` tags each counted
   as 1. Use `grep -o … | wc -l`.
2. **`cmd | while read` runs the loop in a subshell**, so `pass`/`fail` counters
   increment and then vanish. Use a here-string (`done <<< "$OUT"`) instead. A
   heredoc cannot live inside `<(…)` process substitution, so capture into a
   variable first.

Also: `curl -L` writes `%{http_code}` once per redirect hop, so a chain yields
`301200` and a timeout `000000`. Only the last three digits are the outcome.
