## 2. View Types

### 2.1 Text

The `Text` view displays a single styled line of content using an optional `TextStyle`.

```swift
public struct Text: Renderable {
    public let content: String
    public let style: TextStyle

    public init(_ content: String, style: TextStyle = .plain) {
        self.content = content
        self.style = style
    }

    public func render() -> String {
        style.apply(to: content)
    }
}
```

---

### 2.2 VStack

A vertical stack of child views. Each child is indented based on the `padding` value and aligned using the specified `Alignment`.

```swift
public struct VStack: Layouting {
    public let children: [Renderable]
    public let alignment: Alignment
    public let padding: Int

    public init(alignment: Alignment = .leading, padding: Int = 0, @ViewBuilder _ content: () -> [Renderable]) {
        self.alignment = alignment
        self.padding = padding
        self.children = content()
    }

    public func render() -> String {
        let indent = String(repeating: " ", count: padding)
        return children.map { indent + $0.render() }.joined(separator: "\n")
    }
}
```

---

### 2.3 HStack

A horizontal stack of child views rendered on a single line, separated by spaces and prefixed by optional padding.

```swift
public struct HStack: Layouting {
    public let children: [Renderable]
    public let alignment: Alignment
    public let padding: Int

    public init(alignment: Alignment = .leading, padding: Int = 0, @ViewBuilder _ content: () -> [Renderable]) {
        self.alignment = alignment
        self.padding = padding
        self.children = content()
    }

    public func render() -> String {
        let indent = String(repeating: " ", count: padding)
        return indent + children.map { $0.render() }.joined(separator: " ")
    }
}
```

---

### 2.4 Stage

A top-level semantic container that can group scenes, components, or temporal slices. The `title` is always shown, followed by the content block.

```swift
public struct Stage: Renderable {
    public let title: String
    public let content: Renderable

    public init(title: String, @ViewBuilder content: () -> Renderable) {
        self.title = title
        self.content = content()
    }

    public func render() -> String {
        "[Stage: \(title)]\n" + content.render()
    }
}
```

---

### 2.5 TeatroIcon

A symbolic display element rendered with a gestural or expressive icon. Useful for stage props, semantic emphasis, or layout anchoring.

```swift
public struct TeatroIcon: Renderable {
    public let symbol: String

    public init(_ symbol: String) {
        self.symbol = symbol
    }

    public func render() -> String {
        "◉ \(symbol)"
    }
}
```
---

```

### 2.6 Panel

A rectangular container specifying width, height and optional corner radius.

```swift
public struct Panel: Renderable {
    public let width: Int
    public let height: Int
    public let cornerRadius: Int
    public let content: [Renderable]

    public init(width: Int, height: Int, cornerRadius: Int = 0, @ViewBuilder content: () -> [Renderable]) {
        self.width = width
        self.height = height
        self.cornerRadius = cornerRadius
        self.content = content()
    }

    public func render() -> String {
        "[Panel \(width)x\(height) r:\(cornerRadius)]\n" + content.map { $0.render() }.joined(separator: "\n")
    }
}
```

### 2.7 Dot, Rule and InputCursor

Utility views for simple terminal style rendering.

```swift
public struct Dot: Renderable {
    public let color: String
    public let diameter: Int
    public init(color: String = "black", diameter: Int = 10) { ... }
    public func render() -> String { "\u{25CF}" }
}

public struct Rule: Renderable {
    public init() {}
    public func render() -> String { String(repeating: "-", count: 10) }
}

public struct InputCursor: Renderable {
    public init() {}
    public func render() -> String { "|" }
}
```

### 2.8 DispatcherPrompt

An example composite view combining the basic elements into a structured layout used by the Codex deployment loop.

```swift
public struct DispatcherPrompt: Renderable {
    public init() {}
    public func render() -> String {
        Stage(title: "Dispatcher") {
            Panel(width: 640, height: 900, cornerRadius: 12) {
                VStack(alignment: .leading) {
                    Dot(color: "green", diameter: 10)
                    Rule()
                    Text("<content>")
                    Rule()
                    InputCursor()
                }
            }
        }.render()
    }
}
```
```
© 2025 Contexter alias Benedikt Eickhoff, https://fountain.coach. All rights reserved.
Unauthorized copying or distribution is strictly prohibited.
```

````text
©\ 2025 Contexter alias Benedikt Eickhoff 🛡️ All rights reserved.
````
