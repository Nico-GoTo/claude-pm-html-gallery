#!/usr/bin/env bash
# ============================================================
# add-analysis.sh — Add an HTML analysis to the gallery
#
# Usage:
#   ./add-analysis.sh path/to/your-file.html
#
# This script:
#   1. Copies your HTML file into the analyses/ folder
#   2. Prompts you for metadata (title, author, summary, tags)
#   3. Adds an entry to catalog.json
#   4. Commits and pushes to the repo
#
# Requirements: git, python3 (for JSON manipulation)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANALYSES_DIR="$SCRIPT_DIR/analyses"
CATALOG="$SCRIPT_DIR/catalog.json"

# --- Check arguments ---
if [ $# -lt 1 ]; then
  echo "Usage: ./add-analysis.sh <path-to-html-file>"
  echo ""
  echo "Example: ./add-analysis.sh ~/Documents/my-analysis.html"
  exit 1
fi

SOURCE_FILE="$1"

if [ ! -f "$SOURCE_FILE" ]; then
  echo "Error: File not found: $SOURCE_FILE"
  exit 1
fi

if [[ ! "$SOURCE_FILE" == *.html ]]; then
  echo "Warning: File does not have .html extension. Continue? (y/n)"
  read -r CONFIRM
  [ "$CONFIRM" != "y" ] && exit 0
fi

# --- Get filename ---
FILENAME=$(basename "$SOURCE_FILE")
DEST="$ANALYSES_DIR/$FILENAME"

if [ -f "$DEST" ]; then
  echo "A file named '$FILENAME' already exists in analyses/."
  echo "Overwrite? (y/n)"
  read -r OVERWRITE
  [ "$OVERWRITE" != "y" ] && exit 0
fi

# --- Gather metadata ---
echo ""
echo "=== Add Analysis to Gallery ==="
echo ""

read -rp "Title: " TITLE
read -rp "Author: " AUTHOR
read -rp "Summary (1-2 sentences): " SUMMARY
read -rp "Tags (comma-separated, e.g. PLG,funnel,Resolve): " TAGS_RAW

# Default date to today
DATE=$(date +%Y-%m-%d)
read -rp "Date [$DATE]: " DATE_INPUT
DATE="${DATE_INPUT:-$DATE}"

# --- Copy file ---
cp "$SOURCE_FILE" "$DEST"
echo ""
echo "Copied to analyses/$FILENAME"

# --- Update catalog.json ---
python3 -c "
import json, sys

with open('$CATALOG', 'r') as f:
    catalog = json.load(f)

tags = [t.strip() for t in '$TAGS_RAW'.split(',') if t.strip()]

entry = {
    'title': '''$TITLE''',
    'author': '''$AUTHOR''',
    'date': '$DATE',
    'summary': '''$SUMMARY''',
    'tags': tags,
    'file': 'analyses/$FILENAME'
}

catalog.append(entry)

# Sort by date descending
catalog.sort(key=lambda x: x.get('date', ''), reverse=True)

with open('$CATALOG', 'w') as f:
    json.dump(catalog, f, indent=2, ensure_ascii=False)

print('Updated catalog.json (' + str(len(catalog)) + ' entries)')
"

# --- Git commit & push ---
echo ""
read -rp "Commit and push to GitHub? (y/n) " DO_GIT

if [ "$DO_GIT" = "y" ]; then
  cd "$SCRIPT_DIR"
  git add "analyses/$FILENAME" catalog.json
  git commit -m "Add analysis: $TITLE"
  git push
  echo ""
  echo "Done! Your analysis will be live on GitHub Pages in ~1 minute."
else
  echo ""
  echo "Files updated locally. Don't forget to commit and push when ready:"
  echo "  git add analyses/$FILENAME catalog.json"
  echo "  git commit -m \"Add analysis: $TITLE\""
  echo "  git push"
fi

echo ""
echo "=== All done ==="
