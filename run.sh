#!/usr/bin/env bash
# Start the dev server. First run: ./init.sh (toolchain check, npm ci, .env).
#   ./run.sh            dev server on http://localhost:4321/ (all interfaces, so a phone on the
#                       same Wi-Fi can open it for a real mobile check)
#   ./run.sh build      production build into dist/
#   ./run.sh preview    serve dist/ locally
#   ./run.sh stop       stop the dev server (Astro 7's dev server is a background daemon;
#                       `npx astro dev status|logs` also work)
#   ./run.sh test …     run ./test.sh with the given flags (e.g. --offline)
set -euo pipefail
cd "$(dirname "$0")"
case "${1:-}" in
	-h|--help|help) sed -n '2,9p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
	test)           shift; exec ./test.sh "$@" ;;
esac

[ -d node_modules ] || { echo "node_modules missing — running ./init.sh first"; ./init.sh; }

case "${1:-dev}" in
	dev)     echo "Dev server on http://localhost:4321/ (and on this machine's LAN address)"
	         exec npm run dev -- --host ;;
	build)   exec npm run build ;;
	preview) exec npm run preview ;;
	stop)    exec npx astro dev stop ;;
	*)       echo "usage: ./run.sh [dev|build|preview|stop|test|help]" >&2; exit 2 ;;
esac
