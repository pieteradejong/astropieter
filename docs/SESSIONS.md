# Sessions

Newest first. Earlier sessions are recorded in `CHANGELOG.md` and `DECISIONS.md` only.

## 2026-11-14 — Chokepoints page; astro 7.4.12

- Synced the "Chokepoints" project page from `chokepoints-globe` (`scripts/sync-projects.sh --repo
  chokepoints-globe`, after a `--dry-run` that would write only that page), on branch
  `sync/chokepoints-globe`.
- The full `./test.sh` then failed on one check: `npm audit` found a new moderate advisory against
  astro 7.3.5 (GHSA-mh32-jxcr-mh9f). Pinned `astro` to 7.4.12. Astro 7.4 changed its markdown
  internals, but the KaTeX browser fixtures pass. The low katex and fast-xml-parser advisories
  stay warnings, as before.
- Verified: `./test.sh` → 227 passed, 0 failed, 14 warnings; `npm audit --audit-level=moderate` → exit 0.
- Pushed `main` `845a4e2`. Production serves it, `/projects/chokepoints-globe/` → 200, and
  `site / tests` and `security` are green. `site / live` is red only on the Web3Forms key, as it has
  been on every deploy since 2026-10-30 (`./test.sh --live` → 70 passed, 1 failed). That item is
  in the workspace TODO, not this one.
