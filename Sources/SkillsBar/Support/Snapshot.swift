import AppKit
import Foundation
import SwiftUI

enum SnapshotRequest {
    static var outputPath: String? {
        let args = CommandLine.arguments
        guard let index = args.firstIndex(of: "--snapshot"), args.indices.contains(index + 1) else {
            return nil
        }
        return args[index + 1]
    }
}

enum SnapshotRenderer {
    @MainActor
    static func render(to outputURL: URL) {
        do {
            let dashboard = try DashboardLoader().loadSync()
            let model = DashboardModel(dashboard: dashboard, autorefresh: false)
            let view = DashboardView(model: model)
                .frame(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
                .background(Color.black)
            let renderer = ImageRenderer(content: view)
            renderer.scale = 2
            guard let image = renderer.cgImage else {
                throw SnapshotError.bitmapUnavailable
            }
            let bitmap = NSBitmapImageRep(cgImage: image)
            guard let data = bitmap.representation(using: .png, properties: [:]) else {
                throw SnapshotError.pngUnavailable
            }
            try data.write(to: outputURL)
            print("Wrote snapshot \(outputURL.path)")
        } catch {
            fputs("Snapshot failed: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }
}

enum SnapshotError: LocalizedError {
    case bitmapUnavailable
    case pngUnavailable

    var errorDescription: String? {
        switch self {
        case .bitmapUnavailable: return "Could not allocate snapshot bitmap."
        case .pngUnavailable: return "Could not encode snapshot PNG."
        }
    }
}
