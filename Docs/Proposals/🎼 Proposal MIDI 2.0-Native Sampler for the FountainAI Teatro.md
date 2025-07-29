# 🎼 Proposal: MIDI 2.0-Native Sampler for the FountainAI Teatro System

![[Sampler.png]]

## 1. 🎯 Purpose

This proposal introduces a **MIDI 2.0-native audio sampler** as a first-class semantic component in the **FountainAI Teatro architecture**.

The goal is to transcend legacy MIDI 1-style sample triggering and establish a **reactive, expressive, and inspectable sampler** that aligns with Teatro’s dramaturgical model of per-frame animation, multimodal composition, and AI orchestration.

---

## 2. 🧠 Why MIDI 2.0 Changes Everything

MIDI 2.0 is not an incremental upgrade. It transforms MIDI from a limited messaging protocol into a rich, high-resolution, object-oriented system:

- **Per-note control:** Articulation, pitch bend, pressure, and timbre per note
- **32-bit resolution:** No more 0–127; supports expressive nuance
- **Semantic messages:** Notes are *objects*, not events
- **Profile negotiation + property exchange:** Instruments are self-describing and dynamically reconfigurable

This opens the door to a **new kind of sampler** — one that understands intent, not just triggers audio.

---

## 3. 🧱 Architectural Role in Teatro

Teatro is a text-driven GUI and multimedia rendering engine where animation, audio, and interface all arise from *semantic screenplays*. Each **Scene** in Teatro can trigger gestures, animations, and now: **expressive musical events**.

The MIDI 2.0 Sampler integrates as follows:

| Component               | Role                                                                 |
|-------------------------|----------------------------------------------------------------------|
| 🎭 `StoryboardView`     | Triggers semantic gestures (visual + audio)                          |
| 🎼 `TeatroSampler`      | Maps MIDI 2 note objects to expressive audio playback                |
| 🔁 `TeatroPlayerView`   | Synchronizes visual scenes, notes, and audio rendering               |
| 🧠 LLMs / Codex Agents  | Compose structured note objects, explore musical options dynamically |

Each `MIDINote2` object corresponds to a **musical action** with full expressive context — pitch, articulation, brightness, tuning, etc.

---

## 4. 🔧 Sampler Behavior & Features

The sampler will be exposed as an **OpenAPI-defined service** (`/v1/note/play`) and respond to structured input:

```json
{
  "noteId": "xyz-123",
  "channel": 2,
  "noteNumber": 64,
  "velocity": 0.82,
  "pitch": 64.13,
  "articulation": "bowed_light",
  "perNoteControllers": { "74": 0.6 },
  "timestamp": "2025-07-27T08:00:00Z"
}
```

🔊 Response:
- Triggers corresponding sample playback with dynamic modulation
- Assigns a `voiceId` and exposes audio path if rendered
- Logs semantic info for visual playback in the Teatro UI

---

## 5. 🔬 Technical Design (Swift 6, Linux + macOS)

### 🧬 MIDI 2.0 Event Model
```swift
struct MIDI2NoteEvent {
    let note: UInt8
    let velocity: Float
    let pitch: Float
    let timbre: SIMD4<Float>
    let articulation: ArticulationBundle
    let timestamp: UInt64
}
```

Parsed from raw UMP packets using `TeatroMIDIEngine`.

---

### 🧠 Voice Actor Model
Each note spawns an actor-based sampler voice:
```swift
actor Voice {
    let id: UUID
    var note: MIDI2NoteEvent
    var sampler: SampleSource
    var envelope: DynamicEnvelope
    var routing: AudioGraph

    func update(_ newEvent: MIDI2NoteEvent) { ... }
}
```

---

### 🧩 SampleSource Protocol
```swift
protocol SampleSource {
    func render(buffer: inout AudioBuffer, frameCount: Int)
    mutating func update(with event: MIDI2NoteEvent)
}
```

Supports:
- `.wav` and `.aiff` streaming
- Procedural signal generators
- Future: GPT-curated sample sets

---

### 🎛 Teatro GUI Integration
Fully embedded into the GUI:
```swift
Panel("Sampler") {
    VStack {
        Text("Live Voices: \(VoiceAllocator.active.count)")
        SpectrogramView(audioInput: mainBus)
        MatrixView(parameters: currentModulations)
    }
}
```

---

### 🌐 OpenAPI Access (Codex-Orchestrated)
```http
GET    /sampler/voices
POST   /sampler/play
DELETE /sampler/voice/{id}
```

Codex agents can introspect, mutate, and orchestrate live playback.

---

## 6. 🚀 Implications for FountainAI

| Benefit                          | Description                                                                 |
|----------------------------------|-----------------------------------------------------------------------------|
| 🎵 Expressive Music Playback     | Notes are alive — expressive, per-note, semantically rich                   |
| 🔍 Introspection + Reasoning     | LLMs can *understand*, *compare*, and *optimize* playback objects          |
| 🎬 Audio-Visual Sync             | Notes align to semantic scenes, animations, and reflections                 |
| 🧠 Prompt-Oriented Composition   | Codex agents can script orchestration using the full expressive envelope   |
| 🎛 Live Performance Interface    | Teatro can serve as a reactive front-end for experimental AI composition   |

---

## 7. 🗺 Next Steps

1. ✅ **Finalize the OpenAPI specification** (done)
2. 🔧 Scaffold `teatro-sampler` FastAPI service
3. 🧪 Add `/preview`, `/batch`, `/stop`, `/status` endpoints
4. 🎧 Integrate audio backend (initial mock, then Csound or Faust)
5. 🔁 Connect to `TeatroPlayerView` and LLM orchestration pipeline
6. 🧠 Extend with `PatternMap`, `InstrumentProfile`, `SamplerDSL`

---

## 8. 🔚 Summary

This sampler is not a plugin. It’s a **semantic instrument** that plays a central role in Teatro’s unified multimodal architecture. It brings *sound* into the dramaturgical structure — expressive, inspectable, orchestratable — as a peer to GUI and animation.

> 🎼 Sound, finally, becomes programmable — not by control knobs, but by intent.