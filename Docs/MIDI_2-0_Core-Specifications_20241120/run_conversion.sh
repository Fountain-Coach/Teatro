#!/usr/bin/env bash
set -euo pipefail

mkdir -p text images ocr
> ocr_failures.txt

for pdf in *.pdf; do
  base="${pdf%%.*}"
  pdftotext "$pdf" -layout "text/$base.txt"
  mkdir -p "images/$base"
  pdfimages -png "$pdf" "images/$base/table"
  mkdir -p "ocr/$base"
  for img in images/$base/table-*.png; do
    out="ocr/$base/$(basename "$img" .png).txt"
    tesseract "$img" "$out" --psm 1 txt >/dev/null 2>&1 || true
    if [ ! -s "$out.txt" ]; then
      echo "$img" >> ocr_failures.txt
    else
      mv "$out.txt" "$out"
    fi
  done
  md_file="$base.md"
  echo "# $base" > "$md_file"
  echo "<!-- Generated from $pdf by MIDI2 PDF→MD Agent -->\n" >> "$md_file"
  echo "## Extracted Text" >> "$md_file"
  cat "text/$base.txt" >> "$md_file"
  echo "\n## Tables & Diagrams" >> "$md_file"
  for img in images/$base/table-*.png; do
    txt="ocr/$base/$(basename "$img" .png).txt"
    echo "### Table: $(basename $img)" >> "$md_file"
    echo "![Table]($img)\n" >> "$md_file"
    if [ -s "$txt" ]; then
      header=true
      while IFS= read -r line; do
        if $header; then
          cols=( $line )
          echo "| ${cols[*]} |" >> "$md_file"
          echo "|$(printf ' --- |%.0s' "${cols[@]}")" >> "$md_file"
          header=false
        else
          cells=( $line )
          echo "| ${cells[*]} |" >> "$md_file"
        fi
      done < "$txt"
    else
      echo "**⚠️ OCR failed; please review image above.**" >> "$md_file"
    fi
  done
done

echo "# OCR Failure Summary" > OCR_Failures.md
if [ -s ocr_failures.txt ]; then
  echo "The following images had no OCR output and require manual review:" >> OCR_Failures.md
  echo "" >> OCR_Failures.md
  while read -r img; do
    echo "- $img" >> OCR_Failures.md
  done < ocr_failures.txt
else
  echo "No OCR failures detected!" >> OCR_Failures.md
fi
