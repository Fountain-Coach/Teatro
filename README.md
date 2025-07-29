# Teatro View Engine

![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![SwiftPM](https://img.shields.io/badge/SwiftPM-compatible-brightgreen)
*A Declarative, Codex-Controllable Rendering Framework in Swift*
This repository contains the specification for Teatro, a modular Swift 6 view engine. The original long-form documentation has been split into separate files under the `Docs` directory.
## Documentation

## Installation

Add the package to your Package.swift dependencies:

```swift
.package(url: "https://github.com/fountain-coach/teatro.git", branch: "main")
```

Then include `Teatro` as a dependency in your target.

- [Core Protocols](Docs/CoreProtocols/README.md)
- [View Types](Docs/ViewTypes/README.md)
- [Rendering Backends](Docs/RenderingBackends/README.md)
- [CLI Integration](Docs/CLIIntegration/README.md)
- [Animation System](Docs/AnimationSystem/README.md)
- [LilyPond Music Rendering](Docs/LilyPondMusicRendering/README.md)
- [MIDI 2.0 DSL](Docs/MIDI20DSL/README.md)
- [TeatroSampler](Docs/TeatroSampler/README.md)
- [Fountain Screenplay Engine](Docs/FountainScreenplayEngine/README.md)
- [Fountain Parser Implementation Plan](Docs/FountainScreenplayEngine/FountainParserImplementationPlan.md)
- [View Implementation and Testing Plan](Docs/ViewImplementationPlan/README.md)
- [Implementation Roadmap](Docs/ImplementationPlan/README.md)
- [Proposals](Docs/Proposals)
- [Storyboard DSL](Docs/StoryboardDSL/README.md)
- [Summary](Docs/Summary/README.md)
- [Addendum: Apple Platform Compatibility](Docs/Addendum/README.md)
- [Mastering the Teatro Prompting Language for GUI Code Generation](https://chatgpt.com/share/68826ebf-64ac-8005-9b37-40d6e7187ea3)

`TeatroSampler` provides cross-platform MIDI 2 playback for the animation player and bridges events to legacy formats when needed.

The new **Storyboard DSL** allows you to script view states and animated transitions in Swift.  See the guide for an example of generating a textual storyboard preview that can be sent back to Codex.

The `Sources/` directory follows the structure suggested in the documentation and contains placeholders for implementation. `Tests/` remains empty until concrete code is added.

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
