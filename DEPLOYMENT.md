# Deployment

The site is hosted on **Vercel** as project `padj` (team `pieteradejongs-projects`) and served at
**https://padj.vercel.app**. Why Vercel: `DECISIONS.md` #1.

## How a change goes live

Push to `main`. Vercel builds (`astro build`, Node 22.x from `package.json` `engines`), and the
build becomes the production deployment once the GitHub checks `tests`, `security / gitleaks` and
`security / gate` pass. Those are Vercel Deployment Checks (`DECISIONS.md` #26, dotfiles
`docs/deploy-pipeline.md`). On a red check, the build stays Ready but production keeps the
previous one. Fix the cause and push again, or, if the failure is known to be unrelated, run
`vercel promote <deployment-url>`. `vercel-project check` (dotfiles `bin/`) reports drift from
these settings. There is no deploy script. Other branches and pull requests get preview URLs
behind a Vercel login.

Vercel does not run `./test.sh`, so run it before pushing. GitHub runs it after: the `site`
workflow (`.github/workflows/ci.yml`) runs `./test.sh --offline` on the push and, when Vercel
reports the production deployment, `./test.sh --live https://padj.vercel.app` against the served
site. Both show as checks on the commit. To check a deployment by hand:

```bash
./test.sh --live https://padj.vercel.app
gh workflow run ci.yml -f url=https://padj.vercel.app && gh run watch
```

## Rollback

```bash
vercel rollback             # back to the previous production deployment
vercel ls padj              # list deployments
```

The same thing is in the dashboard under the project's Deployments tab.

## Configuration

- **Output:** fully static. Add the `@astrojs/vercel` adapter only when a page needs server rendering.
- **Environment variables:** one, `PUBLIC_WEB3FORMS_KEY` (Production). The contact form posts to
  Web3Forms from the browser, and Astro bakes the key into `/contact/` at build time. That makes
  it public by design, but it still stays out of git. If it is missing, the form renders
  disabled with an "unavailable" notice, and `./test.sh --live` fails. To set it: dashboard →
  `padj` → Settings → Environment Variables, or `vercel env add PUBLIC_WEB3FORMS_KEY production`.
  Then redeploy, because a change only takes effect on the next build. Why: `DECISIONS.md` #19.
- **Analytics:** Vercel Web Analytics (cookie-less), via `<Analytics />` in `Footer.astro`.
  The static `public/terra/` page does not render the footer, so it is not counted.
- **Local link:** `vercel link` writes `.vercel/` (gitignored), which only the CLI needs.
- **Node version:** the Vercel project setting is 24.x, but `package.json` `engines` (22.x) takes
  precedence on Vercel, so builds run on 22, the same as CI. Change `engines` to move both.
- **One deployment per push.** Each push to `main` should create exactly one GitHub deployment.
  Vercel names its environment `Production` while one project is linked to the repo and
  `Production – <project>` when several are. On 2026-10-04/05 a second Vercel project was briefly
  linked and deployed every push too; it has since been relinked. The `live` job in `ci.yml`
  accepts `Production` and `Production – padj` and ignores any other name. Check with
  `gh api 'repos/pieteradejong/astropieter/deployments?per_page=3' -q '.[].environment'`.

## Old host

`https://pieterd38.sg-host.com/` is the retired SiteGround address (`DECISIONS.md` #1). It still
answers with a build from June 2025 (Astro 5.8, the pre-restyle look) and will until the cancelled
SiteGround plan ends in November 2026. Nothing deploys there and nothing should: the rsync path
was removed in September 2026 (commit 17dc0d6). Anything outside the repo that still links to it
(profiles, signatures, printed QR codes) should point at https://padj.vercel.app instead.

## Plan limits

Hobby (free) plan: personal, non-commercial use only. Move to Pro when anything hosted here
starts serving paying users.

## Link report

A weekly GitHub Actions job (`.github/workflows/link-report.yml`, Mondays 13:00 UTC) builds the
site and checks every link in it, plus the live homepage, with lychee. Why: `DECISIONS.md` #6.

- **Where the report lands:** a comment on the open issue "Weekly link report". GitHub emails you
  each comment. The job also fails when a link is broken, which sends GitHub's failed-run email.
- **Run it now:** `gh workflow run link-report.yml && gh run watch`
- **Noise:** a host that rejects bots can be excluded with `--exclude <regex>` in the workflow's
  `args`.
- **60-day rule:** GitHub disables scheduled workflows in a public repo after 60 days without a
  commit. It emails a warning first, and any push re-enables the schedule.
