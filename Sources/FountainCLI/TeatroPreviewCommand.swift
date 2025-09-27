import ArgumentParser
import Foundation
import TeatroRenderAPI

@main
struct FountainCLI: ParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "teatro",
        abstract: "Teatro CLI",
        subcommands: [Preview.self]
    )

    struct Preview: ParsableCommand {
        static let configuration = CommandConfiguration(abstract: "Launch interactive preview")

        @Argument(help: "Path to a Fountain script (.fountain)")
        var script: String = ""

        func run() throws {
            // For now we ignore the script and just run the demo controller.
            let controller = try TeatroPreviewAPI.launchPreview(config: .init(window: .init(title: "Teatro Preview", width: 800, height: 450), fps: 60))
            try controller.runFor(seconds: 2.0)
            Thread.sleep(forTimeInterval: 2.5)
        }
    }
}
