# Teatro View Engine

![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)
*A Declarative, Codex-Controllable Rendering Framework in Swift*

Teatro is centered on **MIDI 2.0** for sequencing and timing. MIDI 1.0 is supported only as a fallback for legacy export.

The long-form documentation lives under `Docs/Chapters`. Browse the chapters in order for a full overview.

## Documentation
- [1. Core Protocols](Docs/Chapters/01_CoreProtocols.md) – foundation for all views
- [2. View Types](Docs/Chapters/02_ViewTypes.md) – building blocks for scenes
- [3. Rendering Backends](Docs/Chapters/03_RenderingBackends.md) – HTML, SVG and more
- [4. CLI Integration](Docs/Chapters/04_CLIIntegration.md) – scripted rendering
- [5. Animation System](Docs/Chapters/05_AnimationSystem.md) – frame-based timelines
- [6. LilyPond Music Rendering](Docs/Chapters/06_LilyPondMusicRendering.md) – sheet music export
- [7. MIDI 2.0 DSL](Docs/Chapters/07_MIDI20DSL.md) – expressive sequencing
- [8. Fountain Screenplay Engine](Docs/Chapters/08_FountainScreenplayEngine.md) – parse scripts
- [9. Fountain Parser](Docs/Chapters/09_FountainParser.md) – parser internals
- [10. Summary](Docs/Chapters/10_Summary.md) – overview and advice
- [11. Addendum](Docs/Chapters/11_Addendum.md) – Apple platform notes
- [12. TeatroPlayerView Usage](Docs/Chapters/12_TeatroPlayer.md) – realtime playback
- [13. TeatroSampler](Docs/Chapters/13_TeatroSampler.md) – MIDI 2 sampler
- [14. Glossary](Docs/Chapters/14_Glossary.md) – quick reference

Historical proposals live in [`Docs/Proposals`](Docs/Proposals).

## Installation
Add the package to your `Package.swift` dependencies:
```swift
.package(url: "https://github.com/fountain-coach/teatro.git", branch: "main")
```
Then include `Teatro` as a dependency in your target.

````text
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
