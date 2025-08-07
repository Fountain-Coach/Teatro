# Codex Agent Instructions: Convert MIDI2 Spec PDFs to Markdown Files

This document instructs Codex to generate a shell-based agent that converts *each* MIDI 2.0 specification PDF in a directory into a corresponding Markdown (`.md`) file containing human- and machine-readable content. The agent:

- Extracts embedded text via **Poppler-Utils**.
- Extracts and embeds table/diagram images.
- Performs OCR on images with **Tesseract**.
- Integrates raw text, images, and OCR tables into `<basename>.md` files.
- Flags and summarizes OCR failures for manual review.

---

## 1. Prerequisites

Install on Debian/Ubuntu or macOS:

```bash
# Poppler-Utils for text and image extraction
sudo apt-get install poppler-utils      # Debian/Ubuntu
brew install poppler                    # macOS

# Tesseract OCR for image-to-text
sudo apt-get install tesseract-ocr      # Debian/Ubuntu
brew install tesseract                  # macOS
```

Ensure the following directory layout before running:

```
<working_dir>/
├── *.pdf             # MIDI2 spec PDFs
├── text/             # will hold raw text (.txt)
├── images/           # will hold extracted images per PDF
├── ocr/              # will hold OCR outputs per PDF
└── run_conversion.sh # generated agent script
```

---

## 2. Agent Workflow Within `run_conversion.sh`

```bash
#!/usr/bin/env bash
set -euo pipefail

# Initialize directories
mkdir -p text images ocr
> ocr_failures.txt
```

### Loop Over Each PDF

```bash
for pdf in *.pdf; do
  base="${pdf%%.*}"

  # 1. Extract raw text
  pdftotext "$pdf" -layout "text/$base.txt"

  # 2. Extract table/diagram images
  mkdir -p "images/$base"
  pdfimages -png "$pdf" "images/$base/table"

  # 3. OCR images
  mkdir -p "ocr/$base"
  for img in images/$base/table-*.png; do
    out="ocr/$base/$(basename "$img" .png).txt"
    tesseract "$img" "$out" --psm 1 txt
    # Record failures
    if [ ! -s "$out" ]; then
      echo "$img" >> ocr_failures.txt
    fi
  done

  # 4. Assemble Markdown file for this PDF
  md_file="$base.md"
  echo "# $base" > "$md_file"
  echo "<!-- Generated from $pdf by MIDI2 PDF→MD Agent -->\n" >> "$md_file"

  # 4a. Append raw text
  echo "## Extracted Text" >> "$md_file"
  cat "text/$base.txt" >> "$md_file"

  # 4b. Append tables & images
  echo "\n## Tables & Diagrams" >> "$md_file"
  for img in images/$base/table-*.png; do
    txt="ocr/$base/$(basename "$img" .png).txt"
    echo "### Table: $(basename $img)" >> "$md_file"
    echo "![Table]($img)\n" >> "$md_file"
    if [ -s "$txt" ]; then
      # Render OCR into Markdown table
      header=true
      while IFS= read -r line; do
        if \$header; then
          cols=( $line )
          # Header row
          echo "| ${cols[*]} |" >> "$md_file"
          # Separator row
          echo "|$(printf ' --- |%.0s' "\${cols[@]}")" >> "$md_file"
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
```

---

## 3. OCR Failure Report

After processing all PDFs, generate a summary file `OCR_Failures.md`:

```bash
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
```

---

## 4. Usage

Make the script executable and run it:

```bash
chmod +x run_conversion.sh
./run_conversion.sh
```

Each PDF `<basename>.pdf` produces `<basename>.md`. The `OCR_Failures.md` lists any image files requiring manual inspection.

---

*End of agent instructions.*
