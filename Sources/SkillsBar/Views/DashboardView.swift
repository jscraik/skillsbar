import AppKit
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: DashboardModel
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var colorSchemeContrast
    @Environment(\.skillsBarReduceTransparencyOverride) private var reduceTransparencyOverride
    @Environment(\.skillsBarIncreasedContrastOverride) private var increasedContrastOverride
    @Environment(\.skillsBarSnapshotMode) private var snapshotMode

    var body: some View {
        ZStack {
            PopoverInteriorBackdrop(
                reduceTransparency: reduceTransparencyOverride ?? reduceTransparency,
                increasedContrast: increasedContrastOverride ?? (colorSchemeContrast == .increased),
                snapshotMode: snapshotMode
            )

            ReleaseEvidenceView(dashboard: model.dashboard, isRefreshing: model.isRefreshing)
                .padding(.horizontal, 12)
                .padding(.vertical, 12)
        }
        .frame(width: MenuBarTemplateMetrics.width, height: MenuBarTemplateMetrics.height)
        .foregroundStyle(.primaryText)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(alignment: .topTrailing) {
            PopoverCloseButton()
                .padding(10)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.46), Color.white.opacity(0.12)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.30), radius: 18, y: 9)
        .preferredColorScheme(.dark)
        .accessibilityElement(children: .contain)
    }
}

private struct PopoverCloseButton: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var hover = PopoverCloseHoverModel()

    var body: some View {
        Button { closePopover() } label: {
            Image(systemName: "xmark")
                .font(.system(size: 10, weight: .semibold))
                .frame(width: 30, height: 30)
                .background(Color.white.opacity(hover.isHovering ? 0.075 : 0.025))
                .clipShape(Circle())
                .overlay(Circle().stroke(Color.white.opacity(hover.isHovering ? 0.16 : 0.06), lineWidth: 1))
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

private struct PipelinePostureHeader: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool

    private var candidate: PipelineCandidate { dashboard.pipeline }
    private var active: PipelineStageReceipt? { candidate.activeReceipt }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            SkillsSDKLogoView(size: 46)
                .padding(.top, 4)

            VStack(alignment: .leading, spacing: 6) {
                Text("Skills SDK")
                    .scaledSystemFont(size: 14, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.bodyText)
                Text(active?.evidenceStatus == .reviewRequired ? "Candidate requires review" : "Current local candidate")
                    .scaledSystemFont(size: 15.5, weight: .medium, relativeTo: .title2)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.90)
                packageIdentityLabel
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Spacer(minLength: 8)

            RefreshStatus(isRefreshing: isRefreshing)

            PipelineReadinessSummary(candidate: candidate)
                .frame(width: 112)
        }
        .frame(minHeight: 96, alignment: .top)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Skills SDK. Current local candidate. Pipeline readiness \(candidate.postureScore) out of 100. \(candidate.evidencedStageCount) of 6 stages evidenced.")
    }

    private var packageIdentityLabel: some View {
        HStack(spacing: 6) {
            Text(dashboard.registryPath)
                .scaledSystemFont(size: 9.5, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.bodyText)
                .lineLimit(1)
                .minimumScaleFactor(0.75)
                .allowsTightening(true)
            Text("LOCAL")
                .scaledSystemFont(size: 8.5, weight: .medium, relativeTo: .caption2)
                .foregroundStyle(.bodyText)
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .overlay(
                    RoundedRectangle(cornerRadius: 5, style: .continuous)
                        .stroke(Color.white.opacity(0.20), lineWidth: 1)
                )
        }
    }
}

private struct PipelineReadinessSummary: View {
    let candidate: PipelineCandidate

    var body: some View {
        VStack(alignment: .trailing, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(candidate.postureScore)")
                    .font(.system(size: 22, weight: .semibold, design: .rounded))
                    .foregroundStyle(candidate.activeReceipt?.evidenceStatus.tone.color ?? Color.successAccent)
                Text("/ 100")
                    .scaledSystemFont(size: 10, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
            }
            .monospacedDigit()

            WeightedReadinessBar(candidate: candidate)
                .frame(height: 6)

            Text("pipeline readiness")
                .scaledSystemFont(size: 9.5, weight: .semibold, relativeTo: .caption)
                .foregroundStyle(.bodyText)
            Text("\(candidate.evidencedStageCount) of 6 stages evidenced")
                .scaledSystemFont(size: 9, weight: .regular, relativeTo: .caption2)
                .foregroundStyle(.secondaryText)
                .lineLimit(1)
                .minimumScaleFactor(0.90)
        }
        .padding(.top, 4)
        .accessibilityHidden(true)
    }
}

private struct WeightedReadinessBar: View {
    let candidate: PipelineCandidate
    private let spacing: CGFloat = 2

    var body: some View {
        GeometryReader { geometry in
            let receipts = candidate.orderedReceipts
            let availableWidth = max(0, geometry.size.width - spacing * CGFloat(max(0, receipts.count - 1)))

            HStack(spacing: spacing) {
                ForEach(receipts) { receipt in
                    let segmentWidth = availableWidth * CGFloat(receipt.stage.weight) / 100
                    let earned = candidate.contribution(for: receipt)
                    let earnedFraction = CGFloat(earned) / CGFloat(receipt.stage.weight)

                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(Color.white.opacity(0.10))
                        if earned > 0 {
                            Capsule()
                                .fill(receipt.evidenceStatus.tone.color)
                                .frame(width: segmentWidth * min(max(earnedFraction, 0), 1))
                        }
                    }
                    .frame(width: segmentWidth)
                }
            }
        }
        .accessibilityHidden(true)
    }
}

private struct PipelineStageCard: View {
    let dashboard: SkillDashboard

    private var candidate: PipelineCandidate { dashboard.pipeline }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Text("SDK PIPELINE")
                    .scaledSystemFont(size: 12, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
                Spacer()
                Text("Contributes")
                    .scaledSystemFont(size: 12, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 8)

            QuietDivider()

            ZStack(alignment: .topLeading) {
                PipelineConnector()
                    .padding(.leading, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 18)

                VStack(spacing: 0) {
                    ForEach(Array(candidate.orderedReceipts.enumerated()), id: \.element.id) { index, receipt in
                        PipelineStageRow(
                            receipt: receipt,
                            contribution: candidate.contribution(for: receipt),
                            isActive: receipt.stage == candidate.activeReceipt?.stage,
                            detail: detail(for: receipt)
                        )
                        if index > 1 && index < candidate.orderedReceipts.count - 1 {
                            QuietDivider()
                                .padding(.leading, 50)
                        }
                    }
                }
            }

            Text("Unproven or stale stages contribute 0.")
                .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.secondaryText)
                .padding(.horizontal, 6)
                .padding(.top, 7)
        }
        .accessibilityElement(children: .contain)
    }

    private func detail(for receipt: PipelineStageReceipt) -> String {
        if receipt.stage == .securityReview {
            return "\(dashboard.security.statusDisplay) - resolve before local proof"
        }
        return receipt.nextAction
    }
}

private struct PipelineConnector: View {
    var body: some View {
        VStack(spacing: 0) {
            Rectangle()
                .fill(Color.successAccent.opacity(0.38))
                .frame(width: 1, height: 40)
            GeometryReader { geometry in
                Path { path in
                    path.move(to: CGPoint(x: 0.5, y: 0))
                    path.addLine(to: CGPoint(x: 0.5, y: geometry.size.height))
                }
                .stroke(
                    Color.secondaryText.opacity(0.42),
                    style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4])
                )
            }
            .frame(width: 1)
        }
        .frame(width: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct PipelineStageRow: View {
    let receipt: PipelineStageReceipt
    let contribution: Int
    let isActive: Bool
    let detail: String
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    private var symbol: String {
        switch receipt.evidenceStatus {
        case .passed: return "checkmark.circle"
        case .reviewRequired: return "exclamationmark.triangle"
        case .blocked: return "xmark.octagon.fill"
        case .held: return "pause.circle"
        case .unproven: return "lock.fill"
        case .stale: return "clock.fill"
        }
    }

    private var symbolSize: CGFloat {
        switch receipt.evidenceStatus {
        case .passed: return 20
        case .reviewRequired, .blocked: return 22
        case .held, .unproven, .stale: return 15
        }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: symbolSize, weight: .medium))
                .foregroundStyle(receipt.evidenceStatus.tone.color)
                .frame(width: 28, alignment: .center)
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 3) {
                Text(receipt.stage.title)
                    .scaledSystemFont(size: 14, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.primaryText)
                Text(receipt.stageScore.map(String.init) ?? receipt.evidenceStatus.label)
                    .scaledSystemFont(size: isActive ? 14 : 12, weight: isActive ? .medium : .regular, design: .rounded, relativeTo: .caption)
                    .foregroundStyle(receipt.evidenceStatus.tone.color)
                if isActive, !detail.isEmpty {
                    Text(detail)
                        .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .lineLimit(1)
                }
            }
            Spacer(minLength: 8)
            Text(receipt.evidenceStatus.isCurrentEvidence ? "\(contribution) / \(receipt.stage.weight)" : "—")
                .scaledSystemFont(size: 14, weight: .medium, design: .rounded, relativeTo: .subheadline)
                .monospacedDigit()
                .foregroundStyle(receipt.evidenceStatus.tone.color)
                .frame(width: 52, alignment: .trailing)
            if isActive, !receipt.command.isEmpty {
                Button { feedback.copy(receipt.command) } label: {
                    Image(systemName: feedback.copiedCommand == receipt.command ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 17, weight: .medium))
                        .frame(width: 32, height: 32)
                        .copyConfirmationMotion(isConfirmed: feedback.copiedCommand == receipt.command)
                }
                .buttonStyle(ImmediateFeedbackButtonStyle())
                .foregroundStyle(feedback.copiedCommand == receipt.command ? Color.successAccent : Color.primaryText)
                .help("Copy \(receipt.stage.title) inspection command")
                .accessibilityLabel("Copy \(receipt.stage.title) inspection command")
            }
        }
        .padding(.horizontal, isActive ? 10 : 6)
        .padding(.vertical, isActive ? 8 : 6)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.090),
                                receipt.evidenceStatus.tone.color.opacity(0.030),
                                Color.black.opacity(0.055)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
            }
        }
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.25), Color.white.opacity(0.075)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        }
        .shadow(color: isActive ? Color.black.opacity(0.16) : .clear, radius: 7, y: 3)
        .overlay(alignment: .leading) {
            if isActive {
                UnevenRoundedRectangle(
                    topLeadingRadius: 9,
                    bottomLeadingRadius: 9,
                    bottomTrailingRadius: 0,
                    topTrailingRadius: 0
                )
                .fill(receipt.evidenceStatus.tone.color)
                .frame(width: 3)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(receipt.stage.title). \(receipt.evidenceStatus.label). Contribution \(contribution).")
    }
}

private struct TesslRegistryCard: View {
    let dashboard: SkillDashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 10) {
                TesslLogoView(size: 42)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Tessl Registry")
                        .scaledSystemFont(size: 16, weight: .medium, relativeTo: .headline)
                        .foregroundStyle(Color.teal)
                    Text(dashboard.registryPath)
                        .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .lineLimit(1)
                    HStack(spacing: 6) {
                        Text(dashboard.tessl.registryVersionDisplay)
                            .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                        if let visibility = dashboard.tessl.registryVisibilityDisplay {
                            RegistryVisibilityBadge(visibility: visibility.uppercased())
                        }
                    }
                }
                Spacer(minLength: 4)
                ScoreHex(
                    score: dashboard.tessl.registryResultLabel,
                    tone: .warning,
                    width: 44,
                    height: 50,
                    textSize: 20
                )
            }

            if let lift = dashboard.tessl.registryImprovementMultiplier {
                HStack(spacing: 0) {
                    Spacer()
                    Text(String(format: "↑ %.2fx", lift))
                        .scaledSystemFont(size: 9, weight: .semibold, relativeTo: .caption2)
                        .foregroundStyle(Color.successAccent)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Color(red: 0.025, green: 0.04, blue: 0.05).opacity(0.94))
                        .overlay(Capsule().stroke(Color.successAccent.opacity(0.48), lineWidth: 1))
                        .clipShape(Capsule())
                    Spacer().frame(width: 72)
                }
                .frame(height: 12)
                .padding(.top, -5)
                .padding(.bottom, -4)
            }

            HStack(spacing: 9) {
                HistoricalMetricColumn(
                    label: "Quality",
                    value: dashboard.tessl.registryQualityScore.map { "\($0)%" } ?? "--",
                    progress: dashboard.tessl.registryQualityScore.map { Double($0) / 100.0 },
                    tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryQualityScore)
                )
                VerticalDivider().frame(height: 39)
                HistoricalMetricColumn(
                    label: "Impact",
                    value: dashboard.tessl.registryImpactScore.map { "\($0)%" } ?? "--",
                    progress: dashboard.tessl.registryImpactScore.map { Double($0) / 100.0 },
                    tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryImpactScore)
                )
                VerticalDivider().frame(height: 39)
                HistoricalMetricColumn(
                    label: "Security",
                    value: dashboard.tessl.registrySecurityDisplay,
                    progress: dashboard.tessl.registrySecurityTone == .positive ? 1 : nil,
                    tone: dashboard.tessl.registrySecurityTone
                )
            }

            Text(dashboard.registryEvidenceCaption)
                .scaledSystemFont(size: 10.5, weight: .regular, relativeTo: .caption)
                .foregroundStyle(Color.teal.opacity(0.82))
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [
                    Color.white.opacity(0.072),
                    Color.teal.opacity(0.075),
                    Color.black.opacity(0.075)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.teal.opacity(0.48)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.18), radius: 8, y: 4)
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tessl Registry. \(dashboard.registryEvidenceCaption) Score \(dashboard.tessl.registryResultLabel).")
    }
}

private struct HistoricalMetricColumn: View {
    let label: String
    let value: String
    let progress: Double?
    let tone: StatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(label)
                .scaledSystemFont(size: 11, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.primaryText)
            Text(value)
                .scaledSystemFont(size: 14, weight: .medium, design: .rounded, relativeTo: .subheadline)
                .foregroundStyle(tone.color)
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.10))
                    if let progress {
                        Capsule()
                            .fill(tone.color)
                            .frame(width: geometry.size.width * min(max(progress, 0), 1))
                    }
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct PipelineAction: View {
    let receipt: PipelineStageReceipt?
    @ObservedObject private var feedback = CopyFeedbackModel.shared
    @FocusState private var copyFocused: Bool

    private var command: String { receipt?.command ?? "" }
    private var canCopy: Bool { !command.isEmpty }
    private var commandPreview: String {
        guard let separator = command.range(of: " && ") else { return command }
        return String(command[separator.upperBound...])
    }
    private var actionTitle: String {
        (receipt?.nextAction ?? "All stages have current evidence.")
            .replacingOccurrences(of: " in SKILL.md.", with: "")
    }
    private var copyAccessibilityLabel: String {
        let stageTitle = receipt?.stage.title ?? "pipeline"
        return "Copy " + stageTitle + " inspection command"
    }

    var body: some View {
        HStack(spacing: 10) {
                Image(systemName: "terminal")
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 38, height: 38)
                    .background(Color.white.opacity(0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 4) {
                Text(actionTitle)
                    .scaledSystemFont(size: 14, weight: .medium, relativeTo: .subheadline)
                    .lineLimit(1)
                if canCopy {
                    Text(commandPreview)
                        .scaledSystemFont(size: 10.5, weight: .regular, design: .monospaced, relativeTo: .caption)
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.26))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                        .accessibilityLabel("Inspection command")
                        .accessibilityValue(command)
                }
            }
                Spacer(minLength: 4)
                if canCopy {
                    Button { feedback.copy(command) } label: {
                        Image(systemName: feedback.copiedCommand == command ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                            .copyConfirmationMotion(isConfirmed: feedback.copiedCommand == command)
                    }
                    .buttonStyle(ImmediateFeedbackButtonStyle())
                    .foregroundStyle(feedback.copiedCommand == command ? Color.successAccent : Color.primaryText)
                    .background(Color.white.opacity(copyFocused ? 0.085 : 0.045))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(RoundedRectangle(cornerRadius: 8, style: .continuous).stroke(copyFocused ? Color.focusAccent : Color.white.opacity(0.14), lineWidth: copyFocused ? 2 : 1))
                    .focused($copyFocused)
                    .help(copyAccessibilityLabel)
                    .accessibilityLabel(copyAccessibilityLabel)
                }
                Button { NSApp.terminate(nil) } label: {
                    Image(systemName: "power")
                        .font(.system(size: 15, weight: .semibold))
                        .frame(width: 36, height: 36)
                }
                .buttonStyle(ImmediateFeedbackButtonStyle())
                .foregroundStyle(Color.primaryText)
                .background(Color.white.opacity(0.045))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.14), lineWidth: 1)
                )
                .help("Quit SkillsBar")
                .accessibilityLabel("Quit SkillsBar")
        }
        .padding(10)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.080), Color.white.opacity(0.028)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.24), Color.white.opacity(0.075)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.16), radius: 7, y: 3)
    }
}

private struct PopoverInteriorBackdrop: View {
    let reduceTransparency: Bool
    let increasedContrast: Bool
    let snapshotMode: Bool

    var body: some View {
        ZStack {
            Color(red: 0.025, green: 0.04, blue: 0.05)
            if !reduceTransparency && !increasedContrast && !snapshotMode {
                Rectangle()
                    .fill(.ultraThinMaterial)
                    .opacity(0.52)
            }
        }
            .overlay(
                LinearGradient(
                    colors: reduceTransparency || increasedContrast
                        ? [
                            Color(red: 0.025, green: 0.04, blue: 0.05),
                            Color(red: 0.018, green: 0.03, blue: 0.038)
                        ]
                        : [
                            Color(red: 0.025, green: 0.045, blue: 0.055).opacity(0.48),
                            Color(red: 0.012, green: 0.025, blue: 0.032).opacity(0.62)
                        ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(alignment: .top) {
                LinearGradient(
                    colors: [Color.white.opacity(0.075), .clear],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 110)
                .allowsHitTesting(false)
            }
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
    let width: CGFloat
    let height: CGFloat
    let textSize: CGFloat

    init(
        score: String,
        tone: StatusTone,
        width: CGFloat = 72,
        height: CGFloat = 82,
        textSize: CGFloat = 32
    ) {
        self.score = score
        self.tone = tone
        self.width = width
        self.height = height
        self.textSize = textSize
    }

    var body: some View {
        ZStack {
            RoundedHexagon(cornerRadius: 5)
                .fill(Color.black.opacity(0.50))
            RoundedHexagon(cornerRadius: 5)
                .stroke(tone.color.opacity(0.28), lineWidth: 0.75)
                .padding(4)
            RoundedHexagon(cornerRadius: 5)
                .stroke(tone.color.opacity(0.92), lineWidth: 2)
                .padding(1)
            Text(score)
                .font(.system(size: textSize, weight: .semibold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(tone.color)
        }
        .frame(width: width, height: height)
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

private struct RefreshStatus: View {
    let isRefreshing: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        Group {
            if isRefreshing {
                HStack(spacing: 4) {
                    if reduceMotion {
                        Image(systemName: "arrow.clockwise")
                    } else {
                        ProgressView()
                            .controlSize(.small)
                    }

                    Text("Refreshing")
                }
                .scaledSystemFont(size: 10, weight: .medium, relativeTo: .caption2)
                .foregroundStyle(.secondaryText)
                .transition(.opacity)
            } else {
                Color.clear
            }
        }
        .frame(width: 74, height: 24, alignment: .trailing)
        .opacity(isRefreshing ? 1 : 0)
        .accessibilityHidden(!isRefreshing)
        .accessibilityLabel(isRefreshing ? "Refreshing evidence" : "")
        .animation(reduceMotion ? nil : .easeOut(duration: 0.16), value: isRefreshing)
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
                    Text("\(dashboard.tessl.registryVersionDisplay)  •  score \(dashboard.tessl.registryResultLabel)")
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
                            .copyConfirmationMotion(isConfirmed: copied)
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
                            .copyConfirmationMotion(isConfirmed: copied)
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
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.white.opacity(configuration.isPressed ? 0.10 : 0))
            .opacity(configuration.isPressed ? 0.78 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.97 : 1)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.10), value: configuration.isPressed)
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

    func copyConfirmationMotion(isConfirmed: Bool) -> some View {
        modifier(CopyConfirmationMotion(isConfirmed: isConfirmed))
    }
}

private struct CopyConfirmationMotion: ViewModifier {
    let isConfirmed: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @ViewBuilder
    func body(content: Content) -> some View {
        if reduceMotion {
            content
        } else {
            content
                .contentTransition(.opacity)
                .animation(.easeOut(duration: 0.14), value: isConfirmed)
        }
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
