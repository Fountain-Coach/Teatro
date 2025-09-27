Teatro Documentation Index

Overview
- Modular Swift packages for rendering, audio, GUI, and telemetry live under Packages/. Start with Docs/ONBOARDING.md for a guided tour.
- For public API and examples, prefer the umbrella module: import Teatro.

Key Guides
- ONBOARDING: Docs/ONBOARDING.md
- Render API: Docs/RenderAPI.md
- CLI Reference: Docs/CLI/RenderCLI.md
- System Architecture: Docs/SystemArchitecture.md

Modules
- Packages/TeatroCore/README.md
- Packages/TeatroAudio/README.md
- Packages/TeatroGUI/README.md
- Packages/TeatroTelemetry/README.md

Design PDFs
- Teatro View Engine – Feature Overview and Refactoring Plan.pdf
  - Tagline: High-level plan describing the modular refactor and feature roadmap for the Teatro view engine.
- SDL3 and MIDI2 Integration Strategy for Teatro GUI.pdf
  - Tagline: Strategy document outlining SDL3 windowing, rendering loop design, and MIDI 2.0 visualization plans for the GUI preview.
- Analysis of MIDI 2.0 Implementation in the Teatro Project.pdf
  - Tagline: Evaluation of MIDI 2.0 usage patterns, event models, and integration surfaces across the codebase.

API and Engineering
- OpenAPI: Docs/API/openapi.yaml (Render service schema)
- Coverage notes: Docs/Engineering/COVERAGE.md

Chapters
- The Docs/Chapters directory contains focused write-ups (view DSL, storyboard, MIDI integration, SSE over MIDI2, etc.) that map directly to package modules.

Legacy
- Older or superseded materials are kept under Docs/Legacy for reference. When in doubt, defer to the latest chapters and module READMEs.
