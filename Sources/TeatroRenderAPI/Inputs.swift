import Foundation

public protocol RenderScriptInput {
    var fountainText: String { get }
}

public protocol RenderStoryboardInput {
    var umpData: Data? { get }
    var storyboardDSL: String? { get }
}

public protocol RenderSessionInput {
    var logText: String { get }
}

public protocol RenderSearchInput {
    var query: String { get }
}

public struct SimpleScriptInput: RenderScriptInput {
    public let fountainText: String
    public init(fountainText: String) {
        self.fountainText = fountainText
    }
}

public struct SimpleStoryboardInput: RenderStoryboardInput {
    public let umpData: Data?
    public let storyboardDSL: String?
    public init(umpData: Data? = nil, storyboardDSL: String? = nil) {
        self.umpData = umpData
        self.storyboardDSL = storyboardDSL
    }
}

public struct SimpleSessionInput: RenderSessionInput {
    public let logText: String
    public init(logText: String) {
        self.logText = logText
    }
}

public struct SimpleSearchInput: RenderSearchInput {
    public let query: String
    public init(query: String) {
        self.query = query
    }
}
