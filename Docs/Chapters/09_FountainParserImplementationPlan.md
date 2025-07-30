## 9. Fountain Parser Implementation
_Historical notes on parser implementation._

This guide documents the complete strategy for implementing a Fountain screenplay parser in Swift for the Teatro View engine. It mirrors the official specification available at [fountain.io/syntax](https://fountain.io/syntax/) and does **not** omit any feature. Every rule is represented in a deterministic state machine rather than through regular expressions so that it can be overridden or extended when integrating into Teatro.
**Historical Note:** The parser is fully implemented; this plan remains for reference.

**Status:** The parser described below is implemented in `Sources/ViewCore/FountainParser.swift` and tested under `TeatroTests`.

## Token Types

The parser must recognize all of the following element types exactly as described in the spec:

- **Scene Headings**
- **Action**
- **Character**
- **Parenthetical**
- **Dialogue**
- **Dual Dialogue**
- **Lyrics**
- **Transitions**
- **Centered Text**
- **Emphasis** (bold, italic, underline and their combinations)
- **Title Page Fields**
- **Page Breaks**
- **Notes**
- **Boneyard**
- **Sections**
- **Synopses**
- Any text that fails to match a rule defaults to **Action**.

Elements like Notes (`[[...]]`) and Boneyard blocks (`/* ... */`) may span multiple lines. The parser needs dedicated state for each opening and closing delimiter to ensure proper nesting.

## Parsing State Machine

1. **Title Page State** – Parse lines of the form `Key: Value` before the main body begins. Indented lines belong to the previous key. Transition to the Body State once a blank line occurs without a key.
2. **Body State** – Consume screenplay lines. This state contains sub‑states for constructs such as notes and boneyard to allow multi‑line elements. The machine emits tokens in the order encountered without reordering or collapsing blank lines unless mandated by the spec.
3. **Note and Boneyard Sub‑States** – Once entering these, lines are appended to the element until the corresponding closing delimiter is found. Boneyard may contain blank lines while notes may not.

## Detection Functions (No Regular Expressions)

- `isSceneHeading(line:)` – Detect leading periods or keywords like `INT.`, `EXT.`, `I/E.` ignoring case. Ensure surrounding blank lines if required.
- `isAction(line:)` – The fallback when nothing else matches. Prefix `!` forces Action even if the line would otherwise qualify as Character or Transition.
- `isCharacter(line:)` – Lines in full uppercase that follow a blank line and are not themselves blank. May include parenthetical extensions on the same line. Dual dialogue is signaled by a trailing `^`.
- `isParenthetical(line:)` – Lines starting with `(` immediately after a character or dialogue line.
- `isDualDialogue(line:)` – Recognized when a Character line ends with `^` before any trailing whitespace.
- `isLyrics(line:)` – Lines beginning with `~` are always treated as Lyrics.
- `isTransition(line:)` – Uppercase lines ending with `TO:` with blank lines before and after unless forced with the `>` prefix. A trailing colon followed by spaces converts it back to Action.
- `isCentered(line:)` – Text enclosed between `>` and `<` on the same line, including the delimiters.
- `isPageBreak(line:)` – A line consisting of three or more `=` characters.
- `isSection(line:)` – Lines beginning with one or more `#` characters denote nested sections. The count of leading hashes represents the depth.
- `isSynopsis(line:)` – A single line beginning with `=` that does not also qualify as a page break.
- `isNote` and `isBoneyard` – Maintain counters for the opening and closing markers to support multi‑line capture.

## Emphasis Parsing

Within dialogue and action text, scan character by character to recognise emphasis markers exactly as `_underline_`, `*italic*`, `**bold**`, and `***bold italic***`. Backslashes escape any marker. Emphasis spans cannot cross line boundaries and must nest properly.

## Title Page Fields

The parser collects all contiguous leading lines matching `Key: Value` pairs before the first blank line with no key. Keys include `Title`, `Credit`, `Author`, `Source`, `Draft date`, `Contact` and any others defined in the spec. Each value may continue on one or more indented lines.

## Customisation via RuleSet

Expose a `RuleSet` configuration structure so the Teatro View engine can alter behaviour without modifying parser logic. Options include:

- Additional scene heading keywords.
- Extra transition keywords.
- Enabling or disabling features such as Notes, Boneyard, Sections, or Synopses.

`FountainParser` instances accept a `RuleSet` argument on initialisation to override the defaults. Extensions can thus adapt the parser to simplified or specialised formats.

## Abstract Syntax Tree Output

Every parsed element becomes a `FountainElement` node with the following properties:

- `type` – the enum case derived from the token types above.
- `rawText` – the exact text as it appears in the script.
- `lineNumber` – the source line where the element begins.
- `children` – nested elements such as emphasis spans inside a dialogue block.

The resulting array of nodes is fed into the Teatro View renderer which maps each element to an on‑screen representation.

## Validation Strategy

- **Unit Tests** – For each syntax rule craft lines that intentionally target edge cases, ensuring detection is robust. Scene headings, transitions, dual dialogue, multi‑line boneyard, and nested emphasis are all covered.
- **End‑to‑End Test** – Parse the full example screenplay from the Fountain specification and verify the AST element order and properties.
- **Custom Rule Tests** – Instantiate the parser with alternative rule sets and confirm behaviour matches the override definitions.

## Error Handling

Any malformed line that does not conform to a specific rule defaults to an Action element, as recommended by the spec. This prevents content from disappearing due to parser errors. Boneyard is the only construct that may span multiple blank lines.

## Documentation

This document resides alongside the Teatro View engine implementation so developers can cross‑reference the Fountain specification. All future updates to the spec should be mirrored here without omission. Examples showing how to customize rule sets and parse scripts should be added as the implementation evolves.




`````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
`````
