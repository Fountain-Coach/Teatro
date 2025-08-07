# Codex Agent Instructions: Enhanced OCR & Markdown Conversion for MIDI2 Spec PDFs

This **agent.md** describes how Codex should generate a shell-based agent (`run_conversion.sh`) that transforms *each* MIDI 2.0 specification PDF in a directory into a polished Markdown file (`<basename>.md`) with minimal manual cleanup. Key features:

- **Text extraction** via Poppler-Utils (`pdftotext`).
- **Table image extraction** via Poppler-Utils (`pdfimages`).
- **Pre-processing** of images with ImageMagick (deskew, resize, threshold).
- **Multi-pass OCR** using Tesseract, OCRmyPDF, and Kraken.
- **Consolidation**: first non-empty OCR result per image.
- **Automated cleanup**: Pandoc for reflow, `sed` for artifact removal.
- **OCR Failure summary** for any remaining images.

---

## 1. Prerequisites

Install required tools on Debian/Ubuntu or macOS:

```bash
# PDF processing
sudo apt-get install poppler-utils imagemagick pandoc  # Debian/Ubuntu
brew install poppler imagemagick pandoc                # macOS

# OCR engines
sudo apt-get install tesseract-ocr ocrmypdf            # Debian/Ubuntu
brew install tesseract ocrmypdf                        # macOS
pip install kraken                                     # Kraken OCR
```

Ensure this layout:
```
<working_dir>/
├── *.pdf             # MIDI2 spec PDFs
├── text/             # raw text outputs
├── images/           # extracted images per PDF
├── ocr_t1/           # Tesseract first-pass outputs
├── ocr_t2/           # OCRmyPDF outputs
├── ocr_k/            # Kraken outputs
├── ocr_final/        # Consolidated OCR results
├── ocr_failures.txt  # records images with no OCR output
└── run_conversion.sh # generated agent script
```

---

## 2. Agent Workflow (`run_conversion.sh`)

```bash
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
    tesseract "$proc" "$t1" --psm 6 txt

    # OCRmyPDF second pass
    mkdir -p ocr_t2
    t2_pdf="ocr_t2/${base}-$(basename "$img" .png)-ocr.pdf"
    ocrmypdf --force-ocr "$proc" "$t2_pdf"
    pdftotext "$t2_pdf" "ocr_t2/${base}-$(basename "$img" .png).txt"

    # Kraken third pass
    mkdir -p ocr_k
    t3="ocr_k/${base}-$(basename "$img" .png).txt"
    kraken -i "$proc" ocr -o "$t3"

    # Consolidate: pick first non-empty
    final="ocr_final/${base}-$(basename "$img" .png).txt"
    mkdir -p ocr_final
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
        header=true
        while IFS= read -r line; do
          if 
