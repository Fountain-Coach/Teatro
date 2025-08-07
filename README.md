# Teatro View Engine

![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)
*A Declarative, Codex-Controllable Rendering Framework in Swift*

Teatro is centered on **MIDI 2.0** for sequencing and timing. MIDI 1.0 is supported only as a fallback for legacy export.

## MIDI-CI Discovery

Teatro includes basic support for the MIDI Capability Inquiry (MIDI-CI) protocol.
`MIDICI` types generate SysEx packets for discovery, profile negotiation and
property exchange. These packets can be encoded with `UMPEncoder` and parsed
from `UMPParser` output using `MIDICIDispatcher` to obtain strongly typed
messages for application workflows.

The long-form documentation lives under `Docs/Chapters`. Start with the timeline and progress through each chapter.

## Documentation

- [1. Core Protocols](Docs/Chapters/01_CoreProtocols.md)
- [2. View Types](Docs/Chapters/02_ViewTypes.md)
- [3. Rendering Backends](Docs/Chapters/03_RenderingBackends.md)
- [4. CLI Integration](Docs/Chapters/04_CLIIntegration.md)
- [5. Animation System](Docs/Chapters/05_AnimationSystem.md)
- [6. LilyPond Music Rendering](Docs/Chapters/06_LilyPondMusicRendering.md)
- [7. MIDI 2.0 DSL](Docs/Chapters/07_MIDI20DSL.md)
- [8. Fountain Screenplay Engine](Docs/Chapters/08_FountainScreenplayEngine.md)
- [9. Fountain Parser Implementation](Docs/Chapters/09_FountainParserImplementationPlan.md)
- [10. Storyboard DSL](Docs/Chapters/10_StoryboardDSL.md)
- [11. TeatroPlayerView Usage](Docs/Chapters/11_TeatroPlayer.md)
- [15. TeatroSampler](Docs/Chapters/12_TeatroSampler.md)
- [Addendum: Apple Platform Compatibility](Docs/Chapters/Addendum.md)

Historical proposals live in [`Docs/Proposals`](Docs/Proposals).

## Continuous Integration

A GitHub Actions workflow runs [SwiftLint](.swiftlint.yml) and `swift test` on every push and pull request to ensure code quality and style consistency.

## Installation
Add the package to your `Package.swift` dependencies:
```swift
.package(url: "https://github.com/fountain-coach/teatro.git", branch: "main")
```
Then include `Teatro` as a dependency in your target.

````text
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
