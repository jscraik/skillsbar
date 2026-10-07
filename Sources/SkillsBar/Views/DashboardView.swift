import AppKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: DashboardModel
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.skillsBarReduceTransparencyOverride) private var reduceTransparencyOverride
    @Environment(\.skillsBarIncreasedContrastOverride) private var increasedContrastOverride
    @Environment(\.skillsBarSnapshotMode) private var snapshotMode

    var body: some View {
        ZStack {
            PopoverInteriorBackdrop(
                colorScheme: colorScheme,
                reduceTransparency: reduceTransparencyOverride ?? reduceTransparency,
                increasedContrast: increasedContrastOverride ?? (colorSchemeContrast == .increased),
                snapshotMode: snapshotMode
            )

            if model.hasLoadedEvidence {
                ReleaseEvidenceView(
                    dashboard: model.dashboard,
                    isRefreshing: model.isRefreshing,
                    isFixture: model.usesReviewFixture,
                    availableSkillPaths: model.availableSkillPaths,
                    selectedSkillPath: model.dashboard.fleet.selectedSkillPath,
                    isSkillSelectionPinned: model.isSkillSelectionPinned,
                    onSelectSkill: { model.selectSkill(path: $0) },
                    onRefresh: { Task { await model.refresh() } }
                )
                    .padding(.horizontal, 12)
                    .padding(.top, 12)
                    .padding(.bottom, 8)
            } else {
                EvidenceLoadingView()
                    .padding(24)
            }
        }
        .frame(
            width: MenuBarTemplateMetrics.width,
            height: snapshotMode ? MenuBarTemplateMetrics.preferredHeight : MenuBarTemplateMetrics.height
        )
        .foregroundStyle(.primaryText)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .onExitCommand { NSApp.keyWindow?.orderOut(nil) }
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.10), lineWidth: 1)
            .allowsHitTesting(false)
        )
        .accessibilityElement(children: .contain)
    }
}

private struct EvidenceLoadingView: View {
    var body: some View {
        VStack(spacing: 12) {
            ProgressView()
                .controlSize(.small)
            Text("Loading local evidence")
                .font(.system(size: 15, weight: .medium, design: .rounded))
            Text("Reading the selected skill and its governed receipts…")
                .font(.system(size: 12.5, weight: .regular, design: .rounded))
                .foregroundStyle(.bodyText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Loading local evidence")
    }
}

private struct PopoverInteriorBackdrop: View {
    let colorScheme: ColorScheme
    let reduceTransparency: Bool
    let increasedContrast: Bool
    let snapshotMode: Bool

    var body: some View {
        if reduceTransparency || increasedContrast || snapshotMode {
            if colorScheme == .dark {
                Color.focusDarkSurface
            } else {
                Color(nsColor: .windowBackgroundColor)
            }
        } else {
            PopoverMaterial()
        }
    }
}

private struct PopoverMaterial: NSViewRepresentable {
    func makeNSView(context: Context) -> NSVisualEffectView {
        let view = TransparentPopoverEffect()
        view.material = .popover
        view.blendingMode = .behindWindow
        view.state = .active
        return view
    }

    func updateNSView(_ view: NSVisualEffectView, context: Context) {}
}

private final class TransparentPopoverEffect: NSVisualEffectView {
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        // Behind-window material requires the hosting window to expose its backdrop.
        window?.isOpaque = false
        window?.backgroundColor = .clear
    }
}

enum TesslLogoLoader {
    static let image: NSImage? = resourceImage(named: "TesslLogo")
}

enum SkillsSDKIconLoader {
    static let image: NSImage? = resourceImage(named: "SkillsSDKIcon")

    static let menuBarImage: NSImage? = {
        guard let image = image?.copy() as? NSImage else { return nil }
        image.size = NSSize(width: 18, height: 18)
        image.isTemplate = true
        return image
    }()
}

private func resourceImage(named name: String) -> NSImage? {
    if let url = Bundle.main.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
    }
    if let url = Bundle.module.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
    }
    return nil
}

extension ShapeStyle where Self == Color {
    static var primaryText: Color { .primary }
    static var secondaryText: Color { .secondary }
    static var bodyText: Color { Color(nsColor: .secondaryLabelColor) }
}

extension Color {
    static var focusDarkSurface: Color { Color(red: 0.105, green: 0.12, blue: 0.13) }
    static var focusActionBlue: Color { Color(red: 0, green: 0.435, blue: 0.94) }
    static var focusWarningInk: Color { Color(red: 0.55, green: 0.32, blue: 0.02) }
    static var focusInfoInk: Color { Color(red: 0.04, green: 0.40, blue: 0.48) }
    static var releaseSurface: Color { Color.primary.opacity(0.04) }
    static var releaseSurfacePressed: Color { Color.primary.opacity(0.10) }
    static var releaseBorderSubtle: Color { Color.primary.opacity(0.12) }
    static var releaseMetricTrack: Color { Color.primary.opacity(0.10) }
    static var successAccent: Color { Color(red: 0.31, green: 0.89, blue: 0.50) }
    static var warningAccent: Color { Color(red: 1.0, green: 0.69, blue: 0.08) }
    static var advisoryAccent: Color { Color(red: 0.16, green: 0.84, blue: 0.94) }
    static var pendingAccent: Color { Color(red: 0.56, green: 0.58, blue: 0.64) }
    static var dangerAccent: Color { Color(red: 1.0, green: 0.40, blue: 0.34) }
}
