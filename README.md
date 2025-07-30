# Teatro View Engine

![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)
*A Declarative, Codex-Controllable Rendering Framework in Swift*

Teatro is centered on **MIDI 2.0** for sequencing and timing. MIDI 1.0 is supported only as a fallback for legacy export.

The long-form documentation lives under `Docs/Chapters`. Start with the timeline and progress through each chapter.

## Documentation
- [0. Timeline](Docs/Chapters/00_Timeline.md) – project history
- [1. Core Protocols](Docs/Chapters/01_CoreProtocols.md) – foundation for all views
- [2. View Types](Docs/Chapters/02_ViewTypes.md) – building blocks for scenes
- [3. Rendering Backends](Docs/Chapters/03_RenderingBackends.md) – HTML, SVG and more
- [4. CLI Integration](Docs/Chapters/04_CLIIntegration.md) – scripted rendering
- [5. Animation System](Docs/Chapters/05_AnimationSystem.md) – frame-based timelines
- [6. LilyPond Music Rendering](Docs/Chapters/06_LilyPondMusicRendering.md) – sheet music export
- [7. MIDI 2.0 DSL](Docs/Chapters/07_MIDI20DSL.md) – expressive sequencing
- [8. Fountain Screenplay Engine](Docs/Chapters/08_FountainScreenplayEngine.md) – parse scripts
- [9. Fountain Parser Plan](Docs/Chapters/09_FountainParserImplementationPlan.md) – historical notes
- [10. View Implementation Plan](Docs/Chapters/10_ViewImplementationPlan.md) – archived plan
<<<<<<< HEAD
- [11. Storyboard DSL](Docs/Chapters/11_StoryboardDSL.md) – declarative scenes
- [12. Summary](Docs/Chapters/12_Summary.md) – overview and advice
- [13. Addendum](Docs/Chapters/13_Addendum.md) – Apple platform notes
- [14. TeatroPlayerView Usage](Docs/Chapters/14_TeatroPlayer.md) – realtime playback
- [15. TeatroSampler](Docs/Chapters/15_TeatroSampler.md) – MIDI 2 sampler
- [16. Glossary](Docs/Chapters/16_Glossary.md) – quick reference
=======
- [11. Implementation Roadmap](Docs/Chapters/11_ImplementationRoadmap.md) – historical roadmap
- [12. Storyboard DSL](Docs/Chapters/12_StoryboardDSL.md) – declarative scenes
- [13. Summary](Docs/Chapters/13_Summary.md) – overview and advice
- [14. Addendum](Docs/Chapters/14_Addendum.md) – Apple platform notes
- [15. TeatroPlayerView Usage](Docs/Chapters/15_TeatroPlayer.md) – realtime playback
- [16. TeatroSampler](Docs/Chapters/16_TeatroSampler.md) – MIDI 2 sampler
- [17. Glossary](Docs/Chapters/17_Glossary.md) – quick reference
>>>>>>> main

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
