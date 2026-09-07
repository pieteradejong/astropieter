# Terracotta restyle — what changed

Preview build applying `~/dev/projects/personal_style` to astropieter.
Scope: **tokens + type only.** No masthead, contents panel, colophon, drop caps or
issue numbers; nav, header, footer and page structure keep their existing markup.

## New files

| File | Source |
|---|---|
| `src/styles/pub-core.css` | `personal_style/tokens/core.css`, verbatim (`:root` only, no side effects) |
| `src/styles/pub-fonts.css` | `personal_style/tokens/fonts.css`, `../fonts/` → `/fonts/` |
| `src/styles/pub-theme-terracotta.css` | `personal_style/tokens/theme-terracotta.css`, dark block commented out |
| `public/fonts/*.woff2` (8) | `personal_style/fonts/`, 188 K total |
| `public/fonts/NOTICE.md` | OFL 1.1 provenance, travels with the fonts |

## Wiring

- `src/components/BaseHead.astro` imports the three token sheets before `global.css`,
  and preloads source-serif-400 / playfair-display-400 / inter-600. The dead
  commented-out Atkinson preloads are gone (there was never an `@font-face` for them).
- `data-pub-theme="terracotta"` added to `<html>` in both `src/layouts/Default.astro`
  and `src/layouts/BlogPost.astro` — that attribute is how the theme files scope.

## The bridge (`src/styles/global.css`)

Only the `:root` block was rewritten. The site's bare-name variables now resolve to
`--pub-*`, so all 9 components, 2 layouts and 8 pages restyle without touching their
scoped `<style>` blocks:

```
--background → --pub-paper      --border       → --pub-rule
--card-bg    → --pub-paper-3    --accent       → --pub-accent-deep
--primary-text → --pub-ink      --accent-hover → --pub-ink
--secondary-text → --pub-muted  --footer-bg    → --pub-paper-2
--box-shadow → none             --gray-gradient → --pub-paper
```

Three type roles replace `'Avenir', Helvetica, Arial`:
body → Source Serif 4, headings → Playfair Display, nav/labels/buttons/tags → Inter
in tracked uppercase. Body leading 1.4 → `--pub-leading-body` (1.65); `--font-size-base`
ceiling 16px → 18px for the serif.

## Accessibility fix — read this before changing the accent

**Terracotta's `--pub-accent` (#C15F3C) is 3.95:1 on paper.** That fails both WCAG AA
for normal text and `personal_style/docs/CHECKLIST.md`'s own "accent ≥4.5:1" rule. This
is upstream in the design system, not introduced here.

The split applied, which is what `BRIEF.md` means by *"plus a deeper accent for links"*:

- **Text** uses `--pub-accent-deep` (#8F3E23, **6.81:1**) — links, nav hover, button
  backgrounds, tag and badge text.
- **Decoration** keeps the bright `--pub-accent` — rules, borders, focus rings, the
  active-nav underline. 3.95:1 clears the 3:1 threshold for non-text UI.

All 18 text pairs now pass; body ink is 13.84:1. Worth fixing `theme-terracotta.css`
upstream, or at least noting it in the style guide's KNOWN-ISSUES.

## Judgment calls worth a second opinion

1. **Circular portraits kept.** `border-radius: 50%` on the header and homepage photos
   survives, though BRIEF says "no rounded corners" — a portrait crop reads as photo
   treatment, not box chrome. Squaring them is a one-line change if you disagree.
2. **Dark mode deliberately off.** The theme ships a hand-tuned dark palette; it is
   commented out in `pub-theme-terracotta.css` because scoped styles elsewhere still
   assume a light ground. Enabling it is a follow-up, not a flip.
3. **`about.astro` timeline recolored.** It used two blues (`#2A7FA5`, `#4A90E2`)
   alongside the accent — three colors, which BRIEF forbids. The three event
   categories are now outlined chips in accent-deep / ink / muted.
4. **`public/terra/index.html` is untouched.** It is a standalone static page served
   verbatim from `public/`, so it bypasses the Astro layouts and keeps its own look.

## Fixed in passing

- `Tag.astro` referenced six variables (`--tag-bg`, `--accent-light`, `--success*`,
  `--warning*`) that were **never defined anywhere** — three of its four variants had
  been rendering with unset background and color. Now on `--pub-*`.
- `blog/index.astro`'s draft badge used ad-hoc `var(--warning-bg, #fff3cd)` fallbacks
  for the same missing variables.

## Still open (pre-existing, not touched)

- `src/pages/index.astro` has a **byte-for-byte duplicated `<style>` block** (the
  `.bio-container` / `.bio-left` / `.bio-right` rules appear twice). Dead code.
- `src/assets/kickboxing_cko.jpg` (2.9 MB) appears unreferenced.
- `src/assets/book_sharing_feynman.jpg` is 7.8 MB.

## Verification run

`./test.sh` → **53 passed, 0 failed.** Production build clean: no `Avenir` in `dist/`,
8 `@font-face` rules, 8 woff2 files shipped, and the only surviving decorations are
`border-radius:50%` (portraits) and `box-shadow:none`.

## Promotion

Copy back into the real tree, then delete this directory and its `.gitignore` entry:

```
cd ~/dev/projects/astropieter
rsync -a --exclude node_modules --exclude dist --exclude .astro \
      --exclude RESTYLE-NOTES.md preview-terracotta/ ./
```

Commit separately from the untracked `public/terra/` + `src/content/projects/terra.md`
work already sitting in the tree.
