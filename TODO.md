# TODO

Older open items for this site live in `~/dev/TODO.md` § astropieter. Items from 2026-10-23 on are
kept here.

- [ ] 2026-10-23 — **Restore the TV Show Chat GitHub link** (`githubUrl`) if `tvshowchat` goes
      public again. `DECISIONS.md` #24.
- [ ] 2026-10-25 — **Pieter: create the first prose manifest.** Read the live pages (Home, About,
      Contact, Reading, why-blog, footer) and, if that text is what you stand behind, run
      `./test.sh --bless-prose` and commit `tests/prose.sha256`. Until then § Prose integrity
      only warns. Open texts (why-blog opener, contact privacy note, CONTENT-REVIEW items) will
      each need a re-bless when they land. `DECISIONS.md` #25.
- [x] 2026-10-25 — **`npm audit` is red:** high advisories in transitive `undici` and `zod` (fix
      available) turn `./test.sh` red, and CI's `tests` check will fail the same way. Do a
      lockfile-only `npm audit fix`, as in `4129257`, then re-run the suite. Found by the
      `DECISIONS.md` #25 run. **Done 2026-10-28:** undici 8.12.3, zod 4.6.7;
      `npm audit --audit-level=moderate` exit 0; `./test.sh --offline` 189 passed, 0 failed.
- [x] 2026-10-25 — **Commit the prose check** (`test.sh`, `scripts/prose-blocks.mjs`,
      `docs/TESTING.md`, `CLAUDE.md`, `CHANGELOG.md`, `DECISIONS.md`, `TODO.md`): uncommitted,
      awaiting Pieter's go. It's test-only, so no site change ships when it's pushed. `DECISIONS.md` #25.
      **Done 2026-10-28:** committed as `bc4cf8d`, not pushed yet.
- [x] 2026-10-28 — **Push astropieter `main`**: the prose check (`bc4cf8d`), the lockfile fix,
      and the `portfolio-games` branch (the cnc-web page, DECISIONS #26). This is the first push
      gated by Deployment Checks. Verify: `gh run list --workflow ci.yml --limit 2` green, `vercel
      ls padj` shows it as production, `./test.sh --live https://padj.vercel.app` passes, and
      `/projects/cnc-web/` answers. Then turn #26's `NOT YET` into its Verified line. Needs
      Pieter's go. **Done 2026-10-28:** pushed on Pieter's go; see #26 § Verified.
- [x] 2026-10-28 — **`sync-projects.sh` does not add `aiGenerated`**, which the schema requires
      (#23). A `portfolio.md` without it syncs fine and then fails the build. Either check for it
      in the script (exit 1, as with other invalid fields) or document it in `docs/PORTFOLIO.md`
      § Publishing a project. `DECISIONS.md` #20. **Done 2026-10-28:** both. The script refuses
      it (fixture: exit 1), and `docs/PORTFOLIO.md` names the field.
- [ ] 2026-10-23 — **Check the live TV Show Chat page** after the `d4d75e5` deploy: no GitHub
      link, page still listed. `DECISIONS.md` #24.
