# 🎧 TeatroSampler: A Cross-Platform, Actor-Based MIDI 2.0 Sampler for Semantic Playback

## 🎯 Purpose

`TeatroSampler` is the audio synthesis engine of the **Teatro View Engine**, responsible for rendering real-time sound in sync with visually animated scenes, storyboards, or semantic timelines. It interprets expressive `MIDI2Note` events and plays them through a modular audio backend — enabling sound to become a **first-class orchestration layer** in AI-driven GUI generation and reflection.

---

## 🧱 Architecture Overview

- **Actor-based**: Safe, isolated, concurrency-aware using Swift 6.1
- **Protocol-oriented**: Unified interface for all sound engines
- **Cross-platform**: Linux and Apple platform support
- **Codex-friendly**: Fully controllable via GPT orchestration

---

## 🧩 SampleSource Protocol

All audio engines plug into the sampler via a standard, memory-safe protocol:

```swift
public protocol SampleSource: Sendable {
    func trigger(_ note: MIDI2Note) async
    func stopAll() async
    func loadInstrument(_ path: String) async throws
}
```

---

## 🪕 Modular Backends

### 🎹 FluidSynthSampler

- Uses **libfluidsynth**
- Plays `.sf2` SoundFonts
- Very low latency
- Ideal for default playback and CLI previews
- Available on **Linux and macOS**

### 🎛️ CsoundSampler

- Uses **Csound API**
- Supports `.orc` (orchestra) and `.sco` (score)
- Enables procedural audio: envelopes, granular textures, generative soundscapes
- Perfect for **Codex-driven sound synthesis**
- Works on **Linux, macOS, iOS**

---

## 🧠 TeatroSampler Actor

```swift
public enum SamplerBackend {
    case fluidsynth(sf2Path: String)
    case csound(orchestraText: String)
}

public actor TeatroSampler: SampleSource {
    private let impl: SampleSource

    public init(backend: SamplerBackend) async throws {
        switch backend {
        case .fluidsynth(let sf2):
            let s = FluidSynthSampler()
            try await s.loadInstrument(sf2)
            self.impl = s
        case .csound(let orc):
            let c = CsoundSampler()
            try await c.loadInstrument(orc)
            self.impl = c
        }
    }

    public func trigger(_ note: MIDI2Note) async {
        await impl.trigger(note)
    }

    public func stopAll() async {
        await impl.stopAll()
    }
}
```

---

## 🧠 Semantic Orchestration

TeatroSampler enables Codex agents or LLM workflows to:
- Reflect on sound alongside visuals
- Choose rendering strategy per corpus or scene
- Encode `.ump` or `.mid` for playback or export
- Drive instruments or articulations from GPT context (e.g. sadness → filter sweep)

---

## 🔌 Integration Points

| Layer               | How it Connects                         |
|---------------------|------------------------------------------|
| `TeatroPlayerView`  | Drives sampler per frame or event        |
| `MIDISequence`      | Supplies semantic timing + expression    |
| `Storyboard`        | Coordinates visual + audio playback      |
| `CodexPreviewer`    | Can emit `.ump` + `.orc` summaries       |
| `CLI Renderer`      | Triggers audio output headless           |

---

## 🛣️ Roadmap

- [ ] `.ump` stream output for MIDI 2.0 routing
- [ ] SFZ or AUv3 support on Apple platforms
- [ ] Soundfont auto-mapping per storyboard role
- [ ] Audio pattern recognition for GPT feedback
- [ ] Hybrid orchestration (FluidSynth + Csound combo)

---

## 🧪 Example: Storyboard + Sampler Playback

```swift
let sampler = try await TeatroSampler(backend: .fluidsynth(sf2Path: "choir.sf2"))
let player = TeatroPlayerView(storyboard: introStoryboard, midi: themeMelody, sampler: sampler)
```

---

## 🎼 Summary

The `TeatroSampler` transforms **semantic scenes into synchronized sound**, enabling AI-assisted orchestration to not only *see* and *read*, but also *hear* the rhythm of an interface, the voice of a transition, or the tone of an interaction.  

It is more than a backend — it's the **aural imagination** of Teatro.
