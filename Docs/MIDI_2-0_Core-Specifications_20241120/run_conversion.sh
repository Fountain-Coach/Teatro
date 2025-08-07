#!/usr/bin/env bash
set -euo pipefail

# Initialize directories and failure log
mkdir -p text images ocr_t1 ocr_t2 ocr_k ocr_final
: > ocr_failures.txt

for pdf in *.pdf; do
  base="${pdf%%.*}"
  md_file="${base}.md"

  # 1. Extract embedded text
  pdftotext "$pdf" -layout "text/$base.txt"

  # 2. Extract table images
  mkdir -p "images/$base"
  pdfimages -png "$pdf" "images/$base/table"

  # 3. Multi-pass OCR pipeline
  find "images/$base" -name 'table-*.png' | while read img; do
    proc="${img%.png}-proc.png"
    # Pre-process: deskew, upscale, binarize
    convert "$img" -deskew 40% -resize 200% -threshold 50% "$proc"

    # Tesseract first pass
    t1="ocr_t1/${base}-$(basename "$img" .png).txt"
    tesseract "$proc" "$t1" --psm 6 txt >/dev/null 2>&1 || true

    # OCRmyPDF second pass
    t2_pdf="ocr_t2/${base}-$(basename "$img" .png)-ocr.pdf"
    ocrmypdf --force-ocr "$proc" "$t2_pdf" >/dev/null 2>&1 || true
    pdftotext "$t2_pdf" "ocr_t2/${base}-$(basename "$img" .png).txt" >/dev/null 2>&1 || true

    # Kraken third pass
    t3="ocr_k/${base}-$(basename "$img" .png).txt"
    kraken -i "$proc" ocr -o "$t3" >/dev/null 2>&1 || true

    # Consolidate: pick first non-empty
    final="ocr_final/${base}-$(basename "$img" .png).txt"
    for src in "$t1" "ocr_t2/${base}-$(basename "$img" .png).txt" "$t3"; do
      if [ -s "$src" ]; then
        cp "$src" "$final"
        break
      fi
    done

    # Log failures
    [[ -s "$final" ]] || echo "$img" >> ocr_failures.txt
  done

  # 4. Build Markdown document
  {
    echo "# $base"
    echo "<!-- Generated from $pdf -->"
    echo
    echo "## Extracted Text"
    cat "text/$base.txt"
    echo
    echo "## Tables & OCR Results"
    find "images/$base" -name 'table-*.png' | while read img; do
      echo
      echo "### $(basename "$img")"
      echo "![Table]($img)"
      echo
      final="ocr_final/${base}-$(basename "$img" .png).txt"
      if [ -s "$final" ]; then
        echo '```'
        cat "$final"
        echo '```'
      else
        echo "_No OCR text available._"
      fi
    done
  } | pandoc -f markdown -t gfm -s -o "$md_file"

  # Cleanup: remove trailing whitespace
  sed -i 's/[ \t]*$//' "$md_file"
done

# 5. OCR failure summary
{
  echo "# OCR Failure Summary"
  if [ -s ocr_failures.txt ]; then
    echo "The following images had no OCR output and require manual review:" 
    echo
    while read -r img; do
      echo "- $img"
    done < ocr_failures.txt
  else
    echo "No OCR failures detected!"
  fi
} > OCR_Failures.md
