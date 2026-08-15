#!/bin/bash
# Comprehensive test suite for the astropieter Astro site.
# Covers: production build integrity, content collections, RSS/draft filtering,
# KaTeX rendering, responsive CSS, generated routes, dependency health, and a
# live dev-server smoke test.
#
# Usage: ./test.sh

set -uo pipefail
cd "$(dirname "$0")"

GREEN='\033[0;32m'
RED='\033[0;31m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

PASS_COUNT=0
FAIL_COUNT=0
SKIP_COUNT=0

pass() { echo -e "  ${GREEN}✓${NC} $1"; PASS_COUNT=$((PASS_COUNT + 1)); }
fail() { echo -e "  ${RED}✗${NC} $1"; FAIL_COUNT=$((FAIL_COUNT + 1)); }
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

echo -e "${GREEN}${PASS_COUNT} passed${NC}, ${RED}${FAIL_COUNT} failed${NC}, ${YELLOW}${SKIP_COUNT} skipped${NC}"

if [ "$FAIL_COUNT" -gt 0 ]; then
	exit 1
fi
exit 0
