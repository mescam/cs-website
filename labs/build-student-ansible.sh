#!/usr/bin/env bash
# Publikujemy skrypt Typst, nigdy cały katalog draft.
set -euo pipefail
cd -- "$(dirname -- "$0")"
student_pdf_output=${1:-0-ansible.pdf}
: "${STUDENT_FONT_PATH:?Ustaw ścieżkę do fontów DejaVu}"
typst compile --font-path "$STUDENT_FONT_PATH" \
  0-ansible.typ "$student_pdf_output"
