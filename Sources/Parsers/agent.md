# 🧩 Teatro Parser Agent

**Last Updated:** August 04, 2025  
**Maintainer:** FountainAI / Codex Agents  
**Directory:** `Sources/Parsers/agent.md`  
**Mission:** Close the gap between declared input format support and verified parser coverage in the Teatro CLI.

---

## 🎯 Agent Mission

The Parser Agent is responsible for implementing and maintaining _native Swift 6.1+_ input parsers for the Teatro CLI. Its focus is on supporting:

- MIDI formats: `.mid`, `.ump`
- Declarative documents: `.fountain`, `.ly`, `.csd`
- Embedded session containers: `.session`
- Structured animation blueprints: `.storyboard`

**Constraint:** No third-party parser dependencies allowed. All parsing logic must be fully inlined and testable in Swift.

---

## ✅ Current Coverage Snapshot

| Input Format       | Status      | Parser | CLI Support | Tests |
|--------------------|-------------|--------|-------------|-------|
| `.fountain`        | ✅ Complete | ✓ `FountainParser` | ✓ | ✓ |
| `.ly` (LilyPond)   | ✅ Complete | External | ✓ | - |
| `.csd` (Csound)    | ⚠️ Partial  | ❌ raw load only | ✓ | ❌ |
| `.mid` (SMF)       | ✅ Complete | ✓ `MidiFileParser` | ✓ | ✓ |
| `.ump` (MIDI 2.0)  | ✅ Complete | ✓ `UMPParser` | ✓ | ✓ |
| `.storyboard`      | ❌ Missing  | ❌ | ❌ | ❌ |
| `.session`         | ❌ Missing  | ❌ | ❌ | ❌ |

---

## 🔨 Implementation Tasks

### 1. Parsers
- [x] `MidiFileParser.swift` with full event decoding
- [x] `UMPParser.swift` supporting UMP formats 1.0/2.0
- [ ] `StoryboardParser.swift` (Storyboard DSL)
- [ ] `SessionParser.swift` (Teatro container format)
- [ ] Canonical event unification (`MidiEventProtocol`)

### 2. CLI Integration
- [x] Dispatch by file extension
- [ ] Add `.storyboard`, `.session` to dispatcher
- [ ] `--force-format`, `--renderer`, `--dump-events` CLI flags
- [ ] `--emit-ump` output mode

### 3. Watch Mode
- [ ] macOS `DispatchSource` file observer
- [ ] Linux fallback loop (already implemented)

### 4. Output Backends
- [ ] `UMPEncoder.swift` for round-trip UMP
- [ ] MIDI to `.csd` renderer
- [ ] FluidSynth or mock audio playback

### 5. Testing
- [x] `MidiFileParserTests.swift`
- [x] `UMPParserTests.swift`
- [ ] `Tests/StoryboardParserTests.swift`
- [ ] `Tests/SessionParserTests.swift`
- [ ] Fixture-based event normalization tests

---

## 📦 DSL Grammar Plans

### `.storyboard`
- Scene declaration
- Frame timing
- Layered directives

### `.session`
- Container index
- Embedded files (MIDI, Fountain, etc.)
- Corpus references

---

## 🧪 Ground Truth

All implementations must be verifiable via `swift test` and conform to:

- `MidiEventProtocol`
- Unified timeline model
- Deterministic output structure (JSON/Markdown for now)

---

## 🧠 Maintenance Duties

- [ ] Track parser/CLI/test coverage parity
- [ ] Sync with `ImplementationPlan.md`
- [ ] Cross-check against Codex milestone table

