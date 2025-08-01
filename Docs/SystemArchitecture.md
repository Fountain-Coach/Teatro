## System Architecture Overview
_A high-level view of Teatro's modules and design patterns._

### Repository Layout
- `Sources/` – Swift source files grouped by feature area.
- `Tests/` – Unit tests covering rendering and audio functionality.
- `Docs/` – Documentation chapters and proposals.
- `assets/` – Example resources used in tests and demos.

![AI Image Prompt: A top-level diagram of the Teatro repository showing the major folders Sources, Tests, Docs and assets with arrows indicating workflow from code to documentation and tests](architecture-overview.png)

### Core Modules
**ViewCore** (`Sources/ViewCore`)
- Defines the `Renderable` protocol and fundamental view types like [`Text`](../Sources/ViewCore/Text.swift) and [`VStack`](../Sources/ViewCore/VStack.swift).
- Uses the `ViewBuilder` result builder in [`Protocols.swift`](../Sources/ViewCore/Protocols.swift) to assemble nested views, illustrating the **Builder** pattern.
- Layout containers such as [`HStack`](../Sources/ViewCore/HStack.swift) and [`Stage`](../Sources/ViewCore/Stage.swift) compose children conforming to `Renderable`, forming a **Composite** view hierarchy.

**Renderers** (`Sources/Renderers`)
- Convert views into multiple output formats: [`HTMLRenderer`](../Sources/Renderers/HTMLRenderer.swift), [`MarkdownRenderer`](../Sources/Renderers/MarkdownRenderer.swift), [`SVGRenderer`](../Sources/Renderers/SVGRenderer.swift) and [`ImageRenderer`](../Sources/Renderers/ImageRenderer.swift).
- [`SVGRenderer`](../Sources/Renderers/SVGRenderer.swift) caches rendered output using a simple dictionary for re-use.
- Animation utilities in [`SVGAnimation`](../Sources/Renderers/SVGAnimation) work with storyboards to create animated SVGs.

**Audio** (`Sources/Audio`)
- Provides MIDI compatibility helpers in [`MIDICompatibilityBridge.swift`](../Sources/Audio/MIDICompatibilityBridge.swift).
- The [`TeatroSampler`](../Sources/Audio/TeatroSampler.swift) actor routes note events to backends implementing `SampleSource`, demonstrating the **Strategy** pattern with [`FluidSynthSampler`](../Sources/Audio/Samplers/FluidSynthSampler.swift) and [`CsoundSampler`](../Sources/Audio/Samplers/CsoundSampler.swift).

**Storyboard and Animation** (`Sources/Storyboard`)
- Declarative scene definitions via [`Storyboard`](../Sources/Storyboard/Storyboard.swift).
- The animation system uses [`Animator`](../Sources/Animation/Animator.swift) and [`SVGAnimator`](../Sources/Renderers/SVGAnimation/SVGAnimator.swift).

**CLI Utilities** (`Sources/CLI`)
- [`RenderCLI`](../Sources/CLI/RenderCLI.swift) exposes rendering targets via command line.

![AI Image Prompt: Diagram showing flow from Storyboard to SVGAnimator to final animated SVG output](storyboard-flow.png)

### Design Patterns in Context
- **Builder** – `ViewBuilder` and `StoryboardBuilder` create nested structures.
- **Composite** – `Renderable` views compose other renderables (`VStack`, `Stage`).
- **Strategy** – `SampleSource` implementations swap audio backends.
- **Adapter** – `MIDICompatibilityBridge` converts modern MIDI events for Csound or LilyPond.

### Extensibility
The modular structure allows adding new renderers or sampler backends with minimal changes. Tests in `Tests/` verify each component.

![AI Image Prompt: Layered architecture showing ViewCore at the center, surrounded by Renderers, Audio, CLI and Tests](layered-architecture.png)

---
``© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.``
