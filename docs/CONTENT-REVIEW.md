# Content review — open items

Found during the 2026-10-14 site review. These are facts and wording only Pieter can settle, so
they were documented, not changed. Tick an item when the pages agree. Delete this file when empty.

## Facts that disagree between pages

- [ ] **Career start year.** Home says "since 2012" (`src/pages/index.astro:34`); Software says
  2013 (`src/pages/software.astro:15`); Press says "over 7 years" (`src/pages/press.astro:13`),
  which is stale in 2026 whichever year is right.
- [ ] **Job title and degree.** Press calls you "Senior Software Engineer" and says you are
  "pursuing a part-time MSc in Computer Science at Georgia Tech" (`press.astro:13`). About never
  mentions either. Confirm both are current, then say the same thing on both pages.
- [ ] **Cities.** Press lists Miami, NYC, San Francisco and Silicon Valley; About lists Baltimore
  and Silicon Valley.
- [ ] **About timeline ends in 2014** and has no work entries at all, although
  `.event-professional` styles exist (`about.astro:220`). For a recruiter this is the biggest gap
  on the site.
- [ ] **CodePath and Hack Reactor roles.** The timeline describes you as a student at both
  (`about.astro:19,28`); Volunteering calls you a "CodePath Teaching Assistant"
  (`about.astro:116`), and the timeline also says "Lab instructor" at Hack Reactor. Student,
  instructor, or both in sequence?
- [ ] **Interests lists differ.** Footer (`src/components/Footer.astro:33-38`) vs Contact
  (`src/pages/contact.astro:13-15`, which adds linguistics). Pick one list.

## Stale or placeholder text

- [ ] `src/content/blog/why-blog.md:16` says the site deploys to SiteGround with `rsync`. It is
  on Vercel now (DECISIONS #1).
- [ ] `why-blog.md:7` opens with "No promises I'll keep this up", and it is the only published
  post (dated July 2022). Either write the next post or reword the opener.
- [ ] Reading page: most reviews say "In progress…" (`src/pages/reading.astro:61,84,106,170,193`).
- [ ] Reading page: "My Review System" uses a movie trilogy as its example (`reading.astro:33`).
- [ ] `src/content/blog/ai-enhanced-programming-observations.md` body is "[Your content here]"
  (draft, not published).
- [ ] `/software` and `/press` are thin (three paragraphs and one paragraph). They are kept but
  unlisted: not in the nav, not in the sitemap. Finish them or delete them.

## Typos

- [ ] "CicleCI" → "CircleCI" (`src/pages/software.astro:23`)
- [ ] "to convoluted" → "too convoluted" (`src/content/blog/why-blog.md:26`)
- [x] "uniquitous", "readibly" in `LaTeX_test.md` (fixed 2026-10-14; the post is now a draft)

## Fixed in the same review (for the record)

- Four Amazon links on `/reading/` pointed at pages that no longer exist; replaced with the
  publisher ISBN product pages. One dead blog link removed from `LaTeX_test.md`.
