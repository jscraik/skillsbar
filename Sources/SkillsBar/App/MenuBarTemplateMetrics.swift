import CoreGraphics

enum MenuBarTemplateMetrics {
    // The evidence popover is intentionally tall: it keeps the active gate,
    // Tessl context, and utility actions visible as one calm inspection surface.
    // Short displays still retain the internal scroll view in ReleaseEvidenceView.
    static let width: CGFloat = 420
    static let height: CGFloat = 1_180
    static let minimumInteractiveTarget: CGFloat = 44
}
