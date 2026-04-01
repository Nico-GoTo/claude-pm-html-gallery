#!/usr/bin/env bash
# ============================================================
# auto-push.sh — Watches for new/changed HTML files, commits & pushes
#
# Usage:
#   ./auto-push.sh          (runs once — good for manual use or cron)
#   ./auto-push.sh --watch  (runs continuously, checks every 30 seconds)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

do_sync() {
  # Check for any uncommitted changes in analyses/
  if git status --porcelain analyses/ | grep -q .; then
    echo "[$(date '+%H:%M:%S')] New or changed files detected:"
    git status --short analyses/

    # Stage all HTML changes
    git add analyses/*.html 2>/dev/null || true
    git add analyses/ 2>/dev/null || true

    # Count new files for commit message
    COUNT=$(git status --porcelain analyses/ | wc -l | tr -d ' ')
    git commit -m "Add/update ${COUNT} analysis file(s)"

    # Push
    git push
    echo "[$(date '+%H:%M:%S')] Pushed to GitHub. Gallery will update in ~1 minute."
  fi
}

if [ "${1:-}" = "--watch" ]; then
  echo "Watching analyses/ folder for changes (every 30s)..."
  echo "Press Ctrl+C to stop."
  echo ""
  while true; do
    do_sync
    sleep 30
  done
else
  do_sync
  echo "Done. (Run with --watch to keep monitoring.)"
fi
