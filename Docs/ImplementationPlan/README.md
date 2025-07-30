## Implementation Roadmap
_Historical roadmap capturing past goals._
**Historical Note:** This roadmap is kept for archive purposes only.

This roadmap converts the critique and analysis of the Teatro View Engine into concrete development tasks. It builds upon the existing [View Implementation and Testing Plan](../Chapters/10_ViewImplementationPlan.md).

## 11.1 Finalize Placeholder Features

1. **MIDI 2.0 Support**
   - Introduce `MIDI2Note` and `UMPEncoder` to generate Universal MIDI Packets.
   - Provide a `CsoundScore` view type and `CsoundRenderer` for `.csd` output.
   - Extend `RenderCLI` with `csound` and `ump` targets and add tests for the generated files.
   - Implement `TeatroSampler` for cross-platform MIDI 2 playback.
   - Add `MIDICompatibilityBridge` to convert sampler events into `MIDINote`, `CsoundScore`, and `LilyScore`.
2. **GIF Export**
   - Extend `Animator` with a helper for `.gif` generation using ImageMagick or a Swift wrapper.
   - Document required tools and provide a sample test that produces an animated gif from frame PNGs.

## 11.2 Expand Testing and Continuous Integration

1. **CLI Tests**
   - Implement integration tests that run the `RenderCLI` binary for each `RenderTarget`.
   - Verify console output or generated files.
2. **PNG and PDF Verification**
   - Include tests that confirm image and PDF outputs exist (mocking external dependencies when unavailable).
3. **GitHub Actions**
   - Add a basic workflow running `swift build` and `swift test` on push and pull requests.

## 11.3 Cross‑Platform Improvements

1. **Deprecation Fixes**
   - Update any use of `Process.launchPath` to `executableURL` in `LilyScore.renderToPDF()`.
2. **Platform-Specific Renderers**
   - Detect whether Cairo is available at runtime.
   - Provide CoreGraphics-based rendering on macOS/iOS and keep Cairo on Linux.

## 11.4 Documentation Updates

1. **README Corrections**
   - Ensure the root `README` accurately describes the presence of tests.
2. **Quick‑Start Instructions**
   - Provide setup steps for dependencies like Cairo and LilyPond for each supported platform.

## 11.5 Advanced Features

1. **Timed Rendering Components**
   - Design new view types such as `TimedView`, `Beat`, or `Marker` for synchronization of animations and music.
   - Outline their APIs and add unit tests once implemented.
2. **SwiftUI Preview Layer**
   - Prototype a simple SwiftUI wrapper to preview Teatro views on Apple platforms.

## 11.6 Storyboard DSL and View State Transitions

Codex deployments often orchestrate multi-step interfaces. To simplify complex
timelines, introduce a storyboard-like DSL within Teatro:

1. **Declarative Scene Graph** – A Swift builder API describing each state of
   the interface. Scenes contain named views and optional metadata. **Implemented
   via `Storyboard` and `Scene`.**
2. **Transition Blocks** – Define tweens or crossfades between scenes using
   easing functions and frame counts. **Implemented through `Transition`.**
3. **Codex Integration** – Allow GPT agents to emit storyboard files that can be
   rendered frame-by-frame or previewed live on macOS. **Implemented via
   `CodexStoryboardPreviewer` and the example in `Docs/StoryboardDSL`.**
4. **Renderer Hooks** – Use existing `Animator` output on Linux and map to
   SwiftUI animations on Apple platforms. **Initial hooks provided through the
   `Storyboard.frames()` API.**
5. **Testing** – Add unit tests for state parsing and ensure deterministic frame
   generation. **Covered in `StoryboardTests`.**

See [Storyboard DSL](../StoryboardDSL/README.md) for a step-by-step example of generating a prompt for Codex using the DSL.

## 11.7 Packaging and Release

- Verify `Package.swift` manifests build on both Linux and macOS.
- Create `.podspec` files and ensure they are not ignored.
- Tag releases and submit them to the Swift Package Index.
- Document the process in the project README files.

---

This document should evolve alongside the codebase. **Maintain and update this roadmap** as new features land or priorities shift to keep development focused and transparent.


````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
