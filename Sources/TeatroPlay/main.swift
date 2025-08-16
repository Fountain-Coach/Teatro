import Foundation

@main
struct TeatroPlay {
  /// Explicit, concurrency-safe entry point. No top-level execution elsewhere.
  @MainActor
  static func main() async {
    do {
      let app = try TeatroApp()
      try await app.run()
    } catch {
      FileHandle.standardError.write(Data("TeatroPlay failed: \(error)\n".utf8))
      // Optionally: exit(EXIT_FAILURE)
    }
  }
}

