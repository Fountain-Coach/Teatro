## 11. TeatroPlayerView Usage

_Real-time playback bridging MIDI and views._

This document explains how to pair rendered frames with MIDI timing and play
them back in real time.

### Building frame and MIDI pairs

1. Generate a `Storyboard` using the DSL.
2. Create a matching `MIDISequence` where each `MIDI2Note.duration` equals the
   desired frame duration.

### Playing the storyboard

```swift
let frames = storyboard.frames()
let player = TeatroPlayerView(storyboard: storyboard, midi: melody)
```

### Overlays and reflections

Pass `comments: [String]` when constructing frames to display semantic notes
overlayed during playback.

### Enabling audio

`TeatroPlayerView` drives audio via `TeatroSampler`, a cross-platform actor-based
MIDI 2.0 sampler. Provide a `SampleSource` when initializing the player to
connect to your audio backend.



`````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
`````
