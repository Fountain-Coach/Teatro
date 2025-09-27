import Foundation

public struct Scene {
    public let name: String
    public let view: Renderable
    public var metadata: [String: String]

    public init(_ name: String, metadata: [String: String] = [:], content: () -> Renderable) {
        self.name = name
        self.metadata = metadata
        self.view = content()
    }
}

public enum Easing: String {
    case linear
    case easeIn
    case easeOut
    case easeInOut
}

public struct Transition {
    public enum Style {
        case crossfade
        case tween
    }
    public let style: Style
    public let frames: Int
    public let easing: Easing?

    public init(style: Style, frames: Int, easing: Easing? = nil) {
        self.style = style
        self.frames = frames
        self.easing = easing
    }
}

public enum StoryboardStep {
    case scene(Scene)
    case transition(Transition)
}

@resultBuilder
public enum StoryboardBuilder {
    public static func buildBlock(_ components: StoryboardStep...) -> [StoryboardStep] {
        components
    }

    public static func buildExpression(_ expression: Scene) -> StoryboardStep {
        .scene(expression)
    }

    public static func buildExpression(_ expression: Transition) -> StoryboardStep {
        .transition(expression)
    }
}

public struct Storyboard {
    public let steps: [StoryboardStep]

    public init(@StoryboardBuilder _ builder: () -> [StoryboardStep]) {
        self.steps = builder()
    }

    public func frames() -> [Renderable] {
        var result: [Renderable] = []
        var lastView: Renderable?
        var pendingTransition: Transition?

        for step in steps {
            switch step {
            case .scene(let scene):
                if let transition = pendingTransition, let last = lastView {
                    for _ in 0..<transition.frames {
                        result.append(last)
                    }
                    pendingTransition = nil
                }
                result.append(scene.view)
                lastView = scene.view
            case .transition(let transition):
                pendingTransition = transition
            }
        }

        return result
    }
}
