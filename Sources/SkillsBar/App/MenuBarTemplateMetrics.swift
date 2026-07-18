import CoreGraphics

enum MenuBarTemplateMetrics {
    // Keep the MenuBarExtra comfortably within a laptop-height visible frame
    // so it reads as a menu-bar utility, not a temporary application window.
    // The full evidence stack remains available through DashboardView's
    // internal scroll region.
    static let width: CGFloat = 404
    static let height: CGFloat = 560
}
