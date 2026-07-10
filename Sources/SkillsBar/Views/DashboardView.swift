import AppKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: DashboardModel
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.skillsBarReduceTransparencyOverride) private var reduceTransparencyOverride
    @Environment(\.skillsBarIncreasedContrastOverride) private var increasedContrastOverride

    var body: some View {
        let presentation = ReviewPresentation(dashboard: model.dashboard)

        ZStack {
            PopoverInteriorBackdrop(
                reduceTransparency: reduceTransparency || reduceTransparencyOverride == true,
                increasedContrast: colorSchemeContrast == .increased || increasedContrastOverride == true
            )

            ScrollView {
                VStack(spacing: 0) {
                    ReviewHeader(dashboard: model.dashboard)
                    QuietDivider()
                    PackageIdentity(model: model, dashboard: model.dashboard, presentation: presentation)
                    ReviewTriggerCard(dashboard: model.dashboard)
                        .padding(.top, 10)
                    RegistryEvidenceRow(dashboard: model.dashboard)
                        .padding(.top, 10)
                    QuietDivider()
                        .padding(.top, 8)
                    EvidenceBridge(presentation: presentation)
                    QuietDivider()
                    ReviewAction(presentation: presentation)
                        .padding(.top, 10)
                }
                .padding(.horizontal, 18)
                .padding(.top, 16)
                .padding(.bottom, 14)
            }
            .scrollIndicators(.hidden)
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
        .foregroundStyle(.primaryText)
        .accessibilityElement(children: .contain)
    }
}

private struct PopoverInteriorBackdrop: View {
    let reduceTransparency: Bool
    let increasedContrast: Bool

    var body: some View {
        Rectangle()
            .fill(
                reduceTransparency || increasedContrast
                    ? AnyShapeStyle(Color(red: 0.025, green: 0.04, blue: 0.05))
                    : AnyShapeStyle(.ultraThinMaterial)
            )
            .overlay(
                LinearGradient(
                    colors: [
                        Color(red: 0.035, green: 0.055, blue: 0.065).opacity(0.88),
                        Color(red: 0.025, green: 0.045, blue: 0.055).opacity(0.94)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
    }
}

private struct ReviewHeader: View {
    let dashboard: SkillDashboard

    private var presentation: ReviewPresentation { ReviewPresentation(dashboard: dashboard) }

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            SkillsSDKLogoView(size: 42)
                .padding(.top, 2)

            VStack(alignment: .leading, spacing: 6) {
                Text("Skills SDK")
                    .scaledSystemFont(size: 13, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.bodyText)

                Text(dashboard.verdictTitle)
                    .scaledSystemFont(size: 25, weight: .semibold, relativeTo: .title)
                    .foregroundStyle(presentation.emphasisTone.color)

                Text(dashboard.verdictDetail)
                    .scaledSystemFont(size: 14, weight: .regular, relativeTo: .body)
                    .foregroundStyle(.bodyText)
            }

            Spacer(minLength: 8)

            VStack(spacing: 5) {
                ScoreHex(score: dashboard.scoreText, tone: presentation.emphasisTone)
                Text("review score")
                    .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
            }
        }
        .frame(minHeight: 108, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Skills SDK. \(dashboard.verdictTitle). \(dashboard.verdictDetail). Review score \(dashboard.scoreText).")
    }
}

private struct ScoreHex: View {
    let score: String
    let tone: StatusTone

    var body: some View {
        ZStack {
            RoundedHexagon(cornerRadius: 5)
                .fill(
                    LinearGradient(
                        colors: [Color.black.opacity(0.72), Color.black.opacity(0.48)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            RoundedHexagon(cornerRadius: 5)
                .stroke(tone.color.opacity(0.30), lineWidth: 5)
                .padding(2.5)
            RoundedHexagon(cornerRadius: 5)
                .stroke(tone.color, lineWidth: 1.5)
                .padding(1)
            Text(score)
                .font(.system(size: 32, weight: .semibold, design: .rounded))
                .foregroundStyle(tone.color)
        }
        .frame(width: 72, height: 82)
        .shadow(color: tone.color.opacity(0.14), radius: 5)
        .accessibilityHidden(true)
    }
}

private struct PackageIdentity: View {
    @ObservedObject var model: DashboardModel
    let dashboard: SkillDashboard
    let presentation: ReviewPresentation

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 8) {
                Text(presentation.packageIdentity)
                    .scaledSystemFont(size: 17, weight: .medium, relativeTo: .headline)
                    .foregroundStyle(.primaryText)
                    .lineLimit(2)

                Spacer(minLength: 8)

                Menu {
                    ForEach(model.availableSkillPaths, id: \.self) { skillPath in
                        Button {
                            model.selectSkill(path: skillPath)
                        } label: {
                            if skillPath == dashboard.fleet.selectedSkillPath {
                                Label(skillPath, systemImage: "checkmark")
                            } else {
                                Text(skillPath)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "arrow.triangle.2.circlepath")
                        .font(.system(size: 13, weight: .medium))
                        .frame(width: 28, height: 28)
                }
                .disabled(model.availableSkillPaths.isEmpty || model.isSkillSelectionPinned)
                .help(model.isSkillSelectionPinned ? "Skill selection is pinned by AGENT_SKILL_PATH" : "Select local skill")
                .accessibilityLabel("Select local skill")

            }

            Text(dashboard.description)
                .scaledSystemFont(size: 13, weight: .regular, relativeTo: .subheadline)
                .foregroundStyle(.bodyText)
                .lineLimit(2)
        }
        .frame(minHeight: 58, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct ReviewTriggerCard: View {
    let dashboard: SkillDashboard

    private var presentation: ReviewPresentation { ReviewPresentation(dashboard: dashboard) }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: presentation.triggerSystemName)
                    .font(.system(size: 24, weight: .medium))
                    .foregroundStyle(presentation.emphasisTone.color)
                    .frame(width: 32, height: 32)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 8) {
                    Text(presentation.triggerTitle)
                        .scaledSystemFont(size: 17, weight: .semibold, relativeTo: .headline)
                        .foregroundStyle(presentation.emphasisTone.color)

                    HStack(spacing: 8) {
                        SkillsSDKLogoView(size: 24)
                        Text("Skills SDK")
                            .scaledSystemFont(size: 14, weight: .medium, relativeTo: .subheadline)
                        Text("LOCAL")
                            .scaledSystemFont(size: 10, weight: .semibold, relativeTo: .caption2)
                            .foregroundStyle(Color.successAccent)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.successAccent.opacity(0.12))
                            .clipShape(Capsule())
                        Text(dashboard.displayName)
                            .scaledSystemFont(size: 12, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                            .lineLimit(1)
                    }

                    HStack(spacing: 9) {
                        Text(dashboard.scoreText)
                            .foregroundStyle(presentation.emphasisTone.color)
                        Text("•")
                            .foregroundStyle(.secondaryText)
                        Text(dashboard.impact.statusLabel)
                        Text("•")
                            .foregroundStyle(.secondaryText)
                        Text(dashboard.security.statusDisplay)
                            .foregroundStyle(dashboard.security.tone.color)
                    }
                    .scaledSystemFont(size: 13, weight: .medium, design: .rounded, relativeTo: .subheadline)
                }
            }

            QuietDivider()
                .padding(.vertical, 13)

            HStack(alignment: .top, spacing: 0) {
                MetricColumn(
                    title: "Quality",
                    value: dashboard.quality.statusLabel,
                    detail: presentation.qualityDetail,
                    tone: dashboard.quality.tone
                )
                VerticalDivider()
                MetricColumn(
                    title: "Impact",
                    value: dashboard.impact.statusLabel,
                    detail: presentation.impactDetail,
                    tone: dashboard.impact.tone
                )
                VerticalDivider()
                MetricColumn(
                    title: "Security",
                    value: dashboard.security.statusDisplay,
                    detail: dashboard.security.severityLine.replacingOccurrences(of: ", ", with: ",\n"),
                    tone: dashboard.security.tone
                )
            }
            .frame(minHeight: 82)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color.black.opacity(0.20))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(alignment: .leading) {
            RoundedRectangle(cornerRadius: 2, style: .continuous)
                .fill(presentation.emphasisTone.color)
                .frame(width: 3)
                .padding(.vertical, 2)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(presentation.triggerTitle). Local Skills SDK. Score \(dashboard.scoreText). Quality \(dashboard.quality.statusLabel). Impact \(dashboard.impact.statusLabel). Security \(dashboard.security.statusDisplay), \(dashboard.security.severityLine).")
    }
}

private struct MetricColumn: View {
    let title: String
    let value: String
    let detail: String
    let tone: StatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title)
                .scaledSystemFont(size: 12, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.bodyText)
            Text(value)
                .scaledSystemFont(size: 18, weight: .medium, design: .rounded, relativeTo: .title3)
                .foregroundStyle(tone.color)
                .lineLimit(1)
            Text(detail)
                .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.bodyText)
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 10)
    }
}

private struct RegistryEvidenceRow: View {
    let dashboard: SkillDashboard

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            TesslLogoView(size: 42)

            VStack(alignment: .leading, spacing: 7) {
                HStack(spacing: 7) {
                    Text("Tessl Registry")
                        .scaledSystemFont(size: 15, weight: .medium, relativeTo: .headline)
                        .foregroundStyle(.primaryText)
                    Text("•")
                        .foregroundStyle(.secondaryText)
                    Text(dashboard.registryPath)
                        .scaledSystemFont(size: 12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.88)
                }

                HStack(spacing: 7) {
                    Text("v\(dashboard.tessl.registryVersion ?? dashboard.version)  •  score \(dashboard.tessl.registryResultLabel)")
                        .scaledSystemFont(size: 12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                    if let visibility = dashboard.tessl.registryVisibilityDisplay {
                        RegistryVisibilityBadge(visibility: visibility)
                    }
                }

                HStack(spacing: 6) {
                    RegistryMetric(
                        label: "Quality",
                        value: dashboard.tessl.registryQualityScore.map { "\($0)%" } ?? "--",
                        tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryQualityScore)
                    )
                    Text("•").foregroundStyle(.secondaryText)
                    RegistryMetric(
                        label: "Impact",
                        value: dashboard.tessl.registryImpactScore.map { "\($0)%" } ?? "--",
                        tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryImpactScore)
                    )
                    Text("•").foregroundStyle(.secondaryText)
                    RegistryMetric(
                        label: "Security",
                        value: dashboard.tessl.registrySecurityDisplay,
                        tone: dashboard.tessl.registrySecurityTone
                    )
                }
            }
        }
        .frame(minHeight: 78, alignment: .center)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct RegistryVisibilityBadge: View {
    let visibility: String

    var body: some View {
        Text(visibility)
            .scaledSystemFont(size: 10, weight: .medium, relativeTo: .caption2)
            .foregroundStyle(.bodyText)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.white.opacity(0.065))
            .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 5, style: .continuous)
                    .stroke(Color.white.opacity(0.12), lineWidth: 1)
            )
            .accessibilityLabel("Registry visibility: \(visibility)")
    }
}

private struct RegistryMetric: View {
    let label: String
    let value: String
    let tone: StatusTone

    var body: some View {
        Text(label + " ")
            .foregroundStyle(.bodyText)
        + Text(value)
            .foregroundStyle(tone.color)
    }
}

private struct EvidenceBridge: View {
    let presentation: ReviewPresentation

    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .bottomTrailing) {
                Circle()
                    .fill(presentation.bridgeTone.color.opacity(0.18))
                    .overlay(Circle().stroke(presentation.bridgeTone.color.opacity(0.55), lineWidth: 1.5))
                    .frame(width: 38, height: 38)
                Image(systemName: presentation.bridgeSystemName)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(Color.white.opacity(0.92))
                    .frame(width: 38, height: 38)
                if presentation.showsBridgeWarningBadge {
                    Circle()
                        .fill(Color.warningAccent)
                        .frame(width: 10, height: 10)
                        .overlay(Circle().stroke(Color.black.opacity(0.45), lineWidth: 1))
                        .offset(x: 2, y: 2)
                }
            }
            .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 5) {
                Text(presentation.bridgeTitle)
                    .scaledSystemFont(size: 14, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.primaryText)
                Text(presentation.bridgeDetail)
                    .scaledSystemFont(size: 12, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
            }
        }
        .frame(minHeight: 58)
        .frame(maxWidth: .infinity, alignment: .leading)
        .accessibilityElement(children: .combine)
    }
}

private struct ReviewAction: View {
    let presentation: ReviewPresentation
    @ObservedObject private var feedback = CopyFeedbackModel.shared
    @FocusState private var copyFocused: Bool

    private var copied: Bool {
        feedback.copiedCommand == presentation.actionCommand
    }

    private var copyFailed: Bool { feedback.copyError != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("ACTION")
                .scaledSystemFont(size: 10, weight: .medium, relativeTo: .caption2)
                .foregroundStyle(.secondaryText)

            VStack(spacing: 8) {
                HStack(spacing: 11) {
                    Image(systemName: "terminal")
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(.primaryText)
                        .frame(width: 38, height: 38)
                        .background(Color.white.opacity(0.045))
                        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8, style: .continuous)
                                .stroke(Color.white.opacity(0.14), lineWidth: 1)
                        )
                        .accessibilityHidden(true)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(copied ? "Inspect command copied" : feedback.copyError ?? presentation.actionTitle)
                            .scaledSystemFont(size: 14, weight: .medium, relativeTo: .subheadline)
                            .foregroundStyle(.primaryText)
                        Text(presentation.actionDetail)
                            .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                    }

                    Spacer(minLength: 8)

                    Button {
                        feedback.copy(presentation.actionCommand)
                    } label: {
                        Image(systemName: copied ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 15, weight: .semibold))
                            .frame(width: 38, height: 38)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(ImmediateFeedbackButtonStyle())
                    .foregroundStyle(copyFailed ? Color.dangerAccent : copied ? Color.successAccent : .primaryText)
                    .background(Color.white.opacity(copyFocused ? 0.085 : 0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(copyFocused ? Color.focusAccent : Color.white.opacity(0.14), lineWidth: copyFocused ? 2 : 1)
                    )
                    .focused($copyFocused)
                    .help("Copy inspect command")
                    .accessibilityLabel(copyFailed ? "Could not copy inspect command" : copied ? "Inspect command copied" : "Copy inspect command")
                }

                Text(presentation.actionCommand)
                    .scaledSystemFont(size: 10.5, weight: .regular, design: .monospaced, relativeTo: .caption)
                    .foregroundStyle(Color.white.opacity(0.80))
                    .lineLimit(3)
                    .frame(maxWidth: .infinity, minHeight: 42, alignment: .topLeading)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 7)
                    .background(Color.black.opacity(0.26))
                    .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 7, style: .continuous)
                            .stroke(Color.white.opacity(0.10), lineWidth: 1)
                    )
                    .accessibilityLabel("Inspect command")
                    .accessibilityValue(presentation.actionCommand)
            }
            .padding(10)
            .background(Color.white.opacity(0.035))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(Color.white.opacity(0.13), lineWidth: 1)
            )
        }
    }
}

private struct ImmediateFeedbackButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0))
            .opacity(configuration.isPressed ? 0.78 : 1)
    }
}

private struct ScaledSystemFontModifier: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    init(size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo textStyle: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: textStyle)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

private extension View {
    func scaledSystemFont(
        size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .default,
        relativeTo textStyle: Font.TextStyle
    ) -> some View {
        modifier(ScaledSystemFontModifier(size: size, weight: weight, design: design, relativeTo: textStyle))
    }
}

private struct SkillsSDKLogoView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = SkillsSDKIconLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: size * 0.48, weight: .medium))
                    .foregroundStyle(.primaryText)
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: max(6, size * 0.22), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: max(6, size * 0.22), style: .continuous)
                .stroke(Color.white.opacity(0.13), lineWidth: 1)
        )
    }
}

private struct TesslLogoView: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = TesslLogoLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: size * 0.48, weight: .medium))
                    .foregroundStyle(.primaryText)
            }
        }
        .frame(width: size, height: size)
        .background(Color.black.opacity(0.30))
        .clipShape(RoundedRectangle(cornerRadius: max(6, size * 0.22), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: max(6, size * 0.22), style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
        )
    }
}

private struct QuietDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.11))
            .frame(height: 1)
    }
}

private struct VerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1)
    }
}

private struct RoundedHexagon: Shape {
    let cornerRadius: CGFloat

    func path(in rect: CGRect) -> Path {
        let vertices = [
            CGPoint(x: rect.midX, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.25),
            CGPoint(x: rect.maxX, y: rect.minY + rect.height * 0.75),
            CGPoint(x: rect.midX, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.75),
            CGPoint(x: rect.minX, y: rect.minY + rect.height * 0.25)
        ]

        func insetPoint(from vertex: CGPoint, toward neighbor: CGPoint) -> CGPoint {
            let dx = neighbor.x - vertex.x
            let dy = neighbor.y - vertex.y
            let length = max(hypot(dx, dy), 1)
            let distance = min(cornerRadius, length * 0.25)
            return CGPoint(
                x: vertex.x + dx / length * distance,
                y: vertex.y + dy / length * distance
            )
        }

        var path = Path()
        let firstEntry = insetPoint(from: vertices[0], toward: vertices[5])
        path.move(to: firstEntry)

        for index in vertices.indices {
            let vertex = vertices[index]
            let next = vertices[(index + 1) % vertices.count]
            let exit = insetPoint(from: vertex, toward: next)
            let nextEntry = insetPoint(from: next, toward: vertex)
            path.addQuadCurve(to: exit, control: vertex)
            path.addLine(to: nextEntry)
        }
        path.closeSubpath()
        return path
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
    if let url = Bundle.module.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
    }
    if let url = Bundle.main.url(forResource: name, withExtension: "png") {
        return NSImage(contentsOf: url)
    }
    return nil
}

extension ShapeStyle where Self == Color {
    static var primaryText: Color { Color.white.opacity(0.96) }
    static var secondaryText: Color { Color(red: 0.55, green: 0.57, blue: 0.62) }
    static var bodyText: Color { Color(red: 0.69, green: 0.70, blue: 0.75) }
}

extension Color {
    static var successAccent: Color { Color(red: 0.31, green: 0.89, blue: 0.50) }
    static var warningAccent: Color { Color(red: 1.0, green: 0.69, blue: 0.08) }
    static var advisoryAccent: Color { Color(red: 0.16, green: 0.84, blue: 0.94) }
    static var pendingAccent: Color { Color(red: 0.56, green: 0.58, blue: 0.64) }
    static var dangerAccent: Color { Color(red: 1.0, green: 0.40, blue: 0.34) }
    static var focusAccent: Color { Color(red: 0.57, green: 0.63, blue: 0.98) }
}
