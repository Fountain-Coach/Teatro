# Parser Agent Plan for Teatro /parsers

> This document defines the responsibilities, objectives, and implementation roadmap for the Parser Agent in the Teatro project. The agent’s mission is to implement and maintain native parsers for new input formats—**Standard MIDI Files (SMF)** and **Universal MIDI Packet (UMP)**—while keeping the codebase free of external parsing dependencies. All updates and progress will be tracked here and in **Docs/ImplementationPlan.md**.

## 📋 1. Current Status (Status Quo)

The CLI currently supports rendering from the following source formats:

- **.fountain**
- **.ly** (LilyPond)
- **.csd** (Csound)

**Pending formats** (not yet implemented):

- **.storyboard**
- **.mid / .midi** (Standard MIDI Files) – header parsing implemented
- **.ump** (Universal MIDI Packet)
- **.session**

> **Open Issues**:
> - The `ump` output target is listed in the dispatcher but has no implementation.
> - Width/height environment variables only take effect when corresponding CLI flags are provided; no fallback behavior.
> - Watch mode relies on a polling loop instead of using `DispatchSource.makeFileSystemObjectSource`.
> - Tests cover only help/version output and unknown flags; `swift test` fails without Csound headers.

---

## 🚀 2. Agent Objectives

### 1. **Native MIDI Parsers**  
   - Implement robust SMF (`.mid/.midi`) and UMP (`.ump`) parsers in **Swift 6.1** with zero third‑party dependencies.  
   - Decode file structures, interpret MIDI 1.0 and 2.0 events, expose a unified event model for renderers.

### 2. **CLI Extension**  
   - Extend the argument parser to recognize new input formats by extension _and_ by file signature.  
   - Add and wire up the `ump` output target in the render dispatcher.

### 3. **Runtime Improvements**  
   - Replace file‑watch polling with `DispatchSource.makeFileSystemObjectSource` for real‑time responsiveness.  
   - Implement fallback behavior: environment variables for width/height apply even when flags are omitted.  
   - Expand test coverage to include parsing logic and new features.

### 4. **Status Tracking & Logging**  
   - Maintain progress updates in this file and in **Docs/ImplementationPlan.md**.  
   - Chronologically log key decisions, issues encountered, and solutions adopted.

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

---

## 🌱 5. Future Considerations

### - **Additional Formats**: Define and implement parsers for **.session** and **.storyboard**.
### - **Performance**: Explore streaming parsers, memory mapping, and Swift concurrency for large‑file support.
### - **Versioning**: Track revisions in the MIDI 2.0 specification and gracefully handle unknown or reserved messages.

---

> _Maintaining clear documentation and comprehensive logging ensures long‑term reliability and ease of maintenance for the Teatro parsing subsystem._



---

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
