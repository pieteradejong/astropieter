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
**Verified:** 2026-10-14, after the link fixes of ba48af8 were pushed. `gh workflow run
link-report.yml` → run 38605109476 `completed success` in 29s (`gh run list --workflow
link-report.yml --limit 1`). The three scheduled runs before it (2026-09-28, 10-05, 10-12) had
failed on dead Amazon links and the genius.com 403, which that commit fixes and excludes.
Issue #2 "Weekly link report" got the run's comment at 17:15:52Z. Notification email: not checked
from here.

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

## 10. The site's health is a GitHub check, not a statement
**Date:** 2026-10-14
**Context:** Pieter asked for checkmarks on the GitHub repo showing the website fully works. Until
now `./test.sh` only ran when someone ran it, Vercel never runs it, and the only checks on a commit
were the security workflow, Vercel's own build status and the weekly link job. "171 passed" in a
terminal is not visible to anyone else and says nothing about what visitors get.
**Decision:** `.github/workflows/ci.yml`, two jobs, both pinned by SHA and `contents: read`:
- `tests`: on push to `main` and on pull requests, `npm ci --ignore-scripts`, Playwright's own
  Chromium (`playwright.config.ts` already falls back to it when no Chrome path exists), then
  `./test.sh --offline`. The network sections (outbound links, KaTeX SRI fetch, Web Analytics API)
  stay out, so a third-party outage cannot fail the push check; the weekly link report owns links.
- `live`: on Vercel's `deployment_status` success for the environment `Production – padj` only
  (the repo also receives statuses from a second, misconfigured Vercel project, TODO.md), checks
  out the deployed commit, waits for the deployment URL and the alias to answer, then runs
  `./test.sh --live https://padj.vercel.app`: every route, canonical host, analytics script, and
  the browser suites (content and mobile) against the served site. Also runnable by hand with a
  URL (`workflow_dispatch`).
- README carries the badges for `site`, `security` and `link-report`.
Rejected:
- Running the full networked suite on push: Amazon and similar hosts answer CI runners
  unpredictably; the push check would go red for reasons unrelated to the commit.
- A cron that checks production every hour: noise without a cause to attach it to; the
  deployment event is the moment that matters, and the weekly link job already covers drift.
- Vercel's own build check as "the site works": it proves the build command exited 0, not that a
  route renders or that a phone can use it.
- Making the checks required on `main` (branch protection): GitHub-side setting, and EN-3 in the
  workspace TODO is still Pieter's call.
**Verified:** 2026-10-14, on the third push. The first (36f3abd) produced a Ready Vercel deployment
and `./test.sh --live https://padj.vercel.app` → `60 passed, 0 failed` locally, but `site / tests`
(run 38603520687) was cancelled at the 20-minute timeout (#12) and `site / live` was skipped (#13).
The second (05b7e25) ran both to the end; each failed on one Terra test (#14). The third (387593a):
`gh run list --workflow ci.yml` → `site` push run 38638470496 `success` (1m43s) and `site`
deployment_status run 38638495290 `success` (1m48s). Both checks show green on the commit.

## 11. The old SiteGround address is left to lapse; Vercel is the only production
**Date:** 2026-10-14
**Context:** Pieter reported that "production" at `https://pieterd38.sg-host.com/` still showed the
old style. That address is the SiteGround host retired in #1; it still serves a build from
2025-06-17 (Astro 5.8, pre-restyle) because the cancelled plan runs until November 2026. The
restyled site has been live on Vercel since September. Pieter: "i have already cancelled my
siteground by november ... lets focus on vercel".
**Decision:** nothing is deployed to SiteGround again and no redirect is installed there. The
address expires with the plan. `DEPLOYMENT.md` § Old host records this; external links that still
point at it (profiles, signatures, printed QR codes) are repointed to https://padj.vercel.app by
Pieter before November.
Rejected:
- Redeploying the current build to SiteGround: restores the rsync path removed in 17dc0d6 and
  keeps two production hosts for a few weeks, for an address nobody should keep using.
- Uploading an `.htaccess` redirect to padj.vercel.app: needs SSH or dashboard access to an
  account that is going away, and the plan ends in weeks anyway.
Reopen if the SiteGround plan is renewed, or if a custom domain is bought (then `site`,
`public/qr.svg` and the canonical URL move together, see #7).
**Verified:**
- `curl -sI https://pieterd38.sg-host.com/` → `last-modified: Tue, 17 Jun 2025`; the body carries
  `generator" content="Astro v5.8.0"` and no `data-pub-theme`.
- `curl -s https://padj.vercel.app/` → `data-pub-theme="terracotta"`, `Astro v7.3.5`.
- `grep -rn sg-host src public docs` → no reference; only #1 names it.

## 12. The dev server in `test.sh` is started with an explicit `--background`
**Date:** 2026-10-14
**Context:** The first real `site / tests` run (#10) was cancelled at its 20-minute timeout, stuck
at "Dev server smoke test" (run 38603520687). `test.sh` launched `npx astro dev --port 4322` in the
foreground, relying on a comment that "Astro's dev server now self-daemonizes". It does not: Astro 7
backgrounds only with `--background`, or when `am-i-vibing` detects an AI agent as the parent
process. Every local run had been started from Claude Code, so the suite passed here and blocked on
the runner.
**Decision:** `npx astro dev --background --port 4322`. The flag is the documented behaviour, works
in a plain shell and in CI, and keeps the existing teardown (`astro dev stop` in `cleanup`).
Rejected:
- Setting `ASTRO_DEV_BACKGROUND=1` or faking an agent environment: undocumented switches.
- `npx astro dev &` with a PID kill: Astro's lock file would still see a running server, and
  `astro dev stop` is what the script and `run.sh stop` already use.
- Running the browser tests against `astro preview` of the build instead: dev mode is what the
  draft-post check exercises.
**Verified:**
- Reproduced in a cleared environment (`env -i` with only PATH and HOME):
  `timeout 15 npx astro dev --port 4323` → exit 124, still in the foreground after 15 s.
- Same environment with the flag: `npx astro dev --background --port 4323` returns, prints
  `Stop: astro dev stop`, and `curl http://localhost:4323/` → 200.
- Same environment, `./test.sh --offline` → `164 passed, 0 failed, 9 warnings, 2 skipped`
  (the two skips are the network sections `--offline` turns off).
- CI: push 387593a → `site / tests` run 38638470496 `success` in 1m43s; the smoke test and the
  browser suites ran on the runner.

## 13. `site / live` accepts the environment names `Production` and `Production – padj`
**Date:** 2026-10-14
**Context:** On the first deployment after #10 was pushed, the `live` job was skipped (run
38603552773). Its filter required `github.event.deployment.environment == 'Production – padj'`,
copied from October's deployment events. Vercel names the GitHub environment `Production` while one
project is linked to the repo and `Production – <project>` when several are; a second project had
been linked on 2026-10-04/05 and has since been relinked, so the name changed back.
**Decision:** match either name. Any other environment is still ignored.
Rejected:
- Matching on `startsWith(environment, 'Production')`: would run against a stray project's deploy.
- Matching on `environment_url`: the per-deployment URL is not the production alias, and the job
  checks https://padj.vercel.app regardless.
**Verified:**
- `gh api 'repos/pieteradejong/astropieter/deployments?per_page=3' -q '.[] | .environment'` →
  `Production` for 36f3abd; `Production – padj` and `Production – sovereign-data-centers` for 3621d24.
- CI: pushes 05b7e25 and 387593a each produced a GitHub deployment `Production`, and `site / live`
  ran on both (runs 38636383406, 38638495290) instead of being skipped; the second is `success`.

## 14. Terra honours reduced motion, and its browser tests run under it
**Date:** 2026-10-14
**Context:** With #12 and #13 in place, both GitHub checks ran to the end and failed on one test
each: "Mobile: Terra › at 375px the layer panel is behind a Layers button" timed out on
`locator.click` after 30 s (runs 38636353396 and 38636383406). Reproduced with Playwright's bundled
Chromium on this Mac: the test passes but takes 13 s, and every step after load is slow (a bounding
box ~0.8 s, a click ~1.5 s). The cause is the page, not the test: `public/terra/index.html` renders
a post-processed WebGL frame on every animation frame, which on the runner's 2 vCPU with software
WebGL leaves no idle frames for Playwright's actionability checks.
**Decision:** the page honours `prefers-reduced-motion: reduce`: auto orbit is off and the scene
redraws about four times a second (`setTimeout` 250 ms before the next `requestAnimationFrame`)
instead of every frame. The Terra tests emulate that preference (`page.emulateMedia`) and the 375px
test is marked `test.slow()` (90 s). Measured with the bundled Chromium: steps after load drop from
seconds to milliseconds; the test goes from 13 s to 5 s.
Rejected:
- Only raising the timeout or using `click({ force: true })`: masks a page that saturates the main
  thread, and would still be fragile on a slower runner.
- Skipping the Terra tests in CI: the mobile layout of the demo is exactly what #8 added them for.
- Rendering on demand (only when state changes): the right end state, but a larger change to the
  frame loop, hooks and cable animations than this fix needs.
Reopen if the reduced-motion frame rate makes the globe feel broken for users who have the OS
setting on; 4 fps was chosen so drags still respond.
**Verified:**
- `node` script with the bundled Chromium, 375px, `emulateMedia({ reducedMotion: 'reduce' })`:
  goto 3.3 s, then toggle visible +136 ms, click +35 ms, panel visible +1 ms, two bounding boxes
  +6 ms; `#tAuto.checked` → false. Same steps without reduced motion: 3.7 s, then +0.8 s, +1.5 s,
  +0.3 s, +2.4 s.
- `CHROME_PATH=<bundled chromium> npx playwright test -g Terra` → `6 passed (7.2s)`, the 375px
  test 4.9 s (13.5 s before).
- `./test.sh --offline` in a cleared environment → `164 passed, 0 failed, 9 warnings, 2 skipped`.
- CI: push 387593a → `site / tests` 38638470496 `success`, `site / live` 38638495290 `success`;
  the Terra 375px test passed in both.

## 15. Every page is stamped with its commit, and `--live` compares it with `origin/main`
**Date:** 2026-10-14
**Context:** Two finished commits (ba48af8, 36f3abd) sat unpushed for a session while `./test.sh`
was green: "branch is level with its remote" only warns, by design, because the suite runs before
the push. Nothing compared what production serves with what the repo holds; the gap was found by
hand (`vercel ls` plus `git status -sb`). Pieter: "ensure to capture everything in a comprehensive
test.sh or other testing methods".
**Decision:** `astro.config.mjs` defines `__BUILD_COMMIT__` from `VERCEL_GIT_COMMIT_SHA` (set by
Vercel at build time) or `git rev-parse HEAD`, and `BaseHead.astro` emits it as
`<meta name="build-commit">`. `./test.sh` checks the built stamp is HEAD. `./test.sh --live` fails
when production's stamp differs from `origin/main` (`git ls-remote`) and warns when local HEAD is
not what production serves. The `live` CI job runs the same check after every deployment, so a
push whose build failed, or a deployment that never happened, is a red check.
Rejected:
- Comparing the `last-modified` header or Vercel's deployment list: says when, not what, and the
  deployment list needs the CLI and a login that the `live` job does not have.
- Making the unpushed-commits warning a failure: the suite is meant to run before the push, so
  "ahead of origin" is its normal state.
- Exposing the commit on a `/version` route: one more unlisted page to keep out of the sitemap,
  for information a meta tag carries on every page.
Reopen if the site ever builds from something other than a git commit.
**Verified:**
- `npm run build` locally → `dist/index.html` contains `<meta name="build-commit" content="<HEAD>">`,
  and `./test.sh` → `✓ build-commit stamp is HEAD`.
- `./test.sh --live https://padj.vercel.app` before this change was deployed → `63 passed, 1 failed`,
  the failure being `✗ no build-commit stamp on https://padj.vercel.app/` (production still served
  387593a, which predates the stamp), and `✓ Vercel project is linked to github
  pieteradejong/astropieter, production branch main`.
- `./test.sh --offline` in a cleared environment → `176 passed, 0 failed, 9 warnings, 2 skipped`,
  including the nine new "Deployment pipeline" checks and the two Terra reduced-motion tests.
- Push 4aabb1f: `site / tests` run 38639999743 `success` (2m28s); `site / live` run 38640032517
  `success` (2m34s) with `✓ production serves origin/main (4aabb1f)`, `62 passed, 0 failed, 1
  skipped` (the Vercel API checks need a CLI login the runner does not have).
- Local, once production served the new stamp: `./test.sh --live https://padj.vercel.app` →
  `64 passed, 0 failed, 0 warnings, 0 skipped`.

## 16. The header gets a 960px column; the prose measure stays 720px
**Date:** 2026-10-14
**Context:** On desktop the six nav links wrapped, with Contact alone on a second row, because the
header shared the page's 720px `.content-container` and the tracked uppercase labels plus 1em
padding do not fit in it. Pieter: "this one is on two lines, it needs to be on one (desktop)".
**Decision:** `header .content-container` is 960px wide; link padding 0.6em and a 0.5rem gap from
768px; `white-space: nowrap` on labels; `flex-wrap: nowrap` from 1024px. The 720px measure for
`main` is unchanged. The dropdown's box border is phone-only.
Rejected:
- Shrinking the label size or tracking until six fit in 720px: the labels are the system's one
  sans role and already at its smallest readable size.
- Dropping or renaming "Reading and Lyrics": content decision, not a layout fix.
- Letting the nav wrap by design: a centred orphan under five links reads as a mistake.
Reopen if a seventh nav item is added; at 960px there is room for one, not two.
**Verified:** `npx playwright test -g nav` → `8 passed`, including the new `nav links sit on one
row at 1024px / 1280px`; screenshots at 768, 1024 and 1280px show one row. `./test.sh --offline`
in a cleared environment → `178 passed, 0 failed, 9 warnings, 2 skipped`.

## 17. Portfolio rules live in this repo; per-repo status lives in the private register
**Date:** 2026-10-16
**Context:** The rules for the online portfolio were scattered: showcase requirements in the
`pieteram` notes repo (a planned pieter.am site that never existed), demo and page rules in
entries #3–#5 and #9 here, nothing anywhere about the GitHub profile README, the public repo
listing or the other satellite repos. The portfolio is the whole public presence, not just this
site, and it needed one place that a reader of this repo would find.
**Decision:** `docs/PORTFOLIO.md` holds the doctrine: surfaces, showcase criteria, the publish
checklist, content and voice rules, satellite repo policy. It is public, so it holds rules only.
Which repo is shown, source-only or a candidate is recorded in the private workspace register
(`repos.md`, column `Portfolio`), never here. `./test.sh` checks what it can of the criteria
and now warns when a project entry has no `githubUrl`. `pieteram` is folded in and archived.
Rejected:
- `dotfiles/docs/`: fails that repo's own scope test (restore the machine, or someone would copy
  it), and the security material there is already being moved out for the same reason.
- A new private repo for the rules and the status together: one more repo for one file, and the
  rules would then live apart from the site they govern.
- Making this repo private so the status could live next to the rules: switches off GitHub
  secret scanning and push protection (free only for public repos on a personal account) and
  retracts nothing, since everything here has been public since the first push.
**Verified:**
- `./test.sh` (full suite, with network) after the change: `184 passed, 0 failed, 11 warnings`,
  exit 0; the new warning fired once, for `chrome-bookmarks.md: no githubUrl`.
- Every path cited in `docs/PORTFOLIO.md` exists (`test -e` over the extracted paths), and every
  `DECISIONS` number cited is ≤ 17.
- Register: the main table of `repos.md` has 136 rows of equal width after the column was added
  (`awk -F'|' ... | sort -u` → one value, `10`).
- `/bin/bash -n test.sh` parses under bash 3.2.

## 18. The portfolio vet is a script in this repo that reads the filesystem and `gh`, and records judgments only in the private register
**Date:** 2026-10-16
**Context:** The register's `Portfolio` column (#17) was seeded from the five existing pages;
127 rows said `—` by default. Vetting about 130 directories by hand each time is not
repeatable, and nothing existing emits one row per repo with the signals the showcase musts
need: `dotaudit` records findings only, the GitHub baseline register holds aggregates.
**Decision:** `scripts/vet-projects.sh`, read-only toward every project, scores each directory
under `~/dev/projects` on 8 mechanical musts behind a gate (third-party, satellite, retired,
take-home, archived, must-stay-private), using one `gh repo list` call for GitHub metadata.
Output goes to `~/dev/audit-reports/`, mode 600, and the script refuses a git repo as output
directory. The lists that are judgments arrive as environment variables, so the public script
names no repo it has an opinion about. The qualitative read and its verdicts are recorded in
the dated report and the private register; `docs/PORTFOLIO.md` § Vetting the pool documents the
method only.
Rejected:
- A `dotaudit` module: that tool records problems, not a per-repo profile, and its repo's
  README says audit tooling is moving out of dotfiles.
- A one-off script: the column has to be re-measured as projects change.
- Verdicts in this repo: it is public; "not ready" judgments about named repos belong in the
  private register (D9 of the workspace design decisions).
**Verified:**
- First run 2026-10-16: 138 rows (103 repos, 4 nested, 31 not-git); gate hits 53 (31 not-git,
  8 third-party, 5 must-stay-private, 4 satellite, 2 retired, 2 archived, 1 take-home); 85
  scored, range 1/8 to 8/8; both files `stat -f %Lp` → `600`; `git -C ~/dev/audit-reports
  rev-parse` fails, so the output is outside git.
- Spot-check against `gh repo view` and `git log -1` on tvshowchat, games (`cnc-web`),
  go-service, eu27-data-sovereignty, transcriptions (`private-llm`): visibility, license and
  last-commit agree. A first run read CI as absent on repos with workflows; fixed (the `ls`
  over two globs failed when `.yaml` matched nothing) and re-run before the numbers above.
- `/bin/bash -n scripts/vet-projects.sh` parses; `--help` exits 0.
- `./test.sh` (full suite) after adding the script and docs: `185 passed, 0 failed, 10 warnings`.

## 19. A missing Web3Forms key fails `--live`, warns offline, and disables the form
**Date:** 2026-10-20
**Context:** Production `/contact/` shipped with an empty `access_key` because
`PUBLIC_WEB3FORMS_KEY` is not set on the Vercel project. The page looked fine and every
submission was rejected by Web3Forms; no check noticed, and `DEPLOYMENT.md` said the site needs
no environment variables.
**Decision:** `./test.sh --live` fails when the served `access_key` input has no value, so the
`site / live` check turns red after a deploy without the key. The build checks only warn, because
CI's `--offline` build and fresh clones have no key. `contact.astro` renders the submit button
disabled with "The contact form is temporarily unavailable." when the key is empty, and the
script refuses to post a keyless request. The key is set by Pieter, never by the assistant.
Rejected:
- Failing the build when the key is missing: breaks CI's offline build and any fork, while the
  real question is what production serves.
- A `mailto:` fallback: the site publishes no email address, and adding one is a content decision.
**Verified:**
- `./test.sh --live https://padj.vercel.app` (before the key is set) → `✗ contact form has no
  Web3Forms access key …`, `66 passed, 1 failed`: the check catches the live bug.
- `./test.sh --offline` (local `.env` has a key) → `✓ contact form carries a Web3Forms access
  key`, `179 passed, 0 failed, 10 warnings, 2 skipped`.
- `PUBLIC_WEB3FORMS_KEY= npx astro build --outDir <scratch>` → `<button type="submit" disabled …>`
  and the result line reads "The contact form is temporarily unavailable."
- NOT YET: production with the key set — `--live` passing and one real submission arriving
  (`~/dev/TODO.md`, astropieter section).

## 20. Project pages come from the project repo's `portfolio.md`, pulled in by a sync script
**Date:** 2026-10-22
**Context:** Pieter wants one pipeline: push a project, it deploys to its own Vercel project, and a
flag decides whether it is listed here. The flag controls listing only, not hosting. Until now each
page was written by hand in this repo (`docs/PORTFOLIO.md` § Publishing a project), and nothing
connected it to the project it describes.
**Decision:** The project repo owns its page. `portfolio.md` at its root holds the schema's
frontmatter, `public: true|false` and the body. `scripts/sync-projects.sh`, run by hand on a branch
here, reads that file from every public repo through `gh` and writes or removes
`src/content/projects/<repo>.md` and its hero. Generated pages carry `syncedFrom: "<repo>@<sha>"`
(a new optional schema field). The script only rewrites or removes pages with that field, refuses a
slug that collides with a hand-written page, keeps a page when a read fails with anything but a
404, and refuses single-quoted `githubUrl`/`demoUrl`, which the link checks would not see.
Pushing `main` is still the deploy, after `./test.sh`.
Rejected:
- A `listed:` field on pages in this repo: an unlisted project's page would still sit in a public
  repo.
- Fetching `portfolio.md` at build time: the site would change without a commit here, and
  `./test.sh` would test something other than what ships.
- An Action in each project repo that opens a PR here: it needs a long-lived cross-repo token in
  every project.
- Moving the hand-written pages to their repos now: not needed for the flag, and each move is a
  content review of its own.
**Verified:**
- `shellcheck` and `/bin/bash -n` pass on the script.
- Against fixtures (`SYNC_FROM_DIR`), `--dry-run` reported one write and two refusals (`public:
  maybe`, a single-quoted `githubUrl`), exit 1, and changed nothing.
- A real run for the `cnc-web` fixture wrote the page with its hero and `syncedFrom`. A rerun
  printed "unchanged".
- `./test.sh --offline` with that page passed (`182 passed, 0 failed`), including "project
  'cnc-web' shows its hero on the card and the detail page". The fixture page was then removed;
  `games/portfolio.md` itself says `public: false`.
- NOT YET: a run against GitHub, which needs the games repo pushed (`~/dev/TODO.md`).

## 21. /press and /software are deleted and redirect to /about; the settled biography is pinned by tests
**Date:** 2026-10-23
**Context:** The 2026-10-14 review (`docs/CONTENT-REVIEW.md`) found the same facts disagreeing
across pages: the career start year (2012 / 2013 / "over 7 years"), a Georgia Tech MSc on /press
only, two city lists, and CodePath/Hack Reactor roles. /press and /software were thin pages kept
unlisted (#9) in case they were finished. Pieter settled the facts on 2026-10-23: experience
since 2011 (a software internship at WePay in Palo Alto), Senior Software Engineer, no MSc,
cities Baltimore, Palo Alto, San Francisco, NYC and Miami, a student at CodePath and at Hack
Reactor, Hacker in Residence at Hack Reactor, and not a CodePath TA.
**Decision:** Delete `src/pages/press.astro` and `src/pages/software.astro`. `astro.config.mjs`
`redirects` sends both to `/about/`, so old links land somewhere. The title moves to the Home
bio. Where the cities go is Pieter's to write (#23). `test.sh` § Biography consistency fails on:
- a second start year
- a "years of experience" count
- any retired claim or placeholder text in the build
- Home without the title
- a footer interest not named on Contact
Supersedes #9 for /press and /software; /qr stays unlisted.
Rejected:
- Finishing both pages: the facts they held now fit in two sentences on Home, and every extra page
  is one more place for a fact to drift.
- Keeping them unlisted with corrected facts: still built, still indexable by direct link, still
  a second copy to keep in step.
- Vercel `vercel.json` 301s instead of Astro redirects: a second config file for two URLs. Astro's
  stub (meta refresh, `noindex`, canonical to /about/) also works under `npm run dev` and is
  testable from `dist/`.
**Verified:**
- `./test.sh` → `199 passed, 0 failed, 11 warnings, 0 skipped`, including
  `✓ /press/ redirects to /about/`, `✓ /software/ redirects to /about/`,
  `✓ every page dates the career from 2011` and `✓ every footer interest is named on Contact`.
- `dist/press/index.html` → `<meta http-equiv="refresh" content="0;url=/about/">`.
- NOT YET: the same on production after the push (`./test.sh --live` now checks it).

## 22. Contact form: botcheck honeypot and an on-page privacy note; no third-party scripts
**Date:** 2026-10-23
**Context:** A security and privacy vetting found three problems (privacy-by-design §6–§7):
- The contact form sends name, email and message to Web3Forms, and Vercel Web Analytics counts
  every page view. Neither the site nor the README said so.
- The form had no spam protection. Once the key is set, it relays spam into Pieter's inbox.
- `/terra/` loaded three.js from jsDelivr with no integrity hash, so a CDN compromise would run
  code on the site.

The same vetting found more that is acceptable:
- `.env` was never committed.
- The security CI calls the reusable workflow.
- The Web3Forms key is a public form ID by design.
**Decision:**
- The form gets Web3Forms' hidden `botcheck` checkbox.
- A plain-language note under the form names Web3Forms, its retention, the cookie-less
  analytics, and how to have a message deleted. Pieter writes it (#23): the assistant's draft
  was removed, and `test.sh` warns until the note exists and fails if it is incomplete.
- The README gets a processor table.
- three.js r158 is vendored at `public/terra/vendor/`, verified byte-identical to the npm
  tarball (registry integrity `sha512-TALj4E…`) and to the jsDelivr copy, with its MIT licence
  beside it.

`test.sh` § Privacy and form safety enforces each of these:
- It fails on a missing honeypot, a missing or incomplete note, a form posting anywhere but
  api.web3forms.com, any third-party `<script src>`, or a processor missing from the README.
- It warns on third-party stylesheets.

Rejected:
- hCaptcha or reCAPTCHA: a third-party script on the contact page, which is what the policy
  forbids. Web3Forms calls the honeypot weaker; revisit if spam arrives.
- A separate /privacy page: two processors fit in three sentences where the data is entered.
- An SRI hash on the CDN three.js instead of vendoring: it fixes integrity but still sends every
  /terra/ visitor's IP to jsDelivr.
**Verified:**
- `./test.sh` → `199 passed, 0 failed`, including:
  - `✓ contact form carries the hidden botcheck honeypot`
  - `✓ no third-party <script src> in the build`
  - `✓ README processor table lists hosting, analytics and the form backend`
- The /terra/ browser tests pass on the vendored file.
- `shasum -a 256`: npm and jsDelivr copies both `3b3a1c97…1d51`.
- NOT YET:
  - The KaTeX stylesheet (jsDelivr, every page, SRI-pinned) and Google Fonts on /terra/ still
    leak visitor IPs. `test.sh` warns, and the README lists both (`~/dev/TODO.md`).
  - A real submission with the key set.

## 23. AI writes project descriptions only, and each project page says whether AI wrote it
**Date:** 2026-10-23
**Context:** On 2026-10-23 the assistant drafted sentences in Pieter's voice: a city list on
Home, reworded About entries, the contact privacy note, and a new blog opener. Pieter wants to
write the site himself, except for project descriptions, and wants readers to see which
descriptions AI wrote.
**Decision:** AI writes project descriptions only (`src/content/projects/`, a repo's
`portfolio.md`). Every other page is Pieter's. AI may apply facts he has settled and fix
typos there, and nothing more. The rule is in `docs/PORTFOLIO.md` § Content and voice and
`CLAUDE.md` § Gotchas.

The project schema gets a required `aiGenerated: boolean`, and
`src/components/AuthorshipNote.astro` shows it at the bottom of each project page:
- `true`: a sparkle icon and "Description generated by AI".
- `false`: "Description written by Pieter".

All five current descriptions are `true`: Claude rewrote every one in `c8dc28b`
(2026-10-03). The 2026-10-23 drafts were reverted to Pieter's text, keeping only his settled
facts: 2011, Senior Software Engineer, Palo Alto, Hacker in Residence, and no CodePath TA.

Pieter also had four older AI-written pieces reverted:
- The why-blog sentence `2c23f91` changed to say Vercel. His original says SiteGround with
  `rsync`, which is now false, and is his to rewrite.
- The two draft posts `information-theory-part-1-foundations` and
  `ai-enhanced-programming-observations`, deleted. `test.sh` now derives the draft list from
  the frontmatter, and the dev-mode draft check uses `test-fixture-markdown`.
- The `/qr/` hint line.
- The contact form's "temporarily unavailable" text (#19). Without a key the button is now
  disabled with no message.
Rejected:
- An optional field defaulting to `false`: a page would claim Pieter wrote it by omission.
- The label on the `/projects` cards as well: it is asked for "at the bottom of each project".
  The cards repeat the same description, so revisit if Pieter wants it there too.
- A text-only label: Pieter asked for an icon. The sparkle is the common AI mark, drawn inline
  in `--accent` so it follows the palette and needs no asset.
**Verified:**
- `./test.sh` → `198 passed, 0 failed, 12 warnings, 0 skipped`, including
  `✓ all 5 project pages state whether the description was generated by AI`. After the four
  reverts: `196 passed, 0 failed, 12 warnings, 0 skipped` (two fewer drafts to check).
- Setting one built page to `data-ai-generated="false"` → `✗ … terra(field=true,page=false)`.
- Screenshot of `/projects/terra/`: a terracotta sparkle and "Description generated by AI" under
  a hairline at the page bottom.
- NOT YET: `scripts/sync-projects.sh` with a `portfolio.md` that carries the field (the build
  rejects one without it).

## 24. The TV Show Chat page drops its GitHub link while that repo is private
**Date:** 2026-10-23
**Context:** `pieteradejong/tvshowchat` went private on 2026-10-23 while the personal email in its
history is dealt with (tvshowchat `DECISIONS.md` #21). Strangers now get a 404 for it, and
`test.sh`'s outbound-link check failed: `✗ https://github.com/pieteradejong/tvshowchat -> 404
(dead link on a project entry)`.
**Decision:** Removed `githubUrl` from `src/content/projects/tv-show-chat.md` (the field is
optional). The page stays listed.
Rejected:
- Unlisting the project. The description and diagram are still accurate, and only the code link
  is gone.
- Allow-listing the 404 in `test.sh`. That would publish a dead link.
**Verified:** `./test.sh` → `195 passed, 0 failed, 13 warnings, 0 skipped`; pushed
`2c23f91..d4d75e5`. NOT YET: the live page after the Vercel deploy.
