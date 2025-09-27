import Foundation

@MainActor
public struct Animator {
    public static func renderFrames(_ frames: [Renderable], baseName: String = "frame") {
        let directory = "Animations"
        try? FileManager.default.createDirectory(atPath: directory, withIntermediateDirectories: true)
        for (i, frame) in frames.enumerated() {
            let path = "\(directory)/\(baseName)_\(i).png"
            ImageRenderer.renderToPNG(frame, to: path)
        }
    }
}
