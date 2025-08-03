## 15. TeatroSampler

_MIDI 2.0 sampler with fallback bridging._

The **TeatroSampler** provides cross-platform MIDI 2 playback for the animation player. It routes `MIDI2Note` events to backend implementations and keeps audio and visuals in sync.
MIDI 1.0 events are bridged only when exporting to legacy players.

### 16.1 Overview
- Actor-based design conforming to `SampleSource`.
- Built-in backends: `FluidSynthSampler` for SoundFont files and `CsoundSampler` for Csound orchestras.
- `TeatroSamplerDemo` shows triggering notes with FluidSynth.

### 16.2 Proposal vs. Implementation
The [MIDI 2.0-Native Sampler](../Proposals/🎼%20Proposal%20MIDI%202.0-Native%20Sampler%20for%20the%20FountainAI%20Teatro.md) proposal describes a full OpenAPI service and dynamic voice actors. The current code implements the actor model and compatibility bridge but lacks the OpenAPI layer.

### 16.3 Using the sampler

```swift
let sampler = try await TeatroSampler(backend: .fluidsynth(sf2Path: "synth.sf2"))
await sampler.trigger(MIDI2Note(channel: 0, note: 60, velocity: 0.8, duration: 1.0))
```

Call `stopAll()` when playback completes.

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
