#!/usr/bin/env bash
# Render the user-facing Markdown docs to PDF (and regenerate the
# tutorial's .docx) into build/docs/.
#
#   PDF path:  pandoc (GitHub-flavored Markdown -> standalone HTML with
#              the images embedded) -> WeasyPrint (HTML+CSS -> PDF),
#              styled by tools/pdf/style.css. No LaTeX needed.
#   DOCX path: docs/md_to_docx.py, the project's own converter.
#
# Requires: pandoc, and Python 3 with the `weasyprint` and `python-docx`
# packages (pip install -r tools/requirements-docs.txt). WeasyPrint needs
# the system Pango/Cairo libraries; on Debian/Ubuntu:
#   apt-get install pandoc fonts-dejavu-core libpango-1.0-0 libpangoft2-1.0-0
# on macOS with Homebrew:  brew install pandoc pango
#
# Usage:  tools/build_docs.sh            # writes build/docs/*.pdf, *.docx
#
# To add another document to the PDF set, append a "src|out|title" line
# to the DOCS list below.
set -euo pipefail

cd "$(dirname "$0")/.."
out=build/docs
mkdir -p "$out"

# src markdown | output basename | <title> for the PDF metadata
DOCS=(
  "docs/forth_tutorial.md|forth_tutorial|Learning Forth on 2068-Forth"
  "README.md|README|2068-Forth README"
)

for entry in "${DOCS[@]}"; do
  IFS='|' read -r src base title <<<"$entry"
  html="$out/$base.html"
  pdf="$out/$base.pdf"
  echo "== $src -> $pdf"
  # --embed-resources inlines the PNGs so the HTML (and PDF) is
  # self-contained; --resource-path makes the docs' relative image
  # links resolve. pagetitle sets <title> without adding a title block
  # (each document already starts with its own H1).
  # The README's Actions status badge is a remote image; drop it so the
  # render never touches the network.
  grep -v 'actions/workflows/build.yml/badge.svg' "$src" | \
  pandoc -f gfm -t html5 --standalone --embed-resources \
    --resource-path="$(dirname "$src")" \
    --css tools/pdf/style.css \
    --metadata pagetitle="$title" \
    -o "$html"
  python3 -m weasyprint --quiet "$html" "$pdf"
  rm -f "$html"
done

echo "== docs/forth_tutorial.md -> $out/forth_tutorial.docx"
python3 docs/md_to_docx.py docs/forth_tutorial.md "$out/forth_tutorial.docx"

ls -la "$out"
