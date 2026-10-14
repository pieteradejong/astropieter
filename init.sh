#!/usr/bin/env bash
# One-time setup for a fresh clone: checks the toolchain, installs the pinned
# dependencies, creates .env from the template and tells you what to run next.
# Safe to re-run. Nothing here needs the network beyond `npm ci`.
set -euo pipefail
cd "$(dirname "$0")"

GREEN='\033[0;32m'; BLUE='\033[0;34m'; RED='\033[0;31m'; NC='\033[0m'
say()  { printf '%b\n' "${BLUE}$1${NC}"; }
ok()   { printf '%b\n' "  ${GREEN}✓${NC} $1"; }
die()  { printf '%b\n' "  ${RED}✗${NC} $1" >&2; exit 1; }

say "astropieter — initial setup"

# Node 22.12+ is Astro 7's floor (README § Upgrade Reqs). package.json pins engines to 22.x.
command -v node >/dev/null 2>&1 || die "Node.js is not installed. This machine uses nvm: 'nvm install 22 && nvm use 22'."
NODE_V=$(node -p 'process.versions.node')
node -e 'const [a,b]=process.versions.node.split(".").map(Number); process.exit(a>22||(a===22&&b>=12)?0:1)' \
	|| die "Node $NODE_V found, but Astro 7 needs 22.12 or newer ('nvm install 22')."
ok "Node $NODE_V"
command -v npm >/dev/null 2>&1 || die "npm is not installed."
ok "npm $(npm -v)"

# Exact, reproducible install from the lockfile (repo-standards: exact pins, one package manager).
say "Installing dependencies (npm ci)…"
if [ -f package-lock.json ]; then
	npm ci --no-audit --no-fund
else
	die "package-lock.json is missing — this repo installs from the lockfile only."
fi
ok "node_modules ready"

# .env: the only variable is the public Web3Forms key used by /contact/.
if [ ! -f .env ]; then
	cp .env.example .env
	ok ".env created from .env.example — fill in PUBLIC_WEB3FORMS_KEY for the contact form"
else
	ok ".env present (left untouched)"
fi

# Browser tests use an installed Chrome; nothing is downloaded (playwright.config.ts).
CHROME_FOUND=""
for c in "${CHROME_PATH:-}" \
	"/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
	"/Applications/Chrome.app/Contents/MacOS/Google Chrome" \
	"/usr/bin/google-chrome"; do
	if [ -n "$c" ] && [ -x "$c" ]; then CHROME_FOUND="$c"; break; fi
done
if [ -n "$CHROME_FOUND" ]; then
	ok "Chrome for browser tests: $CHROME_FOUND"
else
	printf '%b\n' "  ! no Chrome found — set CHROME_PATH, or run 'npx playwright install chromium' before ./test.sh"
fi

say "Done. Next:"
printf '  %b  dev server with live reload\n'            "${BLUE}./run.sh${NC}"
printf '  %b  full pre-push suite (Vercel does not run it)\n' "${BLUE}./test.sh${NC}"
printf '  %b  production build into dist/\n'            "${BLUE}npm run build${NC}"
printf '  Deploy: push to main (DEPLOYMENT.md).\n'
