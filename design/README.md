# Design source

The house style for this site — "PADJ Productions, Issue 01 · Field Notes",
authored as a Claude Design canvas.

| File | What it is |
|------|------------|
| `padj-publication-template.html` | Self-contained bundle. Open in any browser; fonts and runtime are embedded, no network needed. |
| `padj-template-source.html` | Extracted template only — readable markup, but references fonts by UUID so it will not render standalone. For reading the CSS, not for viewing. |

The canonical copy lives at `~/dev/design/PADJ.html`, with the full token
breakdown documented under **PADJ Field Notes** in `~/dev/design/DESIGN_SYSTEMS.md`.

## The two directions

Alternates sharing one element vocabulary — not a light/dark pair.

**1A — Two-column, rust.** Spectral + JetBrains Mono. Page `#fbf7f0`, ink
`#26221e`, accent `#b0492a`.

**1B — Single column + 176px margin rail, ink blue.** Archivo + Source Serif 4.
Page `#fcfbf9`, ink `#1f2328`, accent `#2f5d7c`.

`#2f5d7c` is within a few points of this site's existing `#2A7FA5`, so 1B reads
as a refinement of what the site already does rather than a rebrand.

## Governing rules

> A template is a set of decisions you agree not to make again.

- Set the measure before the type size — 62–72 characters, capped at 600–640px.
- Drop cap once per article, never after a subhead.
- Code flush and unjustified on a tinted band; inline code at `0.85em`.
- Charts carry no gridlines and no legend; the caption carries the claim.
- Uppercase micro-labels at `0.12em`–`0.3em` letter-spacing.

## Porting to the web

This is a print system — 816px is US Letter at 96dpi and it outputs an 8-page
PDF. Three things need handling on the way to the browser:

1. 1A's two-column justified text must collapse to one column below ~900px.
2. Page furniture (folios, page numbers) has no web equivalent.
3. Justification without hyphenation gives rivers at narrow widths — enable
   `hyphens: auto` or set ragged-right.

## Rendering to PNG/PDF

Not generated automatically — headless Chromium failed on this machine. To
produce them: open `padj-publication-template.html` in a browser, then
**File → Print → Save as PDF** (set margins to none, enable background
graphics). For PNG, screenshot the rendered artboards.
