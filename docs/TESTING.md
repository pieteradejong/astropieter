# Testing

One entry point: `./test.sh`. Run it before every deploy — `deploy.sh` does not
run it for you.

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

**Dependency health** — `npm audit` clean, no legacy `src/content/config.ts`,
no unused `@astrojs/tailwind`, no lowercase route handlers (`get` instead of
`GET`, which silently broke RSS once), no `var()` inside a `@media` condition
(invalid CSS that LightningCSS now hard-errors on).

**Production build** — exits clean, no `[ERROR]`, no deprecation warnings.

**Build output** — every expected page exists; every published post and project
has a detail page; every draft is *absent* from the production build.

**RSS feed** — well-formed XML, no drafts, no `undefined` values.

**KaTeX** — the LaTeX post actually renders `class="katex"` markup.

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
"ability to build" …), thin descriptions, empty bodies, and entries with no
image. The banned list was built from phrases actually present in this repo,
not from a style guide.

**Accessibility** — every `<img>` has alt text, `<html>` has a lang, every
visible form field has a label.

**Metadata and SEO** — canonical URLs all point at the configured host; every
Astro page has a title and description; Open Graph and Twitter card tags;
sitemap generated. Pages served verbatim from `public/` are checked separately,
since they never pass through `BaseHead` and the fix lives in the source file.

**Payload weight** — the README calls loading speed a top priority, so weight is
a check rather than a note. Flags any shipped file over 1 MB, an oversized total
build, and any Astro starter placeholder still shipping.

**Repository hygiene** — `deploy.sh` gitignored, `.deploy-env` untracked,
LICENSE present, working tree clean, branch level with its remote, and **no
ignored directory holding source that is not in git**. That last one is the
`preview-terracotta/` lesson: a complete restyle lived in a gitignored folder,
in exactly one copy, invisible to every tool, for as long as it did because
nothing looked.

**Outbound link integrity** — every `githubUrl`, `demoUrl` and `deploymentUrl`
in project frontmatter is fetched. Internal demos must exist as a real page in
the build. A host that does not answer is distinguished from the network being
down, because a demo link that hangs reads to a visitor exactly like one that
is broken.

**Dev server smoke test** — starts Astro on :4322, checks every main route
returns 200, and confirms drafts *are* reachable in dev.

## What it does not cover

- **Visual regression.** Nothing renders the page and looks at it. The theme
  checks prove the right tokens ship, not that the layout is right.
- **JavaScript behaviour.** The project-card expand/collapse is untested.
- **The terra page.** `public/terra/index.html` is a 5 MB self-contained
  artifact served verbatim; only its weight and metadata are checked, not its
  contents.
- **Cross-browser and mobile rendering.**
- **Anything about the live site.** All checks run against `dist/` and a local
  dev server. Nothing verifies what SiteGround is actually serving.

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
