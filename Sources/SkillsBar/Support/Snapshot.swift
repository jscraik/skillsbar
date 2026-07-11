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

struct SnapshotConfiguration {
    var dynamicTypeSize: DynamicTypeSize = .large
    var reduceTransparency = false
    var increasedContrast = false

    static let `default` = SnapshotConfiguration()
}

private struct ReduceTransparencyOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

private struct IncreasedContrastOverrideKey: EnvironmentKey {
    static let defaultValue: Bool? = nil
}

extension EnvironmentValues {
    var skillsBarReduceTransparencyOverride: Bool? {
        get { self[ReduceTransparencyOverrideKey.self] }
        set { self[ReduceTransparencyOverrideKey.self] = newValue }
    }

    var skillsBarIncreasedContrastOverride: Bool? {
        get { self[IncreasedContrastOverrideKey.self] }
        set { self[IncreasedContrastOverrideKey.self] = newValue }
    }
}

enum SnapshotRenderer {
    @MainActor
    static func render(to outputURL: URL) {
        do {
            _ = NSApplication.shared
            let dashboard = try DashboardDataSource().loadSync()
            try render(dashboard: dashboard, to: outputURL)
            print("Wrote snapshot \(outputURL.path)")
        } catch {
            fputs("Snapshot failed: \(error.localizedDescription)\n", stderr)
            Foundation.exit(1)
        }
    }

    @MainActor
    static func render(dashboard: SkillDashboard, to outputURL: URL) throws {
        try render(dashboard: dashboard, configuration: .default, to: outputURL)
    }

    @MainActor
    static func render(
        dashboard: SkillDashboard,
        configuration: SnapshotConfiguration,
        to outputURL: URL
    ) throws {
        let model = DashboardModel(dashboard: dashboard, autorefresh: false)
        let view = DashboardView(model: model)
            .frame(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
            .background(Color.black)
            .environment(\.dynamicTypeSize, configuration.dynamicTypeSize)
            .environment(\.skillsBarReduceTransparencyOverride, configuration.reduceTransparency)
            .environment(\.skillsBarIncreasedContrastOverride, configuration.increasedContrast)
        let hostingView = NSHostingView(rootView: view)
        hostingView.frame = NSRect(
            origin: .zero,
            size: NSSize(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
        )
        hostingView.layoutSubtreeIfNeeded()
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.05))
        hostingView.layoutSubtreeIfNeeded()
        hostingView.displayIfNeeded()
        guard let bitmap = hostingView.bitmapImageRepForCachingDisplay(in: hostingView.bounds) else {
            throw SnapshotError.bitmapUnavailable
        }
        hostingView.cacheDisplay(in: hostingView.bounds, to: bitmap)
        guard let data = bitmap.representation(using: .png, properties: [:]) else {
            throw SnapshotError.pngUnavailable
        }
        try data.write(to: outputURL)
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
