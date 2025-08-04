# 🧩 Teatro Parser Agent Task Matrix

**Last Updated:** August 04, 2025  
**Maintainer:** FountainAI / Codex Agents  
**Directory:** `Sources/Parsers/agent.md`  
**Purpose:** Replace prose-style spec with machine-actionable backlog. Codex agents can consume this table and implement full vertical slices.

---

## 📋 Task Matrix

| Feature                | File(s)                                                                 | Action       | Status  | Blockers                    | Tags                 |
|------------------------|-------------------------------------------------------------------------|--------------|---------|-----------------------------|----------------------|
| `.fountain` parser     | `FountainParser.swift`, CLI                                             | ✅ Complete   | ✅ Done  | —                           | parser, cli, tested  |
| `.ly` (LilyPond)       | external tool                                                           | Delegate     | ✅ Done  | N/A                         | passthrough          |
| `.csd` (Csound)        | CLI passthrough, future `CSDRenderer.swift`                             | Implement    | ⚠️ Partial | Csound note model unclear   | renderer, csound     |
| `.mid` parser (SMF)    | `MidiFileParser.swift`, tests                                           | ✅ Complete   | ✅ Done  | —                           | parser, tested       |
| `.ump` parser          | `UMPParser.swift`, tests                                                | ✅ Complete   | ✅ Done  | —                           | parser, tested       |
| `.storyboard` parser   | `StoryboardParser.swift`, CLI, tests, DSL doc                           | Implement    | ⏳ TODO | DSL grammar missing         | parser, dsl, cli     |
| `.session` support     | `SessionParser.swift`, CLI, test, doc                                   | Implement    | ⏳ TODO | Container spec undefined    | parser, container    |
| CLI dispatch           | `RenderCLI.swift`                                                       | Extend       | ⏳ TODO | Needs `.storyboard`, `.session` cases | cli         |
| CLI flags              | `RenderCLI.swift`                                                       | Add          | ⏳ TODO | `--force-format`, etc.      | cli, flags           |
| Watch mode (macOS)     | CLI watcher                                                             | Add          | ⏳ TODO | Add `DispatchSource` impl   | cli, watcher         |
| UMP encoder            | `UMPEncoder.swift`                                                      | Implement    | ⏳ TODO | None                        | encoder, ump         |
| `.csd` renderer        | `CSDRenderer.swift`                                                     | Implement    | ⏳ TODO | Map note events to score    | renderer, csound     |
| FluidSynth backend     | `TeatroSampler.swift`                                                   | Implement    | ⏳ TODO | Playback integration        | audio, output        |
| `MidiEventProtocol`    | `MidiEvents.swift`, shared model                                        | Refactor     | ⏳ TODO | Cross-parser normalization  | core, protocol       |
| Grammar docs           | `Docs/Chapters/StoryboardDSL.md`, `SessionFormat.md`                    | Write        | ⏳ TODO | Define syntax/spec          | docs, spec           |
| Test fixture coverage  | `Tests/Fixtures/`, normalization tests                                  | Add          | ⏳ TODO | Need fixture MIDI/session   | tests, fixtures      |
| Test parity tracker    | `Tests/Parsers/*.swift`, CLI tests                                      | Expand       | ⏳ TODO | CLI outputs not verified    | tests, cli           |
| Coverage tracking      | `COVERAGE.md`                                                           | Add          | ⚠️ Partial | Needs coverage metrics      | coverage, report     |

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
