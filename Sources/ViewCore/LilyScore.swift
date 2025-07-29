import Foundation

public struct LilyScore: Renderable {
    public let content: String

    public init(_ content: String) {
        self.content = content
    }

    public func render() -> String {
        content
    }

    public func renderToPDF(filename: String = "score") {
        let tempPath = "/tmp/\(filename).ly"
        try? content.write(toFile: tempPath, atomically: true, encoding: .utf8)

        let task = Process()
        task.launchPath = "/usr/bin/env"
        task.arguments = ["lilypond", "-o", filename, tempPath]
        try? task.run()
        task.waitUntilExit()
    }
}
