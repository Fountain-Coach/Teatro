# Teatro

A modular, deterministic rendering engine in Swift with MIDI 2.0, screenplay (Fountain) parsing, multiple output renderers (SVG/HTML/PNG), an audio layer for real‑time playback, and an SDL‑based preview GUI. The codebase is split into focused Swift packages to keep core logic lean and headless while allowing GUI and audio to evolve independently.

Quick links
- Onboarding: Docs/ONBOARDING.md
- Docs index: Docs/README.md
- Core API: Packages/TeatroCore/README.md
- Audio: Packages/TeatroAudio/README.md
- GUI: Packages/TeatroGUI/README.md
- Telemetry: Packages/TeatroTelemetry/README.md

Status
- Platforms: macOS 14+. Linux support is being brought up progressively (GUI runs with SDL stubs; audio backends vary by platform).
- SDL3 preview: available with a stubbed backend; event loop and overlays are in place and ready for native SDL integration.

## Architecture

Teatro is organized as a small set of SwiftPM packages that you can use together or independently. The top‑level umbrella module `Teatro` re‑exports everything for convenient consumption.

- TeatroCore: Pure Swift rendering engine, view DSL and layout, Fountain parser, storyboard DSL, renderers (SVG/HTML/PNG), MIDI/UMP encoding, and unified MIDI event types. No GUI or audio dependencies.
- TeatroAudio: MIDI 2.0 samplers and sinks (FluidSynth, Csound, AVFoundation). Depends on TeatroCore for shared types.
- TeatroGUI: SDL‑based preview scaffolding + SwiftUI overlays for token/timing visualization. Depends on TeatroCore.
- TeatroTelemetry: SSE over MIDI 2.0 (Flex Data + SysEx8), reliability helpers (ACK/NACK, gap detection), and timing utilities. Depends on TeatroCore.

The repo also ships CLI tools and a small demo app that exercise these packages.

## Installation

Add the package to your Package.swift:

```swift
.package(url: "https://github.com/fountain-coach/teatro.git", branch: "main")
```

Then depend on either the umbrella or the individual modules:

```swift
// Umbrella (re‑exports all submodules)
.product(name: "Teatro", package: "teatro")

// Or pick specific modules
.product(name: "TeatroCore", package: "teatro")
.product(name: "TeatroAudio", package: "teatro")
.product(name: "TeatroGUI", package: "teatro")
.product(name: "TeatroTelemetry", package: "teatro")
```

## Quick start

- Render a simple view to SVG programmatically

```swift
import Teatro // or: import TeatroCore

let view = VStack {
    Text("Hello, Teatro!")
    Text("MIDI 2.0 • Fountain • SDL3")
}

// Write SVG to disk
try SVGRenderer.render(view: view, output: "output.svg")

// Or capture as a string
let svg = SVGRenderer.render(view)
```

- Use the CLI to render a file

```bash
# Render a Fountain script to SVG
swift run RenderCLI script.fountain --format svg --output out.svg

# Convert UMP to MIDI 1.0 bytes (example)
swift run RenderCLI song.ump --midi1-bridge > song.midi
```

- Launch the preview GUI demo

```bash
swift run TeatroPreviewDemo
```

- Minimal playback utility

```bash
# Route UMP→MIDI1 and play (see CLI docs for sinks and flags)
swift run RenderCLI song.ump --midi1-bridge | \
  swift run teatro-play --from-stdin
```

## Products

Libraries
- Teatro: Umbrella re‑exporting all modules
- TeatroCore: Core engine (no side effects)
- TeatroAudio: Audio backends and sampler
- TeatroGUI: SDL‑based preview scaffolding and overlays
- TeatroTelemetry: SSE over MIDI 2.0 and reliability helpers

Executables
- RenderCLI: Batch render and conversion tool
- teatro-play: Minimal playback helper
- TeatroPreviewDemo: Small app that exercises the preview loop
- FountainCLI: Convenience entry for previewing via CLI

## Build and test

- Build: `swift build`
- Test: `swift test`

Core and CLI tests run headless. GUI uses a stubbed SDL backend so it compiles reliably on CI and can be enabled with native SDL later.

## Documentation

- Docs index: Docs/README.md (PDFs with taglines, chapters, API spec)
- Onboarding: Docs/ONBOARDING.md
- Chapters: Docs/Chapters (view DSL, storyboard, MIDI, SSE over MIDI2, etc.)

## Contributing

- Start with Docs/ONBOARDING.md to understand the module layout and guidelines.
- Use Swift 6.1 and SwiftPM.
- Run `swift test` before submitting changes.

© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.

