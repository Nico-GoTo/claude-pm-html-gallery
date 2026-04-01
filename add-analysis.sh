#!/usr/bin/env bash
# ============================================================
# add-analysis.sh — Add one or more HTML analyses to the gallery
#
# Usage:
#   ./add-analysis.sh file1.html file2.html file3.html
#
# This script (for each file):
#   1. Copies your HTML file into the analyses/ folder
#   2. Prompts you for metadata (title, author, summary, tags)
#   3. Adds an entry to catalog.json
#
# After all files are processed, optionally commits and pushes.
#
# Requirements: git, python3 (for JSON manipulation)
# ============================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ANALYSES_DIR="$SCRIPT_DIR/analyses"
CATALOG="$SCRIPT_DIR/catalog.json"

# --- Check arguments ---
if [ $# -lt 1 ]; then
  echo "Usage: ./add-analysis.sh <html-file> [html-file2] [html-file3] ..."
  echo ""
  echo "Examples:"
  echo "  ./add-analysis.sh ~/Documents/my-analysis.html"
  echo "  ./add-analysis.sh report1.html report2.html report3.html"
  exit 1
fi

ADDED_FILES=()

for SOURCE_FILE in "$@"; do

  echo ""
  echo "========================================"
  echo "Processing: $(basename "$SOURCE_FILE")"
  echo "========================================"

  if [ ! -f "$SOURCE_FILE" ]; then
    echo "Error: File not found: $SOURCE_FILE — skipping."
    continue
  fi

  if [[ ! "$SOURCE_FILE" == *.html ]]; then
    echo "Warning: File does not have .html extension. Continue? (y/n)"
    read -r CONFIRM
    [ "$CONFIRM" != "y" ] && continue
  fi

  # --- Get filename ---
  FILENAME=$(basename "$SOURCE_FILE")
  DEST="$ANALYSES_DIR/$FILENAME"

  if [ -f "$DEST" ]; then
    echo "A file named '$FILENAME' already exists in analyses/."
    echo "Overwrite? (y/n)"
    read -r OVERWRITE
    [ "$OVERWRITE" != "y" ] && continue
  fi

  # --- Gather metadata ---
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
  echo "Copied to analyses/$FILENAME"

  # --- Update catalog.json ---
  python3 -c "
import json

with open('$CATALOG', 'r') as f:
    catalog = json.load(f)

tags = [t.strip() for t in '''$TAGS_RAW'''.split(',') if t.strip()]

entry = {
    'title': '''$TITLE''',
    'author': '''$AUTHOR''',
    'date': '$DATE',
    'summary': '''$SUMMARY''',
    'tags': tags,
    'file': 'analyses/$FILENAME'
}

catalog.append(entry)
catalog.sort(key=lambda x: x.get('date', ''), reverse=True)

with open('$CATALOG', 'w') as f:
    json.dump(catalog, f, indent=2, ensure_ascii=False)

print('Updated catalog.json (' + str(len(catalog)) + ' entries)')
"

  ADDED_FILES+=("analyses/$FILENAME")

done

# --- Summary ---
if [ ${#ADDED_FILES[@]} -eq 0 ]; then
  echo ""
  echo "No files were added."
  exit 0
fi

echo ""
echo "========================================"
echo "Added ${#ADDED_FILES[@]} file(s):"
for f in "${ADDED_FILES[@]}"; do echo "  - $f"; done
echo "========================================"

# --- Git commit & push ---
echo ""
read -rp "Commit and push all to GitHub? (y/n) " DO_GIT

if [ "$DO_GIT" = "y" ]; then
  cd "$SCRIPT_DIR"
  git add "${ADDED_FILES[@]}" catalog.json
  git commit -m "Add ${#ADDED_FILES[@]} analysis file(s)"
  git push
  echo ""
  echo "Done! Changes will be live on GitHub Pages in ~1 minute."
else
  echo ""
  echo "Files updated locally. To push manually:"
  echo "  git add ${ADDED_FILES[*]} catalog.json"
  echo "  git commit -m \"Add analyses\""
  echo "  git push"
fi

echo ""
echo "=== All done ==="
