# Render Target Plugins
_A guide to extending Teatro's CLI with custom output formats._

For CLI usage, see [render-cli](CLI/RenderCLI.md).

## RendererPlugin
`RendererPlugin` defines the contract each renderer must satisfy. A plugin declares a unique `identifier`, optional `fileExtensions`, and implements `render(view:output:)` where rendering work occurs. Helpers like `write(_:)` and `writeData(_:)` make it easy to send results to stdout or a file.

```swift
public protocol RendererPlugin {
    static var identifier: String { get }
    static var fileExtensions: [String] { get }
    static func render(view: Renderable, output: String?) throws
}
```

## RendererRegistry
`RendererRegistry` keeps a mapping from identifiers and file extensions to plugin types. Use `register(_:)` to add a plugin. The shared singleton is used by the CLI to determine valid `--format` options.

```swift
// Register a renderer
RendererRegistry.register(MyRenderer.self)

// Lookup by name or extension
let renderer = RendererRegistry.shared.plugin(for: "svg")
```

## Plugin Discovery
Because Swift packages do not expose automatic plugin discovery, each module performs registration when it is loaded. A common pattern is to call `RendererRegistry.register` from a global during module initialization.

```swift
struct MyRenderer: RendererPlugin {
    static let identifier = "mine"
    static let fileExtensions = ["mine"]
    static func render(view: Renderable, output: String?) throws {
        try write("custom", to: output, defaultName: "out.mine")
    }
}

private let _registration: Void = {
    RendererRegistry.register(MyRenderer.self)
}()
```

Once the module containing this code is imported, the CLI immediately recognises the new target and it appears in `render-cli --help` under available formats.

## Tutorial: Creating a Custom Renderer Package
1. **Create a package**
   ```bash
   swift package init --type library --name MyRenderer
   ```
2. **Declare dependencies** in `Package.swift` on `Teatro` and `RenderCLI`:
   ```swift
   .package(url: "https://github.com/your-org/Teatro.git", branch: "main"),
   ```
   Then add `.product(name: "Teatro", package: "Teatro")` and `.product(name: "RenderCLI", package: "Teatro")` to your target dependencies.
3. **Implement a target** conforming to `RenderTargetProtocol`.
4. **Create a plugin** that registers the target in `registerTargets(in:)`.
5. **Add a global registration constant** so importing the module triggers registration.
6. **Build and run**
   ```bash
   swift build
   swift run RenderCLI --format myTarget
   ```

This approach lets third‑party packages ship additional renderers without modifying the core CLI.

---
© 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
