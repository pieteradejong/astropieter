#!/usr/bin/env bash
# sync-projects.sh — bring project pages in from the project repos themselves.
#
# A project repo that wants a page on /projects carries `portfolio.md` at its
# root: the frontmatter of src/content.config.ts's project schema, plus
# `public: true|false`, plus the page body (docs/PORTFOLIO.md § Publishing a
# project). This script reads that file from every PUBLIC repo of the owner and:
#
#   public: true   writes src/content/projects/<repo>.md and copies the hero to
#                  src/assets/projects/<repo>.<ext>
#   public: false  removes the page this script generated earlier, if any
#   no file        the same as public: false
#
# Generated pages carry `syncedFrom: "<repo>@<sha>"`. Only those are ever
# rewritten or removed; hand-written pages are never touched, and a repo whose
# slug collides with one is refused. Private repos are never listed: GitHub is
# asked only for public ones. Nothing is committed or pushed. Run it on a
# branch, run ./test.sh (the build validates the schema, the link checks
# validate githubUrl and demoUrl), then push main, which deploys.
#
# Inputs (environment, all optional):
#   SYNC_OWNER     GitHub owner             default pieteradejong
#   SYNC_FROM_DIR  read <dir>/<repo>/portfolio.md instead of GitHub (tests,
#                  drafting); every subdirectory counts as a public repo
#
# Exit codes: 0 ok (changed or not) · 1 a repo's portfolio.md is invalid ·
#             2 bad usage or missing tool.
set -u

usage() {
	cat <<'EOF'
usage: scripts/sync-projects.sh [--dry-run] [--repo NAME] [--help]

Reads portfolio.md from every public repo (or only NAME) and writes or removes
the generated pages under src/content/projects/. Prints what changed.
EOF
}

DRY=0; ONLY=""
while [ $# -gt 0 ]; do
	case "$1" in
		-h|--help) usage; exit 0 ;;
		--dry-run) DRY=1; shift ;;
		--repo) [ $# -ge 2 ] || { usage >&2; exit 2; }; ONLY="$2"; shift 2 ;;
		*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
done

cd "$(dirname "$0")/.." || exit 2
OWNER="${SYNC_OWNER:-pieteradejong}"
FROM_DIR="${SYNC_FROM_DIR:-}"
PAGES="src/content/projects"
ASSETS="src/assets/projects"
if [ -z "$FROM_DIR" ]; then
	command -v gh >/dev/null 2>&1 || { echo "gh is not on PATH" >&2; exit 2; }
	command -v jq >/dev/null 2>&1 || { echo "jq is not on PATH" >&2; exit 2; }
fi
TMP="$(mktemp -d "${TMPDIR:-/tmp}/sync-projects.XXXXXX")"
trap 'rm -rf "$TMP"' EXIT

CHANGED=0; BAD=0
note() { echo "  $*"; }
act() { CHANGED=1; if [ "$DRY" -eq 1 ]; then note "would $*"; else note "$*"; fi; }

# ── Sources ──────────────────────────────────────────────────────────────────
list_repos() {
	if [ -n "$FROM_DIR" ]; then
		for d in "$FROM_DIR"/*/; do [ -d "$d" ] && basename "$d"; done
	else
		gh repo list "$OWNER" --visibility public --no-archived --limit 1000 --json name --jq '.[].name'
	fi
}
# fetch <repo> <path> <dest>: 0 the file exists in the repo's default branch,
# 1 it does not (404), 3 anything else (network, auth, rate limit): the caller
# must then keep what it has, never treat the file as gone. Read-only (GET).
fetch() {
	if [ -n "$FROM_DIR" ]; then
		[ -f "$FROM_DIR/$1/$2" ] || return 1
		cp "$FROM_DIR/$1/$2" "$3"; return 0
	fi
	if gh api "repos/$OWNER/$1/contents/$2" --jq '.content' > "$3.b64" 2> "$3.err"; then
		base64 --decode < "$3.b64" > "$3" 2>/dev/null && [ -s "$3" ] && return 0
		return 3
	fi
	grep -q 'HTTP 404' "$3.err" && return 1
	return 3
}
head_sha() {
	if [ -n "$FROM_DIR" ]; then
		git -C "$FROM_DIR/$1" rev-parse HEAD 2>/dev/null || echo local
	else
		gh api "repos/$OWNER/$1/commits/HEAD" --jq '.sha' 2>/dev/null || echo unknown
	fi
}

# ── Frontmatter, line by line (the Astro build is the schema check) ─────────
fm() { awk 'NR==1 && $0=="---" {f=1; next} f && $0=="---" {exit} f' "$1"; }
fm_value() { fm "$1" | sed -n "s/^$2:[[:space:]]*//p" | head -1 | sed -E "s/[[:space:]]+\$//; s/^\"(.*)\"\$/\\1/; s/^'(.*)'\$/\\1/"; }
body() { awk 'NR==1 && $0=="---" {f=1; next} f==1 && $0=="---" {f=2; next} f==2' "$1"; }
synced_repo() { fm_value "$1" syncedFrom | sed 's/@.*//'; }

# ── Pull in every listed repo ────────────────────────────────────────────────
WANTED="$TMP/wanted"; : > "$WANTED"
KEEP="$TMP/keep"; : > "$KEEP"          # repos that errored this run: their pages stay as they are
REPOS="$TMP/repos"
list_repos > "$REPOS" || { echo "could not list the repos; nothing changed" >&2; exit 2; }
# skip <repo> <message>: report an error for this repo and keep its page untouched.
skip() { note "✗ $1: $2"; echo "$1" >> "$KEEP"; BAD=1; }
echo "sync-projects: $( [ -n "$FROM_DIR" ] && echo "fixtures in $FROM_DIR" || echo "public repos of $OWNER")$( [ "$DRY" -eq 1 ] && echo ' (dry run)')"
while IFS= read -r repo; do
	[ -n "$repo" ] || continue
	[ -n "$ONLY" ] && [ "$repo" != "$ONLY" ] && continue
	src="$TMP/$repo.md"
	fetch "$repo" portfolio.md "$src"; rc=$?
	if [ "$rc" = 3 ]; then skip "$repo" "could not read portfolio.md (not a 404); its page is kept"; continue; fi
	[ "$rc" = 0 ] || continue
	flag="$(fm_value "$src" public)"
	case "$flag" in
		true) ;;
		false) continue ;;
		*) skip "$repo" "portfolio.md: public must be true or false, got '${flag:-nothing}'"; continue ;;
	esac
	# test.sh's link checks read double-quoted githubUrl/demoUrl only; a
	# single-quoted one would be published unchecked.
	if fm "$src" | grep -qE "^(githubUrl|demoUrl):[[:space:]]*'"; then
		skip "$repo" "githubUrl and demoUrl must be double-quoted (the link checks skip other forms)"; continue
	fi
	slug="$(echo "$repo" | tr '[:upper:]' '[:lower:]')"
	page="$PAGES/$slug.md"
	if [ -f "$page" ] && [ "$(synced_repo "$page")" != "$repo" ]; then
		skip "$repo" "$page is a hand-written page; rename one of them"; continue
	fi

	hero="$(fm_value "$src" hero)"
	hero_line=""
	if [ -n "$hero" ]; then
		case "$hero" in
			/*|*..*|http*) skip "$repo" "hero must be a path inside the repo, got '$hero'"; continue ;;
		esac
		ext="$(echo "${hero##*.}" | tr '[:upper:]' '[:lower:]')"
		case "$ext" in jpg|jpeg|png|webp) ;; *) skip "$repo" "hero must be jpg, png or webp"; continue ;; esac
		if ! fetch "$repo" "$hero" "$TMP/$slug.hero"; then skip "$repo" "hero $hero not readable in the repo"; continue; fi
		hero_line="hero: \"../../assets/projects/$slug.$ext\""
	fi
	echo "$repo" >> "$WANTED"

	new="$TMP/$slug.page"
	{
		echo "---"
		fm "$src" | grep -vE '^(#|(public|hero|syncedFrom):)'
		[ -n "$hero_line" ] && echo "$hero_line"
		echo "syncedFrom: \"$repo@$(head_sha "$repo")\""
		echo "---"
		body "$src"
	} > "$new"

	if [ -f "$page" ] && cmp -s <(grep -v '^syncedFrom:' "$page") <(grep -v '^syncedFrom:' "$new") \
		&& { [ -z "$hero_line" ] || cmp -s "$TMP/$slug.hero" "$ASSETS/$slug.$ext"; }; then
		note "= $repo unchanged"; continue
	fi
	act "write $page"
	if [ "$DRY" -eq 0 ]; then
		cp "$new" "$page"
		[ -n "$hero_line" ] && cp "$TMP/$slug.hero" "$ASSETS/$slug.$ext"
	fi
done < "$REPOS"

# ── Remove generated pages no longer wanted ─────────────────────────────────
for page in "$PAGES"/*.md; do
	[ -f "$page" ] || continue
	repo="$(synced_repo "$page")"
	[ -n "$repo" ] || continue
	[ -n "$ONLY" ] && [ "$repo" != "$ONLY" ] && continue
	grep -qx "$repo" "$WANTED" && continue
	grep -qx "$repo" "$KEEP" && continue
	hero="$(fm_value "$page" hero | sed 's#^\.\./\.\./assets/projects/##')"
	act "remove $page ($repo is private, unlisted or has no portfolio.md)"
	if [ "$DRY" -eq 0 ]; then
		rm -f "$page"
		[ -n "$hero" ] && rm -f "$ASSETS/$hero"
	fi
done

[ "$CHANGED" -eq 0 ] && note "nothing to change"
[ "$CHANGED" -eq 1 ] && [ "$DRY" -eq 0 ] && echo "next: ./test.sh (full, with network), then commit and push main"
exit "$BAD"
