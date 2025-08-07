## 1. Core Protocols
_A foundation for building every view type._

### 1.1 Renderable

The foundational protocol of the Teatro View Engine. All visual, narrative, or musical view types conform to `Renderable`, exposing a structured layout tree via `layout()`. A default `render()` method remains for legacy text-based workflows.

```swift
public protocol Renderable {
    func layout() -> LayoutNode
}

public extension Renderable {
    func render() -> String { layout().toText() }
}
```

---

### 1.2 Layouting

Used by layout-oriented views such as `VStack` or `HStack`. Provides optional horizontal alignment and indentation padding.

```swift
public protocol Layouting: Renderable {
    var alignment: Alignment { get }
    var padding: Int { get }
}
```

---

### 1.3 Alignment

The alignment options available to layout containers.

```swift
public enum Alignment: String {
    case leading = "left"
    case center = "center"
    case trailing = "right"
}
```

---

### 1.4 TextStyle

This enum describes inline style variations applied to `Text` views.

```swift
public enum TextStyle {
    case bold, italic, underline, plain

    public func apply(to content: String) -> String {
        switch self {
        case .bold: return "**\\(content)**"
        case .italic: return "*\\(content)*"
        case .underline: return "_\\(content)_"
        case .plain: return content
        }
    }
}
```

---

### 1.5 @ViewBuilder

Swift-style result builder for grouping child views declaratively.

```swift
@resultBuilder
public enum ViewBuilder {
    public static func buildBlock(_ components: Renderable...) -> [Renderable] {
        components
    }
}
```
---

`````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
`````
