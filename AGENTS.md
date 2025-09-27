# Teatro Refactor – Modular Architecture Initiative

- **Owner:** Contexter@Fountain-Coach  
- **Version:** 0.1 (2025-09-27)  
- **Scope:** Restructure the Teatro repository from a single monolithic package into a set of modular Swift packages. Establish clear boundaries for core rendering, audio output, GUI preview, and CLI tools, to improve maintainability and onboarding. Align Teatro’s codebase with its future role as the SDL-based rendering backend for FountainAI and related projects.

- **ID:** teatro-modular-refactor  
- **Name:** Teatro Modular Architecture & SDL Integration Readiness

## 1. Description

This refactoring breaks Teatro’s “collage” of features into well-defined modules:
- **TeatroCore** – The core deterministic rendering engine (view DSL, Fountain parser, timeline animation, MIDI encoding, file format outputs). No GUI or audio side-effects.
- **TeatroAudio** – MIDI 2.0 native sampler and audio backends (FluidSynth, Csound) packaged behind a clean async API.
- **TeatroGUI** – Interactive GUI preview using SDL3 for rendering and input, plus MIDI2 real-time visualization.
- **TeatroCLI** – Command-line tools and executables for using Teatro in scripts and pipelines.
- **TeatroTelemetry** (optional) – Streaming SSE over MIDI2 handling and diagnostics (if not within Core).

Each module will live in `Packages/` with its own tests and documentation. External usage of Teatro is preserved via a unified API module (`TeatroRenderAPI`) that taps into these internals.

By doing this, we **decouple** components and prevent unwieldy growth. New contributors can focus on one module at a time. The SDL GUI can evolve separately, and headless usage remains lightweight.

This refactor also mirrors the successful modularization of FountainKit:contentReference[oaicite:151]{index=151}, ensuring consistency across the organization.

## 2. Architectural Objectives

### 2.1 Modular Boundaries & Dependencies
Define strict boundaries: 
- TeatroCore should not depend on any C libraries or SDL – it’s pure Swift (plus `MIDI2` and utility packages). 
- TeatroAudio depends on Core (for data types) but Core *does not* depend on Audio. 
- TeatroGUI depends on Core (for content) and optionally Audio (for controlling playback), but core logic doesn’t depend on GUI.
- CLI depends on whatever modules needed but no module depends on CLI.
- Telemetry (if separate) depends on Core and MIDI2, and GUI depends on Telemetry for overlay data.

This ensures, for example, we can build Core on a platform without audio or GUI, and still run all its features.

### 2.2 Public API Stability
Continue to provide a simple public interface for common use-cases. The `TeatroRenderAPI` (or just `Teatro` umbrella) will re-export core functions like `renderScript`, types like `TeatroPlayerView`, etc., so external code sees minimal changes. We avoid breaking existing integrations like HelloFountainAITeatro:contentReference[oaicite:152]{index=152} – they might just need to update import names. Mark new module boundaries with proper Swift package products and use semantic versioning to signal changes.

### 2.3 SDL3 Integration (Future-proof)
Lay the groundwork for fully integrating SDL3:
- The TeatroGUI module will contain all needed SDL initialization and event loop code. We will ensure it can create a window, draw text or simple shapes for frames, and handle user input (keyboard/mouse) to control playback.
- Keep GUI rendering logic abstracted: possibly implement a basic text-based rendering first (to mirror current SVG output) and plan to expand with more graphical fidelity (fonts, colors, etc.).
- Ensure GUI runs on macOS and Linux reliably (use feature flags or dummy devices in CI to run tests).

### 2.4 Maintain or Improve Performance
Splitting into modules should not degrade performance. In fact, it may improve build times (parallel builds of modules) and allow more focused optimization. We will monitor that rendering an SVG or playing audio has no regression. The GUI loop will target 60 FPS for modest content, as per requirements:contentReference[oaicite:153]{index=153}.

### 2.5 Documentation & Onboarding
For each module, create a README or doc explaining its usage and APIs. Update the top-level documentation to include a map of the new structure (which part does what, with links to internal docs). Include an **ONBOARDING** section so that a newcomer knows to start by reading TeatroCore’s README (for example) before diving into code.

## 3. Deliverables (Planned Modules & Components)

- **Packages/TeatroCore/** – Core library  
  - *Content:* View DSL (`Renderable`, `ViewBuilder`, `Text`, `VStack`, etc.), layout engine (`LayoutNode`), FountainParser & FountainElement model, Storyboard DSL + Animator, MIDI DSL (MIDI2Note, MIDISequence, UMP encoding), Renderers (SVGRenderer, HTMLRenderer, MarkdownRenderer, etc.), MIDI1Bridge, and other pure logic.  
  - *Tests:* Fountain parsing tests, rendering snapshot tests (SVG output), MIDI encoding tests, etc.  
  - *Product:* `TeatroCore` (library)

- **Packages/TeatroAudio/** – Audio backend library  
  - *Content:* `CCsound` and `CFluidSynth` C targets, `CsoundSampler` actor, `FluidSynthSampler` actor, `TeatroSampler` facade, SampleSource protocol, plus any audio-related utilities.  
  - *Tests:* SamplerDemo or dedicated tests that initialize the sampler (perhaps using the dummy sine.orc and a small SF2) and ensure note triggers work.  
  - *Product:* `TeatroAudio` (library)

- **Packages/TeatroGUI/** – GUI/Preview library  
  - *Content:* SDL integration (window creation, rendering context), an event loop that coordinates with TeatroCore (to get frames) and TeatroAudio (for sound). `TeatroPreviewController` class or actor to manage a running preview. SwiftUI `TeatroPlayerView` can live here (behind `#if canImport(SwiftUI)` flag) or remain in Core if it only uses Core. SSE overlay UI components (if any, e.g., drawing token text on screen).  
  - *Tests:* Integration tests if possible (e.g., run the preview in a headless mode for a short duration and verify that no errors occur, or use Xvfb in CI for SDL on Linux:contentReference[oaicite:154]{index=154}:contentReference[oaicite:155]{index=155}). Otherwise, reliance on manual testing for GUI aspects with automated unit tests for non-UI logic (like the data flow).  
  - *Product:* `TeatroGUI` (library)

- **Packages/TeatroCLI/** – Executables  
  - *Content:* Sources for `RenderCLI` (the ArgumentParser definitions and command implementations), `teatro-play`, `TeatroPreviewDemo` (which will now use TeatroGUI API to launch a preview). Possibly `FountainCLI` if it remains (or that may fold into RenderCLI as a subcommand).  
  - *Note:* We might not need a separate package for CLI; we could keep CLI targets in the main repo Package.swift but segregated from libraries. However, a separate package `TeatroCLI` helps enforce that libraries don’t depend on CLI.  
  - *Product:* Executables: `render-cli`, `teatro-play`, `teatro-preview` (if introduced), etc.

- **Packages/TeatroTelemetry/** – (Optional) Streaming & Reliability  
  - *Content:* SSE envelope structures, dispatcher (FlexData/SysEx8 parsing), reliability algorithm (ack tracking, sequence gap detection), and the `StreamPreviewController` that bridges UMP streams to high-level token events.  
  - *Notes:* This could also be part of TeatroCore if we consider it fundamental. But isolating it is cleaner if we foresee using it in FountainKit’s telemetry. If separate, it produces a `TeatroTelemetry` library that both FountainKit and TeatroGUI can use.  
  - *Tests:* Already there are tests like FountainSSEEnvelopeTests, etc. Those move here. Ensure end-to-end test with a sample UMP stream to tokens.

- **Top-level integration:**  
  - Update the root `Package.swift` to either use these as local package dependencies or simply remove in favor of a workspace (in which case clients would use `.package(path: "Packages/TeatroCore")`, etc., or we publish these to git). Perhaps simpler: keep one Package.swift that defines all targets but group them logically (similar result, but using SwiftPM target dependencies rather than separate packages). Decision to be finalized, but outcome is the same modular separation.

- **Docs & Guides:**  
  - `AGENTS.md` (this document) updated upon completion with any changes in plan/version.  
  - `ONBOARDING.md` or contributing guide explaining module structure.  
  - Update README usage examples (if any new imports or initialization steps).  
  - Possibly a migration note: “If you previously used `import TeatroRenderAPI`, continue to do so; internal modules are mostly invisible except if you import individual ones for advanced use.”

## 4. Implementation Plan (Milestones & Tasks)

- **Milestone 1:** Create module scaffolds and move View/Core code  
  - [ ] Set up `Packages/TeatroCore` with a minimal Package.swift and move core source files.  
  - [ ] Adjust import paths in moved files, ensure `swift test` passes for TeatroCore alone.  
  - [ ] Remove those files from the old target, run overall tests.  

- **Milestone 2:** Move Audio code to TeatroAudio  
  - [ ] Create `Packages/TeatroAudio`, move Csound and FluidSynth wrappers and Swift sampler code.  
  - [ ] Fix any cross-module references (Core types used in Audio, e.g., convert MIDI2Note to simpler form if needed or make MIDI2Note type public in Core).  
  - [ ] Test that `TeatroSamplerDemo` still runs using new module (adjust its target dependencies).  

- **Milestone 3:** Establish TeatroCLI package  
  - [ ] Move RenderCLI source into `Packages/TeatroCLI` (or keep in main but retarget dependencies to new modules).  
  - [ ] Update CLI commands to use new APIs (e.g., if `TeatroCore` is separate, ensure `import TeatroCore` or via umbrella).  
  - [ ] Test CLI commands: e.g., `swift run render-cli input.fountain --format svg` yields identical output as before.  

- **Milestone 4:** Integrate Telemetry (if separate)  
  - [ ] Move SSE parsing and StreamPreviewController to `Packages/TeatroTelemetry`.  
  - [ ] Ensure TeatroGUI (or Core) uses this for SSE features (e.g., GUI calls `StreamPreviewController.ingestFlex()` on incoming MIDI bytes).  
  - [ ] Run SSE tests to confirm no breakage.  

- **Milestone 5:** Activate SDL in TeatroGUI  
  - [ ] Implement basic SDL window open/close in TeatroGUI (perhaps a `TeatroWindowManager` class).  
  - [ ] Tie a render callback to TeatroCore: e.g., for each frame tick (maybe 60Hz or driven by MIDI events), get current frame’s text layout from core and blit to window.  
  - [ ] Add user controls: e.g., Esc to close, Space to pause, etc., as a proof of concept.  
  - [ ] Test `TeatroPreviewDemo` manually on macOS and Linux.  

- **Milestone 6:** Finalize API and remove old structure  
  - [ ] Eliminate the old `Sources/Teatro` monolithic target from Package.swift, instead have the new packages produce the needed products.  
  - [ ] Ensure the umbrella `TeatroRenderAPI` either becomes part of TeatroCore or is a small target depending on Core+GUI to expose combined functionality (decide whether to keep the name or just have users import TeatroCore + TeatroGUI explicitly).  
  - [ ] Bump package version, update documentation references from old paths to new.  

Each milestone will be a pull request (if using PRs) or at least a distinct commit, to allow bisecting if needed.

## 5. Testing & Quality

- **Continuous Integration:** Update CI to build and test all modules. For example, add jobs for `swift test -c debug Packages/TeatroCore`, etc., in addition to the root build. Use an Xvfb headless display for SDL tests on Linux CI:contentReference[oaicite:156]{index=156} to run GUI tests without a physical GPU. 
- **Unit & Integration Tests:** All existing tests must pass. Additional tests will be added for new module boundaries (e.g., a test that instantiating TeatroSampler in isolation doesn’t crash, a test that RenderCLI’s format registry lists expected formats from Core’s plugins). 
- **Performance Checks:** Render a known complex Fountain script to SVG before and after refactor to ensure rendering time is not worse. Do similarly for a MIDI playback. 
- **Documentation Checks:** Ensure that any code examples in Docs/Chapters are updated to new module imports if needed (e.g., if now one must `import TeatroCore` or if `TeatroPlayerView` moved). Possibly provide an alias in code for backward compat (like `public typealias TeatroPlayerView = TeatroGUI.TeatroPlayerView` if needed).

## 6. Impact and Rollout

- **Impact:** No runtime behavior change intended (except the new actual GUI features coming online). The main impact is on developers: a more organized codebase. 
- **Migration for users:** Minimal. If using SPM, they might see new targets. We’ll maintain `package.name = "teatro"` so existing `.package(url: "…Teatro.git", branch: "main")` still works. If we change product names, we’ll document it. Internally, FountainAI’s next update can adopt the new imports (which should be trivial). 
- **Timeline:** The refactor can be done incrementally over a couple of weeks, with the core split happening first (which yields immediate benefits). The SDL integration may continue beyond the refactor as its own project, but this structure allows working on it concurrently without disturbing core. 

## 7. Conclusion

By modularizing Teatro, we **future-proof** its development and make it contributor-friendly. The engine’s innovative features – from screenplay rendering to synchronized music visualization – will be much easier to extend and maintain in this new architecture. This refactoring brings Teatro in line with the architectural rigor of FountainKit:contentReference[oaicite:157]{index=157}, ensuring that the Teatro engine can reliably serve as the unified rendering backend (with SDL3 support) for all FountainAI applications going forward.

