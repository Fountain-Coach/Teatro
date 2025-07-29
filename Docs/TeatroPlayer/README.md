## TeatroPlayerView Usage

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

`TeatroPlayerView` relies on `TeatroSampler` for live MIDI 2.0 playback. Provide
a `SampleSource` to connect to Csound, Faust, or any custom backend.

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
