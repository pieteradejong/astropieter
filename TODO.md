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
- [ ] 2026-10-25 — **`npm audit` is red:** high advisories in transitive `undici` and `zod` (fix
      available) turn `./test.sh` red, and CI's `tests` check will fail the same way. Do a
      lockfile-only `npm audit fix`, as in `4129257`, then re-run the suite. Found by the
      `DECISIONS.md` #25 run.
- [ ] 2026-10-25 — **Commit the prose check** (`test.sh`, `scripts/prose-blocks.mjs`,
      `docs/TESTING.md`, `CLAUDE.md`, `CHANGELOG.md`, `DECISIONS.md`, `TODO.md`): uncommitted,
      awaiting Pieter's go. It's test-only, so no site change ships when it's pushed. `DECISIONS.md` #25.
- [ ] 2026-10-23 — **Check the live TV Show Chat page** after the `d4d75e5` deploy: no GitHub
      link, page still listed. `DECISIONS.md` #24.
