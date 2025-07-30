## 4a. Teatro CLI Implementation Guide

This guide expands on the built‑in command‑line interface shipped with the **Teatro View Engine**. It explains the code structure, describes common use cases, and walks through a basic tutorial. The CLI is handy for quickly rendering views without embedding them in a GUI application.

---

### Overview

The executable target `RenderCLI` lives in `Sources/CLI` and is declared in `Package.swift`:

```swift
.executable(name: "RenderCLI", targets: ["RenderCLI"])
```

Running `swift run RenderCLI <target>` builds the CLI and renders a simple demo `Stage` using the selected output format. Supported targets come from the `RenderTarget` enum:

```swift
public enum RenderTarget: String {
    case html, svg, png, markdown, codex, svgAnimated, csound, ump
}
```

The `main` function constructs a small view and switches over `RenderTarget` to invoke the matching renderer. If no argument is given, it defaults to the `codex` previewer.

Environment variables allow you to tweak renderer dimensions. See [docs/environment_variables.md](../../../docs/environment_variables.md) for defaults and descriptions of `TEATRO_SVG_WIDTH`, `TEATRO_SVG_HEIGHT`, `TEATRO_IMAGE_WIDTH`, and `TEATRO_IMAGE_HEIGHT`.

---

### Use Cases

- **Previewing views** during development or testing
- **Generating assets** such as `.svg` or `.png` files in scripts
- **Producing animation frames** with the `svgAnimated` option
- **Creating audio scores** via the `csound` target or MIDI packets with `ump`
- **Feeding Codex** by emitting `codex` previews for introspection

---

### Tutorial

1. **Build and run**

   ```bash
   swift run RenderCLI html
   ```

   This command outputs HTML for the demo view. Swap `html` with `svg`, `png`, `markdown`, `codex`, `svgAnimated`, `csound`, or `ump` as needed.

2. **Adjust output size**

   Set environment variables before running the CLI:

   ```bash
   export TEATRO_SVG_WIDTH=800
   export TEATRO_SVG_HEIGHT=600
   swift run RenderCLI svg
   ```

3. **Integrate in a workflow**

   - Use `swift build -c release` to compile a standalone binary.
   - Call the binary from build scripts to generate GUI artifacts.
   - Combine with the Storyboard DSL and `SVGAnimator` to render animated scenes.

The CLI offers a quick entry point for experimenting with Teatro without a full GUI application. You can script view generation, generate assets for documentation, or pipe preview output directly into Codex for further processing.

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
