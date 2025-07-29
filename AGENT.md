# 🤖 Teatro AGENT.md

This repository contains the **Teatro View Engine**, a declarative Swift 6 framework for rendering text, music, and screenplay artifacts. Documentation lives under the `Docs/` directory and is organized by feature area.

## Contributor Guidelines
- Use the Swift 6.1 toolchain.
- Run `swift build` and `swift test` before committing code.
- Follow the directory conventions described in `Docs/Summary/README.md`.
- Keep `Docs/ImplementationPlan` updated when priorities shift.

## Project Highlights
- Modular `Renderable` protocol with multiple rendering backends.
- Multiple outputs: HTML, Markdown, SVG, PNG, animated SVG, and Codex introspection.
- Music rendering via LilyPond scores, MIDI 2.0 sequencing, and real‑time sampling with Csound/FluidSynth.
- Screenplay and storyboard support using the Fountain format.
- CLI utilities and a SwiftUI preview layer for quick iteration.

For detailed walkthroughs see the individual documentation files linked from the root `README.md`.

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
