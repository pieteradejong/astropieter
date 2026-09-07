# Font provenance

Three families, all under the SIL Open Font License 1.1, which permits
redistribution in a repository like this one. Full licence text:
<https://openfontlicense.org/>

| Family | Role | Version | Copyright |
|---|---|---|---|
| Playfair Display | display | 1.203 | Copyright 2017 The Playfair Display Project Authors (https://github.com/clauseggers/Playfair-Display), with Reserved Font Name "Playfair Display". |
| Source Serif 4 | body | 4.004 | © 2014–2021 Adobe Systems Incorporated (http://www.adobe.com/), with Reserved Font Name 'Source'. |
| Inter | meta | 4.001 | Copyright 2016 The Inter Project Authors (https://github.com/rsms/inter) |

## How these files were made

Fetched from Google Fonts as the **latin subset only**, then cut to
static instances with `fontTools.varLib.instancer`:

```
inter-{400,600}.woff2                    from Inter variable, wght 100–900
source-serif-{400,700}[-italic].woff2    from Source Serif 4 variable, wght 200–900
playfair-display-400[-italic].woff2      already static
```

Instancing is not an optimisation, it is a correctness fix. WeasyPrint
renders a variable font's *default* instance, so shipping the variable
file makes bold body copy print at regular weight with no warning.
Instancing also happened to halve Inter: 48 KB to 24 KB.

Reserved Font Names are intact — these are unmodified outlines at fixed
weights, not new designs, so no renaming is required.

## Coverage

The latin subset covers everything the issues currently use (the only
non-ASCII character in them is U+2014 em dash) plus the punctuation the
design itself emits: `·` in the masthead band, en/em dashes, and the
curly quotes smartypants produces. Arrows and mathematical symbols are
**not** covered and will fall back silently — see docs/KNOWN-ISSUES.md.
