#!/usr/bin/env bash
# Publikujemy konkretny skrypt studencki, nigdy cały katalog draft.
set -euo pipefail
cd -- "$(dirname -- "$0")"
student_pdf_output=${1:-0-ansible.pdf}
: "${STUDENT_FONT_PATH:?Ustaw ścieżkę do fontów DejaVu}"
student_build_dir=$(mktemp -d)
trap 'rm -f "$student_build_dir/ansible.typ"; rmdir "$student_build_dir"' EXIT
pandoc draft/01-ansible.md \
  --from=markdown --to=typst --standalone \
  --template=templates/student.typ \
  --output="$student_build_dir/ansible.typ"
typst compile --font-path "$STUDENT_FONT_PATH" \
  "$student_build_dir/ansible.typ" "$student_pdf_output"
