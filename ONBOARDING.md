Teatro Modular Architecture (Preview)

This repository is in the process of being modularized to improve maintainability and onboarding. The initial refactor adds first-class SwiftPM targets while preserving the umbrella `Teatro` module for backwards compatibility.

Modules
- TeatroCore: Pure Swift core (view DSL, layout, parsers, renderers, MIDI logic). Builds without GUI/audio. Available as a library product.
- TeatroAudio: Samplers and audio sinks (FluidSynth, Csound). Depends on TeatroCore for data types. Available as a library product.
- TeatroGUI: SDL-based preview scaffolding and SwiftUI overlays. Depends on TeatroCore and includes MIDI integration utilities.
- TeatroTelemetry: Placeholder for SSE over MIDI2 telemetry components. Will be filled in subsequent milestones.
- Teatro (umbrella): Backwards-compatible module that re-exports Core, Audio, GUI, Telemetry to minimize external breaking changes.

Status
- The code compiles and existing executables run via the umbrella module.
- Tests will be updated in follow-up to align with new boundaries and event type surfaces.

Building
- swift build
- swift test  # some tests may require updates; see TODOs

What changed in code
- Introduced new SwiftPM targets for Core/Audio/GUI and an umbrella `Teatro`.
- Moved `MIDIAudioSink` protocol into Core to remove Core→Audio dependency.
- Moved `RendererRegistry.swift` into Renderers to avoid circular dependencies.
- Split SwiftUI streaming overlays out of Core and into GUI.

Next steps
- Extract Telemetry (SSE/CI) into its own module target(s).
- Optionally move modules into `Packages/` subpackages for full isolation.
- Update CI to build all targets and run GUI tests headlessly on Linux (Xvfb).

