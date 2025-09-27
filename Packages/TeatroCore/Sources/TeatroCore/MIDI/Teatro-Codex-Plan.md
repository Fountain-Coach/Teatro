# Codex Plan — Teatro: Merge with Fountain‑Coach/midi2 and Make the MIDI‑1 Bridge Audible

**Version:** 1.0  
**Date:** 2025-08-14 14:26 UTC  
**Audience:** Codex, Teatro Engineering

---

## Scope

Unify Teatro’s MIDI‑2 path with the **Fountain‑Coach/midi2** library and complete the **MIDI‑1 bridge** with a real audio sink so rendered events produce sound on Apple and Linux.

- Import `Fountain-Coach/midi2` just as in FountainAI.  
- Replace/merge internal UMP/event types with the library’s provided interfaces via a thin facade.  
- Keep the **Flex envelope** contract intact (fields `v`, `ts`, `corr`, `intent`, `body`; replies with `ack`, `progress`, terminal `success`/`error`).

---

## Module Map (SPM targets)

- **TeatroMIDI2** (facade over `Fountain-Coach/midi2`):  
  Typed UMP + Flex envelope encode/decode; helpers to traverse Channel Voice/Utility/SysEx packets.
- **TeatroBridge**:  
  UMP → MIDI‑1 bridge using the unified midi2 types; preserves timing and channel/group mapping.
- **TeatroAudio**:  
  - Apple: `AVAudioEngine + AVAudioUnitSampler` (AUSampler).  
  - Linux: `FluidSynth` (SF2) or `sfizz` (SFZ) via C interop.  
  Audio sinks are behind a small interface (`MIDIAudioSink`).
- **TeatroCLI**:  
  - `teatro-play`: feed UMP or bridged MIDI‑1 into the selected sink.  
  - Dev shortcuts to load a default SF2/SFZ.

---

## Facades & Interfaces

### Unified UMP facade (wrapping midi2)

```swift
public enum UMPEvent {
    case channelVoice(/* fields */)
    case utility(/* fields */)
    case systemExclusive7(/* stream chunks */)
    case systemExclusive8(/* stream chunks */)
    case flexEnvelope(FlexEnvelope) // parsed JSON envelope
}

public struct FlexEnvelope {
    public var v: Int
    public var ts: UInt64
    public var corr: String
    public var intent: String
    public var body: [String: Any]
}
```

Internally this is backed by `Fountain-Coach/midi2`; the facade keeps Teatro’s code stable while we merge.

### Audio sink interface

```swift
public protocol MIDIAudioSink {
    func noteOn(note: UInt8, vel: UInt8, ch: UInt8)
    func noteOff(note: UInt8, ch: UInt8)
    func controlChange(cc: UInt8, value: UInt8, ch: UInt8)
}
```

- **Apple implementation:** wraps `AVAudioUnitSampler` (load SF2/DLS; responds to Note/CC).  
- **Linux implementation:** wraps `FluidSynth` (SF2) or `sfizz` (SFZ); routes audio to JACK/ALSA.

---

## Step-by-Step PR Plan (merge & make sound)

**PR‑1 — Import midi2 & create `TeatroMIDI2` facade**  
- Add SPM dependency on `Fountain-Coach/midi2`.  
- Introduce `UMPEvent` + `FlexEnvelope` facade mapped to the library types.  
- Add round‑trip tests for UMP parse/encode and Flex envelope decode.

**PR‑2 — Bridge unification**  
- Replace any Teatro‑specific UMP parsers with calls into the midi2 facade.  
- Assert 1:1 mapping for Note On/Off, CC, Pitch Bend; add tests for group/channel math.

**PR‑3 — Audible MIDI‑1 bridge (Apple)**  
- Implement `TeatroAudioEngine` (`AVAudioEngine + AVAudioUnitSampler`).  
- Wire the **MIDI‑1 bridge** callback to the sampler.  
- Load a default SF2 and play a major scale via CLI to verify.

**PR‑4 — Audible MIDI‑1 bridge (Linux)**
- Add `FluidSynthSink` (default) and optional `SfizzSink` with a simple preset loader.
- `teatro-play` can accept UMP or MIDI‑1 bytes from stdin and route to sink.

**PR‑5 — CLI & examples** — completed
- `teatro-play` streams bridged UMP or MIDI‑1 into FluidSynth or Sfizz sinks.
- Headless CI uses JACK/ALSA loopback with demo assets.

**PR‑6 — Cleanup & deprecations**
- Remove duplicate/legacy MIDI types; public surface points to the midi2 facade.
- Keep typealiases and deprecation shims for one release to preserve API stability.

---

## Suggested Tree

```
Teatro/
  Sources/
    TeatroMIDI2/      # facade wrapping Fountain-Coach/midi2
    TeatroBridge/     # UMP → MIDI-1 unification using facade
    TeatroAudio/      # AUSampler (Apple) & FluidSynth/sfizz (Linux)
    TeatroCLI/        # teatro-play
  Tests/
    UMPTests/         # golden vectors, facade conformance
    BridgeTests/      # MIDI-1 event mapping
    AudioTests/       # headless sink tests
```

---

## Definition of Done

- Teatro builds against `Fountain-Coach/midi2`; UMP parsing & Flex envelopes use the unified interfaces.  
- MIDI‑1 bridge produces **audible** notes on Apple (AUSampler) and Linux (FluidSynth/sfizz).  
- CLI demo plays the same phrase cross‑platform.  
- README shows end‑to‑end example and notes the unified midi2 dependency.

---

## Notes on Compatibility

- Preserve external API stability with `typealias` + `@available(*, deprecated)` shims where needed.  
- If Teatro had bespoke UMP structures, keep conversion helpers for one release, then remove.

---

## Appendix — Minimal Apple sampler glue

```swift
import AVFoundation

final class TeatroAudioEngine {
    private let engine = AVAudioEngine()
    private let sampler = AVAudioUnitSampler()

    init() throws {
        engine.attach(sampler)
        engine.connect(sampler, to: engine.mainMixerNode, format: nil)
        try engine.start()
        // Load a default SF2
        let sf2URL = URL(fileURLWithPath: "/Library/Sounds/GeneralUser.sf2")
        try sampler.loadSoundBankInstrument(at: sf2URL, program: 0, bankMSB: 0x79, bankLSB: 0x00)
    }

    func handleMIDI1(status: UInt8, data1: UInt8, data2: UInt8, channel: UInt8) {
        switch status & 0xF0 {
        case 0x90: sampler.startNote(MIDINoteNumber(data1), withVelocity: MIDIVelocity(data2), onChannel: channel)
        case 0x80: sampler.stopNote (MIDINoteNumber(data1), onChannel: channel)
        case 0xB0: sampler.sendController(MIDIController(data1), withValue: data2, onChannel: channel)
        default: break
        }
    }
}
```

---

**End of document.**
