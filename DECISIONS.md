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
