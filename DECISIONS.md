# Decisions

Append-only. Supersede an entry with a new one that links back.

## 1. Host on Vercel, as the one platform for this site and future apps
**Date:** 2026-09-24
**Context:** SiteGround was cancelled as too expensive, leaving the site with no host and
`site` pointing at a dead `sg-host.com` address. The replacement also has to be the single
platform for future production apps: full-stack web, Python (FastAPI) backends, background
work, containers. Requirements: $0 now and pay per app later, personal use, deploy on push,
cookie-less analytics, a free subdomain. Data and auth stay on Supabase. No app needs a 24/7
always-on process.
**Decision:** Vercel, project `padj` in team `pieteradejongs-projects`, at
https://padj.vercel.app. It runs every app type on the list: Functions (Node, Python, Go),
container images (stateless, autoscaling), WebSockets, Queues, Workflow, Cron, and Services.
Supabase is a first-party integration. Hobby plan now. **Move to Pro the day anything hosted
here serves paying users** (Hobby is non-commercial). The site stays static; add
`@astrojs/vercel` only when a page needs server rendering.
Rejected:
- Cloudflare Pages/Workers: unlimited static bandwidth, but weaker fit for Python and
  containers.
- Render, Railway, Fly: always-on containers, but a weaker frontend story, and free tiers that
  sleep or no longer exist.
- Staying on SiteGround: cost.
Reopen if an app needs an always-on process, which Vercel does not host.
**Verified:**
- `git push origin main` (02103fc) produced a production deployment with no manual step.
  `vercel inspect` reported `target production`, `status ● Ready`, aliased to
  `https://padj.vercel.app`.
- `./test.sh --live https://padj.vercel.app` → `13 passed, 0 failed`:
  - all 10 routes return 200 on the same host
  - canonical is `https://padj.vercel.app/`
  - `/_vercel/insights/script.js` is served
  - every blog post renders in Chrome with no math errors, leaked LaTeX or console errors
- Anonymous `curl https://padj.vercel.app/` → `<meta name="generator" content="Astro v7.3.5">`.
- PARTIAL: a first pageview has not yet been confirmed in the Web Analytics dashboard (it
  lags). Recheck on the next visit to the dashboard.

## 2. Analytics verification for #1 corrected: the API, not the script
**Date:** 2026-09-25
**Context:** #1's Verified line counted "`/_vercel/insights/script.js` is served" as analytics
working. It is not proof: Vercel serves that script whether or not Web Analytics is enabled, and
on 2026-09-24 at 18:35 EDT the API reported "Web Analytics is not enabled for this project" while
that check passed. This entry supersedes #1's analytics line and resolves its PARTIAL item. The
hosting decision in #1 stands.
**Decision:** analytics counts as working only when the Web Analytics API returns data.
`./test.sh --live` now queries it with `vercel api` (a window within the last 31 days, as Hobby
only serves those, rounded to whole days) and fails on "not enabled". The script check stays as
a separate, weaker signal.
**Verified:**
- Analytics was enabled in the dashboard around 19:00 EDT on 2026-09-24.
- `vercel api "/v1/query/web-analytics/visits/aggregate?…&since=2026-09-24T00:00:00Z&until=2026-09-27T00:00:00Z&by=requestPath"`
  at 07:59 EDT on 2026-09-25 → `{"requestPath": "/", "visitors": 1, "pageviews": 1}`.
- `./test.sh --live https://padj.vercel.app` → `14 passed, 0 failed`, including
  `✓ Web Analytics is enabled and queryable`.

## 3. One demo field: `demoUrl`
**Date:** 2026-09-27
**Context:** The projects schema had two optional fields for the same idea, `demoUrl` and
`deploymentUrl`. They rendered as two different labels ("Live Demo →" and "Demo →"), and a
project could set both. A "has a demo" flag needs one source of truth.
**Decision:** `demoUrl` is the only demo field. `deploymentUrl` is removed from
`src/content.config.ts` and from both project pages. `test.sh` fails if any project file still
uses `deploymentUrl:`. A demo can be internal (`/terra/`, served from `public/`) or an absolute
URL.
Rejected:
- Keeping both fields with a precedence rule: two names for one thing is how the mismatch
  started.
- Renaming to `liveUrl`: churn for no gain, since `demoUrl` was already the more common one.
**Verified:** `./test.sh` → `✓ no project uses the retired deploymentUrl field`, and
`grep -rn deploymentUrl src/` → no matches (exit 1).

## 4. A listed demo must work
**Date:** 2026-09-27
**Context:** Of 8 projects, 2 listed a demo. TV Show Chat's `https://tvshowchat1.onrender.com/`
gave no response in 20s on 2026-09-27 (a Render free tier that sleeps or is gone). `test.sh`
only warned on a timeout, so a dead demo sat on the live site. A "Live demo" badge (#5) that
points at a dead page is worse than no badge.
**Decision:** A dead demo is removed, not labelled. tvshowchat's link is dropped, and it now
shows as Source only. In `test.sh` § Outbound link integrity:
- A `demoUrl` that gives no response or 4xx/5xx is a **fail**.
- A `githubUrl` timeout stays a warning.
- The network is probed once up front. URLs are checked in sorted order, so without the probe a
  dead demo sorting before the first reachable host would have been skipped as "no network".
Rejected:
- Keeping the link with a "may be slow" note: visitors don't wait for a cold start either.
- Moving tvshowchat to Vercel now: it needs Redis and an embedding model, so it's a separate
  project. Re-add its `demoUrl` when that is done.
Reopen if a demo needs to stay listed while it's temporarily down.
**Verified:**
- `curl -m 20 https://tvshowchat1.onrender.com/` → `000` after 20.0s (2026-09-27).
- Mutation test: adding `demoUrl: "https://example.invalid/"` to `spacex.md` made
  `./test.sh` report `✗ demo https://example.invalid/ did not respond within 12s` and
  `118 passed, 1 failed`. With the file restored: `118 passed, 0 failed`.

## 5. Demo badge and filter on /projects
**Date:** 2026-09-27
**Context:** Visitors could not tell which projects they can try without scanning every card's
links.
**Decision:**
- Every project card and detail page shows a status badge on its own line above the tech stack:
  "Live demo" (accent) or "Source only" (muted). The badge is `src/components/DemoBadge.astro`,
  a thin wrapper around `Tag.astro`. The first version put it inline with the tech tags, where
  "Source only" read as one more technology, so it was moved.
- `/projects` has a filter: All (n) · With live demo (n). Counts are computed at build time.
  - Each card is wrapped in `.project-item[data-demo=yes|no]`.
  - A small inline script toggles `hidden` and keeps the state in `?demo=1`, so a filtered view
    can be linked.
  - The filter starts `hidden` and the script reveals it, so without JS every card shows and no
    dead control is shown.
  - The buttons use `aria-pressed`.
- `test.sh` checks that the number of "Live demo" badges equals the number of `demoUrl` entries,
  and that every card carries `data-demo`.
Rejected:
- Badge only, with no filter.
- Sorting demos first: it breaks the curated `order`.
- Mirroring the flag to GitHub (repo homepage URL or a `demo` topic): an outward-facing change
  on every repo, for a signal only this page uses.
**Verified:**
- `./test.sh` → `118 passed, 0 failed`, including:
  - `✓ projects page shows 1 'Live demo' badge(s), matching 1 demoUrl entries`
  - `✓ every project card (8) carries a data-demo flag`
- Headless Chrome (Playwright) against the dev server:
  - The default view shows 8 cards, with Terra as the only `yes`.
  - "With live demo" leaves only Terra and sets `?demo=1` and `aria-pressed=true`.
  - "All" restores 8 and clears the parameter.
  - Loading `?demo=1` directly shows only Terra.
  - No console errors.
  - With JS disabled, all 8 cards show and the filter is hidden.
  - At 375px, horizontal overflow is 0px.

## 6. Weekly broken-link report by email, through GitHub Actions
**Date:** 2026-09-27
**Context:** Pieter asked for a weekly email report of broken links of any kind. `test.sh` only
runs when someone runs it, and it only checks project links. The workspace has no mail-sending
tool, and its weekly jobs run under launchd, which cannot send mail.
**Decision:** `.github/workflows/link-report.yml`, run Mondays 13:00 UTC and on demand:
- It builds the site and runs lychee over every `dist/**/*.html` (internal links, blog outbound
  links, project source and demo links) plus the live homepage.
- It posts the report as a comment on the single open issue "Weekly link report", creating the
  issue on the first run. GitHub emails each comment to the repo owner. Clean weeks say
  "0 broken links", so silence means the job didn't run.
- The job then fails if anything is broken, which also triggers GitHub's failed-run email.
- Supply chain:
  - lychee-action is pinned by SHA (`e7477775…`, v2.9.0).
  - The issue step is ~15 lines of `gh`, not `peter-evans/create-issue-from-file` as first
    planned (`supply-chain.md` §1: own code beats a new dependency).
  - The install runs `npm ci --ignore-scripts`.
  - Only this job gets `issues: write`.
  - Checkout uses `persist-credentials: false`.
Rejected:
- SMTP or Resend: needs an API secret in the repo.
- A Claude scheduled routine with the Gmail connector: routes the site through a hosted agent
  and costs more for the same result.
- A launchd job: can't send mail, and only runs while the Mac is awake.
Reopen if the report becomes noise (tune `--accept` or exclude flaky hosts) or if the site
moves off GitHub.
Known limit: GitHub disables scheduled workflows in a public repo after 60 days without a
commit. It emails a warning first, and one push re-enables the schedule.
**Verified:** NOT YET. Needs the first run (`gh workflow run link-report.yml`) to succeed, the
issue to get its first comment, and the notification email to arrive.

## 7. QR code for sharing the site: one static SVG at `/qr/`
**Date:** 2026-10-14
**Context:** Pieter wants the easiest way to show a QR code that opens the site when meeting
someone. Requirements: works on his own phone with no app, nothing to type, no new moving parts.
**Decision:** `public/qr.svg`, generated once with `qrencode` (libqrencode 4.1.1 from Homebrew, a
system tool, not a project dependency) for `https://padj.vercel.app/`, shown on an unlisted page
`src/pages/qr.astro` with the URL printed underneath. The fixed `width`/`height` were stripped from
the SVG so it scales to `min(80vw, 420px)`; the SVG paints its own white ground so it scans under
the dark palette. The page is out of the nav and the sitemap (#9); the way to use it is to bookmark
`/qr/` on the phone. If the domain changes, regenerate the file (CLAUDE.md § Gotchas).
Rejected:
- An npm QR library at build time: a dependency, with install scripts to vet, for a one-off.
- A client-side QR script: JavaScript on a page whose whole content is one image.
- A third-party QR image API (`api.qrserver.com` and the like): every page view tells a third party
  the URL, and the code disappears if the service does.
- Nothing in the site, use the phone's share sheet: differs per OS version and is a fiddle in the
  moment.
**Verified:**
- `zbarimg` on a QuickLook render of `public/qr.svg` → `QR-Code:https://padj.vercel.app/`.
- `./test.sh` → `✓ GET /qr/ -> 200`, `✓ unlisted pages (/press/ /software/ /qr/) are out of the
  sitemap`, `✓ unlisted page still builds: /qr/`; `tests/mobile.spec.ts` passes `/qr/` at 320, 375
  and 414px (no overflow, no text under 12px).

## 8. Overflow on phones: fix the element, test every route, no page-level hack
**Date:** 2026-10-14
**Context:** `global.css` carried `.content-container, main, section, article, div { max-width:
100vw; overflow-x: auto }`. It kept the page from scrolling sideways by turning every block into
its own scroll container, so a too-wide element got a local scrollbar nobody noticed, `overflow-y`
computed to `auto` everywhere, and any future `position: sticky` would have broken. The only mobile
test covered two pages. Meanwhile the post-body rules in `BlogPost.astro` never reached rendered
Markdown (scoped styles do not match `<Content />` output), five pages doubled the gutter by
reusing `.content-container` inside the layout, three nested a second `<main>`, the About timeline
kept a 110px gutter at every width, the project grid's `1fr` min-content floor was wider than a
phone, and breakpoints disagreed (375/480/767/768/1023).
**Decision:**
- Targeted overflow rules: `pre`, `table` and `.katex-display` scroll inside their own box;
  `main, article, .prose { overflow-wrap: anywhere }` wraps long words and URLs; `img, video, svg {
  max-width: 100% }`. `html, body { overflow-x: hidden }` stays as the last line of defence only.
- One phone breakpoint, `max-width: 767px` (`min-width: 768px` for the horizontal nav).
  `--spacing-unit` already scales gutters, so pages drop their own 375/480px rules.
- `tests/mobile.spec.ts` runs every main route at 320, 375 and 414px: `scrollWidth <= clientWidth`
  and no visible element past the right edge (scroll containers excepted), no text under 12px,
  ≥44px nav/footer/form controls, ≥16px inputs, plus the hamburger, the horizontal nav and Terra's
  phone layout. It also runs under `./test.sh --live`.
- Post-body styles live in a `<style is:global>` block in `BlogPost.astro`.
Rejected:
- Keeping the blanket rule and adding the test on top: the rule hides exactly what the test looks
  for inside any `div`.
- `overflow-x: clip` on body only: same symptom-hiding, one level up.
- Per-page breakpoints as before: six values that never agreed, and dead rules nobody could tell
  from live ones.
**Verified:**
- `./test.sh` → `171 passed, 0 failed, 9 warnings` (was 118 passing before this session; the new
  mobile suite adds 44 checks).
- Mutation test on `/about/` at 375px: a `600px`-wide div fails the test naming the element
  (`div#MUT1 right=612`); a 140-character unbroken word alone passes (wrapped by `overflow-wrap`).
  File restored afterwards.
- Built `dist/blog/why-blog/index.html`: `.prose` element rules now ship unscoped and apply to the
  Markdown `<p>`/`<pre>` elements.
- Terra at 375px (Playwright): `#panel` hidden until the 44px `#panelToggle`; a shown `#card` sits
  below `#title`; no text under 12px.

## 9. Unlisted pages: out of the sitemap, kept in the build
**Date:** 2026-10-14
**Context:** `/press/` (one paragraph) and `/software/` (three, with a commented-out nav link) are
unfinished and linked from nowhere, yet sat in the sitemap. `/blog/latex_test/` was a published
KaTeX rendering test with typos and a dead link, and the second of only two posts on the blog
index. `/qr/` (#7) is a utility page that should not rank.
**Decision:** `sitemap({ filter })` in `astro.config.mjs` drops `/press/`, `/software/` and `/qr/`;
the files stay and the routes still build and return 200. `LaTeX_test.md` is `draft: true` (and
loses the schema-unknown `hook:` field). `test.sh` fails if an unlisted page appears in
`dist/sitemap-*.xml` or stops building, and its KaTeX dist check now warns instead of failing when
no published post uses math (the browser fixtures cover the pipeline).
Rejected:
- Deleting press and software: Pieter wants to finish them (docs/CONTENT-REVIEW.md).
- Linking them in the nav as they are: thin pages in the main navigation.
- Keeping latex_test public with the typos fixed: a test page is not an essay, and the blog's
  second entry should be one.
**Verified:**
- `grep -c 'press/\|software/\|qr/' dist/sitemap-0.xml` → `0`; `ls dist/blog/latex_test` → no such
  file; `dist/press/index.html`, `dist/software/index.html`, `dist/qr/index.html` exist.
- `./test.sh` → `✓ unlisted pages (/press/ /software/ /qr/) are out of the sitemap`, three
  `✓ unlisted page still builds`, `! no published post exercises KaTeX in the build`.
