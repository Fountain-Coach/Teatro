import Foundation
import ArgumentParser
import Teatro

public protocol RenderTargetProtocol {
    static var name: String { get }
    static var aliases: [String] { get }
    static func render(view: Renderable, output: String?) throws
}

public extension RenderTargetProtocol {
    static func write(_ string: String, to path: String?, defaultName: String) throws {
        let isStdout = path == nil
        if isStdout {
            print(string)
        } else {
            let file = path ?? defaultName
            try string.write(toFile: file, atomically: true, encoding: .utf8)
            print("Wrote \(file)")
        }
    }

    static func writeData(_ data: Data, to path: String?, defaultName: String) throws {
        let isStdout = path == nil
        if isStdout {
            let hex = data.map { String(format: "%02X", $0) }.joined()
            print(hex)
        } else {
            let url = URL(fileURLWithPath: path ?? defaultName)
            try data.write(to: url)
            print("Wrote \(url.path)")
        }
    }
}
