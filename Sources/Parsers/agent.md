# 🧩 Teatro Parser Agent Task Matrix

**Last Updated:** August 06, 2025
**Maintainer:** FountainAI / Codex Agents  
**Directory:** `Sources/Parsers/agent.md`  
**Purpose:** Replace prose-style spec with machine-actionable backlog. Codex agents can consume this table and implement full vertical slices.

---

## 📋 Task Matrix

| Feature                | File(s)                                                                 | Action       | Status  | Blockers                    | Tags                 |
|------------------------|-------------------------------------------------------------------------|--------------|---------|-----------------------------|----------------------|
| `.fountain` parser     | `FountainParser.swift`, CLI                                             | ✅ Complete   | ✅ Done  | —                           | parser, cli, tested  |
| `.ly` (LilyPond)       | external tool                                                           | Delegate     | ✅ Done  | N/A                         | passthrough          |
| `.csd` (Csound)        | `CSDParser.swift`, CLI                                                 | ✅ Complete   | ✅ Done  | —                           | parser, csound      |
| `.mid` parser (SMF)    | `MidiFileParser.swift`, tests                                           | ✅ Complete   | ✅ Done  | —                           | parser, tested       |
| `.ump` parser          | `UMPParser.swift`, tests                                                | ✅ Complete   | ✅ Done  | —                           | parser, tested       |
| `.storyboard` parser   | `StoryboardParser.swift`, CLI, tests, DSL doc                           | ✅ Complete   | ✅ Done  | —                          | parser, dsl, cli     |
| `.session` support     | `SessionParser.swift`, CLI, tests, `Docs/Chapters/13_SessionFormat.md`  | ✅ Complete   | ✅ Done  | —                          | parser, container    |
| CLI dispatch           | `RenderCLI.swift`, tests                                                | ✅ Complete   | ✅ Done  | —                          | cli, tested        |
| CLI flags              | `RenderCLI.swift`, tests                                                | Add          | ✅ Done  | — | cli, flags           |
| Watch mode (macOS)     | CLI watcher                                                             | ✅ Complete   | ✅ Done  |
—                          | cli, watcher         |
| UMP encoder            | `UMPEncoder.swift`                                                      | ✅ Complete   | ✅ Done  | —                          | encoder, ump         |
| `.csd` renderer        | `CSDRenderer.swift`                                                     | ✅ Complete   | ✅ Done  | —                           | renderer, csound    |
| FluidSynth backend     | `TeatroSampler.swift`                                                   | ✅ Complete   | ✅ Done  | —                          | audio, output        |
| `MidiEventProtocol`    | `MidiEvents.swift`, shared model                                        | ✅ Complete   | ✅ Done  | —                          | core, protocol       |
| Grammar docs           | `Docs/Chapters/10_StoryboardDSL.md`, `Docs/Chapters/13_SessionFormat.md` | ✅ Complete   | ✅ Done | —                         | docs, spec           |
| Test fixture coverage  | `Tests/Fixtures/`, normalization tests                                  | Add          | ✅ Done  | —                           | tests, fixtures      |
| Test parity tracker    | `Tests/Parsers/*.swift`, CLI tests                                      | ✅ Complete  | ✅ Done  | —                           | tests, cli           |
| Coverage tracking      | `COVERAGE.md`                                                           | Add          | ✅ Done  | —                          | coverage, report     |

---

## ✅ Codex Execution Strategy

Codex agents should consume this matrix **row-by-row or batch-by-tag** (e.g. `"parser"`, `"cli"`). For each row:

- Implement the full vertical slice (parser, CLI patch, test, docs)
- Emit a single PR or directory diff
- Confirm with `swift test`

---

## 🔄 Maintenance Routine

- Update this matrix after every Codex commit
- Periodically cross-check with:
  - `ImplementationPlan.md`
  - `RenderCLI.swift` support matrix
  - `Docs/Chapters/`

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
