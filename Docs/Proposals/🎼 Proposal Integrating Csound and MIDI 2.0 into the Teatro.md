# 🎼 Proposal: Integrating Csound and MIDI 2.0 into the Teatro Engine

![[cSound-Midi2-integration.PNG]]

**Author:** Benedikt Eickhoff (Contexter)  
**Platform:** [https://fountain.coach](https://fountain.coach)  
**Date:** 2025-07-25  
**License:** © 2025 Contexter alias Benedikt Eickhoff. All rights reserved.

---

## ✅ Summary

This proposal outlines how to extend the Teatro Engine with native support for:

- **Csound** — as a DSP rendering backend
- **MIDI 2.0** — to enable per-note expression, 32-bit precision, and UMP packet generation

These enhancements will allow Teatro to support:
- Real-time synthesis
- High-resolution playback
- Per-note articulation
- Unified rendering pipelines for music, visuals, and interaction

---

## 1. Motivation

Teatro currently supports:

- **LilyPond** for sheet music (visual PDF rendering)
- **MIDI 1.0-style** DSL (`MIDINote`, `MIDISequence`) for symbolic sequences
- **Animation timelines** via `Animator` for visual output

However:
- MIDI 1.0 lacks expression fidelity and future compatibility
- LilyPond and Csound cannot utilize MIDI 2.0 features
- No current support exists for runtime sound synthesis

---

## 2. Objectives

### 🎯 Add the following capabilities:
- A new `CsoundScore` view type (`Renderable`)
- A `CsoundRenderer` for `.csd` file generation and execution
- A `MIDI2Note` model supporting all MIDI 2.0 expressive features
- A `UMPEncoder` capable of producing raw Universal MIDI Packets
- Optional CLI targets for `.csd` and `.ump` outputs
- Cross-rendering between `MIDINote`, `MIDI2Note`, and `CsoundScore`

---

## 3. Integration Details

### 3.1 `CsoundScore` (New View Type)

```swift
public struct CsoundScore: Renderable {
    public let orchestra: String
    public let score: String

    public init(orchestra: String, score: String) {
        self.orchestra = orchestra
        self.score = score
    }

    public func render() -> String {
        """
        <CsoundSynthesizer>
        <CsOptions>
        ; Audio/MIDI flags
        </CsOptions>
        <CsInstruments>
        \(orchestra)
        </CsInstruments>
        <CsScore>
        \(score)
        </CsScore>
        </CsoundSynthesizer>
        """
    }
}
```

---

### 3.2 `CsoundRenderer`

```swift
public struct CsoundRenderer {
    public static func renderToFile(_ view: CsoundScore, to path: String = "output.csd") {
        try? view.render().write(toFile: path, atomically: true, encoding: .utf8)
    }

    public static func renderAndPlay(_ view: CsoundScore) {
        let path = "/tmp/output.csd"
        renderToFile(view, to: path)

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["csound", path]
        try? task.run()
        task.waitUntilExit()
    }
}
```

---

### 3.3 `MIDI2Note`

```swift
public struct MIDI2Note {
    public let channel: Int
    public let note: Int
    public let velocity: Float // 32-bit float (0.0 - 1.0)
    public let duration: Double
    public let pitchBend: Float?
    public let articulation: String?
    public let perNoteCC: [Int: Float]?
}
```

---

### 3.4 `UMPEncoder`

```swift
public struct UMPEncoder {
    public static func encode(_ note: MIDI2Note) -> [UInt32] {
        // Encode MIDI 2.0 Note On using UMP format
        // Placeholder — actual spec encoding required
        return [/* UMP packet words */]
    }
}
```

---

### 3.5 CLI Integration

Extend `RenderTarget`:

```swift
case csound
case ump
```

Extend `RenderCLI.main`:

```swift
case .csound:
    if let cs = view as? CsoundScore {
        CsoundRenderer.renderAndPlay(cs)
    }

case .ump:
    if let seq = view as? [MIDI2Note] {
        let packets = seq.flatMap { UMPEncoder.encode($0) }
        // Write to file or send to synthesizer
    }
```

---

## 4. Compatibility Matrix

| Feature           | MIDI 1.0 | MIDI 2.0 | LilyPond | Csound |
|------------------|----------|----------|----------|--------|
| Duration Support | ✅        | ✅        | ✅        | ✅      |
| Pitch Precision  | 7-bit     | 32-bit   | Symbolic | Hertz  |
| Per-Note CC      | ❌        | ✅        | ❌        | Partial|
| Dynamic Render   | ❌        | ✅        | ❌        | ✅      |
| Sheet Music      | ❌        | ❌        | ✅        | ❌      |
| Realtime Synthesis | ❌      | ✅        | ❌        | ✅      |

---

## 5. Roadmap

### Phase 1: Csound Integration
- [x] Add `CsoundScore` struct
- [x] Implement `CsoundRenderer`
- [ ] Add CLI support for `.csd` generation and playback
- [ ] Write tests for `.csd` output validity

### Phase 2: MIDI 2.0 UMP Support
- [ ] Define `MIDI2Note` model
- [ ] Implement `UMPEncoder`
- [ ] Build `.ump` export CLI route
- [ ] Add downcast compatibility: `MIDI2Note` → `MIDINote`

### Phase 3: Timeline Synchronization
- [ ] Add `TimedView` or `Beat` abstraction
- [ ] Allow `Animator` to render synchronized visuals + MIDI/UMP/Csound
- [ ] Enable Codex to co-orchestrate time-synced DSLs

---

## 6. Benefits

- 🎧 Enables expressive music performance, not just symbolic output
- 🧠 Bridges GPT output to real-time sound synthesis
- 🎼 Aligns music, UI, and animation into a shared timeline
- 🛠 Sets foundation for semantic music editing, instrument generation, and performance scripting

---

## 7. Risks & Mitigations

| Risk                                   | Mitigation                                             |
|----------------------------------------|--------------------------------------------------------|
| Csound dependency not available        | Gracefully fallback or require optional install        |
| UMP specification complexity           | Start with Note On/Off only, extend incrementally      |
| Renderer compatibility drift           | Ensure `MIDI2Note` downcasts to `MIDINote` or LilyPond |

---

## 8. Conclusion

Integrating Csound and MIDI 2.0 into Teatro will make it the first **AI-driven semantic UI engine** to unify **symbolic**, **performative**, and **synthesized music** under one architecture — built in Swift, compatible with Codex, and deployable across macOS and Linux.

Let's make music a first-class citizen of dramaturgical UI generation.

---