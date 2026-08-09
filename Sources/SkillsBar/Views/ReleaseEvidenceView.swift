import AppKit
import SwiftUI

private enum SkillsBarMotion {
    static let candidateRefresh = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.16)
    static let tesslRefresh = Animation.timingCurve(0.23, 1, 0.32, 1, duration: 0.18)
}

private struct EvidenceValueTransition<Content: View>: View {
    let key: String
    let isEnabled: Bool
    let anchor: UnitPoint
    let animation: Animation
    let content: () -> Content

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    init(
        key: String,
        isEnabled: Bool = true,
        anchor: UnitPoint = .leading,
        animation: Animation = SkillsBarMotion.candidateRefresh,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.key = key
        self.isEnabled = isEnabled
        self.anchor = anchor
        self.animation = animation
        self.content = content
    }

    var body: some View {
        if isEnabled {
            ZStack(alignment: .leading) {
                content()
                    .id(key)
                    .transition(
                        reduceMotion
                            ? .identity
                            : .opacity.combined(with: .scale(scale: 0.98, anchor: anchor))
                    )
            }
            .animation(reduceMotion ? nil : animation, value: key)
        } else {
            content()
        }
    }
}

private extension PipelineCandidate {
    var refreshMotionKey: String {
        let active = activeReceipt
        return [
            fingerprint,
            active?.stage.rawValue ?? "complete",
            active?.evidenceStatus.label ?? "passed",
            active?.nextAction ?? ""
        ].joined(separator: "|")
    }
}

private extension TesslSignal {
    var motionKey: String {
        [
            registryResultLabel,
            registryVersion ?? "—",
            registryQualityScore.map(String.init) ?? "—",
            registryImpactScore.map(String.init) ?? "—",
            registrySecurityDisplay
        ].joined(separator: "|")
    }
}

struct ReleaseEvidenceView: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    let isFixture: Bool
    let availableSkillPaths: [String]
    let selectedSkillPath: String
    let isSkillSelectionPinned: Bool
    let onSelectSkill: ((String) -> Void)?
    let onRefresh: (() -> Void)?

    init(
        dashboard: SkillDashboard,
        isRefreshing: Bool,
        isFixture: Bool = false,
        availableSkillPaths: [String] = [],
        selectedSkillPath: String? = nil,
        isSkillSelectionPinned: Bool = false,
        onSelectSkill: ((String) -> Void)? = nil,
        onRefresh: (() -> Void)? = nil
    ) {
        self.dashboard = dashboard
        self.isRefreshing = isRefreshing
        self.isFixture = isFixture
        self.availableSkillPaths = availableSkillPaths
        self.selectedSkillPath = selectedSkillPath ?? dashboard.fleet.selectedSkillPath
        self.isSkillSelectionPinned = isSkillSelectionPinned
        self.onSelectSkill = onSelectSkill
        self.onRefresh = onRefresh
    }

    var body: some View {
        VStack(spacing: 0) {
            EvidenceValueTransition(key: dashboard.pipeline.refreshMotionKey) {
                ReleaseHeader(
                    dashboard: dashboard,
                    isRefreshing: isRefreshing,
                    isFixture: isFixture,
                    availableSkillPaths: availableSkillPaths,
                    selectedSkillPath: selectedSkillPath,
                    isSkillSelectionPinned: isSkillSelectionPinned,
                    onSelectSkill: onSelectSkill
                )
            }
            ReleaseDivider().padding(.vertical, 14)
            if let active = dashboard.pipeline.activeReceipt {
                VStack(alignment: .leading, spacing: 9) {
                    Text("NEXT REQUIRED")
                        .releaseFont(11, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(.secondaryText)
                        .padding(.horizontal, 12)
                    EvidenceValueTransition(key: dashboard.pipeline.refreshMotionKey) {
                        NextRequiredCard(receipt: active)
                    }
                }
                .padding(.bottom, 16)
            }
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    ReleaseGateList(dashboard: dashboard)
                        .id(dashboard.pipeline.fingerprint)
                    TesslEvidenceCard(dashboard: dashboard)
                    ReleaseFooter(dashboard: dashboard, isRefreshing: isRefreshing, onRefresh: onRefresh)
                    Color.clear.frame(height: 14)
                }
                .padding(.trailing, 2)
            }
            .scrollIndicators(.automatic)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: .infinity)
            .layoutPriority(1)
        }
    }
}

private struct ReleaseHeader: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    let isFixture: Bool
    let availableSkillPaths: [String]
    let selectedSkillPath: String
    let isSkillSelectionPinned: Bool
    let onSelectSkill: ((String) -> Void)?

    private var candidate: PipelineCandidate { dashboard.pipeline }
    private var active: PipelineStageReceipt? { candidate.activeReceipt }
    private var statusLabel: String {
        if isRefreshing { return "Refreshing" }
        if active != nil { return "Needs attention" }
        return "Up to date"
    }
    private var statusColor: Color {
        if isRefreshing { return .advisoryAccent }
        if active != nil { return .warningAccent }
        return .successAccent
    }

    private var statusAccessibilityLabel: String {
        if isRefreshing { return "Refreshing evidence" }
        if active != nil { return "Local source up to date; evidence needs attention" }
        return "Local source up to date"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ReleaseSkillLogo(size: 50)

            VStack(alignment: .leading, spacing: 5) {
                Text("SKILLS SDK")
                    .releaseFont(12, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
                Text(dashboard.displayName)
                    .releaseFont(18, weight: .medium, relativeTo: .headline)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)
                HStack(spacing: 6) {
                    ReleasePill(text: isFixture ? "DEMO FIXTURE" : "LOCAL", tone: isFixture ? .pending : .advisory)
                    Text("v\(dashboard.version.trimmingCharacters(in: CharacterSet(charactersIn: "vV")))")
                        .releaseFont(12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .monospacedDigit()
                    Circle()
                        .fill(statusColor)
                        .frame(width: 8, height: 8)
                    Text(statusLabel)
                        .releaseFont(12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(statusColor)
                        .lineLimit(1)
                        .frame(width: 76, alignment: .leading)
                        .help(statusAccessibilityLabel)
                        .accessibilityLabel(statusAccessibilityLabel)
                }
            }

            Spacer(minLength: 6)

            VStack(alignment: .center, spacing: 2) {
                Text("CURRENT GATE")
                    .releaseFont(9.5, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
                CurrentGateRing(active: active, total: PipelineStage.allCases.count)
            }
            SkillSelectionMenu(
                selectedSkillPath: selectedSkillPath,
                availableSkillPaths: availableSkillPaths,
                isPinned: isSkillSelectionPinned,
                onSelect: onSelectSkill
            )
        }
        .padding(.trailing, 34)
        .accessibilityElement(children: .contain)
    }
}

private struct CurrentGateRing: View {
    let active: PipelineStageReceipt?
    let total: Int

    private var number: Int { active?.stage.number ?? total }
    private var progress: CGFloat {
        guard total > 0 else { return 1 }
        return CGFloat(number) / CGFloat(total)
    }
    private var tone: Color {
        guard let active else { return .successAccent }
        return active.evidenceStatus == .blocked ? .warningAccent : active.evidenceStatus.tone.color
    }

    var body: some View {
        ZStack {
            Circle()
                .stroke(Color.primary.opacity(0.15), lineWidth: 4)
            Circle()
                .trim(from: 0, to: progress)
                .stroke(tone, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                .rotationEffect(.degrees(-90))
            Text(String(format: "%02d", number))
                .releaseFont(18, weight: .medium, design: .rounded, relativeTo: .headline)
                .monospacedDigit()
                .foregroundStyle(.primaryText)
        }
        .frame(width: 54, height: 54)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(active.map { "Current gate \($0.stage.number), \($0.stage.title)" } ?? "All gates current")
    }
}

private struct SkillSelectionMenu: View {
    let selectedSkillPath: String
    let availableSkillPaths: [String]
    let isPinned: Bool
    let onSelect: ((String) -> Void)?

    private var selectedName: String {
        Self.skillName(for: selectedSkillPath)
    }

    var body: some View {
            Menu {
            if availableSkillPaths.isEmpty {
                Text("No local skills discovered")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(availableSkillPaths, id: \.self) { path in
                    Button {
                        onSelect?(path)
                    } label: {
                        if path == selectedSkillPath {
                            Label(Self.skillName(for: path), systemImage: "checkmark")
                        } else {
                            Text(Self.skillName(for: path))
                        }
                    }
                    .disabled(isPinned || onSelect == nil)
                }
            }
            if isPinned {
                Divider()
                Text("Selection pinned by environment")
                    .foregroundStyle(.secondary)
            }
        } label: {
            ZStack {
                Image(systemName: "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .frame(width: 36, height: 36)
                    .background(Color.primary.opacity(0.055))
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.primary.opacity(0.16), lineWidth: 1))
            }
            .frame(width: 48, height: 48)
            .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .help(isPinned ? "Skill selection is pinned by the environment" : "Choose a local skill")
        .accessibilityLabel("Choose skill, currently \(selectedName)")
    }

    private static func skillName(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.deletingLastPathComponent().lastPathComponent.isEmpty
            ? path
            : url.deletingLastPathComponent().lastPathComponent
    }
}

@MainActor
private final class PipelineDisclosureModel: ObservableObject {
    @Published var expandedReceiptIDs: Set<String>
    @Published var expandedGroupIDs: Set<String> = []

    init(activeStage: PipelineStage?) {
        expandedReceiptIDs = activeStage.map { [$0.rawValue] } ?? []
    }
}

private struct ReleaseGateList: View {
    let dashboard: SkillDashboard
    @StateObject private var disclosure: PipelineDisclosureModel

    init(dashboard: SkillDashboard) {
        self.dashboard = dashboard
        _disclosure = StateObject(
            wrappedValue: PipelineDisclosureModel(activeStage: dashboard.pipeline.activeReceipt?.stage)
        )
    }

    private var candidate: PipelineCandidate { dashboard.pipeline }

    private func isReceiptExpanded(_ receipt: PipelineStageReceipt) -> Bool {
        disclosure.expandedReceiptIDs.contains(receipt.stage.rawValue)
    }

    private func toggleReceipt(_ receipt: PipelineStageReceipt) {
        let id = receipt.stage.rawValue
        if disclosure.expandedReceiptIDs.contains(id) {
            disclosure.expandedReceiptIDs.remove(id)
        } else {
            disclosure.expandedReceiptIDs.insert(id)
        }
    }

    private func toggleGroup(_ id: String) {
        if disclosure.expandedGroupIDs.contains(id) {
            disclosure.expandedGroupIDs.remove(id)
        } else {
            disclosure.expandedGroupIDs.insert(id)
        }
    }

    @ViewBuilder
    private func gateRow(_ receipt: PipelineStageReceipt) -> some View {
        ReleaseGateRow(
            receipt: receipt,
            isActive: receipt.stage == candidate.activeReceipt?.stage,
            isExpanded: isReceiptExpanded(receipt),
            securityBadge: receipt.stage == .securityReview ? dashboard.security.severityLine : nil,
            onToggle: { toggleReceipt(receipt) }
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("EVIDENCE PIPELINE")
                    .releaseFont(13, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.secondaryText)
                Spacer()
                Text("\(candidate.evidencedStageCount) current · \(candidate.activeReceipt == nil ? "ready" : "proof held")")
                    .releaseFont(10.5, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
                    .monospacedDigit()
            }
            .padding(.horizontal, 3)

            PipelineSurface {
                ForEach(candidate.orderedReceipts) { receipt in
                    gateRow(receipt)
                    if receipt.id != candidate.orderedReceipts.last?.id {
                        ReleaseDivider()
                    }
                }
            }

        }
        .accessibilityElement(children: .contain)
        .onChange(of: candidate.activeReceipt?.stage.rawValue) { _, activeStageID in
            if let activeStageID {
                disclosure.expandedReceiptIDs = [activeStageID]
            } else {
                disclosure.expandedReceiptIDs.removeAll()
            }
        }
    }

    private func groupDetail(_ receipts: [PipelineStageReceipt]) -> String {
        if receipts.allSatisfy({ $0.evidenceStatus == .passed }) { return "Passed" }
        if let first = receipts.first(where: { $0.evidenceStatus != .passed }) {
            return first.evidenceStatus.label
        }
        return "Unproven"
    }

    @ViewBuilder
    private func compactSection(
        _ receipts: [PipelineStageReceipt],
        id: String,
        title: String,
        detail: String
    ) -> some View {
        if !receipts.isEmpty {
            GateGroupRow(
                title: title,
                detail: detail,
                isExpanded: disclosure.expandedGroupIDs.contains(id),
                onToggle: { toggleGroup(id) }
            )
            if disclosure.expandedGroupIDs.contains(id) {
                ReleaseDivider()
                ForEach(receipts) { receipt in
                    gateRow(receipt)
                    if receipt.id != receipts.last?.id { ReleaseDivider() }
                }
            }
        }
    }

    private func stageRangeTitle(_ receipts: [PipelineStageReceipt]) -> String {
        guard let first = receipts.first?.stage.number,
              let last = receipts.last?.stage.number else { return "" }
        return first == last ? String(format: "%02d", first) : String(format: "%02d–%02d", first, last)
    }

    private func stageRangeDetail(_ receipts: [PipelineStageReceipt]) -> String {
        guard let first = receipts.first?.stage.number,
              let last = receipts.last?.stage.number else { return "" }
        let prefix = first == last ? "Gate \(first)" : "Gates \(first)–\(last)"
        return "\(prefix) \(groupDetail(receipts).lowercased())"
    }
}

private struct PipelineSurface<Content: View>: View {
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .background(Color.releaseSurface)
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(Color.releaseBorderSubtle, lineWidth: 1)
            )
    }
}

private struct GateGroupRow: View {
    let title: String
    let detail: String
    let isExpanded: Bool
    let onToggle: () -> Void

    private var isDownstream: Bool { title.localizedCaseInsensitiveContains("downstream") }
    private var isPassed: Bool { detail.localizedCaseInsensitiveContains("passed") }

    var body: some View {
        Button(action: onToggle) {
            HStack(spacing: 10) {
                Image(systemName: isDownstream ? "chevron.right" : (isPassed ? "checkmark.circle.fill" : "circle.dotted"))
                    .font(.system(size: 21, weight: .medium))
                    .foregroundStyle(isPassed ? Color.successAccent : Color.pendingAccent)
                    .frame(width: 32)
                if isDownstream {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .releaseFont(15, weight: .medium, relativeTo: .subheadline)
                            .foregroundStyle(.primaryText)
                        Text(detail)
                            .releaseFont(12, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                    }
                } else {
                    HStack(spacing: 10) {
                        Text(title)
                            .releaseFont(14, weight: .medium, design: .rounded, relativeTo: .subheadline)
                            .foregroundStyle(.primaryText)
                            .monospacedDigit()
                        Text(detail)
                            .releaseFont(14, weight: .regular, relativeTo: .subheadline)
                            .foregroundStyle(.bodyText)
                    }
                }
                Spacer(minLength: 4)
                Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.bodyText)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 14)
            .padding(.vertical, 13)
        }
        .buttonStyle(PipelineDisclosureButtonStyle())
        .accessibilityLabel("\(title), \(detail)")
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Hides these gate details" : "Shows these gate details")
    }
}

private struct NextRequiredCard: View {
    let receipt: PipelineStageReceipt
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
            ActionGateIcon(receipt: receipt)
                .frame(width: 54)
            VStack(alignment: .leading, spacing: 5) {
                Text(receipt.stage.title)
                    .releaseFont(20, weight: .medium, relativeTo: .headline)
                HStack(spacing: 6) {
                    Circle()
                        .fill(presentationTone)
                        .frame(width: 9, height: 9)
                    Text(receipt.evidenceStatus.label.uppercased())
                        .releaseFont(12.5, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(presentationTone)
                    Text("•")
                        .foregroundStyle(.secondaryText)
                    Text(receipt.compactActionLabel)
                        .releaseFont(12.5, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .help(receipt.nextAction)
                }
                Text(actionInstruction)
                    .releaseFont(14, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            Spacer(minLength: 4)
            }
            if receipt.command.isEmpty {
                ReleaseDivider()
                HStack(alignment: .center, spacing: 8) {
                    Image(systemName: "doc.badge.ellipsis")
                        .font(.system(size: 20, weight: .medium))
                        .foregroundStyle(Color.warningAccent)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next step: receipt required")
                            .releaseFont(15, weight: .medium, relativeTo: .subheadline)
                        Text("Complete the governed \(receipt.stage.title.lowercased()) step, then refresh to bind its receipt.")
                            .releaseFont(12.5, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
            } else {
                ReleaseDivider()
                HStack(alignment: .center, spacing: 8) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Next step: copy command")
                            .releaseFont(15, weight: .medium, relativeTo: .subheadline)
                        Text("Paste into Terminal to run local proof.")
                            .releaseFont(12.5, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                    }
                    .layoutPriority(1)
                    Text(receipt.command)
                        .font(.system(size: 11, weight: .regular, design: .monospaced))
                        .foregroundStyle(.secondaryText)
                        .lineLimit(2)
                        .truncationMode(.middle)
                        .fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: 170, alignment: .leading)
                    Spacer(minLength: 4)
                    Button {
                        feedback.copy(receipt.command)
                    } label: {
                        Text(feedback.copiedCommand == receipt.command ? "Copied" : "Copy command")
                            .releaseFont(14, weight: .medium, relativeTo: .subheadline)
                            .lineLimit(1)
                            .minimumScaleFactor(0.85)
                            .padding(.horizontal, 15)
                            .frame(height: 42)
                    }
                    .buttonStyle(ReleasePressButtonStyle(tint: .advisoryAccent))
                    .frame(width: 132, height: 46)
                    .foregroundStyle(.primaryText)
                    .help("Copy the full \(receipt.stage.title.lowercased()) command")
                    .accessibilityLabel("Copy the full \(receipt.stage.title.lowercased()) command")
                }
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 16)
        .background(Color.releaseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 12, style: .continuous).stroke(presentationTone.opacity(0.68), lineWidth: 1))
    }

    private var presentationTone: Color {
        receipt.evidenceStatus == .blocked ? .warningAccent : receipt.evidenceStatus.tone.color
    }

    private var actionInstruction: String {
        if receipt.stage == .ossLocal {
            return "Run local eval to produce the receipt."
        }
        return receipt.stage.supportingText
    }
}

private struct ActionGateIcon: View {
    let receipt: PipelineStageReceipt

    private var tone: Color {
        receipt.evidenceStatus == .blocked ? .warningAccent : receipt.evidenceStatus.tone.color
    }

    var body: some View {
        Group {
            switch receipt.stage {
            case .ossLocal:
                Image(systemName: "key.fill")
                    .font(.system(size: 27, weight: .semibold))
            case .ossCloud:
                Image(systemName: "cloud.fill")
                    .font(.system(size: 25, weight: .semibold))
            default:
                Text(String(format: "%02d", receipt.stage.number))
                    .releaseFont(20, weight: .medium, design: .rounded, relativeTo: .headline)
                    .monospacedDigit()
            }
        }
        .foregroundStyle(tone)
        .frame(width: 54, height: 54)
        .background(tone.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 11, style: .continuous)
                .stroke(tone.opacity(0.64), lineWidth: 1)
        )
        .accessibilityHidden(true)
    }
}

private struct GateConnector: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                path.move(to: CGPoint(x: 0.5, y: 0))
                path.addLine(to: CGPoint(x: 0.5, y: geometry.size.height))
            }
            .stroke(
                Color.secondaryText.opacity(0.5),
                style: StrokeStyle(lineWidth: 1, lineCap: .round, dash: [4, 4])
            )
        }
        .frame(width: 1)
        .allowsHitTesting(false)
        .accessibilityHidden(true)
    }
}

private struct ReleaseGateRow: View {
    let receipt: PipelineStageReceipt
    let isActive: Bool
    let isExpanded: Bool
    let securityBadge: String?
    let onToggle: () -> Void

    private var rowOpacity: Double {
        switch receipt.evidenceStatus {
        case .held: return 0.78
        case .unproven: return 0.88
        default: return 1
        }
    }

    private var presentationTone: Color {
        receipt.evidenceStatus == .blocked ? .warningAccent : receipt.evidenceStatus.tone.color
    }
    private var actionLabel: String {
        if let completedChecks = receipt.completedChecks,
           let requiredChecks = receipt.requiredChecks,
           requiredChecks > 0,
           completedChecks < requiredChecks {
            return "\(completedChecks) / \(requiredChecks) checks"
        }
        if receipt.evidenceStatus == .unproven { return "Binding required" }
        if receipt.evidenceStatus == .held { return "Held observation" }
        return receipt.compactActionLabel
    }

    private var stateTone: Color {
        if receipt.evidenceStatus == .passed { return .successAccent }
        return isActive ? presentationTone : .bodyText
    }

    var body: some View {
        Button(action: onToggle) {
            VStack(alignment: .leading, spacing: isExpanded ? 12 : 6) {
                HStack(alignment: .top, spacing: 13) {
                    GateSymbol(receipt: receipt, isActive: isActive)
                        .frame(width: 54)

                    VStack(alignment: .leading, spacing: 5) {
                        Text(receipt.stage.title)
                            .releaseFont(16, weight: isActive ? .medium : .regular, relativeTo: .subheadline)
                            .foregroundStyle(.primaryText)
                            .lineLimit(1)
                        HStack(spacing: 5) {
                            Circle()
                                .fill(stateTone)
                                .frame(width: 8, height: 8)
                            Text(receipt.evidenceStatus.label.uppercased())
                                .releaseFont(12, weight: isActive ? .medium : .regular, relativeTo: .caption)
                                .foregroundStyle(stateTone)
                            Text("•")
                                .foregroundStyle(.secondaryText)
                            Text(actionLabel)
                                .releaseFont(12, weight: .regular, relativeTo: .caption)
                                .foregroundStyle(.bodyText)
                                .lineLimit(1)
                                .help(receipt.nextAction)
                        }
                    }

                    Spacer(minLength: 5)
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.bodyText)
                        .padding(.top, 4)
                }

                if isExpanded {
                    Text(receipt.stage.supportingText)
                        .releaseFont(14, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .frame(maxWidth: 292, alignment: .leading)
                        .padding(.leading, 68)
                        .fixedSize(horizontal: false, vertical: true)
                }
                if let securityBadge, !securityBadge.isEmpty {
                    Text(securityBadge)
                        .releaseFont(11, weight: .medium, relativeTo: .caption2)
                        .foregroundStyle(Color.warningAccent)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .overlay(
                            RoundedRectangle(cornerRadius: 5, style: .continuous)
                                .stroke(Color.warningAccent.opacity(0.62), lineWidth: 1)
                        )
                        .padding(.top, 2)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, isExpanded ? 14 : 12)
            .padding(.vertical, isExpanded ? 15 : 11)
            .background {
                if isActive {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .fill(Color.releaseSurface)
                }
            }
            .overlay {
                if isActive {
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(presentationTone.opacity(0.72), lineWidth: 1)
                }
            }
            .overlay(alignment: .leading) {
                if isActive {
                    UnevenRoundedRectangle(
                        topLeadingRadius: 12,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 0,
                        topTrailingRadius: 0
                    )
                    .fill(presentationTone)
                    .frame(width: 4)
                }
            }
        }
        .buttonStyle(PipelineDisclosureButtonStyle())
        .opacity(rowOpacity)
        .accessibilityLabel(
            "Gate \(receipt.stage.number), \(receipt.stage.title). \(receipt.evidenceStatus.label). \(receipt.nextAction)."
        )
        .accessibilityValue(isExpanded ? "Expanded" : "Collapsed")
        .accessibilityHint(isExpanded ? "Hides gate details" : "Shows gate details")
    }
}

private struct GateSymbol: View {
    let receipt: PipelineStageReceipt
    let isActive: Bool

    private var presentationTone: Color {
        receipt.evidenceStatus == .blocked ? .warningAccent : receipt.evidenceStatus.tone.color
    }

    private var symbolTone: Color {
        if receipt.evidenceStatus == .passed { return .successAccent }
        return isActive ? presentationTone : .bodyText
    }

    var body: some View {
        Group {
            if receipt.evidenceStatus == .unproven {
                Image(systemName: "lock.fill")
                    .font(.system(size: 15, weight: .medium))
                    .frame(width: 34, height: 34)
                    .background(Color.primary.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .stroke(Color.secondaryText.opacity(0.6), lineWidth: 1.5)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.primary.opacity(0.08))
                    Circle()
                        .stroke(
                            symbolTone.opacity(isActive || receipt.evidenceStatus == .passed ? 0.72 : 0.65),
                            lineWidth: 1.5
                    )
                    Text(String(format: "%02d", receipt.stage.number))
                        .releaseFont(15, weight: .medium, design: .rounded, relativeTo: .caption)
                        .monospacedDigit()
                }
                .frame(width: isActive ? 44 : 34, height: isActive ? 44 : 34)
            }
        }
        .foregroundStyle(symbolTone)
        .padding(.top, isActive ? 0 : 1)
        .accessibilityHidden(true)
    }
}

private struct TesslEvidenceCard: View {
    let dashboard: SkillDashboard

    private var isLive: Bool { dashboard.tessl.dataOrigin == .liveCLI }
    private var hasRegistrySnapshot: Bool {
        dashboard.tessl.registryScore != nil
            || dashboard.tessl.registryVersion != nil
            || dashboard.tessl.registryQualityScore != nil
            || dashboard.tessl.registryImpactScore != nil
            || dashboard.tessl.registrySecurityLabel != nil
    }
    private var isHistorical: Bool {
        dashboard.tessl.dataOrigin == .cached
            || dashboard.tessl.dataOrigin == .fixture
            || (dashboard.tessl.dataOrigin == .unavailable && hasRegistrySnapshot)
    }
    private var hasCurrentCandidateDigest: Bool {
        dashboard.pipeline.orderedReceipts.first(where: { $0.stage == .candidateBaseline })?.evidenceStatus == .passed
    }
    private var statusLabel: String {
        if isLive { return "LIVE" }
        if !dashboard.tessl.cliAvailable { return "CLI UNAVAILABLE" }
        if isHistorical { return "LAST KNOWN" }
        return "UNAVAILABLE"
    }
    private var statusTone: StatusTone {
        if isLive { return .advisory }
        if isHistorical { return .pending }
        return .warning
    }
    private var versionText: String {
        guard let version = dashboard.tessl.registryVersion, !version.isEmpty else { return "version unavailable" }
        return "v" + version.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }
    private var observedText: String {
        let observation = dashboard.tessl.observedAt ?? dashboard.refreshedAt
        let elapsed = Date().timeIntervalSince(observation)
        guard observation.timeIntervalSince1970 > 0, elapsed >= 0 else { return "last observation unavailable" }
        if elapsed < 60 { return "observed \(max(1, Int(elapsed.rounded())))s ago" }
        if elapsed < 3_600 { return "observed \(Int(elapsed / 60))m ago" }
        return "observed \(Int(elapsed / 3_600))h ago"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 13) {
            HStack(alignment: .top, spacing: 13) {
                ReleaseTesslLogo(size: 50)
                VStack(alignment: .leading, spacing: 5) {
                    HStack(spacing: 7) {
                        Text("Tessl Registry")
                            .releaseFont(17, weight: .medium, relativeTo: .subheadline)
                        ReleasePill(text: statusLabel, tone: statusTone)
                    }
                    Text("\(versionText) · \(observedText)")
                        .releaseFont(12.5, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .lineLimit(1)
                        .monospacedDigit()
                    Text(dashboard.registryPath)
                        .releaseFont(11.5, weight: .regular, relativeTo: .caption2)
                        .foregroundStyle(.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help("Tessl package identity: \(dashboard.registryPath)")
                }
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 5) {
                    if let score = dashboard.tessl.registryScore {
                        RegistryScoreHex(score: "\(score)", muted: !isLive)
                    }
                    if let multiplier = dashboard.tessl.registryImprovementMultiplier {
                        ReleasePill(
                            text: String(format: "%.2fx lift", multiplier),
                            tone: dashboard.tessl.registryImpactTone
                        )
                    }
                }
            }

            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .font(.system(size: 20, weight: .medium))
                    .foregroundStyle(Color.advisoryAccent)
                Text("Registry data is not proof for the current local candidate.")
                    .releaseFont(14, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.primaryText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 11)
            .background(Color.advisoryAccent.opacity(0.045))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(Color.advisoryAccent.opacity(0.28), lineWidth: 1)
            )

            EvidenceValueTransition(
                key: dashboard.tessl.motionKey,
                isEnabled: isLive,
                animation: SkillsBarMotion.tesslRefresh
            ) {
                HStack(spacing: 12) {
                    RegistryMetric(
                        label: "Quality",
                        value: dashboard.tessl.registryQualityScore.map { "\($0)%" } ?? "—",
                        progress: dashboard.tessl.registryQualityScore.map { Double($0) / 100 },
                        tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryQualityScore),
                        muted: !isLive,
                        animateChanges: isLive
                    )
                    RegistryVerticalDivider()
                    RegistryMetric(
                        label: "Impact",
                        value: dashboard.tessl.registryImpactScore.map { "\($0)%" } ?? "—",
                        progress: dashboard.tessl.registryImpactScore.map { Double($0) / 100 },
                        tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryImpactScore),
                        muted: !isLive,
                        animateChanges: isLive
                    )
                    RegistryVerticalDivider()
                    RegistryMetric(
                        label: "Security",
                        value: dashboard.tessl.registrySecurityDisplay,
                        progress: dashboard.tessl.registrySecurityTone == .positive ? 1 : nil,
                        tone: dashboard.tessl.registrySecurityTone,
                        muted: !isLive,
                        animateChanges: isLive
                    )
                }
            }

            if !dashboard.registryEvidenceCaption.isEmpty {
                Text(dashboard.registryEvidenceCaption)
                    .releaseFont(11, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(Color.advisoryAccent.opacity(isLive ? 0.84 : 0.68))
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let url = dashboard.registryURL {
                HStack {
                    Spacer(minLength: 4)
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Text("View in Tessl.io  →")
                            .releaseFont(14, weight: .medium, relativeTo: .caption)
                            .foregroundStyle(Color.advisoryAccent)
                    }
                    .buttonStyle(.plain)
                    .frame(minHeight: MenuBarTemplateMetrics.minimumInteractiveTarget)
                    .contentShape(Rectangle())
                    .accessibilityLabel("View in Tessl.io")
                    Spacer(minLength: 4)
                }
            }
            if !isLive, !hasCurrentCandidateDigest {
                Text("Content comparison blocked until candidate digest exists.")
                    .releaseFont(10, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
            }
        }
        .padding(15)
        .background(Color.releaseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.teal.opacity(isLive ? 0.42 : 0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Tessl Registry. \(isLive ? "Live registry data" : (isHistorical ? "CLI unavailable, last known registry data" : "Registry comparison unavailable")). "
                + dashboard.registryEvidenceCaption
        )
    }
}

private struct RegistryMetric: View {
    let label: String
    let value: String
    let progress: Double?
    let tone: StatusTone
    let muted: Bool
    let animateChanges: Bool

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .releaseFont(12, weight: .regular, relativeTo: .caption2)
                .foregroundStyle(.bodyText)
            Text(value)
                .releaseFont(17, weight: .medium, design: .rounded, relativeTo: .subheadline)
                .foregroundStyle(tone.color.opacity(muted ? 0.68 : 1))
                .monospacedDigit()
                .contentTransition(.opacity)
                .animation(
                    animateChanges && !reduceMotion ? SkillsBarMotion.tesslRefresh : nil,
                    value: value
                )
            GeometryReader { _ in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.releaseMetricTrack)
                    if let progress {
                        Capsule()
                            .fill(tone.color.opacity(muted ? 0.62 : 1))
                            .frame(maxWidth: .infinity)
                            .scaleEffect(
                                x: min(max(progress, 0), 1),
                                y: 1,
                                anchor: .leading
                            )
                            .animation(
                                animateChanges && !reduceMotion ? SkillsBarMotion.tesslRefresh : nil,
                                value: progress
                            )
                    }
                }
            }
            .frame(height: 7)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RegistryVerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.primary.opacity(0.12))
            .frame(width: 1, height: 50)
    }
}

private struct ReleaseFooter: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    let onRefresh: (() -> Void)?
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    private var refreshedText: String {
        guard dashboard.refreshedAt.timeIntervalSince1970 > 0 else { return "Last checked unavailable" }
        let elapsed = Date().timeIntervalSince(dashboard.refreshedAt)
        if elapsed < 60 { return "Last checked \(max(1, Int(elapsed.rounded())))s ago" }
        if elapsed < 3_600 { return "Last checked \(Int(elapsed / 60))m ago" }
        return "Last checked \(Int(elapsed / 3_600))h ago"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 8) {
                Button { onRefresh?() } label: {
                    HStack(spacing: 7) {
                        Image(systemName: isRefreshing ? "arrow.triangle.2.circlepath" : "arrow.clockwise")
                            .font(.system(size: 16, weight: .medium))
                        Text(isRefreshing ? "Refreshing" : "Refresh")
                            .releaseFont(13, weight: .regular, relativeTo: .caption)
                    }
                }
                .buttonStyle(ReleasePressButtonStyle())
                .frame(
                    width: 88,
                    height: MenuBarTemplateMetrics.minimumInteractiveTarget,
                    alignment: .leading
                )
                .foregroundStyle(.bodyText)
                .disabled(onRefresh == nil || isRefreshing)
                .help("Refresh local evidence and registry metadata")
                .accessibilityLabel("Refresh evidence")

                Spacer(minLength: 4)
                Text(refreshedText)
                    .releaseFont(12, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
                    .monospacedDigit()

                Menu {
                    Button("Copy summary") {
                        feedback.copy(diagnosticSummary)
                    }
                    Button("Copy latest observation") {
                        feedback.copy(historySummary)
                    }
                    Button("Copy selected skill path") {
                        feedback.copy(dashboard.fleet.selectedSkillPath)
                    }
                    Button("Copy model profile") {
                        feedback.copy(profileSummary)
                    }
                    Divider()
                    Button("Quit SkillsBar") { NSApp.terminate(nil) }
                } label: {
                    Label("More…", systemImage: "ellipsis.circle")
                        .labelStyle(.titleAndIcon)
                        .releaseFont(12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                }
                .menuStyle(.borderlessButton)
                .menuIndicator(.hidden)
                .tint(.bodyText)
                .frame(
                    minWidth: 82,
                    minHeight: MenuBarTemplateMetrics.minimumInteractiveTarget,
                    alignment: .trailing
                )
                .help("More SkillsBar actions")
                .accessibilityLabel("More SkillsBar actions")
            }
            .frame(maxWidth: .infinity)

            FooterUtilityPanel(
                copyDiagnostics: { feedback.copy(diagnosticSummary) },
                copyHistory: { feedback.copy(historySummary) },
                copyProfile: { feedback.copy(profileSummary) }
            )
        }
        .padding(.bottom, 5)
    }

    private var diagnosticSummary: String {
        let active = dashboard.pipeline.activeReceipt.map { "Gate \($0.stage.number) \($0.stage.title): \($0.evidenceStatus.label)" } ?? "All gates passed"
        return [
            "SkillsBar diagnostic summary",
            "Skill: \(dashboard.displayName)",
            "Candidate: \(dashboard.pipeline.fingerprint)",
            active,
            "Tessl: \(dashboard.registryEvidenceCaption)"
        ].joined(separator: "\n")
    }

    private var historySummary: String {
        let observation = dashboard.refreshedAt.timeIntervalSince1970 > 0
            ? ISO8601DateFormatter().string(from: dashboard.refreshedAt)
            : "unavailable"
        return [
            "SkillsBar latest observation",
            "Observed at: \(observation)",
            "Active gate: \(dashboard.pipeline.activeReceipt?.stage.title ?? "All gates passed")",
            "Registry: \(dashboard.registryEvidenceCaption)"
        ].joined(separator: "\n")
    }

    private var profileSummary: String {
        let profile = dashboard.pipeline.activeReceipt?.modelProfile ?? "not declared"
        return [
            "SkillsBar selected profile",
            "Skill path: \(dashboard.fleet.selectedSkillPath)",
            "Model profile: \(profile)"
        ].joined(separator: "\n")
    }
}

private struct FooterUtilityPanel: View {
    let copyDiagnostics: () -> Void
    let copyHistory: () -> Void
    let copyProfile: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            utilityButton("Diagnostics", icon: "waveform.path.ecg", action: copyDiagnostics)
            utilityButton("History", icon: "clock", action: copyHistory)
            utilityButton("Profile", icon: "person.crop.circle", action: copyProfile)
        }
        .padding(.vertical, 5)
        .background(Color.releaseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(Color.releaseBorderSubtle, lineWidth: 1)
        )
    }

    private func utilityButton(_ title: String, icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Label(title, systemImage: icon)
                .releaseFont(14, weight: .regular, relativeTo: .subheadline)
                .foregroundStyle(.primaryText)
                .frame(
                    maxWidth: .infinity,
                    minHeight: MenuBarTemplateMetrics.minimumInteractiveTarget,
                    alignment: .leading
                )
                .padding(.horizontal, 14)
        }
        .buttonStyle(PipelineDisclosureButtonStyle())
        .accessibilityHint("Copies \(title.lowercased()) information to the clipboard")
    }
}

private struct CanonicalIdentityAction: View {
    let receipt: PipelineStageReceipt?
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    private var command: String { receipt?.command ?? "" }
    private var title: String {
        receipt.map { "\($0.stage.title) command" } ?? "All gates current"
    }
    private var subtitle: String {
        receipt?.nextAction ?? "No held downstream gates"
    }
    private var commandLabel: String {
        receipt.map { "Copy the \($0.stage.title.lowercased()) command" } ?? "Copy pipeline command"
    }
    private var commandPreview: String {
        let executableCommand: String
        if let separator = command.range(of: " && ") {
            executableCommand = String(command[separator.upperBound...])
        } else {
            executableCommand = command
        }

        guard let pathStart = executableCommand.range(of: "'Skills/"),
              let pathEnd = executableCommand[pathStart.upperBound...].firstIndex(of: "'") else {
            return executableCommand
        }
        let path = executableCommand[pathStart.lowerBound..<pathEnd]
        let finalComponent = path.split(separator: "/").last.map(String.init) ?? "skill"
        return executableCommand.replacingCharacters(
            in: pathStart.lowerBound...pathEnd,
            with: "…/\(finalComponent)"
        )
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "terminal")
                .font(.system(size: 19, weight: .medium))
                .frame(width: 38, height: 38)
                .background(Color.primary.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.primary.opacity(0.17), lineWidth: 1)
                )
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 3) {
                Text(title)
                    .releaseFont(14, weight: .medium, relativeTo: .subheadline)
                Text(subtitle)
                    .releaseFont(10.5, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
                if !command.isEmpty {
                    Text(commandPreview)
                        .releaseFont(10, weight: .regular, design: .monospaced, relativeTo: .caption2)
                        .foregroundStyle(Color.primary.opacity(0.78))
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.primary.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            Spacer(minLength: 4)
            if !command.isEmpty {
                Button { feedback.copy(command) } label: {
                    Image(systemName: feedback.copiedCommand == command ? "checkmark" : "doc.on.doc")
                        .font(.system(size: 16, weight: .semibold))
                        .frame(
                            width: MenuBarTemplateMetrics.minimumInteractiveTarget,
                            height: MenuBarTemplateMetrics.minimumInteractiveTarget
                        )
                }
                .buttonStyle(ReleasePressButtonStyle())
                .foregroundStyle(feedback.copiedCommand == command ? Color.successAccent : Color.primaryText)
                .help(commandLabel)
                .accessibilityLabel(commandLabel)
                .accessibilityValue(command)
            }
            Button { NSApp.terminate(nil) } label: {
                Image(systemName: "power")
                    .font(.system(size: 15, weight: .semibold))
                .frame(
                    width: MenuBarTemplateMetrics.minimumInteractiveTarget,
                    height: MenuBarTemplateMetrics.minimumInteractiveTarget
                )
            }
            .buttonStyle(ReleasePressButtonStyle())
            .foregroundStyle(.primaryText)
            .help("Quit SkillsBar")
            .accessibilityLabel("Quit SkillsBar")
        }
        .padding(10)
        .background(Color.releaseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.releaseBorderSubtle, lineWidth: 1)
        )
    }
}

private struct ReleasePill: View {
    let text: String
    let tone: StatusTone

    var body: some View {
        Text(text)
            .releaseFont(8.5, weight: .medium, design: .rounded, relativeTo: .caption2)
            .foregroundStyle(tone.color)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(tone.color.opacity(0.08))
            .overlay(Capsule().stroke(tone.color.opacity(0.38), lineWidth: 1))
            .clipShape(Capsule())
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct RegistryScoreHex: View {
    let score: String
    let muted: Bool

    var body: some View {
        ZStack {
            ReleaseHexagon()
                .fill(
                    LinearGradient(
                        colors: [
                            Color.warningAccent.opacity(muted ? 0.025 : 0.075),
                            Color.primary.opacity(0.08),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ReleaseHexagon()
                .stroke(Color.primary.opacity(muted ? 0.035 : 0.075), lineWidth: 0.75)
                .padding(3)
            ReleaseHexagon()
                .stroke(Color.warningAccent.opacity(muted ? 0.4 : 0.92), lineWidth: 1.6)
            Text(score)
                .releaseFont(18, weight: .semibold, design: .rounded, relativeTo: .title3)
                .foregroundStyle(Color.warningAccent.opacity(muted ? 0.56 : 1))
                .monospacedDigit()
        }
        .frame(width: 40, height: 44)
        .accessibilityLabel("Registry score \(score)")
    }
}

private struct ReleaseHexagon: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.25))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.75))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.height * 0.25))
        path.closeSubpath()
        return path
    }
}

private struct ReleaseSkillLogo: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = SkillsSDKIconLoader.image {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "doc.text")
                    .font(.system(size: size * 0.48, weight: .medium))
            }
        }
        .frame(width: size, height: size)
        .background(Color.releaseSurface)
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.primary.opacity(0.18), lineWidth: 1)
        )
    }
}

private struct ReleaseTesslLogo: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = TesslLogoLoader.image {
                Image(nsImage: image).resizable().interpolation(.high).scaledToFit()
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: size * 0.48, weight: .medium))
            }
        }
        .frame(width: size, height: size)
        .background(Color.primary.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.advisoryAccent.opacity(0.24), lineWidth: 1)
        )
    }
}

private struct ReleaseDivider: View {
    var body: some View {
        Rectangle().fill(Color.primary.opacity(0.11)).frame(height: 1)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }
}

private struct ReleasePressButtonStyle: ButtonStyle {
    var tint: Color = .primary
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.primary.opacity(configuration.isPressed ? 0.11 : 0.045))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.72 : 0.42), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.11), value: configuration.isPressed)
    }
}

private struct PipelineDisclosureButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.releaseSurfacePressed.opacity(configuration.isPressed ? 1 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
            .opacity(configuration.isPressed ? 0.84 : 1)
            .contentShape(Rectangle())
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.96 : 1)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.10), value: configuration.isPressed)
    }
}

private struct ReleaseScaledFont: ViewModifier {
    @ScaledMetric private var size: CGFloat
    let weight: Font.Weight
    let design: Font.Design

    init(_ size: CGFloat, weight: Font.Weight, design: Font.Design, relativeTo style: Font.TextStyle) {
        _size = ScaledMetric(wrappedValue: size, relativeTo: style)
        self.weight = weight
        self.design = design
    }

    func body(content: Content) -> some View {
        content.font(.system(size: size, weight: weight, design: design))
    }
}

private extension View {
    func releaseFont(
        _ size: CGFloat,
        weight: Font.Weight,
        design: Font.Design = .default,
        relativeTo style: Font.TextStyle
    ) -> some View {
        modifier(ReleaseScaledFont(size, weight: weight, design: design, relativeTo: style))
    }
}
