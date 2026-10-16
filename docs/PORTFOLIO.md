# Portfolio rules

What is shown online, how a project gets there, and what the satellite repos are for. The site
at https://padj.vercel.app is the centre, but the portfolio is everything a stranger can find:
the site, the GitHub profile and repo listing, LinkedIn. This is the one place those rules live
(`../DECISIONS.md` #17). Which repo is shown, source-only or a candidate is recorded in the
private workspace register, not here, so this doc never judges an unfinished project in public.

## Surfaces

| Surface | Source | Governed by |
|---|---|---|
| https://padj.vercel.app | this repo, `src/` | this doc; hosting and rollback in `../DEPLOYMENT.md` |
| github.com/pieteradejong, the profile page | repo `pieteradejong`, its `README.md` | § Satellite repos |
| The GitHub repo listing: description, README, LICENSE of every public repo | each repo | `dotfiles/docs/policy/repo-standards.md` § GitHub standard, Tier A (public repo `pieteradejong/dotfiles`) |
| Public repos a project page links to | each repo | § Showcase criteria; before a repo goes public, `dotfiles/docs/policy/security-and-privacy.md` §5 |
| linkedin.com/in/pieteradejong | outside git | must state the same facts as the site (§ Content and voice) |
| pieteradejong.github.io | repo `pieteradejong.github.io` | § Satellite repos |
| pieter.am, peter.am | none | not registered or not resolving; § Satellite repos |

Elsewhere, linked rather than repeated: deploy and rollback `../DEPLOYMENT.md`; the test suite
`TESTING.md`; open content problems `CONTENT-REVIEW.md`; per-repo portfolio status, the
`Portfolio` column of the private register `repos.md`.

## Showcase criteria

A project page is one file, `src/content/projects/<slug>.md`; its fields are defined in
`src/content.config.ts`. The `/projects` list sorts by `order`.

A project **must** have:

- A public repo at Tier A: a README whose first paragraph says what it is, a GitHub description
  (the only text visible in the profile's repo listing), a LICENSE.
- `githubUrl`, or the page says why there is none (see the open question below).
- `demoUrl` only when the demo works. `./test.sh` fails on a dead one, and the "Live demo" /
  "Source only" badge and the `/projects` filter derive from the field (`../DECISIONS.md` #3–#5).
- A page that reads in a 5 to 10 second phone scroll: the `description` sentence, the `hero`,
  the first three `keyFeatures`. `tests/mobile.spec.ts` enforces the 320px layout; the editing
  rule is that nothing essential sits below those three.
- `hero` with a `heroAlt` that says what the picture shows, not what the project is.
- `impact` in one sentence: what the project makes possible or what it taught, no adjectives.
- `tags`, `status` (`active`, `completed`, `archived`) and `order`.
- Nothing from a private data tier, no client or employer material, no other person's data.

A project **should** have:

- Progression over time: what the MVP did and what was added since (`startDate`, `endDate`
  when known).
- Architecture decisions and their trade-offs, in `technicalHighlights`.
- Purpose, audience and usage, in the body.
- Each entry in `techStack` earning its place in the body: how it is used and why.
- Demo material: screenshots with the relevant area marked, or a short video, and usage
  instructions in the repo README for anyone who wants to spend more time.

**What `./test.sh` checks of this** (section "Project content quality" and its neighbours;
details in `TESTING.md`): frontmatter present and valid against the schema (the build fails
otherwise, so `impact`, `tags`, `heroAlt` with `hero` are enforced); a hero on every entry,
rendered on the card and the detail page; `demoUrl` and `githubUrl` resolve, and a dead demo
fails the suite; the demo badges match the `demoUrl` fields; the retired `deploymentUrl` is
absent; a non-empty body; a warning for filler phrasing, a thin description, or a missing
`githubUrl`. Every route at 320px with no overflow. The full suite is the one that counts; the
`--offline` variant skips the link checks.

Three states: **shown** (page with a working demo), **source-only** (page, no demo), **not
shown**. Pieter decides; the private register records it.

**Open question (2026-10-16).** The Chrome Bookmark Assistant page has no `githubUrl` because
its repo was made private on 2026-09-08. That breaks the first rule above. Options: the repo
goes public again, the page is removed, or a "source private" state is added here. Until
decided, the page stays.

## Publishing a project

1. The repo meets Tier A. If it is going public for this, run the go-public checklist
   (`security-and-privacy.md` §5) first. New repos start private.
2. Write `src/content/projects/<slug>.md` against the schema; put the hero in
   `src/assets/projects/`. Work on a branch: projects have no draft flag, so a file on `main`
   is live after the next push.
3. `./test.sh`, the full suite, with network. The dead-demo, sitemap, mobile and outbound-link
   checks all run here; `--offline` is for iterating, not for the push.
4. Push `main`. That is the production deploy. Wait for the `site / tests` and `site / live`
   checks to be green (`../DECISIONS.md` #10, #15). A red `live` means visitors see a broken
   site: `vercel rollback` (`../DEPLOYMENT.md`).
5. Record the state in the private register's `Portfolio` column.
6. If the project changes what the profile README should say, update repo `pieteradejong`.

Removing a project is the same list without step 2: delete the page, test, push, update the
register.

## Content and voice

- **Facts agree on every page.** The canonical facts are: career start year, current title,
  degrees, cities lived in, current city, the interests list. When one changes, change it
  everywhere in the same commit (`grep -rn` the old value under `src/`). The disagreements found
  on 2026-10-14 are in `CONTENT-REVIEW.md`; LinkedIn and the profile README follow the site.
- **First person, plain.** No adjectives about myself; the projects carry that. Concrete numbers
  beat claims: "144 episodes", "484 submarine cables".
- **Every outbound link resolves.** `./test.sh` checks project, `/reading/` and `/about/`
  links; the weekly link report covers the rest (`../DECISIONS.md` #6).
- **Blog posts** carry `draft: true` until done. Drafts are visible in `astro dev`, never built
  for production, never in RSS (`../README.md` § Known inconsistency for the one gap).
- **Unlisted pages** (`/qr/`, `/press/`, `/software/`; `../DECISIONS.md` #9) are out of the nav
  and sitemap but still public. Nothing goes on them that could not go on the homepage.
- **Never on any surface:** anything in a private data tier, confidential client or employer
  material, other people's personal data (`dotfiles/docs/policy/privacy-by-design.md`),
  credentials, internal hostnames.

## Satellite repos

| Repo | Role | Policy |
|---|---|---|
| `pieteradejong` | GitHub profile README | Links padj as the website and `padj.vercel.app/blog/` for writing. Nothing it links may be dead. Bio facts as on the site. Re-read after every project publish. |
| `pieteram` | 2023 design notes for a pieter.am site; no code | Its showcase rules were folded into this doc on 2026-10-16 and the repo archived. |
| `blog` | 2023 markdown drafts, public, no LICENSE | Archive candidate. New writing goes to `src/content/blog/` here. No action yet. |
| `pieteradejong.github.io` | Placeholder Pages site | Redirect to padj or delete. No action yet. |
| `personal_style` | Editorial design kit (markdown to PDF and site) | Not a portfolio surface. |
| pieter.am, peter.am | none | Not registered or not resolving. The site is padj until a domain decision exists. Then: regenerate `public/qr.svg` (`../DECISIONS.md` #7), update the profile README, LinkedIn and this table. |

## Changing these rules

A rule that closes off an alternative gets an entry in `../DECISIONS.md`; a change in what the
site does gets a `../CHANGELOG.md` line. Per-repo status changes go to the private register
only.
