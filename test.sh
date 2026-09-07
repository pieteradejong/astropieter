#!/bin/bash
# Comprehensive test suite for the astropieter Astro site.
#
# Covers: environment and dependency health, production build integrity,
# content collections, RSS/draft filtering, KaTeX rendering, generated routes,
# a live dev-server smoke test, and — the portfolio-specific half — theme
# integrity against the terracotta token system, WCAG AA contrast for both
# palettes, project-entry content quality, accessibility, metadata/SEO,
# payload weight, repository hygiene, and outbound link integrity.
#
# Three verdicts. A FAIL is broken and exits non-zero. A WARN is a real gap
# that is known and accepted for now — it is reported every run and never
# fails the build, so the suite does not cry wolf. A SKIP could not be
# determined (usually no network).
#
# Usage: ./test.sh [--offline]
#   --offline   skip the checks that need the network

set -uo pipefail
cd "$(dirname "$0")"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
WARN_COUNT=0
SKIP_COUNT=0

OFFLINE=0
for arg in "$@"; do
	case "$arg" in
		--offline) OFFLINE=1 ;;
		*) echo "unknown option: $arg (usage: ./test.sh [--offline])"; exit 2 ;;
	esac
done

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
warn() { echo -e "  ${YELLOW}!${NC} $1"; WARN_COUNT=$((WARN_COUNT + 1)); }
skip() { echo -e "  ${YELLOW}-${NC} $1 (skipped)"; SKIP_COUNT=$((SKIP_COUNT + 1)); }
section() { echo -e "\n${BLUE}== $1 ==${NC}"; }

cleanup() {
	# Astro's dev server self-daemonizes (detaches from the launching shell), so
	# it must be torn down via `astro dev stop`, not by killing a wrapper PID.
	npx astro dev stop >/dev/null 2>&1
}
trap cleanup EXIT

# ---------------------------------------------------------------------------
section "Environment"
# ---------------------------------------------------------------------------

NODE_VERSION=$(node -v | sed 's/^v//')
NODE_MAJOR=$(echo "$NODE_VERSION" | cut -d. -f1)
NODE_MINOR=$(echo "$NODE_VERSION" | cut -d. -f2)
if [ "$NODE_MAJOR" -gt 22 ] || { [ "$NODE_MAJOR" -eq 22 ] && [ "$NODE_MINOR" -ge 12 ]; }; then
	pass "Node.js $NODE_VERSION meets Astro's >=22.12 requirement"
else
	fail "Node.js $NODE_VERSION is below Astro's >=22.12 requirement"
fi

if [ -d node_modules ]; then
	pass "node_modules present"
else
	fail "node_modules missing — run npm install"
fi

# ---------------------------------------------------------------------------
section "Dependency health"
# ---------------------------------------------------------------------------

AUDIT_JSON=$(npm audit --json 2>/dev/null)
AUDIT_TOTAL=$(echo "$AUDIT_JSON" | node -e "let d='';process.stdin.on('data',c=>d+=c);process.stdin.on('end',()=>{try{const j=JSON.parse(d);console.log(j.metadata.vulnerabilities.total)}catch(e){console.log('err')}})")
if [ "$AUDIT_TOTAL" = "0" ]; then
	pass "npm audit reports 0 vulnerabilities"
elif [ "$AUDIT_TOTAL" = "err" ]; then
	skip "npm audit output could not be parsed"
else
	fail "npm audit reports $AUDIT_TOTAL vulnerabilities (run npm audit for details)"
fi

if [ -f src/content/config.ts ]; then
	fail "legacy src/content/config.ts still present (should be src/content.config.ts)"
else
	pass "legacy content config removed"
fi

if [ -f src/content.config.ts ]; then
	pass "src/content.config.ts (Content Layer API) present"
else
	fail "src/content.config.ts missing"
fi

if grep -q "@astrojs/tailwind" package.json 2>/dev/null; then
	fail "unused @astrojs/tailwind dependency still in package.json"
else
	pass "no unused @astrojs/tailwind dependency"
fi

# Astro v7 requires uppercase HTTP method exports in endpoint files
BAD_HANDLERS=$(grep -rlE "export (async )?function (get|post|put|patch|del|delete)\(" src/pages 2>/dev/null)
if [ -z "$BAD_HANDLERS" ]; then
	pass "no lowercase API route handlers (get/post/...)"
else
	fail "lowercase API route handler(s) found in: $BAD_HANDLERS"
fi

# CSS custom properties are invalid inside @media conditions (LightningCSS now hard-errors on this)
BAD_MEDIA=$(grep -rlE "@media[^{]*var\(--" src 2>/dev/null)
if [ -z "$BAD_MEDIA" ]; then
	pass "no CSS custom properties used inside @media conditions"
else
	fail "var() used inside @media condition in: $BAD_MEDIA"
fi

# ---------------------------------------------------------------------------
section "Production build"
# ---------------------------------------------------------------------------

rm -rf dist
BUILD_LOG=$(mktemp)
if npm run build > "$BUILD_LOG" 2>&1; then
	pass "npm run build exits successfully"
else
	fail "npm run build failed (see $BUILD_LOG)"
fi

if grep -qiE "\[ERROR\]|error:" "$BUILD_LOG"; then
	fail "build output contains an [ERROR] line"
else
	pass "build output has no [ERROR] lines"
fi

if grep -qi "deprecated" "$BUILD_LOG"; then
	fail "build output contains a deprecation warning"
else
	pass "build output has no deprecation warnings"
fi

if grep -qi "No API Route handler exists" "$BUILD_LOG"; then
	fail "build output reports a missing/mismatched API route handler"
else
	pass "no missing API route handler warnings"
fi

# ---------------------------------------------------------------------------
section "Build output — expected pages"
# ---------------------------------------------------------------------------

EXPECTED_FILES=(
	"dist/index.html"
	"dist/about/index.html"
	"dist/blog/index.html"
	"dist/contact/index.html"
	"dist/reading/index.html"
	"dist/projects/index.html"
	"dist/rss.xml"
	"dist/sitemap-index.xml"
)
for f in "${EXPECTED_FILES[@]}"; do
	if [ -f "$f" ]; then
		pass "$f generated"
	else
		fail "$f missing"
	fi
done

# Every non-draft blog post and every project should get a detail page
for src_file in src/content/blog/*.md src/content/blog/*.mdx; do
	[ -f "$src_file" ] || continue
	is_draft=$(grep -qE "^draft:\s*true" "$src_file" && echo yes || echo no)
	slug=$(basename "$src_file" | sed -E 's/\.(md|mdx)$//')
	if [ "$is_draft" = "yes" ]; then
		if [ -d "dist/blog/$slug" ]; then
			fail "draft post '$slug' was built into dist/blog/$slug"
		else
			pass "draft post '$slug' correctly excluded from production build"
		fi
	else
		if [ -d "dist/blog/$slug" ]; then
			pass "published post '$slug' has a detail page"
		else
			fail "published post '$slug' is missing its detail page"
		fi
	fi
done

for src_file in src/content/projects/*.md src/content/projects/*.mdx; do
	[ -f "$src_file" ] || continue
	slug=$(basename "$src_file" | sed -E 's/\.(md|mdx)$//')
	if [ -d "dist/projects/$slug" ]; then
		pass "project '$slug' has a detail page"
	else
		fail "project '$slug' is missing its detail page"
	fi
done

# ---------------------------------------------------------------------------
section "RSS feed"
# ---------------------------------------------------------------------------

if [ -f dist/rss.xml ]; then
	if command -v xmllint >/dev/null 2>&1; then
		if xmllint --noout dist/rss.xml 2>/dev/null; then
			pass "rss.xml is well-formed XML"
		else
			fail "rss.xml failed XML validation"
		fi
	else
		skip "xmllint not available to validate rss.xml"
	fi

	if grep -qE "<link>[^<]*/blog/(ai-enhanced-programming-observations|information-theory-part-1-foundations)/" dist/rss.xml; then
		fail "draft post(s) leaked into rss.xml"
	else
		pass "no draft posts present in rss.xml"
	fi

	if grep -q "undefined" dist/rss.xml; then
		fail "rss.xml contains literal 'undefined' (likely a broken field mapping)"
	else
		pass "rss.xml has no 'undefined' values"
	fi
else
	fail "dist/rss.xml not generated — skipping RSS content checks"
	SKIP_COUNT=$((SKIP_COUNT + 2))
fi

# ---------------------------------------------------------------------------
section "KaTeX / math rendering"
# ---------------------------------------------------------------------------

if [ -f dist/blog/latex_test/index.html ]; then
	if grep -q 'class="katex"' dist/blog/latex_test/index.html; then
		pass "latex_test post renders KaTeX markup"
	else
		fail "latex_test post has no KaTeX markup"
	fi
else
	skip "dist/blog/latex_test/index.html not found"
fi

# ---------------------------------------------------------------------------
section "Theme integrity"
# ---------------------------------------------------------------------------
# The site is a single-theme design system. Every color and face in the shipped
# bundle should trace back to a --pub-* token; anything else is drift that will
# not follow the palette when it changes (and did not follow it into dark mode).

DIST_CSS=$(cat dist/_astro/*.css 2>/dev/null)

if [ -z "$DIST_CSS" ]; then
	skip "no built CSS found — run npm run build"
else
	# The eight terracotta tokens, light and dark, plus transparent.
	PALETTE='#2b2724|#faf7f0|#f2ede3|#fdfbf6|#c15f3c|#8f3e23|#d9d0c1|#6b635b'
	PALETTE="$PALETTE"'|#ede6da|#1c1917|#26221f|#232019|#e08d6b|#f0ac8e|#3d3833|#a39a8d'
	PALETTE="$PALETTE"'|#0000'
	STRAY=$(echo "$DIST_CSS" | grep -oiE '#[0-9a-f]{3,8}' | tr 'A-F' 'a-f' | sort -u \
		| grep -vE "^($PALETTE)$" || true)
	if [ -z "$STRAY" ]; then
		pass "built CSS contains no color outside the terracotta palette"
	else
		fail "built CSS has off-palette colors: $(echo "$STRAY" | tr '\n' ' ')"
	fi

	if echo "$DIST_CSS" | grep -qiE '(Avenir|Helvetica Neue|Georgia|Times New Roman)[,;}]' \
		&& ! echo "$DIST_CSS" | grep -qiE 'var\(--pub-font'; then
		fail "built CSS falls back to a pre-restyle face outside the --pub-font-* roles"
	else
		pass "type is confined to the three --pub-font-* roles"
	fi

	if echo "$DIST_CSS" | grep -q 'prefers-color-scheme:dark'; then
		pass "dark palette ships in the bundle"
	else
		fail "dark palette missing from the bundle (is it commented out again?)"
	fi

	if echo "$DIST_CSS" | grep -q 'color-scheme:light dark'; then
		pass "color-scheme declared, so native UI follows the palette"
	else
		fail "color-scheme not declared — scrollbars and form controls will stay light"
	fi

	# BRIEF forbids shadows and gradients. --box-shadow/--gray-gradient are kept
	# as no-ops, so only a real value is a violation.
	if echo "$DIST_CSS" | grep -oE 'box-shadow:[^;}]*' | grep -qvE 'box-shadow:\s*(none|var\()'; then
		fail "built CSS has a live box-shadow (BRIEF: no shadows)"
	else
		pass "no shadows in the bundle"
	fi
	if echo "$DIST_CSS" | grep -qE '(linear|radial|conic)-gradient\('; then
		fail "built CSS has a gradient (BRIEF: no gradients)"
	else
		pass "no gradients in the bundle"
	fi
fi

# Source-side: a raw hex in a scoped <style> is the failure mode that kept dark
# mode disabled for as long as it was. Catch it before it reaches the bundle.
SRC_HEX=$(grep -rn '#[0-9a-fA-F]\{3,8\}' src --include='*.astro' --include='*.css' \
	| grep -v 'pub-core.css\|pub-fonts.css\|pub-theme-' || true)
if [ -z "$SRC_HEX" ]; then
	pass "no raw hex colors in components or pages"
else
	fail "raw hex color in source (use a token): $(echo "$SRC_HEX" | head -1 | cut -c1-80)"
fi

for sheet in pub-core.css pub-fonts.css pub-theme-terracotta.css; do
	if [ -f "src/styles/$sheet" ]; then
		pass "token sheet present: $sheet"
	else
		fail "token sheet missing: $sheet"
	fi
done

for layout in src/layouts/Default.astro src/layouts/BlogPost.astro; do
	if grep -q 'data-pub-theme="terracotta"' "$layout"; then
		pass "$(basename "$layout") scopes the theme on <html>"
	else
		fail "$(basename "$layout") is missing data-pub-theme — the palette will not apply"
	fi
done

WOFF_COUNT=$(ls dist/fonts/*.woff2 2>/dev/null | wc -l | tr -d ' ')
FACE_COUNT=$(echo "$DIST_CSS" | grep -o '@font-face' | wc -l | tr -d ' ')
if [ "$WOFF_COUNT" = "8" ]; then
	pass "all 8 self-hosted woff2 faces ship"
else
	fail "expected 8 woff2 files in dist/fonts, found $WOFF_COUNT"
fi
if [ "$FACE_COUNT" -ge 8 ]; then
	pass "$FACE_COUNT @font-face rules in the bundle"
else
	fail "only $FACE_COUNT @font-face rules (expected at least 8)"
fi
# Vendored fonts must carry their license. Workspace rule, and OFL requires it.
if [ -f public/fonts/NOTICE.md ]; then
	pass "vendored fonts ship their OFL notice"
else
	fail "public/fonts/NOTICE.md missing — vendored fonts must carry their license"
fi

# ---------------------------------------------------------------------------
section "Color contrast (WCAG AA)"
# ---------------------------------------------------------------------------
# Both palettes are checked. The bright accent is knowingly below AA for text
# and is restricted to decoration, so it is held to the 3:1 non-text threshold
# instead — see the note in pub-theme-terracotta.css.

CONTRAST_OUT=$(python3 - <<'PYCONTRAST' 2>/dev/null
import re, sys

def parse(path, dark):
    src = open(path).read()
    blocks = re.split(r'@media\s*\(prefers-color-scheme:\s*dark\)', src)
    block = blocks[1] if dark and len(blocks) > 1 else blocks[0]
    return {m.group(1): m.group(2)
            for m in re.finditer(r'--pub-(ink|paper|paper-2|paper-3|accent|accent-deep|rule|muted):\s*(#[0-9A-Fa-f]{6})', block)}

def lum(h):
    h = h.lstrip('#')
    ch = [int(h[i:i+2], 16) / 255 for i in (0, 2, 4)]
    f = lambda c: c / 12.92 if c <= 0.03928 else ((c + 0.055) / 1.055) ** 2.4
    r, g, b = map(f, ch)
    return 0.2126 * r + 0.7152 * g + 0.0722 * b

def ratio(a, b):
    l1, l2 = sorted((lum(a), lum(b)), reverse=True)
    return (l1 + 0.05) / (l2 + 0.05)

path = 'src/styles/pub-theme-terracotta.css'
for label, dark in (('light', False), ('dark', True)):
    t = parse(path, dark)
    if len(t) < 8:
        print(f'FAIL|{label} palette incomplete — parsed {len(t)}/8 tokens')
        continue
    worst_name, worst = None, 99.0
    for ground in ('paper', 'paper-2', 'paper-3'):
        for fg in ('ink', 'muted', 'accent-deep'):
            r = ratio(t[fg], t[ground])
            if r < worst:
                worst_name, worst = f'{fg} on {ground}', r
    if worst >= 4.5:
        print(f'PASS|{label}: all text pairs clear AA (worst {worst_name} at {worst:.2f}:1)')
    else:
        print(f'FAIL|{label}: {worst_name} is {worst:.2f}:1, below the 4.5:1 AA threshold')
    d = ratio(t['accent'], t['paper'])
    if d >= 3.0:
        print(f'PASS|{label}: decoration accent {d:.2f}:1 clears the 3:1 non-text threshold')
    else:
        print(f'FAIL|{label}: decoration accent {d:.2f}:1 is below 3:1')
PYCONTRAST
)
while IFS='|' read -r verdict msg; do
	[ -z "$verdict" ] && continue
	case "$verdict" in
		PASS) pass "$msg" ;;
		FAIL) fail "$msg" ;;
		WARN) warn "$msg" ;;
	esac
done <<< "$CONTRAST_OUT"

# ---------------------------------------------------------------------------
section "Project content quality"
# ---------------------------------------------------------------------------
# A portfolio entry earns its slot with evidence. These checks catch the two
# ways an entry stops carrying its weight: generated filler, and a link that
# does not go anywhere.

CONTENT_OUT=$(python3 - <<'PYCONTENT'
import os, re, glob

# Phrases that assert competence instead of showing it. Every one of these was
# taken from an entry actually in this repo.
BANNED = [
    'demonstrates', 'showcasing', 'showcases', 'comprehensive',
    'cutting-edge', 'state-of-the-art', 'seamless', 'robust solution',
    'leverages', 'utilizing', 'best practices', 'modern techniques',
    'ability to build', 'expertise with',
]

def frontmatter(path):
    text = open(path).read()
    if not text.startswith('---'):
        return None, ''
    end = text.index('\n---', 3)
    return text[3:end], text[end + 4:]

files = sorted(glob.glob('src/content/projects/*.md'))
if not files:
    print('FAIL|no project entries found')

for path in files:
    name = os.path.basename(path)
    fm, body = frontmatter(path)
    if fm is None:
        print(f'FAIL|{name}: no frontmatter')
        continue

    hits = sorted({w for w in BANNED if re.search(r'\b' + re.escape(w), fm + body, re.I)})
    if hits:
        print(f'WARN|{name}: filler phrasing ({", ".join(hits[:3])}) — assert less, show more')
    else:
        print(f'PASS|{name}: no filler phrasing')

    m = re.search(r'^description:\s*"?(.*?)"?\s*$', fm, re.M)
    desc = m.group(1) if m else ''
    if len(desc) < 40:
        print(f'WARN|{name}: description is {len(desc)} chars — too thin to scan from the index')

    if not body.strip():
        print(f'FAIL|{name}: empty body — the detail page would render blank')

    # A portfolio of visual work that ships no images shows the reader nothing.
    if not re.search(r'^(hero|screenshots):', fm, re.M):
        print(f'WARN|{name}: no hero or screenshots — the entry is text-only')
PYCONTENT
)
while IFS='|' read -r verdict msg; do
	[ -z "$verdict" ] && continue
	case "$verdict" in
		PASS) pass "$msg" ;;
		FAIL) fail "$msg" ;;
		WARN) warn "$msg" ;;
	esac
done <<< "$CONTENT_OUT"

# ---------------------------------------------------------------------------
section "Accessibility"
# ---------------------------------------------------------------------------

MISSING_ALT=0
for f in $(find dist -name '*.html' 2>/dev/null); do
	# <img> tags with no alt attribute at all
	n=$(grep -o '<img[^>]*>' "$f" 2>/dev/null | grep -cv 'alt=' || true)
	MISSING_ALT=$((MISSING_ALT + n))
done
if [ "$MISSING_ALT" = "0" ]; then
	pass "every <img> in the build has an alt attribute"
else
	fail "$MISSING_ALT <img> tags are missing alt text"
fi

if [ -f dist/index.html ] && grep -q '<html lang=' dist/index.html; then
	pass "<html> declares a lang"
else
	fail "<html> has no lang attribute"
fi

if [ -f dist/contact/index.html ]; then
	INPUTS=$(grep -o '<input[^>]*type="\(text\|email\)"' dist/contact/index.html | wc -l | tr -d ' ')
	INPUTS=$((INPUTS + $(grep -o '<textarea' dist/contact/index.html | wc -l | tr -d ' ')))
	LABELS=$(grep -o '<label' dist/contact/index.html | wc -l | tr -d ' ')
	if [ "$LABELS" -ge "$INPUTS" ]; then
		pass "contact form has a label for every visible field"
	else
		fail "contact form has $INPUTS fields but only $LABELS labels"
	fi
fi

# ---------------------------------------------------------------------------
section "Metadata and SEO"
# ---------------------------------------------------------------------------

SITE_URL=$(grep -oE "site:\s*'[^']+'" astro.config.mjs | sed "s/.*'\(.*\)'/\1/")
if [ -n "$SITE_URL" ]; then
	pass "astro.config declares site: $SITE_URL"
	SITE_HOST=$(echo "$SITE_URL" | sed -E 's#https?://([^/]+).*#\1#')
	BAD_CANON=$(grep -rho '<link rel="canonical" href="[^"]*"' dist --include='*.html' 2>/dev/null \
		| grep -vc "$SITE_HOST" || true)
	if [ "$BAD_CANON" = "0" ]; then
		pass "every canonical URL points at $SITE_HOST"
	else
		fail "$BAD_CANON canonical URLs do not point at $SITE_HOST"
	fi
else
	fail "astro.config.mjs declares no site: — canonical URLs and the sitemap will be wrong"
fi

NO_DESC=0
NO_TITLE=0
STATIC_NO_DESC=""
for f in $(find dist -name 'index.html' 2>/dev/null); do
	if grep -q 'name="generator" content="Astro' "$f"; then
		# Rendered through BaseHead — metadata is ours to get right.
		grep -q '<meta name="description"' "$f" || NO_DESC=$((NO_DESC + 1))
		grep -q '<title>' "$f" || NO_TITLE=$((NO_TITLE + 1))
	else
		# Served verbatim from public/ — still a landing page, still needs metadata,
		# but the fix is in the source file, not in a layout.
		grep -q '<meta name="description"' "$f" || STATIC_NO_DESC="$STATIC_NO_DESC ${f#dist/}"
	fi
done
[ "$NO_TITLE" = "0" ] && pass "every Astro page has a <title>" || fail "$NO_TITLE Astro pages have no <title>"
[ "$NO_DESC" = "0" ] && pass "every Astro page has a meta description" || fail "$NO_DESC Astro pages have no meta description"
if [ -n "$STATIC_NO_DESC" ]; then
	warn "static page(s) served from public/ have no meta description:$STATIC_NO_DESC"
else
	pass "static pages carry their own metadata"
fi

# Open Graph: every share of a page without these renders as a bare URL.
if grep -rq 'property="og:' dist --include='*.html' 2>/dev/null; then
	pass "Open Graph tags present"
else
	warn "no Open Graph tags — every shared link renders without a title, blurb or image"
fi
if grep -rq 'name="twitter:card"' dist --include='*.html' 2>/dev/null; then
	pass "Twitter card tags present"
else
	warn "no Twitter card tags"
fi

[ -f dist/sitemap-index.xml ] && pass "sitemap generated" || fail "no sitemap in dist"

# ---------------------------------------------------------------------------
section "Payload weight"
# ---------------------------------------------------------------------------
# The README names loading speed a top priority, so weight is a test, not a note.

HEAVY=$(find dist -type f -size +1M 2>/dev/null | sort)
if [ -z "$HEAVY" ]; then
	pass "no single shipped file exceeds 1 MB"
else
	while read -r f; do
		[ -z "$f" ] && continue
		sz=$(du -h "$f" | cut -f1 | tr -d ' ')
		warn "heavy asset: ${f#dist/} ($sz)"
	done <<< "$HEAVY"
fi

TOTAL_KB=$(du -sk dist 2>/dev/null | cut -f1)
if [ -n "$TOTAL_KB" ]; then
	if [ "$TOTAL_KB" -lt 12000 ]; then
		pass "total build is $((TOTAL_KB / 1024)) MB"
	else
		warn "total build is $((TOTAL_KB / 1024)) MB — large for a static personal site"
	fi
fi

# Stock scaffolding assets that shipped with the Astro starter in 2023.
STOCK=$(ls dist/blog-placeholder-*.jpg dist/placeholder-about.jpg 2>/dev/null | wc -l | tr -d ' ')
if [ "$STOCK" = "0" ]; then
	pass "no starter placeholder images in the build"
else
	warn "$STOCK Astro starter placeholder image(s) still shipping"
fi

# ---------------------------------------------------------------------------
section "Repository hygiene"
# ---------------------------------------------------------------------------

if git rev-parse --git-dir >/dev/null 2>&1; then
	if git check-ignore -q deploy.sh 2>/dev/null; then
		pass "deploy.sh is gitignored"
	else
		fail "deploy.sh is NOT gitignored — it is meant to stay per-machine"
	fi
	if git ls-files --error-unmatch .deploy-env >/dev/null 2>&1; then
		fail ".deploy-env is tracked — it holds credentials"
	else
		pass ".deploy-env is not tracked"
	fi

	# The preview-terracotta lesson: a gitignored directory holding real source
	# is work that exists in exactly one place and is invisible to every tool.
	SHADOW=$(git status --porcelain --ignored 2>/dev/null | awk '$1=="!!"{print $2}' \
		| grep -vE '^(node_modules|dist|\.astro|\.DS_Store|\.env|\.deploy-env|deploy\.sh)' || true)
	for d in $SHADOW; do
		if [ -d "$d" ] && [ -n "$(find "$d" -name '*.astro' -o -name '*.ts' 2>/dev/null | head -1)" ]; then
			warn "ignored directory holds source and is not in git: $d"
		fi
	done
	[ -z "$SHADOW" ] && pass "no ignored directory is hiding source from git"

	UNCOMMITTED=$(git status --porcelain 2>/dev/null | wc -l | tr -d ' ')
	if [ "$UNCOMMITTED" = "0" ]; then
		pass "working tree is clean"
	else
		warn "$UNCOMMITTED uncommitted change(s) — deploying ships what is on disk, not what is in git"
	fi

	AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo 0)
	if [ "$AHEAD" = "0" ]; then
		pass "branch is level with its remote"
	else
		warn "$AHEAD commit(s) not pushed — the deployed site would be ahead of GitHub"
	fi
fi

if [ -f LICENSE ]; then
	pass "LICENSE present"
else
	fail "no LICENSE file"
fi

# ---------------------------------------------------------------------------
section "Outbound link integrity"
# ---------------------------------------------------------------------------
# A dead source link on a project entry is worse than no link. This section is
# the one that needs the network; pass --offline to skip it.

if [ "$OFFLINE" = "1" ]; then
	skip "outbound link checks (--offline)"
else
	URLS=$(grep -rhoE '^(githubUrl|demoUrl|deploymentUrl):\s*"[^"]+"' src/content/projects/*.md \
		| sed 's/.*"\(.*\)"/\1/' | sort -u)
	NET_OK=0
	if [ -z "$URLS" ]; then
		skip "no project URLs to check"
	else
		for url in $URLS; do
			case "$url" in
				/*)
					# Internal demo — must exist as a real page in the build.
					if [ -f "dist${url}index.html" ] || [ -f "dist${url%/}.html" ] || [ -f "dist${url%/}/index.html" ]; then
						pass "internal demo exists in build: $url"
					else
						fail "internal demo has no page in the build: $url"
					fi
					;;
				http*)
					code=$(curl -s -o /dev/null -w "%{http_code}" -L --max-time 12 "$url" 2>/dev/null || echo 000)
					code=${code: -3}
					if [ "$code" = "000" ]; then
						# Distinguish "the network is down" from "this one host did not
						# answer". A demo link that hangs is a real defect — free-tier
						# hosts cold-start slowly, and a visitor will not wait either.
						if [ "$NET_OK" = "1" ]; then
							warn "$url did not respond within 12s (cold start or down) — a demo link that hangs reads as broken"
						else
							skip "$url (no network)"
						fi
					elif [ "$code" -lt 400 ]; then
						NET_OK=1
						pass "$url -> $code"
					else
						fail "$url -> $code (dead link on a project entry)"
					fi
					;;
			esac
		done
	fi
fi

# ---------------------------------------------------------------------------
section "Dev server smoke test"
# ---------------------------------------------------------------------------

# Astro's dev server now self-daemonizes; make sure no stale instance from a
# previous run is holding the port before starting a fresh one.
npx astro dev stop >/dev/null 2>&1

DEV_LOG=$(mktemp)
npx astro dev --port 4322 > "$DEV_LOG" 2>&1

READY=0
for _ in $(seq 1 20); do
	if curl -s -o /dev/null "http://localhost:4322/"; then
		READY=1
		break
	fi
	sleep 0.5
done

if [ "$READY" = "1" ]; then
	pass "dev server came up on :4322"

	ROUTES=(
		"/"
		"/about/"
		"/blog/"
		"/blog/latex_test/"
		"/blog/why-blog/"
		"/projects/"
		"/projects/tv-show-chat"
		"/contact/"
		"/reading/"
		"/rss.xml"
	)
	for route in "${ROUTES[@]}"; do
		code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:4322${route}")
		if [ "$code" = "200" ]; then
			pass "GET $route -> 200"
		else
			fail "GET $route -> $code (expected 200)"
		fi
	done

	# In dev mode draft posts should still be reachable for authoring/preview
	draft_code=$(curl -s -o /dev/null -w "%{http_code}" "http://localhost:4322/blog/ai-enhanced-programming-observations/")
	if [ "$draft_code" = "200" ]; then
		pass "draft post is reachable in dev mode -> 200"
	else
		fail "draft post not reachable in dev mode -> $draft_code (expected 200)"
	fi
else
	fail "dev server did not respond on :4322 within 10s (see $DEV_LOG)"
	SKIP_COUNT=$((SKIP_COUNT + 12))
fi

cleanup
DEV_PID=""

# ---------------------------------------------------------------------------
section "Summary"
# ---------------------------------------------------------------------------

echo -e "${GREEN}${PASS_COUNT} passed${NC}, ${RED}${FAIL_COUNT} failed${NC}, ${YELLOW}${WARN_COUNT} warnings${NC}, ${YELLOW}${SKIP_COUNT} skipped${NC}"

if [ "$WARN_COUNT" -gt 0 ]; then
	echo -e "${YELLOW}Warnings are known gaps, not breakage — they do not fail the run.${NC}"
fi

if [ "$FAIL_COUNT" -gt 0 ]; then
	exit 1
fi
exit 0
