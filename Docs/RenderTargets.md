# Render Target Plugins
_A guide to extending Teatro's CLI with custom output formats._

For CLI usage, see [render-cli](CLI/RenderCLI.md).

## RenderTargetProtocol
`RenderTargetProtocol` defines the contract each renderer must satisfy. A target declares a unique `name`, optional `aliases`, and implements `render(view:output:)` where rendering work occurs. Convenience helpers like `write(_:)` and `writeData(_:)` make it easy to send results to stdout or a file.

```swift
public protocol RenderTargetProtocol {
    static var name: String { get }
    static var aliases: [String] { get }
    static func render(view: Renderable, output: String?) throws
}
```

## RenderTargetRegistry
`RenderTargetRegistry` keeps a mapping from target names to types. Use `register(_:)` to add a single target, or `register(plugin:)` to let a plugin supply many targets. The shared singleton is used by the CLI to determine valid `--format` options.

```swift
// Register a target
RenderTargetRegistry.register(MyTarget.self)

// Lookup by name
let target = RenderTargetRegistry.shared.lookup("svg")
```

## Plugin Discovery
Plugins conform to `RenderTargetPlugin` and are responsible for registering one or more targets. Because Swift packages do not expose automatic plugin discovery, each module performs registration when it is loaded. A common pattern is a private global that executes during module initialization.

```swift
enum MyPlugin: RenderTargetPlugin {
    static func registerTargets(in registry: RenderTargetRegistry) {
        registry.register(MyTarget.self)
    }
}

private let _pluginRegistration: Void = {
    RenderTargetRegistry.register(plugin: MyPlugin.self)
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
