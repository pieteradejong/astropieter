# Deployment

The site is hosted on **Vercel** as project `padj` (team `pieteradejongs-projects`) and served at
**https://padj.vercel.app**. Why Vercel: `DECISIONS.md` #1.

## How a change goes live

Push to `main`. Vercel builds (`astro build`, Node 22.x from `package.json` `engines`) and
publishes `dist/` as the production deployment. There is no deploy script and nothing to run
locally. Other branches and pull requests get preview URLs.

Vercel does not run `./test.sh`, so run it before pushing. After a deploy, check what is
actually being served:

```bash
./test.sh --live https://padj.vercel.app
```

## Rollback

```bash
vercel rollback             # back to the previous production deployment
vercel ls padj              # list deployments
```

The same thing is in the dashboard under the project's Deployments tab.

## Configuration

- **Output:** fully static. Add the `@astrojs/vercel` adapter only when a page needs server rendering.
- **Environment variables:** none. The contact form posts to Web3Forms from the browser.
- **Analytics:** Vercel Web Analytics (cookie-less), via `<Analytics />` in `Footer.astro`.
  The static `public/terra/` page does not render the footer, so it is not counted.
- **Local link:** `vercel link` writes `.vercel/` (gitignored), which only the CLI needs.

## Plan limits

Hobby (free) plan: personal, non-commercial use only. Move to Pro when anything hosted here
starts serving paying users.
