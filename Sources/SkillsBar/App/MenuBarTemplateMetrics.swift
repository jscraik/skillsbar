import AppKit

enum MenuBarTemplateMetrics {
    // The evidence popover is intentionally tall: it keeps the active gate,
    // Tessl context, and utility actions visible as one calm inspection surface.
    // Short displays still retain the internal scroll view in ReleaseEvidenceView.
    static let width: CGFloat = 420
    static let preferredHeight: CGFloat = 1_180
    static var height: CGFloat {
        guard let visibleFrame = NSScreen.main?.visibleFrame else { return preferredHeight }
        return min(preferredHeight, max(1, visibleFrame.height - 32))
    }
    static let minimumInteractiveTarget: CGFloat = 44
}
