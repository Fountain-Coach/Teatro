
# Teatro View Engine — **SSE‑over‑MIDI2 Integration Agent** (`agent.md`)

> Owner: Teatro Core / @Fountain‑Coach  
> Version: 0.1 (2025‑08‑21, Europe/Berlin)  
> Scope: Prepare the entire Teatro View Engine to optimally consume **FountainAI SSE streams carried over MIDI 2.0 UMP** (Flex Data / SysEx8) across LAN via RTP‑MIDI; expose them to the GUI and CLI; and make the behavior testable, observable, and Codex‑orchestratable.

---

```yaml
id: teatro-sse-over-midi2
name: Teatro SSE-over-MIDI2 Agent
description: >
  Implements end-to-end support for Server-Sent Events (SSE) streamed over MIDI 2.0
  UMP (Flex Data / SysEx8) with MIDI-CI negotiation, lightweight reliability, and
  JR-timestamped playout. Extends the Teatro rendering/GUI stack to react to these
  streams in real time, and adds record/replay + CLI support.

entrypoint:
  type: process
  command: swift test

apis:
  - id: teatro-render-api
    path: openapi.yaml
    description: Deterministic rendering helpers + preview player

policies:
  - keep changes deterministic and fully test-covered
  - guard timing with JR timestamps and a small jitter buffer (LAN: 2–5 ms)
  - never interleave unrelated Flex Start..End sequences
  - maintain MIDI 1.0 bridge compatibility for record/replay
  - update Docs/ and PR checklists alongside code changes
```

---

## 1) Architectural Objectives

1. **Streaming substrate** — Map **SSE events** (`message`, `error`, `done`, `ctrl`) into **UMP** via **Flex Data** (small, token-like) and **SysEx8/MDS** (large).  
2. **Negotiation** — Use **MIDI‑CI** to expose a `FountainAI.SSE` profile and exchange a small **Property JSON** (MTU, flex limits, ack period, window, JR requirement, encoding).  
3. **Scheduling** — Respect **JR Timestamps** with a **jitter buffer** so token rendering is tight and beat‑aligned.  
4. **Reliability** — Lightweight **ACK/NACK + retransmit buffer** and **receive window**; all visible via the GUI.  
5. **View Engine** — Introduce **stream‑aware views** (e.g., `TokenStreamView`) that bind to asynchronous SSE event publishers.  
6. **Record/Replay** — Persist UMP streams, replay them deterministically, and bridge to MIDI 1.0 when needed.  
7. **Observability** — Metrics (RTT, loss, reorder depth), status lights, and logs.  
8. **CLI & Render API** — “Watch/stream” mode for previews and headless rendering.

---

## 2) Deliverables (PR-ready)

- **Sources/MIDI/SSE/**
  - `FountainSSEEnvelope.swift` (JSON/CBOR model with `ev`, `seq`, `frag`, `ts`, `data`).
  - `FountainSSEDispatcher.swift` (UMP Flex/SysEx8 reassembly, sequence/order, publish events).
  - `FountainSSEReliability.swift` (ack/nack, retransmit ring buffer, rx window).
  - `FountainSSETiming.swift` (JR timestamp helpers, playout scheduler).

- **Sources/MIDI/CI/**
  - `FountainSSEProfile.swift` (MIDI‑CI Profile enable/disable, UUID, constants).
  - `FountainSSEProperties.swift` (Property Exchange schema + validators).
  - Hooks in existing `MIDICI`/`MIDICIDispatcher` to enable profile + properties.

- **Sources/ViewCore/Streaming/**
  - `TokenStreamView.swift` (SwiftUI; consumes async publisher and renders tokens with time alignment).
  - `StreamStatusView.swift` (ACK/NACK/RTT/window indicators).

- **Sources/RenderAPI/**
  - `StreamPreviewController.swift` (bind UMP → SSE publisher → `TeatroPlayerView` overlays).
  - Render API extension: “watch” endpoints (if applicable) to forward live streams.

- **Sources/CLI/**
  - `RenderCLI` flags: `--watch-rtpmidi`, `--sse-group <n>`, `--save-ump <path>`.
  - Pipe to `teatro-play` via existing MIDI1 bridge when requested.

- **Tests/**
  - Unit: Flex/SysEx8 fragmentation & out‑of‑order reassembly; envelope encode/decode; JR schedule rounding.
  - Integration: 3–5% packet loss + reordering; verify final text equals source; metrics sane.
  - CI tests: Profile enable + Property Exchange roundtrip with a mock peer.

- **Docs/**
  - `Docs/Chapters/12_SSE_Over_MIDI2.md` (overview, timing, reliability, GUI).
  - Update `Docs/Chapters/11_TeatroPlayer.md` with stream overlays.
  - Amend `README.md` and `TEATRO_GUI_RenderAPI_Blueprint_PR_Checklist.md` with streaming items.

---

## 3) Envelope & Transport (normative for this repo)

### 3.1 FountainAI SSE Envelope (UTF‑8 JSON by default)

```json
{
  "v": 1,
  "ev": "message" | "error" | "done" | "ctrl",
  "id": "optional",
  "ct": "application/json",
  "seq": 123456,                 
  "frag": { "i": 0, "n": 3 },   
  "ts": 1724142123.123,         
  "data": "<payload or slice>"
}
```

- **Control envelopes** (Group 0): `{"ack": <u64>}`, `{"nack": [<u64>...]}`, `{"window": <u32>}`, `{"hb": true}` inside `ev:"ctrl"`.

### 3.2 UMP Mapping

- **Flex Data** for small/streamy: use Complete/Start/Continue/End. Do **not** interleave unrelated sequences.  
- **SysEx8/Mixed Data Set** for multi‑KB envelopes.  
- **Groups**: `0 = control`, `1 = main tokens`, `2 = metadata` (more lanes negotiable).  
- **JR Timestamp**: attach per‑event when available; GUI uses it for on‑beat display.  

---

## 4) MIDI‑CI Profile (`FountainAI.SSE`)

- **Function Blocks**
  - `FB0`: Control → `Group 0`
  - `FB1`: SSE Lane A → `Group 1`
  - `FB2`: SSE Lane B (optional) → `Group 2`

- **Property Exchange JSON (Get/Set)**
```json
{
  "fountainProfile": "FountainAI.SSE",
  "version": "0.1.0",
  "laneGroups": [1,2],
  "mtu": 1200,
  "maxFlexUmps": 32,
  "maxAppFrags": 8,
  "supportsSysEx8": true,
  "ackPeriodMs": 200,
  "nackGraceMs": 150,
  "rxWindow": 256,
  "jrRequired": true,
  "targetPlayoutMs": 3,
  "encoding": "json"
}
```

- **Behavior**
  - On enable → publish lanes; start ACKs every `ackPeriodMs` with highest contiguous `seq`.
  - NACK after `nackGraceMs` for gaps; sender retransmits from ring buffer (≥512 envelopes).
  - Receiver honors `rxWindow` for back‑pressure.

---

## 5) GUI Wiring

- **`TokenStreamView`** appends tokens as they arrive; on `"done"` seals the segment.  
- **Beat‑grid overlay** when JR timestamps present.  
- **Status strip** shows `connected`, `profileEnabled`, `acks`, `nacks`, `rtt`, `window`, `loss%`.  
- **Record/Replay** buttons: persist UMP to file; replay deterministically; optional MIDI 1.0 export.  

---

## 6) CLI / Render API

- **CLI (`RenderCLI`)**
  - `--watch-rtpmidi` — subscribe to RTP‑MIDI UMP on chosen Group(s).  
  - `--sse-group <n>` — choose data lane.  
  - `--save-ump <file>` — record incoming stream.  
  - `--replay-ump <file>` — offline playback for testing/demos.

- **Render API (`openapi.yaml`)**
  - Add a **/watch** preview endpoint (server‑sent snapshots) that mirrors GUI behavior for headless environments.

---

## 7) Tests & Acceptance

**Unit**
- Flex/SysEx8 reassembly correctness across edge sizes (1B..multi‑KB).  
- Envelope JSON/CBOR round‑trip; illegal field rejection.  
- Reliability logic: ack aggregation, nack gap detection, retransmit pruning.

**Integration**
- Simulate 3–5% loss + reordering → **final assembled text equals reference**.  
- JR timestamp playout with `targetPlayoutMs ≤ 5` (wired) → late packet rate < 0.1%.  
- Profile enable + Property Exchange roundtrip with a mock peer.

**Acceptance**
- Streams render live in `TeatroPlayerView` overlays with status + metrics visible.  
- CLI can record and replay the stream; MIDI 1.0 bridge export still works.  
- Docs updated; checklists completed; CI green.

---

## 8) Task List (Codex‑orchestratable)

1. **Scaffold** `Sources/MIDI/SSE/*` and `Sources/ViewCore/Streaming/*`; export public APIs.  
2. **Dispatcher**: Flex/SysEx8 → Envelope publisher; multi‑UMP sequencing; JR extraction.  
3. **Reliability**: ack/nack, ring buffer, window, heartbeat; metrics hooks.  
4. **MIDI‑CI**: Profile enable/disable, Function Blocks, Property Exchange (Get/Set).  
5. **GUI**: `TokenStreamView`, `StreamStatusView`, overlays in `TeatroPlayerView`.  
6. **CLI**: `RenderCLI` watch/record/replay flags; basic RTP‑MIDI subscriber.  
7. **Tests**: unit + integration + CI; lossy channel simulation.  
8. **Docs**: new chapter + README + PR checklist updates.  
9. **Polish**: performance profiling; memory/copy reduction for large envelopes.  
10. **Submit PR**: include demo recordings and screenshots/gifs.

---

## 9) File/Module Map (proposed)

```
Sources/
  MIDI/
    SSE/
      FountainSSEEnvelope.swift
      FountainSSEDispatcher.swift
      FountainSSEReliability.swift
      FountainSSETiming.swift
    CI/
      FountainSSEProfile.swift
      FountainSSEProperties.swift
  ViewCore/
    Streaming/
      TokenStreamView.swift
      StreamStatusView.swift
  RenderAPI/
    StreamPreviewController.swift
CLI/
  RenderCLI/ (augment existing targets)
Tests/
  SSE/
  CI/
  Integration/
Docs/
  Chapters/12_SSE_Over_MIDI2.md
```

---

## 10) Implementation Notes & Guardrails

- **Timing first**: always schedule by JR timestamp + jitter buffer; never by arrival time when JR is present.  
- **Memory**: reuse buffers when reassembling fragments; cap `maxAppFrags`.  
- **Safety**: drop malformed envelopes; surface errors in `StreamStatusView`.  
- **Interop**: when peer lacks JR, raise `targetPlayoutMs` conservatively (≥8–12 ms) and warn.  
- **MIDI 1.0 bridge**: keep `MIDI1Bridge` pathways intact for export/round‑trip tests.  
- **Docs/tests**: land together with code; no code without updated docs.

---

## 11) Roll‑out Plan (10 steps)

1. Scaffold modules & empty tests.  
2. Implement envelope + pack/unpack for Flex; tests.  
3. Add SysEx8/MDS path; tests.  
4. Build dispatcher + publisher; smoke test with fake frames.  
5. Implement reliability; lossy channel test.  
6. MIDI‑CI profile + properties; mock peer test.  
7. JR scheduler + jitter buffer tuning on wired LAN.  
8. SwiftUI views + overlays; preview demos.  
9. CLI watch/record/replay modes; end‑to‑end test.  
10. Documentation, checklists, PR with demo assets.

---

## 12) Definition of Done

- Live SSE streams (tokens/metadata) render in Teatro with beat‑aligned timing.  
- Reliability visible; retransmits work; window honored.  
- Recording/replay + MIDI 1.0 export pass tests.  
- CI green; docs/PR checklists updated; examples included.

---

### Appendix A — References for Implementers

- Teatro README: MIDI‑2.0 centric design, **TeatroRenderAPI**, **TeatroPlayerView**, **MIDI‑CI basics**, **MIDI1 bridge**.  
- codex‑deployer: houses **Examples/SSEOverMIDI**, **midi** utilities, and a **Teatro GUI integration PR checklist** useful for this work.

```

