import AppKit

enum MenuBarTemplateMetrics {
    // The focus navigator keeps stages compact and scrolls details on short displays.
    static let width: CGFloat = 460
    static let preferredHeight: CGFloat = 586
    static var height: CGFloat {
        guard let visibleFrame = NSScreen.main?.visibleFrame else { return preferredHeight }
        return min(preferredHeight, max(1, visibleFrame.height - 32))
    }
    static let minimumInteractiveTarget: CGFloat = 44
}
