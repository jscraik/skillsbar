import AppKit
import Foundation
import SwiftUI

struct DashboardView: View {
    @ObservedObject var model: DashboardModel

    var body: some View {
        ZStack {
            PopoverInteriorBackdrop()

            VStack(spacing: 0) {
                HeaderScoreView(dashboard: model.dashboard)
                    .padding(.top, 18)

                VStack(alignment: .leading, spacing: 7) {
                    SkillIdentityView(dashboard: model.dashboard)
                    ProofLaneComparisonView(dashboard: model.dashboard)
                    FleetSummaryView(fleet: model.dashboard.fleet)
                    LocalChecksPanel(dashboard: model.dashboard)
                    SecurityBlock(signal: model.dashboard.security)
                    SectionLabel("Action")
                    CommandDock(dashboard: model.dashboard)
                }
                .padding(.horizontal, 14)
                .padding(.top, 3)
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
        }
        .background(Color.clear)
        .foregroundStyle(.primaryText)
    }
}

struct PopoverInteriorBackdrop: View {
    var body: some View {
        Rectangle()
            .fill(
                LinearGradient(
                    colors: [
                        Color.black.opacity(0.56),
                        Color.black.opacity(0.48),
                        Color.black.opacity(0.62)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
            .overlay(
                Rectangle()
                    .fill(Color.white.opacity(0.014))
                    .blendMode(.plusLighter)
            )
    }
}

struct HeaderScoreView: View {
    let dashboard: SkillDashboard

    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            ScoreEmblemView(dashboard: dashboard)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .center, spacing: 8) {
                    Text(dashboard.verdictTitle)
                        .font(.system(size: 16, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                }

                Text(dashboard.verdictDetail)
                    .font(.system(size: 10, weight: .semibold, design: .rounded))
                    .foregroundStyle(.bodyText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 18)
        .padding(.bottom, 10)
    }
}

struct ScoreEmblemView: View {
    let dashboard: SkillDashboard
    private var ringColor: Color {
        if dashboard.score == nil {
            return dashboard.emblemBadgeTone.color.opacity(0.42)
        }
        return dashboard.scoreTone.color.opacity(0.64)
    }
    private var scoreTextColor: Color {
        if dashboard.score == nil {
            return Color.white.opacity(0.86)
        }
        return dashboard.scoreTone == .positive ? dashboard.scoreTone.color : .primaryText
    }

    var body: some View {
        ZStack(alignment: .top) {
            ZStack {
                Hexagon()
                    .fill(
                        LinearGradient(
                            colors: [
                                .greenPanel.opacity(0.92),
                                Color(red: 0.0, green: 0.045, blue: 0.025).opacity(0.96)
                            ],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .overlay(
                        Hexagon()
                            .fill(
                                RadialGradient(
                                    colors: [
                                        ringColor.opacity(0.24),
                                        Color.clear
                                    ],
                                    center: .top,
                                    startRadius: 0,
                                    endRadius: 58
                                )
                            )
                            .blendMode(.plusLighter)
                    )
                    .overlay(
                        Hexagon()
                            .stroke(Color.white.opacity(0.11), lineWidth: 1)
                            .padding(4)
                    )
                    .overlay(Hexagon().stroke(ringColor, lineWidth: 2))
                    .shadow(color: ringColor.opacity(0.18), radius: 8, x: 0, y: 0)
                    .shadow(color: .black.opacity(0.42), radius: 14, x: 0, y: 9)
                    .frame(width: 76, height: 62)

                Text(dashboard.scoreText)
                    .font(.system(size: 22, weight: .heavy, design: .rounded))
                    .foregroundStyle(scoreTextColor)
            }
            .zIndex(0)

            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(0.76))
                .frame(width: 104, height: 36)
                .shadow(color: .black.opacity(0.44), radius: 9, y: -1)
                .offset(y: 38)
                .zIndex(1)

            HStack(spacing: 6) {
                Image(systemName: dashboard.emblemBadgeSystemName)
                    .font(.system(size: 12, weight: .heavy))
                Text(dashboard.emblemBadgeLabel)
                    .font(.system(size: 13, weight: .heavy, design: .rounded))
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .foregroundStyle(dashboard.emblemBadgeTone.color)
            .frame(width: 104, height: 36)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(dashboard.emblemBadgeTone.panelColor.opacity(0.98))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(LinearGradient(colors: [dashboard.emblemBadgeTone.color.opacity(0.46), dashboard.emblemBadgeTone.color.opacity(0.22)], startPoint: .top, endPoint: .bottom), lineWidth: 1)
            )
            .shadow(color: dashboard.emblemBadgeTone.color.opacity(0.18), radius: 8, y: 1)
            .shadow(color: .black.opacity(0.40), radius: 8, y: 5)
            .offset(y: 38)
            .zIndex(2)
        }
        .frame(width: 104, height: 84, alignment: .top)
        .accessibilityLabel("Local score \(dashboard.scoreText), local status \(dashboard.emblemBadgeLabel).")
    }
}

struct ProofLaneComparisonView: View {
    let dashboard: SkillDashboard

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 8) {
                Text("Source")
                    .frame(width: 102, alignment: .leading)
                Text("Score")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Impact")
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Security")
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 8, weight: .heavy, design: .rounded))
            .foregroundStyle(.secondaryText)
            .tracking(0.45)
            .textCase(.uppercase)
            .padding(.horizontal, 10)

            ComparisonMetricRow(
                icon: .skills,
                title: "Skills SDK",
                subtitle: "Local",
                score: dashboard.scoreText,
                scoreTone: dashboard.scoreTone,
                impact: dashboard.localImpactDisplay,
                impactTone: dashboard.impact.tone,
                security: dashboard.security.statusDisplay,
                securityTone: dashboard.security.tone
            )
            ComparisonMetricRow(
                icon: .tessl,
                title: "Tessl",
                subtitle: "Registry",
                score: dashboard.tessl.registryResultLabel,
                scoreTone: dashboard.tessl.ok ? dashboard.tessl.registryScoreTone : dashboard.tessl.tone,
                impact: dashboard.tessl.registryImpactDisplay,
                impactTone: dashboard.tessl.registryImpactTone,
                security: dashboard.tessl.registrySecurityDisplay,
                securityTone: dashboard.tessl.registrySecurityTone
            )
        }
        .padding(.vertical, 4)
        .accessibilityLabel("Proof lanes. Skills SDK local score \(dashboard.scoreText). Tessl registry score \(dashboard.tessl.registryResultLabel).")
    }
}

struct ComparisonMetricRow: View {
    let icon: ProofLaneCard.IconKind
    let title: String
    let subtitle: String
    let score: String
    let scoreTone: StatusTone
    let impact: String
    let impactTone: StatusTone
    let security: String
    let securityTone: StatusTone

    var body: some View {
        HStack(spacing: 8) {
            HStack(spacing: 8) {
                ProofLaneIcon(kind: icon)
                VStack(alignment: .leading, spacing: 1) {
                    Text(title)
                        .font(.system(size: 11, weight: .heavy, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .lineLimit(1)
                    Text(subtitle.uppercased())
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondaryText)
                        .tracking(0.45)
                        .lineLimit(1)
                }
            }
            .frame(width: 102, alignment: .leading)

            MiniValueBadge(text: score, tone: scoreTone, style: .hex)
                .frame(maxWidth: .infinity)
            MiniValueBadge(text: impact, tone: impactTone, style: .pill)
                .frame(maxWidth: .infinity)
            MiniValueBadge(text: security, tone: securityTone, style: .pill)
                .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(icon == .skills ? 0.050 : 0.030))
        )
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Color.white.opacity(0.070), lineWidth: 1))
    }
}

struct MiniValueBadge: View {
    enum Style {
        case hex
        case pill
    }

    let text: String
    let tone: StatusTone
    let style: Style

    var body: some View {
        switch style {
        case .hex:
            ZStack {
                Hexagon()
                    .fill(tone.panelColor.opacity(0.38))
                Hexagon()
                    .stroke(tone.color.opacity(0.72), lineWidth: 0.9)
                Text(displayText)
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                    .foregroundStyle(tone.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.78)
            }
            .frame(width: 36, height: 30)
        case .pill:
            Text(displayText)
                .font(.system(size: displayText.count > 8 ? 8 : 10, weight: .heavy, design: .rounded))
                .foregroundStyle(tone.color)
                .lineLimit(1)
                .minimumScaleFactor(0.70)
                .frame(width: 68, height: 20)
                .background(Capsule().fill(tone.panelColor.opacity(0.70)))
                .overlay(Capsule().stroke(tone.color.opacity(0.34), lineWidth: 1))
        }
    }

    private var displayText: String {
        text == "--" ? "--" : text
    }
}

struct ProofLaneCard: View {
    enum IconKind {
        case skills
        case tessl
    }

    let icon: IconKind
    let title: String
    let status: String
    let value: String
    let detail: String
    let tone: StatusTone
    private var displayValue: String {
        value == "--" ? "--" : value
    }
    private var displayTone: Color {
        value == "--" ? Color.secondaryText : tone.color
    }
    private var valueFont: Font {
        value == "--"
            ? .system(size: 10, weight: .heavy, design: .rounded)
            : .system(size: 18, weight: .heavy, design: .rounded)
    }

    var body: some View {
        HStack(spacing: 10) {
            ProofLaneIcon(kind: icon)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(title)
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundStyle(.primaryText)
                        .lineLimit(1)
                        .minimumScaleFactor(0.82)
                    Text(status.uppercased())
                        .font(.system(size: 7, weight: .heavy, design: .rounded))
                        .foregroundStyle(.secondaryText)
                        .tracking(0.45)
                        .lineLimit(1)
                }
                Text(detail)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.bodyText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 6)

            Text(displayValue)
                .font(valueFont)
                .foregroundStyle(displayTone)
                .lineLimit(1)
                .minimumScaleFactor(0.80)
                .frame(width: 56, alignment: .trailing)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 9)
        .padding(.vertical, 6)
        .overlay(
            Rectangle()
                .fill(Color.white.opacity(icon == .skills ? 0.070 : 0.035))
                .frame(height: 1)
                .padding(.leading, 34),
            alignment: .bottom
        )
    }
}

struct ProofLaneIcon: View {
    let kind: ProofLaneCard.IconKind

    var body: some View {
        Group {
            switch kind {
            case .skills:
                SkillsSDKLogoView(size: 27)
            case .tessl:
                TesslLogoView(size: 27)
            }
        }
        .opacity(0.94)
    }
}

struct FleetSummaryView: View {
    let fleet: FleetSignal

    var body: some View {
        HStack(spacing: 7) {
            Image(systemName: "square.stack.3d.up.fill")
                .font(.system(size: 10, weight: .bold))
                .foregroundStyle(fleet.tone.color)
            Text(fleet.compactLine)
                .font(.system(size: 10, weight: .semibold, design: .rounded))
                .foregroundStyle(.bodyText)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            CopyIconButton(
                command: fleet.inventoryCommand,
                idleSystemName: "list.bullet.clipboard",
                copiedSystemName: "checkmark",
                help: "Copy all-skills inventory command"
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .fill(Color.white.opacity(0.035))
        )
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.06), lineWidth: 1))
        .accessibilityLabel("Local fleet inventory. \(fleet.title). \(fleet.detail).")
    }
}

struct LocalChecksPanel: View {
    let dashboard: SkillDashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 8) {
                MetricBarColumn(
                    title: "Quality",
                    value: dashboard.quality.statusLabel,
                    detail: dashboard.quality.compactDetail,
                    progress: dashboard.quality.scoreFraction,
                    tone: dashboard.quality.tone,
                    showsFill: dashboard.quality.score != nil
                )
                MetricBarColumn(
                    title: "Impact",
                    value: dashboard.impact.statusLabel,
                    detail: dashboard.impact.shortDetail,
                    progress: dashboard.impact.scoreFraction,
                    tone: dashboard.impact.tone,
                    showsFill: dashboard.impact.score != nil
                )
                MetricBarColumn(
                    title: "Security",
                    value: dashboard.security.statusDisplay,
                    detail: dashboard.security.severityLine,
                    progress: min(max(Double(dashboard.security.score ?? 0) / 100.0, 0), 1),
                    tone: dashboard.security.tone,
                    showsFill: dashboard.security.score != nil
                )
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(0.045))
        )
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Color.white.opacity(0.085), lineWidth: 1))
        .accessibilityLabel("Local checks. Quality \(dashboard.quality.statusLabel). Impact \(dashboard.impact.statusLabel). Security \(dashboard.security.statusDisplay).")
    }
}

struct MetricBarColumn: View {
    let title: String
    let value: String
    let detail: String
    let progress: Double
    let tone: StatusTone
    let showsFill: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(title)
                    .font(.system(size: 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.72)
                Spacer(minLength: 2)
                Text(displayValue)
                    .font(.system(size: displayValue.count > 7 ? 8 : 10, weight: .heavy, design: .rounded))
                    .foregroundStyle(tone.color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.66)
            }
            ProgressStripe(value: progress, tone: tone, showsFill: showsFill)
                .frame(height: 5)
            Text(detail)
                .font(.system(size: 8, weight: .medium, design: .rounded))
                .foregroundStyle(.bodyText)
                .lineLimit(1)
                .truncationMode(.tail)
        }
        .frame(maxWidth: .infinity, alignment: .topLeading)
        .accessibilityLabel("\(title). \(value). \(detail).")
    }

    private var displayValue: String {
        value == "--" ? "Pending" : value
    }
}

struct SectionLabel: View {
    let text: String

    init(_ text: String) {
        self.text = text
    }

    var body: some View {
        Text(text.uppercased())
            .font(.system(size: 8, weight: .bold, design: .rounded))
            .foregroundStyle(.secondaryText)
            .tracking(0.7)
            .padding(.top, 5)
    }
}

struct SkillIdentityView: View {
    let dashboard: SkillDashboard

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 6) {
                Text(dashboard.registryPath)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.secondaryText)
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 4)
                CopyIconButton(
                    command: dashboard.selectedSkillInspectCommand,
                    idleSystemName: "doc.text.magnifyingglass",
                    copiedSystemName: "checkmark",
                    help: "Copy selected SKILL.md inspect command"
                )
            }
            Text(dashboard.displayName)
                .font(.system(size: 18, weight: .heavy, design: .rounded))
                .lineLimit(1)
                .minimumScaleFactor(0.86)
            Text(dashboard.summaryLine)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .lineSpacing(1)
                .foregroundStyle(.bodyText)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}

struct EvidenceRow: View {
    let metric: MetricSignal
    let title: String

    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .frame(width: 58, alignment: .leading)
            Text(metric.statusLabel)
                .font(.system(size: 12, weight: .bold, design: .rounded))
                .foregroundStyle(metric.tone.color)
                .lineLimit(1)
                .minimumScaleFactor(0.72)
                .frame(width: 62, alignment: .trailing)
            Text(metric.compactDetail)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundStyle(.bodyText)
                .lineLimit(1)
                .truncationMode(.tail)
            Spacer(minLength: 4)
            CopyIconButton(
                command: metric.command,
                idleSystemName: "terminal",
                copiedSystemName: "checkmark",
                help: "Copy \(metric.sourceShort) command"
            )
            if metric.tone != .positive, let score = metric.score {
                ProgressStripe(value: min(max(Double(score) / 100.0, 0), 1), tone: metric.tone, showsFill: true)
                    .frame(width: 42)
            }
        }
        .accessibilityLabel("\(title). \(metric.statusLabel). \(metric.compactDetail).")
    }
}

struct SecurityBlock: View {
    let signal: SecuritySignal

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                HStack(spacing: 6) {
                    Image(systemName: signal.tone == .warning ? "exclamationmark.shield.fill" : "checkmark.shield.fill")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundStyle(signal.tone.color)
                    Text("Security")
                        .font(.system(size: 15, weight: .heavy, design: .rounded))
                }
                Spacer()
                HStack(spacing: 6) {
                    Text(signal.statusDisplay)
                        .font(.system(size: 14, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                        .minimumScaleFactor(0.78)
                }
                .foregroundStyle(signal.tone.color)
            }

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Text(signal.severityLine)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .foregroundStyle(signal.tone.color)
                    .lineLimit(1)
                Spacer(minLength: 0)
                if signal.status.localizedCaseInsensitiveContains("flag") {
                    Text(signal.penaltyLine)
                        .font(.system(size: 10, weight: .heavy, design: .rounded))
                        .foregroundStyle(signal.tone.color)
                }
            }
            .accessibilityLabel(signal.accessibilityText)
        }
        .padding(.horizontal, signal.status.localizedCaseInsensitiveContains("flag") ? 10 : 0)
        .padding(.vertical, signal.status.localizedCaseInsensitiveContains("flag") ? 8 : 0)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(signal.status.localizedCaseInsensitiveContains("flag") ? signal.tone.panelColor.opacity(0.46) : Color.clear)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(signal.status.localizedCaseInsensitiveContains("flag") ? signal.tone.color.opacity(0.22) : Color.clear, lineWidth: 1)
        )
    }
}

struct TesslBlock: View {
    let dashboard: SkillDashboard
    private var signal: TesslSignal { dashboard.tessl }
    private var localSecurityFlagged: Bool { dashboard.security.status.localizedCaseInsensitiveContains("flag") }
    private var title: String {
        signal.ok ? "Tessl score" : "Tessl registry"
    }
    private var detail: String {
        signal.ok ? signal.registryComparisonDetail(localScore: dashboard.score) : signal.compactDetail
    }
    private var trailingLabel: String {
        signal.ok ? "Registry" : signal.registryStatusLabel
    }
    private var trailingValue: String {
        signal.ok ? signal.registryResultLabel : "--"
    }

    var body: some View {
        HStack(spacing: 10) {
            TesslLogoView(size: 24)
            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .font(.system(size: 12, weight: .bold, design: .rounded))
                    .lineLimit(1)
                Text(detail)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundStyle(.bodyText)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
            Spacer(minLength: 6)
            VStack(alignment: .trailing, spacing: 1) {
                Text(trailingLabel)
                    .font(.system(size: 8, weight: .heavy, design: .rounded))
                    .foregroundStyle(.secondaryText)
                    .textCase(.uppercase)
                    .lineLimit(1)
                Text(trailingValue)
                    .font(.system(size: 17, weight: .heavy, design: .rounded))
                    .foregroundStyle(signal.registryStatusTone.color)
                    .lineLimit(1)
            }
            CopyIconButton(
                command: dashboard.registrySearchCommand,
                idleSystemName: "terminal",
                copiedSystemName: "checkmark",
                help: "Copy Tessl registry search"
            )
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 7)
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.white.opacity(localSecurityFlagged ? 0.020 : 0.030))
        )
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(Color.white.opacity(localSecurityFlagged ? 0.045 : 0.065), lineWidth: 1))
    }
}

struct CommandDock: View {
    let dashboard: SkillDashboard
    @ObservedObject private var feedback = CopyFeedbackModel.shared
    private var signal: TesslSignal { dashboard.tessl }
    private var securityFlagged: Bool { dashboard.security.status.localizedCaseInsensitiveContains("flag") }
    private var actionCommand: String {
        securityFlagged ? dashboard.security.inspectCommand : signal.recoveryCommand
    }
    private var copied: Bool { feedback.copiedCommand == actionCommand }
    private var actionTone: StatusTone {
        if copied { return .positive }
        if securityFlagged { return dashboard.security.tone }
        return signal.tone
    }
    private var actionIcon: String {
        if copied { return "checkmark" }
        if securityFlagged { return "terminal.fill" }
        return signal.ok ? "arrow.up.right.square" : "terminal.fill"
    }
    private var actionTitle: String {
        if copied { return securityFlagged ? "Copied security check" : signal.copiedActionTitle }
        if securityFlagged { return "Copy security check" }
        return signal.actionTitle
    }
    private var actionHelp: String {
        if securityFlagged { return "Copy local SDK security check" }
        return signal.actionHelp
    }
    private var secondaryCommand: String {
        signal.ok ? dashboard.selectedSkillInspectCommand : signal.recoveryCommand
    }
    private var secondaryLabel: String {
        signal.ok ? "Inspect" : "Next"
    }

    var body: some View {
        VStack(spacing: 0) {
            Button {
                if securityFlagged {
                    feedback.copy(dashboard.security.inspectCommand)
                } else if signal.ok {
                    if let url = dashboard.registryURL {
                        NSWorkspace.shared.open(url)
                    }
                } else if signal.cliAvailable {
                    LoginLauncher.open(command: signal.recoveryCommand)
                } else {
                    feedback.copy(signal.recoveryCommand)
                }
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: actionIcon)
                        .font(.system(size: 11, weight: .bold))
                    Text(actionTitle)
                        .font(.system(size: 12, weight: .heavy, design: .rounded))
                        .lineLimit(1)
                    Spacer()
                }
                .foregroundStyle(actionTone.color)
                .padding(.horizontal, 12)
                .padding(.vertical, 7)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(actionTone.panelColor.opacity(securityFlagged ? 0.42 : 0.34))
            }
            .buttonStyle(.plain)
            .help(actionHelp)

            Rectangle()
                .fill(Color.white.opacity(0.050))
                .frame(height: 1)

            HStack(spacing: 10) {
                Text(secondaryLabel)
                    .font(.system(size: 9, weight: .semibold, design: .rounded))
                    .foregroundStyle(.secondaryText)
                Text(secondaryCommand)
                    .font(.system(size: 9, weight: .medium, design: .monospaced))
                    .foregroundStyle(Color.white.opacity(0.70))
                    .lineLimit(1)
                    .truncationMode(.middle)
                Spacer(minLength: 8)
                CopyIconButton(
                    command: secondaryCommand,
                    idleSystemName: signal.ok ? "doc.text.magnifyingglass" : "terminal",
                    copiedSystemName: "checkmark",
                    help: signal.ok ? "Copy selected local skill inspect command" : "Copy next Tessl command"
                )
            }
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
        }
        .background(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .fill(Color.black.opacity(0.30))
        )
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 11, style: .continuous).stroke(actionTone.color.opacity(securityFlagged ? 0.22 : 0.14), lineWidth: 1))
        .accessibilityLabel("Action. \(actionTitle). Secondary command \(secondaryCommand).")
    }
}

struct PrimaryAction: View {
    let dashboard: SkillDashboard
    @ObservedObject private var feedback = CopyFeedbackModel.shared
    private var signal: TesslSignal { dashboard.tessl }
    private var securityFlagged: Bool { dashboard.security.status.localizedCaseInsensitiveContains("flag") }
    private var actionCommand: String {
        securityFlagged ? dashboard.security.inspectCommand : signal.recoveryCommand
    }
    private var copied: Bool { feedback.copiedCommand == actionCommand }
    private var actionTone: StatusTone {
        if copied { return .positive }
        if securityFlagged { return dashboard.security.tone }
        return signal.tone
    }
    private var actionIcon: String {
        if copied { return "checkmark" }
        if securityFlagged { return "terminal.fill" }
        return signal.ok ? "arrow.up.right.square" : "terminal.fill"
    }
    private var actionTitle: String {
        if copied { return securityFlagged ? "Copied security check" : signal.copiedActionTitle }
        if securityFlagged { return "Copy security check" }
        return signal.actionTitle
    }
    private var actionHelp: String {
        if securityFlagged { return "Copy local SDK security check" }
        return signal.actionHelp
    }

    var body: some View {
        Button {
            if securityFlagged {
                feedback.copy(dashboard.security.inspectCommand)
            } else if signal.ok {
                if let url = dashboard.registryURL {
                    NSWorkspace.shared.open(url)
                }
            } else if signal.cliAvailable {
                LoginLauncher.open(command: signal.recoveryCommand)
            } else {
                feedback.copy(signal.recoveryCommand)
            }
        } label: {
            HStack(spacing: 8) {
                Image(systemName: actionIcon)
                    .font(.system(size: 12, weight: .bold))
                Text(actionTitle)
                    .font(.system(size: 12, weight: .heavy, design: .rounded))
                Spacer()
            }
            .foregroundStyle(actionTone.color)
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(securityFlagged ? actionTone.panelColor.opacity(0.80) : signal.ok ? StatusTone.positive.panelColor.opacity(0.80) : Color.black.opacity(0.26))
            )
            .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
            .overlay(RoundedRectangle(cornerRadius: 10).stroke(actionTone.color.opacity(0.42), lineWidth: 1))
        }
        .buttonStyle(.plain)
        .help(actionHelp)
    }
}

struct TesslLogoView: View {
    var size: CGFloat = 28
    private var imageSize: CGFloat { max(16, size * 0.66) }

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
            Circle()
                .fill(Color.white.opacity(0.08))
            Circle()
                .fill(Color.black.opacity(0.24))

            if let image = TesslLogoLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFill()
                    .scaleEffect(1.84)
                    .frame(width: imageSize, height: imageSize)
                    .clipShape(Circle())
            } else {
                Image(systemName: "shippingbox.fill")
                    .font(.system(size: max(11, size * 0.5), weight: .bold))
                    .foregroundStyle(.primaryText)
            }
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        .overlay(Circle().stroke(Color.successAccent.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
    }
}

struct SkillsSDKLogoView: View {
    var size: CGFloat = 28
    private var glyphSize: CGFloat { max(12, size * 0.50) }
    private var dotSize: CGFloat { max(5, size * 0.20) }

    var body: some View {
        ZStack {
            Circle()
                .fill(.thinMaterial)
            Circle()
                .fill(Color.white.opacity(0.08))
            Circle()
                .fill(Color.black.opacity(0.24))

            Image(systemName: "doc.text.fill")
                .font(.system(size: glyphSize, weight: .semibold))
                .foregroundStyle(Color.white.opacity(0.88))
                .offset(x: -1, y: -0.5)

            Circle()
                .fill(Color(red: 0.55, green: 0.66, blue: 0.56))
                .frame(width: dotSize, height: dotSize)
                .overlay(Circle().stroke(Color.black.opacity(0.42), lineWidth: 0.8))
                .offset(x: size * 0.24, y: size * 0.24)
        }
        .frame(width: size, height: size)
        .overlay(Circle().stroke(Color.white.opacity(0.18), lineWidth: 1))
        .overlay(Circle().stroke(Color.successAccent.opacity(0.10), lineWidth: 1))
        .shadow(color: .black.opacity(0.28), radius: 4, y: 2)
    }
}

enum LoginLauncher {
    @MainActor
    static func open(command: String) {
        let script = """
        tell application "Terminal"
            activate
            do script "(escapedAppleScript(command))"
        end tell
        """
        var error: NSDictionary?
        if let appleScript = NSAppleScript(source: script), appleScript.executeAndReturnError(&error).stringValue != nil || error == nil {
            return
        }
        CopyFeedbackModel.shared.copy(command)
    }

    private static func escapedAppleScript(_ value: String) -> String {
        value
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
    }
}

enum TesslLogoLoader {
    static let image: NSImage? = {
        if let resource = Bundle.main.url(forResource: "TesslLogo", withExtension: "png") {
            return NSImage(contentsOf: resource)
        }
        let sourceResource = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/TesslLogo.png")
        return NSImage(contentsOf: sourceResource)
    }()
}

enum SkillsSDKIconLoader {
    static let image: NSImage? = {
        if let resource = Bundle.main.url(forResource: "SkillsSDKIcon", withExtension: "png") {
            let image = NSImage(contentsOf: resource)
            image?.isTemplate = false
            return image
        }
        let sourceResource = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .appendingPathComponent("Resources/SkillsSDKIcon.png")
        let image = NSImage(contentsOf: sourceResource)
        image?.isTemplate = false
        return image
    }()

    static let menuBarImage: NSImage? = {
        guard let image else { return nil }
        let targetSize = NSSize(width: 23, height: 23)
        let resized = NSImage(size: targetSize)
        resized.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high
        image.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .sourceOver, fraction: 1)
        image.draw(in: NSRect(origin: .zero, size: targetSize), from: .zero, operation: .plusLighter, fraction: 0.18)
        resized.unlockFocus()
        resized.isTemplate = false
        return resized
    }()
}

struct InstallCommand: View {
    let command: String
    let signal: TesslSignal
    private var displayedCommand: String {
        signal.ok ? command : signal.recoveryCommand
    }

    var body: some View {
        HStack(spacing: 10) {
            Text(signal.installLabel)
                .font(.system(size: 9, weight: .semibold, design: .rounded))
                .foregroundStyle(.secondaryText)
            Text(displayedCommand)
                .font(.system(size: 9, weight: .medium, design: .monospaced))
                .foregroundStyle(Color.white.opacity(0.78))
                .lineLimit(1)
                .truncationMode(.middle)
            Spacer(minLength: 8)
            CopyIconButton(
                command: displayedCommand,
                idleSystemName: signal.ok ? "doc.on.doc" : "terminal",
                copiedSystemName: "checkmark",
                help: signal.ok ? "Copy install command" : "Copy next Tessl command"
            )
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .fill(Color.black.opacity(signal.ok ? 0.30 : 0.36))
        )
        .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.white.opacity(0.16), lineWidth: 1))
    }
}

struct SourcePill: View {
    let text: String

    var body: some View {
        Text(text)
            .font(.system(size: 7, weight: .bold, design: .rounded))
            .foregroundStyle(Color.pendingAccent.opacity(0.68))
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(Color.black.opacity(0.16))
            )
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.pendingAccent.opacity(0.16), lineWidth: 1))
    }
}

struct CopyIconButton: View {
    let command: String
    let idleSystemName: String
    let copiedSystemName: String
    let help: String
    @ObservedObject private var feedback = CopyFeedbackModel.shared
    private var copied: Bool { feedback.copiedCommand == command }

    var body: some View {
        Button {
            feedback.copy(command)
        } label: {
            Image(systemName: copied ? copiedSystemName : idleSystemName)
                .font(.system(size: 9, weight: .bold))
                .frame(width: 19, height: 19)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .foregroundStyle(copied ? StatusTone.positive.color : .secondaryText)
        .background(Color.white.opacity(copied ? 0.045 : 0.018))
        .clipShape(RoundedRectangle(cornerRadius: 5, style: .continuous))
        .help(help)
        .accessibilityLabel(help)
    }
}

struct FooterBar: View {
    @ObservedObject var model: DashboardModel

    var body: some View {
        HStack(spacing: 8) {
            Spacer(minLength: 0)
            CopyIconButton(
                command: model.dashboard.localEvidenceCommand,
                idleSystemName: "doc.on.clipboard",
                copiedSystemName: "checkmark",
                help: "Copy all local SDK checks"
            )
            Button {
                Task { await model.refresh() }
            } label: {
                Image(systemName: model.isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                    .font(.system(size: 9, weight: .bold))
                    .frame(width: 18, height: 18)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .foregroundStyle(model.isRefreshing ? StatusTone.warning.color : .secondaryText)
            .help("Refresh local and Tessl evidence")
        }
        .frame(height: 18)
        .padding(.bottom, 2)
    }
}

struct ProgressStripe: View {
    let value: Double
    let tone: StatusTone
    let showsFill: Bool

    var body: some View {
        GeometryReader { proxy in
            ZStack(alignment: .leading) {
                Capsule().fill(Color.white.opacity(0.115))
                if showsFill {
                    Capsule()
                        .fill(LinearGradient(colors: [tone.color, tone.color.opacity(0.72)], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(7, proxy.size.width * value))
                        .shadow(color: tone.color.opacity(0.22), radius: 5, x: 0, y: 0)
                }
            }
        }
        .frame(height: 6)
    }
}

struct Hexagon: Shape {
    func path(in rect: CGRect) -> Path {
        let points = [
            CGPoint(x: rect.midX - rect.width * 0.28, y: rect.minY),
            CGPoint(x: rect.midX + rect.width * 0.28, y: rect.minY),
            CGPoint(x: rect.maxX, y: rect.midY),
            CGPoint(x: rect.midX + rect.width * 0.28, y: rect.maxY),
            CGPoint(x: rect.midX - rect.width * 0.28, y: rect.maxY),
            CGPoint(x: rect.minX, y: rect.midY)
        ]
        var path = Path()
        path.move(to: points[0])
        for point in points.dropFirst() { path.addLine(to: point) }
        path.closeSubpath()
        return path
    }
}

extension ShapeStyle where Self == Color {
    static var primaryText: Color { Color.white.opacity(0.96) }
    static var secondaryText: Color { Color(red: 0.57, green: 0.57, blue: 0.64) }
    static var bodyText: Color { Color(red: 0.71, green: 0.71, blue: 0.77) }
    static var accentGreen: Color { Color.successAccent }
}

extension Color {
    static var greenPanel: Color { Color(red: 0.0, green: 0.15, blue: 0.075) }
    static var greenBorder: Color { Color(red: 0.02, green: 0.25, blue: 0.11) }
    static var successAccent: Color { Color(red: 0.31, green: 0.89, blue: 0.50) }
    static var warningAccent: Color { Color(red: 1.0, green: 0.70, blue: 0.22) }
    static var advisoryAccent: Color { Color(red: 0.16, green: 0.84, blue: 0.94) }
    static var pendingAccent: Color { Color(red: 0.56, green: 0.58, blue: 0.64) }
    static var dangerAccent: Color { Color(red: 1.0, green: 0.40, blue: 0.34) }
}

