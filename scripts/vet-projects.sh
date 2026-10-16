#!/usr/bin/env bash
# vet-projects.sh — mechanical pass over every directory under a projects root,
# scoring each against the portfolio musts in docs/PORTFOLIO.md.
#
# Read-only toward every repo: git is only queried, no file under the root is
# opened except README*, LICENSE*, manifests and workflow files, and no code is
# executed. One `gh repo list` call supplies visibility, description and license
# as GitHub sees them. Output is a TSV and a rendered Markdown report in an
# audit directory that must not be inside a git repo; both are chmod 600.
#
# The script carries no judgments about specific repos. The lists that are
# judgments (must stay private, retired) arrive through environment variables;
# the lists that are structure (the site and its satellite repos, take-homes)
# have defaults that can be overridden the same way.
#
# Inputs (environment, all optional):
#   VET_ROOT       projects root            default ~/dev/projects
#   VET_OUT        report directory         default ~/dev/audit-reports
#   VET_OWNER      GitHub owners counted as "own", space-separated
#                                           default pieteradejong
#   VET_SKIPLIST   dotaudit-style skiplist (mode:name:reason); `skip:` entries
#                  are not entered, `fork:` entries are excluded
#                                           default ~/dev/dotfiles/private/audit/skiplist.conf
#   VET_NEVER      repos that must stay private, space-separated   default empty
#   VET_RETIRED    retired repos                default "_to_delete pieteram bookmark-search"
#   VET_TAKEHOME   take-home assignments        default "origin-backend-take-home-assignment applicant-take-home"
#   VET_SATELLITE  the site and its satellites  default "astropieter pieteradejong pieteradejong.github.io blog"
#   VET_NO_GH=1    skip the gh call (columns become ?)
#
# Exit codes: 0 ok · 2 bad usage or missing root · 3 refused to write inside a git repo.
set -u

usage() {
	cat <<'EOF'
usage: scripts/vet-projects.sh [--root DIR] [--out DIR] [--quiet] [--help]

Scores every directory under the projects root against the portfolio musts
(docs/PORTFOLIO.md § Vetting the pool) and writes
  <out>/portfolio-vet-<date>.tsv   one row per directory
  <out>/portfolio-vet-<date>.md    the same, rendered, sorted by score
Both files are mode 600. The out directory must not be inside a git repo.

Columns: dir kind owner github_name visibility archived description license_disk
license_gh ci security_ci tests readme_lines readme_first_para images docs_dir
changelog decisions last_commit commits shape_hint gate score

Score = how many of 8 mechanical musts hold: README (>= 40 lines, first
paragraph), GitHub description, LICENSE on disk, CI, tests, commit in the last
12 months, >= 10 commits, something visual or deployable (images, vercel.json,
.vercel/, Dockerfile). A gated row scores "excluded" with the reason.

Environment: VET_ROOT VET_OUT VET_OWNER VET_SKIPLIST VET_NEVER VET_RETIRED
VET_TAKEHOME VET_SATELLITE VET_NO_GH (see the header comment).
EOF
}

ROOT="${VET_ROOT:-$HOME/dev/projects}"
OUT_DIR="${VET_OUT:-$HOME/dev/audit-reports}"
OWNERS="${VET_OWNER:-pieteradejong}"
SKIPLIST="${VET_SKIPLIST:-$HOME/dev/dotfiles/private/audit/skiplist.conf}"
NEVER="${VET_NEVER:-}"
RETIRED="${VET_RETIRED:-_to_delete pieteram bookmark-search}"
TAKEHOME="${VET_TAKEHOME:-origin-backend-take-home-assignment applicant-take-home}"
SATELLITE="${VET_SATELLITE:-astropieter pieteradejong pieteradejong.github.io blog}"
QUIET=0

while [ $# -gt 0 ]; do
	case "$1" in
		--root) ROOT="$2"; shift 2 ;;
		--out) OUT_DIR="$2"; shift 2 ;;
		--quiet) QUIET=1; shift ;;
		-h|--help) usage; exit 0 ;;
		*) echo "unknown option: $1" >&2; usage >&2; exit 2 ;;
	esac
done

[ -d "$ROOT" ] || { echo "no such projects root: $ROOT" >&2; exit 2; }
mkdir -p "$OUT_DIR" || exit 2
if git -C "$OUT_DIR" rev-parse --git-dir >/dev/null 2>&1; then
	echo "refusing to write the vet into a git repo: $OUT_DIR" >&2
	echo "the report names private repos and judges them; keep it out of version control." >&2
	exit 3
fi

STAMP=$(date +%Y-%m-%d)
TSV="$OUT_DIR/portfolio-vet-$STAMP.tsv"
MD="$OUT_DIR/portfolio-vet-$STAMP.md"
: > "$TSV"; chmod 600 "$TSV"
# One year ago, for the recency must. BSD date first (macOS), GNU as fallback.
CUTOFF=$(date -v-1y +%Y-%m-%d 2>/dev/null || date -d '1 year ago' +%Y-%m-%d)

say() { [ "$QUIET" = 1 ] || echo "$@"; }

# --- helpers -----------------------------------------------------------------

git_ro() { git -C "$1" --no-pager --no-optional-locks "${@:2}" 2>/dev/null; }

# owner/repo from a remote URL (same cases as the gate's visibility helper).
gh_slug_from_url() {
	local u="$1" s
	case "$u" in
		git@github.com:*)          s="${u#git@github.com:}" ;;
		ssh://git@github.com/*)    s="${u#ssh://git@github.com/}" ;;
		https://github.com/*)      s="${u#https://github.com/}" ;;
		https://*@github.com/*)    s="${u#*@github.com/}" ;;
		*/github.com/*/*)          s="${u##*/github.com/}" ;;
		*) return 1 ;;
	esac
	s="${s%/}"; s="${s%.git}"
	case "$s" in
		*/*/*|/*|*/) return 1 ;;
		*/) return 1 ;;
		*/*) printf '%s' "$s" ;;
		*) return 1 ;;
	esac
}

in_list() { # in_list needle "a b c"
	local n="$1" w
	for w in $2; do [ "$w" = "$n" ] && return 0; done
	return 1
}

skiplist_mode() { # skiplist_mode name -> skip|fork|"" (empty)
	[ -r "$SKIPLIST" ] || return 0
	grep -E "^(skip|fork):$1:" "$SKIPLIST" 2>/dev/null | head -1 | cut -d: -f1
}

# GitHub metadata, one call, cached in a temp TSV: name vis archived fork desc license pushed
GH_TSV=$(mktemp "${TMPDIR:-/tmp}/vet-gh.XXXXXX")
trap 'rm -f "$GH_TSV"' EXIT
GH_OK=0
if [ "${VET_NO_GH:-0}" != 1 ] && command -v gh >/dev/null 2>&1; then
	for o in $OWNERS; do
		gh repo list "$o" --limit 500 \
			--json name,visibility,isArchived,isFork,description,licenseInfo,pushedAt \
			--jq '.[] | [.name, (.visibility|ascii_downcase), (if .isArchived then "Y" else "N" end), (if .isFork then "Y" else "N" end), (if (.description // "") == "" then "N" else "Y" end), (.licenseInfo.key // "-"), (.pushedAt[0:10])] | @tsv' \
			>> "$GH_TSV" 2>/dev/null && GH_OK=1
	done
fi
gh_field() { # gh_field name column
	[ "$GH_OK" = 1 ] || { printf '?'; return; }
	local v
	v=$(awk -F'\t' -v n="$1" -v c="$2" '$1==n {print $c; exit}' "$GH_TSV")
	printf '%s' "${v:--}"
}

# --- one row -------------------------------------------------------------------

vet_dir() { # vet_dir path kind
	local d="$1" kind="$2" name rel
	rel="${d#$ROOT/}"; name=$(basename "$d")
	local owner="none" ghname="-" vis="-" archived="-" desc="-" lic_gh="-" gate=""
	local url slug
	if [ "$kind" != "not-git" ]; then
		url=$(git_ro "$d" remote get-url origin)
		if [ -n "$url" ] && slug=$(gh_slug_from_url "$url"); then
			ghname="${slug#*/}"
			if in_list "${slug%%/*}" "$OWNERS"; then owner="own"; else owner="third-party"; fi
		elif [ -n "$url" ]; then
			owner="third-party"; ghname="(non-github)"
		fi
		if [ "$owner" = own ]; then
			vis=$(gh_field "$ghname" 2); archived=$(gh_field "$ghname" 3)
			desc=$(gh_field "$ghname" 5); lic_gh=$(gh_field "$ghname" 6)
		fi
	fi

	# gate, first reason wins
	local mode; mode=$(skiplist_mode "$name")
	if [ "$kind" = not-git ]; then gate="not-git"
	elif [ "$mode" = fork ] || [ "$owner" = third-party ]; then gate="third-party"
	elif in_list "$name" "$SATELLITE"; then gate="satellite"
	elif in_list "$name" "$RETIRED" || in_list "$(basename "$(dirname "$d")")" "$RETIRED"; then gate="retired"
	elif in_list "$name" "$TAKEHOME"; then gate="take-home"
	elif [ "$archived" = Y ]; then gate="archived"
	elif in_list "$name" "$NEVER"; then gate="must-stay-private"
	fi

	# disk signals
	local readme readme_lines=0 first_para=N lic_disk="-" ci=N sec_ci=N tests=none
	readme=$(find "$d" -maxdepth 1 -iname 'readme*' -type f 2>/dev/null | head -1)
	if [ -n "$readme" ]; then
		readme_lines=$(wc -l < "$readme" | tr -d ' ')
		# a prose line in the first 15 that is not a heading, badge, image or html
		if head -15 "$readme" | grep -vE '^\s*$|^#|^\s*[!\[<]|^\s*-{3,}|^\s*\|' | grep -qE '[A-Za-z]{3,}.*[A-Za-z]{3,}'; then first_para=Y; fi
	fi
	local lf; lf=$(find "$d" -maxdepth 1 -iname 'license*' -type f 2>/dev/null | head -1)
	[ -n "$lf" ] && lic_disk=$(basename "$lf")
	if [ -n "$(find "$d/.github/workflows" -maxdepth 1 \( -name '*.yml' -o -name '*.yaml' \) -type f 2>/dev/null | head -1)" ]; then
		ci=Y
		grep -lq 'security-reusable.yml' "$d"/.github/workflows/*.y*ml 2>/dev/null && sec_ci=Y
	fi
	if [ -f "$d/test.sh" ] && [ -d "$d/tests" ]; then tests=both
	elif [ -f "$d/test.sh" ]; then tests=test.sh
	elif [ -d "$d/tests" ] || [ -d "$d/test" ]; then tests=tests/
	fi
	local images docs_dir=N changelog=N decisions="-"
	images=$(find "$d" \( -name node_modules -o -name .git -o -name .venv -o -name venv -o -name dist -o -name build -o -name .next \) -prune -o \
		-type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.gif' -o -iname '*.svg' -o -iname '*.webp' \) -print 2>/dev/null | head -200 | wc -l | tr -d ' ')
	[ -d "$d/docs" ] && docs_dir=Y
	[ -f "$d/CHANGELOG.md" ] && changelog=Y
	if [ -f "$d/DECISIONS.md" ]; then decisions=root; elif [ -f "$d/docs/DECISIONS.md" ]; then decisions=docs; fi
	local last="-" commits="-"
	if [ "$kind" != not-git ]; then
		last=$(git_ro "$d" log -1 --format=%cs); [ -n "$last" ] || last="-"
		commits=$(git_ro "$d" rev-list --count HEAD); [ -n "$commits" ] || commits="ERR"
	fi
	local shape="-"
	if [ -f "$d/package.json" ]; then shape=node
	elif [ -f "$d/pyproject.toml" ] || [ -f "$d/requirements.txt" ]; then shape=python
	elif [ -f "$d/Package.swift" ] || ls "$d"/*.xcodeproj >/dev/null 2>&1; then shape=swift
	elif [ -f "$d/go.mod" ]; then shape=go
	elif [ -f "$d/Cargo.toml" ]; then shape=rust
	elif [ -f "$d/index.html" ]; then shape=static
	fi
	local deployable=N
	if [ "$images" -gt 0 ] || [ -f "$d/vercel.json" ] || [ -d "$d/.vercel" ] || [ -f "$d/Dockerfile" ]; then deployable=Y; fi

	# score
	local score
	if [ -n "$gate" ]; then
		score="excluded"
	else
		score=0
		[ "$readme_lines" -ge 40 ] && [ "$first_para" = Y ] && score=$((score+1))
		[ "$desc" = Y ] && score=$((score+1))
		[ "$lic_disk" != "-" ] && score=$((score+1))
		[ "$ci" = Y ] && score=$((score+1))
		[ "$tests" != none ] && score=$((score+1))
		[ "$last" != "-" ] && [ "$last" \> "$CUTOFF" ] && score=$((score+1))
		case "$commits" in ''|*[!0-9]*) ;; *) [ "$commits" -ge 10 ] && score=$((score+1)) ;; esac
		[ "$deployable" = Y ] && score=$((score+1))
		score="$score/8"
	fi
	[ -z "$gate" ] && gate="-"

	printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' \
		"$rel" "$kind" "$owner" "$ghname" "$vis" "$archived" "$desc" "$lic_disk" "$lic_gh" \
		"$ci" "$sec_ci" "$tests" "$readme_lines" "$first_para" "$images" "$docs_dir" "$changelog" \
		"$decisions" "$last" "$commits" "$shape" "$gate" "$score" >> "$TSV"
	say "  $rel  $score${gate:+ }$( [ "$gate" != "-" ] && printf '(%s)' "$gate")"
}

# --- discovery -----------------------------------------------------------------

say "vet-projects: $ROOT → $OUT_DIR  (gh metadata: $( [ "$GH_OK" = 1 ] && echo yes || echo no))"
N=0
for d in "$ROOT"/*/; do
	d="${d%/}"; name=$(basename "$d")
	case "$name" in .*) continue ;; esac
	if [ "$(skiplist_mode "$name")" = skip ]; then say "  $name  (skiplist: not entered)"; continue; fi
	if [ -d "$d/.git" ]; then
		vet_dir "$d" repo
	else
		vet_dir "$d" not-git
		for c in "$d"/*/; do
			c="${c%/}"
			[ -d "$c/.git" ] && vet_dir "$c" nested
		done
	fi
	N=$((N+1))
done

# --- render ------------------------------------------------------------------------

{
	echo "# Portfolio vet — $STAMP"
	echo
	echo "Mechanical pass of \`scripts/vet-projects.sh\` over \`$ROOT\` against the musts in"
	echo "\`docs/PORTFOLIO.md\` § Vetting the pool. One row per directory; nested repos one level"
	echo "down have kind \`nested\`. GitHub metadata: $( [ "$GH_OK" = 1 ] && echo "from one \`gh repo list\` call" || echo "not fetched (columns show ?)")."
	echo "Score counts the 8 mechanical musts; \`excluded\` rows failed the gate for the reason shown."
	echo "This file is point-in-time and mode 600. Verdicts and gaps from the qualitative read are"
	echo "appended by hand below the tables."
	echo
	echo "## Counts"
	echo
	echo "- directories entered: $N (plus nested repos as separate rows)"
	echo "- rows: $(wc -l < "$TSV" | tr -d ' ')"
	echo "- gated: $(awk -F'\t' '$22!="-"' "$TSV" | wc -l | tr -d ' ') — $(awk -F'\t' '$22!="-" {c[$22]++} END {for (k in c) printf "%s %d; ", k, c[k]}' "$TSV")"
	echo "- scored: $(awk -F'\t' '$22=="-"' "$TSV" | wc -l | tr -d ' ')"
	echo
	echo "## Scored rows, best first"
	echo
	echo "| Dir | Kind | Vis | Desc | License | CI | Tests | README | Imgs | Docs | Last | Commits | Shape | Score |"
	echo "|---|---|---|---|---|---|---|---|---|---|---|---|---|---|"
	awk -F'\t' '$22=="-" { split($23,s,"/"); printf "%s\t%s\n", s[1], $0 }' "$TSV" | sort -t$'\t' -k1,1nr -k2,2 | cut -f2- | \
	awk -F'\t' '{ printf "| `%s` | %s | %s | %s | %s | %s | %s | %s | %s | %s%s%s | %s | %s | %s | **%s** |\n", $1,$2,$5,$7,$8,$10,$12,$13" ("$14")",$15,$16,($17=="Y"?"+CL":""),($18!="-"?"+D":""),$19,$20,$21,$23 }'
	echo
	echo "## Excluded rows"
	echo
	echo "| Dir | Kind | Owner | GitHub | Vis | Reason |"
	echo "|---|---|---|---|---|---|"
	awk -F'\t' '$22!="-" { printf "| `%s` | %s | %s | %s | %s | %s |\n", $1,$2,$3,$4,$5,$22 }' "$TSV" | sort
	echo
	echo "## Qualitative verdicts"
	echo
	echo "_Appended by hand after the read; see docs/PORTFOLIO.md § Vetting the pool for the scale._"
} > "$MD"
chmod 600 "$MD"
say "wrote $TSV and $MD ($(wc -l < "$TSV" | tr -d ' ') rows)"
