# 🧩 Teatro Parser Agent

**Last Updated:** September 09, 2025
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
| `.storyboard`      | ⚠️ Partial  | ✓ `StoryboardParser` | ✓ | ✓ |
| `.session`         | ⚠️ Basic  | ✓ `SessionParser` | ✓ | ✓ |

---

## 🔨 Implementation Tasks

### 1. Parsers
- [x] `MidiFileParser.swift` with full event decoding
- [x] `UMPParser.swift` supporting UMP formats 1.0/2.0
- [x] `StoryboardParser.swift` (Storyboard DSL)
- [x] `SessionParser.swift` (Teatro container format)
- [ ] Canonical event unification (`MidiEventProtocol`)

### 2. CLI Integration
- [x] Dispatch by file extension
- [x] Add `.storyboard` to dispatcher
- [x] Add `.session` to dispatcher
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
- [x] `Tests/StoryboardParserTests.swift`
- [x] `Tests/SessionParserTests.swift`
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

## 🛠️ 3. Implementation Tasks

### 3.1 SMF Parser (`MidiFileParser`)

#### - **Header Parsing**  
  - Read and validate the `MThd` chunk (exactly 6 bytes).  
  - Extract `format`, `trackCount`, and `division` fields.
#### - **Track Parsing**  
  - Iterate over each `MTrk` chunk.  
  - Decode variable‑length delta‑times and running status.  
  - Handle channel voice messages (Note On/Off, Control Change, Program Change, Pitch Bend), system messages, and SysEx.
#### - **Meta‑Events**  
  - Decode tempo, time signature, track name.  
  - Preserve unknown meta‑events as raw data for future use.
#### - **Error Handling**  
  - Throw descriptive errors for malformed files (bad chunk IDs, truncated data).

### 3.2 UMP Parser (`UMPParser`)

#### - **Packet Framing**  
  - Read the file as a sequence of 32‑bit words.  
  - Use top 4 bits for message type; next 4 bits for group.  
  - Determine packet length (1–4 words) per message type.
#### - **Event Decoding**  
  - Support MIDI 1.0 and 2.0 channel voice messages within UMP.  
  - Handle SysEx7/SysEx8, system real‑time/common, utility messages.  
  - Preserve unsupported types (e.g., Mixed Data Set) as opaque payloads.
- **Group/Channel Mapping**  
  - Map each group (0–15) and channel to the unified model, ensuring correct numbering.
- **Error Handling**  
  - Validate 32‑bit alignment; report incomplete or misaligned packets.

### 3.3 Unified Event Model

#### - **Protocol Definition**  
  - Define `MidiEventProtocol` with properties: `timestamp`, `type`, `channel`, `noteNumber`, `velocity`, `controllerValue`, `metaType`, `rawData`.
#### - **Concrete Types**  
  - Implement `ChannelVoiceEvent`, `MetaEvent`, `SysExEvent`, `UnknownEvent` conforming to the protocol.
#### - **Normalization Helpers**  
  - Provide methods to map MIDI 2.0 velocities (0–65 535) and controller values (0–4 294 967 295) to 8‑bit ranges.

### 3.4 CLI Integration & Output Targets

- **Argument Parser Enhancements**  
  - Recognize `.mid`, `.midi`, `.ump` by extension and by file signature (e.g., `MThd`, 32‑bit alignment).
- **Dispatcher Updates**  
  - Implement and register the `ump` output target.  
  - Connect unified events to existing renderers; ensure both MIDI 1.0 and 2.0 compatibility.
- **Environment Variables**  
  - Apply `TEATRO_WIDTH`/`TEATRO_HEIGHT` even without explicit flags.
- **Watch Mode**  
  - Switch from polling loop to `DispatchSource.makeFileSystemObjectSource` for file monitoring.

### 3.5 Testing Suite

- **Unit Tests**  
  - Verify header parsing, track/message decoding, variable‑length quantity, meta‑events for SMF.  
  - Test UMP framing, decoding of each message type, group/channel mapping, and error cases.
- **Integration Tests**  
  - Feed parsed events into renderers; assert correct scheduling and output.  
  - Validate environment‑variable precedence and watch‑mode responsiveness.
- **Regression Tests**  
  - Add test files for each bug fix or feature; track coverage against MIDI 2.0 spec.


## 🔄 4. Maintenance & Reporting

### - **Regular Status Updates**  
  - After each milestone, update the **Status Quo** section and **ImplementationPlan.md**.  
  - Report supported formats, pending work, and any caveats.
### - **Implementation Log**
  - Append dated entries detailing decisions, issues, resolutions, and spec references.
### - **Issue Tracking**
  - Document unimplemented MIDI 2.0 messages or spec changes as TODOs in the repo and here.

### Implementation Log

- 2025-08-04: Added basic SMF track parsing and tests.
- 2025-08-04: Added tempo and time signature meta event decoding to MidiFileParser.
- 2025-08-04: Added Control Change, Program Change, and Pitch Bend event decoding to MidiFileParser.
- 2025-08-05: Added initial UMPParser with MIDI 1.0 channel voice message decoding.
- 2025-08-06: Added system real-time/common message decoding to UMPParser and unit tests.
- 2025-08-07: Added utility message decoding to UMPParser and unit tests.
- 2025-08-08: Added MIDI 2.0 channel voice message decoding to UMPParser and unit tests.
- 2025-08-09: Added width/height environment variable fallback in RenderCLI.
- 2025-08-10: Introduced unified MIDI event model and updated SMF/UMP parsers.
- 2025-08-11: Added truncated packet error handling to UMPParser and tests.
- 2025-08-12: Replaced CLI watch mode polling with DispatchSource-based file monitoring on supported platforms.
- 2025-08-13: Added file signature detection for MIDI and UMP inputs in RenderCLI.
- 2025-08-14: Added placeholder UMP rendering output target in RenderCLI.
- 2025-08-15: Added SysEx7 and SysEx8 message decoding to UMPParser and unit tests.
- 2025-08-16: Added channel pressure decoding to MidiFileParser and UMPParser.
- 2025-08-17: Added polyphonic key pressure decoding to MidiFileParser and UMPParser.
- 2025-08-18: Added unit test verifying preservation of unknown meta events in MidiFileParser.
- 2025-08-19: Added MIDI 2.0 Program Change and Pitch Bend decoding to UMPParser and unit tests.
- 2025-08-20: Added Program Change and Pitch Bend decoding tests to MidiFileParser.
- 2025-08-21: Treat Note On with velocity 0 as Note Off in MidiFileParser and UMPParser.
- 2025-08-22: Added Control Change decoding tests for MidiFileParser and UMPParser.
- 2025-08-23: Added running status decoding test to MidiFileParser.
- 2025-08-24: Added SysEx event decoding test to MidiFileParser.
- 2025-08-25: Added SysEx8 decoding test to UMPParser.
- 2025-08-26: Fixed MIDI 2.0 Note On velocity 0 handling in UMPParser and added corresponding test.
- 2025-08-27: Added error handling tests for invalid SMF headers, tracks, and events in MidiFileParser.
- 2025-08-28: Added track length bounds check to MidiFileParser and unit test.
- 2025-08-29: MidiFileParser now accumulates delta times into absolute timestamps and includes a unit test.
- 2025-08-30: Added system common/real-time message decoding and running status clearing to MidiFileParser with unit tests.
- 2025-08-31: Added real-time message running status preservation test to MidiFileParser.
- 2025-09-01: Added key signature meta event decoding to MidiFileParser and unit test.
- 2025-09-02: Added TempoEvent and TimeSignatureEvent decoding to MidiFileParser and unit tests.
- 2025-09-03: Added TrackNameEvent and decoding support to MidiFileParser and unit tests.
- 2025-09-04: Added LyricEvent decoding to MidiFileParser and unit test.
- 2025-09-05: Added MarkerEvent decoding to MidiFileParser and unit test.
- 2025-09-06: Added InstrumentNameEvent and CuePointEvent decoding to MidiFileParser with unit tests.
- 2025-09-07: Added SMPTE offset meta event decoding to MidiFileParser and unit test.
- 2025-09-08: Added basic StoryboardParser with CLI integration and unit test.
- 2025-09-09: Added basic SessionParser with CLI dispatch and unit test.


All implementations must be verifiable via `swift test` and conform to:

- `MidiEventProtocol`
- Unified timeline model
- Deterministic output structure (JSON/Markdown for now)

---

## 🧠 Maintenance Duties

- [ ] Track parser/CLI/test coverage parity
- [ ] Sync with `ImplementationPlan.md`
- [ ] Cross-check against Codex milestone table


---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
