import Foundation
import SwiftUI

@main
struct SkillsBarApp: App {
    @StateObject private var model = DashboardModel()

    init() {
        if let outputPath = SnapshotRequest.outputPath {
            SnapshotRenderer.render(to: URL(fileURLWithPath: outputPath))
            Foundation.exit(0)
        }
    }

    var body: some Scene {
        MenuBarExtra {
            DashboardView(model: model)
                .frame(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
        } label: {
            SkillsMenuBarIconView(status: model.menuBarStatus)
                .accessibilityLabel("\(model.menuTitle), \(model.menuBarStatus.label)")
        }
        .menuBarExtraStyle(.window)
    }
}
