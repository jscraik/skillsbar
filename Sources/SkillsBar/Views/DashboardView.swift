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
                    .padding(.horizontal, 16)
                    .padding(.top, 32)
                    .padding(.bottom, 18)
            } else {
                EvidenceLoadingView()
                    .padding(24)
            }
        }
        .frame(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
        .foregroundStyle(.primaryText)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        .overlay(alignment: .topTrailing) {
            PopoverCloseButton()
                .padding(13)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.primary.opacity(0.32), Color.primary.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                ),
                lineWidth: 1
            )
            .allowsHitTesting(false)
        )
        .shadow(color: Color.black.opacity(0.18), radius: 22, y: 12)
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

private struct PopoverCloseButton: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var hover = PopoverCloseHoverModel()

    var body: some View {
        Button { closePopover() } label: {
            ZStack {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .frame(width: 30, height: 30)
                    .background(Color.primary.opacity(hover.isHovering ? 0.075 : 0.025))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(hover.isHovering ? 0.16 : 0.06), lineWidth: 1))
            }
            .frame(
                width: MenuBarTemplateMetrics.minimumInteractiveTarget,
                height: MenuBarTemplateMetrics.minimumInteractiveTarget
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(ImmediateFeedbackButtonStyle())
        .keyboardShortcut(.cancelAction)
        .foregroundStyle(.bodyText)
        .contentShape(Rectangle())
        .onHover { hover.isHovering = $0 }
        .help("Close SkillsBar")
        .accessibilityLabel("Close SkillsBar")
    }

    private func closePopover() {
        let popoverWindow = NSApp.keyWindow
        dismiss()
        popoverWindow?.orderOut(nil)
    }
}

@MainActor
private final class PopoverCloseHoverModel: ObservableObject {
    @Published var isHovering = false
}

private struct PopoverInteriorBackdrop: View {
    let colorScheme: ColorScheme
    let reduceTransparency: Bool
    let increasedContrast: Bool
    let snapshotMode: Bool

    var body: some View {
        ZStack {
            Color(nsColor: colorScheme == .dark ? .underPageBackgroundColor : .windowBackgroundColor)
            if !reduceTransparency && !increasedContrast && !snapshotMode {
                Rectangle()
                    .fill(.regularMaterial)
                    .opacity(0.78)
            }
        }
        .overlay(
            LinearGradient(
                colors: reduceTransparency || increasedContrast
                    ? [
                        Color(nsColor: colorScheme == .dark ? .underPageBackgroundColor : .windowBackgroundColor),
                        Color(nsColor: .controlBackgroundColor)
                    ]
                    : [
                        Color.primary.opacity(0.025),
                        .clear
                    ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .overlay(alignment: .top) {
            LinearGradient(
                colors: [Color.primary.opacity(0.055), .clear],
                startPoint: .top,
                endPoint: .bottom
            )
            .frame(height: 110)
            .allowsHitTesting(false)
        }
    }
}

private struct ImmediateFeedbackButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.primary.opacity(configuration.isPressed ? 0.10 : 0))
            .opacity(configuration.isPressed ? 0.78 : 1)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.10), value: configuration.isPressed)
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
    static var bodyText: Color { .secondary.opacity(0.88) }
}

extension Color {
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
