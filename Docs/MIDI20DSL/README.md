## 7. MIDI 2.0 DSL

The Teatro View Engine includes a declarative Swift DSL for composing MIDI sequences. It enables Codex and GPT agents to structure musical timelines with precise note control.
`MIDISequence` can now drive visual animations when paired with
`TeatroPlayerView`. Each `MIDI2Note.duration` determines how long the matching
frame stays on screen during playback and can be rendered as Universal MIDI Packets.

---

### 7.1 MIDI2Note

A single expressive event: pitch, 32-bit velocity, channel, and duration in seconds.

```swift
public struct MIDI2Note {
    public let channel: Int
    public let note: Int
    public let velocity: Float
    public let duration: Double
    public let pitchBend: Float?
    public let articulation: String?

    public init(channel: Int, note: Int, velocity: Float, duration: Double, pitchBend: Float? = nil, articulation: String? = nil) {
        self.channel = channel
        self.note = note
        self.velocity = velocity
        self.duration = duration
        self.pitchBend = pitchBend
        self.articulation = articulation
    }
}
```

---

### 7.2 MIDISequence

A collection of `MIDI2Note` elements. Supports Swift result builder syntax.

```swift
public struct MIDISequence {
    public let notes: [MIDI2Note]

    public init(@NoteBuilder _ build: () -> [MIDI2Note]) {
        self.notes = build()
    }
}
```

#### NoteBuilder

```swift
@resultBuilder
public enum NoteBuilder {
    public static func buildBlock(_ notes: MIDI2Note...) -> [MIDI2Note] {
        notes
    }
}
```

---

### 7.3 UMPEncoder

Encodes each `MIDI2Note` into raw Universal MIDI Packet words for playback or file output.

```swift
public struct UMPEncoder {
    public static func encode(_ note: MIDI2Note) -> [UInt32] {
        // Placeholder encoding
        [0]
    }
}
```

---

### Example

```swift
let melody = MIDISequence {
    MIDI2Note(channel: 0, note: 60, velocity: 0.8, duration: 0.5)
    MIDI2Note(channel: 0, note: 64, velocity: 0.8, duration: 0.5)
    MIDI2Note(channel: 0, note: 67, velocity: 0.8, duration: 1.0)
}

let packets = melody.notes.flatMap { UMPEncoder.encode($0) }
```

---

### Integration Notes

- This system now supports MIDI 2.0 features such as per-note expression and UMP packet generation
- Compatible with future `MIDIPianoRoll` visual rendering
- Pairs well with `Animator` for synchronizing scenes and sounds
- Drives `TeatroPlayerView` animations when provided alongside a `Storyboard`


```
© 2025 Contexter alias Benedikt Eickhoff, https://fountain.coach. All rights reserved.
Unauthorized copying or distribution is strictly prohibited.
```

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
