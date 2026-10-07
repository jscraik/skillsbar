import AppKit
import SwiftUI

private enum SkillsBarMotion {
    static let feedback = Animation.easeOut(duration: 0.12)
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
            ReleaseHeader(
                dashboard: dashboard,
                isRefreshing: isRefreshing,
                isFixture: isFixture
            ) {
                SkillSelectionMenu(
                    dashboard: dashboard,
                    selectedSkillPath: selectedSkillPath,
                    availableSkillPaths: availableSkillPaths,
                    isPinned: isSkillSelectionPinned,
                    onSelect: onSelectSkill
                )
            }
            ReleaseDivider().padding(.top, 8).padding(.bottom, 4)
            ScrollView {
                VStack(alignment: .leading, spacing: 8) {
                    FocusNavigator(candidate: dashboard.pipeline, securityBadge: dashboard.security.severityLine)
                    TesslEvidenceCard(dashboard: dashboard)
                    .padding(.vertical, 8)
                    .overlay(alignment: .top) { ReleaseDivider() }
                }
                .padding(.trailing, 2)
            }
            .scrollIndicators(.automatic)
            .scrollBounceBehavior(.basedOnSize)
            .frame(maxHeight: .infinity)
            .layoutPriority(1)
            ReleaseDivider().padding(.top, 2)
            ReleaseFooter(dashboard: dashboard, isRefreshing: isRefreshing, onRefresh: onRefresh)
        }
    }
}

private struct FocusNavigator: View {
    let candidate: PipelineCandidate
    let securityBadge: String
    @StateObject private var selection: FocusNavigatorModel

    init(candidate: PipelineCandidate, securityBadge: String) {
        self.candidate = candidate
        self.securityBadge = securityBadge
        _selection = StateObject(wrappedValue: FocusNavigatorModel(candidate: candidate))
    }

    private var summary: String {
        let receipts = candidate.orderedReceipts
        let counts: [(PipelineEvidenceStatus, String)] = [
            (.passed, "passed"), (.reviewRequired, "needs review"),
            (.blocked, "blocked"), (.stale, "stale")
        ]
        var parts = counts.compactMap { status, label -> String? in
            let count = receipts.filter { $0.evidenceStatus == status }.count
            return count > 0 ? "\(count) \(label)" : nil
        }
        let awaiting = receipts.filter { $0.evidenceStatus == .held || $0.evidenceStatus == .unproven }.count
        if awaiting > 0 { parts.append("\(awaiting) awaiting proof") }
        return parts.joined(separator: " · ")
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            PipelineStageGrid(candidate: candidate, selection: selection)
            Text(summary)
                .releaseFont(13, weight: .regular, relativeTo: .caption)
                .foregroundStyle(.bodyText).monospacedDigit()
                .fixedSize(horizontal: false, vertical: true)
            ReleaseDivider().padding(.vertical, 4)
            if let receipt = selection.receipt(in: candidate) {
                SelectedStageDetail(
                    receipt: receipt,
                    activeStage: candidate.activeReceipt?.stage,
                    stageCount: candidate.orderedReceipts.count,
                    securityBadge: securityBadge
                )
                .id(receipt.stage)
                .id(candidate.fingerprint)
            }
        }
        .onChange(of: candidate) { _, updated in selection.reconcile(updated) }
    }
}

private struct PipelineStageGrid: View {
    let candidate: PipelineCandidate
    @ObservedObject var selection: FocusNavigatorModel
    @FocusState private var focusedStage: PipelineStage?

    var body: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 5), count: 3), spacing: 5) {
            ForEach(candidate.orderedReceipts, id: \.stage) { receipt in
                PipelineStageCell(
                    receipt: receipt,
                    isSelected: selection.selectedStage == receipt.stage,
                    isCurrent: candidate.activeReceipt?.stage == receipt.stage,
                    isFocused: focusedStage == receipt.stage
                ) {
                    selection.select(receipt.stage)
                }
                .focused($focusedStage, equals: receipt.stage)
            }
        }
        .onMoveCommand { direction in
            guard let stage = focusedStage,
                  let next = selection.moveFocus(from: stage, direction: direction)
            else { return }
            focusedStage = next
        }
    }
}

private struct PipelineStageCell: View {
    @Environment(\.colorScheme) private var colorScheme
    let receipt: PipelineStageReceipt
    let isSelected: Bool
    let isCurrent: Bool
    let isFocused: Bool
    let action: () -> Void

    private var tint: Color {
        isCurrent ? (colorScheme == .dark ? .warningAccent : .focusWarningInk) : .focusActionBlue
    }

    var body: some View {
        Button(action: action) {
            VStack(spacing: 3) {
                ZStack {
                    HStack {
                    Text(String(format: "%02d", receipt.stage.number))
                        .releaseFont(14, weight: .regular, relativeTo: .caption)
                        .monospacedDigit()
                    Spacer()
                    }
                    Image(systemName: receipt.evidenceStatus.symbol)
                        .font(.system(size: 17, weight: .medium))
                        .foregroundStyle(receipt.evidenceStatus.iconColor(in: colorScheme))
                }
                Text(receipt.stage.compactTitle)
                    .releaseFont(13, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(isSelected && isCurrent ? tint : Color.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .foregroundStyle(.primary)
            .frame(maxWidth: .infinity, minHeight: 36)
            .padding(.horizontal, 12).padding(.vertical, 5)
            .background(isSelected ? tint.opacity(0.08) : Color.primary.opacity(0.012), in: RoundedRectangle(cornerRadius: 8))
            .overlay(RoundedRectangle(cornerRadius: 8).strokeBorder(isSelected ? tint.opacity(0.85) : Color.releaseBorderSubtle, lineWidth: isSelected ? 1.5 : 1))
            .overlay(RoundedRectangle(cornerRadius: 6).inset(by: 3).stroke(isFocused ? Color.primary : .clear, lineWidth: 2).allowsHitTesting(false))
        }
        .buttonStyle(FocusStageButtonStyle())
        .accessibilityLabel("Stage \(receipt.stage.number), \(receipt.stage.title), \(receipt.evidenceStatus.label)\(isCurrent ? ", next required" : "")")
        .accessibilityAddTraits(isSelected ? .isSelected : [])
        .help("\(receipt.stage.title) · \(receipt.evidenceStatus.label)")
    }
}

struct SelectedStageDetail: View {
    @ScaledMetric(relativeTo: .caption) private var statusHeight = 26.0
    @ScaledMetric(relativeTo: .body) private var explanationHeight = 38.0
    let receipt: PipelineStageReceipt
    let activeStage: PipelineStage?
    let stageCount: Int
    let securityBadge: String

    private var detailText: String {
        if receipt.stage == .securityReview,
           receipt.evidenceStatus == .reviewRequired,
           receipt.nextAction.contains("full governed security receipt is missing or malformed") {
            return "Full security receipt missing or malformed.\nInspect findings before continuing."
        }
        return receipt.nextAction
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(alignment: .firstTextBaseline) {
                Text("Gate \(String(format: "%02d", receipt.stage.number)) / \(String(format: "%02d", stageCount))")
                    .monospacedDigit()
                Spacer(minLength: 8)
                if let activeStage {
                    Text(activeStage == receipt.stage ? "Next required" : "Next required: Gate \(String(format: "%02d", activeStage.number))")
                } else {
                    Text("All stages passed")
                }
            }
            .releaseFont(12, weight: .regular, relativeTo: .caption)
            .foregroundStyle(.bodyText)
            Text(receipt.stage.title)
                .releaseFont(19, weight: .medium, relativeTo: .headline)
                .fixedSize(horizontal: false, vertical: true)
            Group {
                if receipt.stage == .securityReview, !securityBadge.isEmpty {
                    SeverityBadges(labels: securityBadge)
                } else {
                    Label(receipt.evidenceStatus.label, systemImage: receipt.evidenceStatus.symbol)
                        .releaseFont(13, weight: .medium, relativeTo: .subheadline)
                }
            }
            .frame(minHeight: statusHeight, alignment: .leading)
            Text(detailText)
                .releaseFont(13, weight: .regular, relativeTo: .body)
                .foregroundStyle(.primary)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
                .frame(minHeight: explanationHeight, alignment: .topLeading)
                .accessibilityLabel(receipt.nextAction)
            if !receipt.command.isEmpty {
                CommandAction(receipt: receipt)
            } else {
                Text("No command available for this stage")
                    .releaseFont(12, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
                    .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct SeverityBadges: View {
    let labels: String

    private var values: [String] {
        labels.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    var body: some View {
        ViewThatFits(in: .horizontal) {
            HStack(spacing: 8) { badges }
            VStack(alignment: .leading, spacing: 6) { badges }
        }
    }

    @ViewBuilder private var badges: some View {
        ForEach(values, id: \.self) { label in
            StatusBadge(text: label, tone: .warning, prominence: .strong)
        }
    }
}

@MainActor
private final class CommandDisclosureModel: ObservableObject {
    @Published var isExpanded = false
}

private struct CommandAction: View {
    let receipt: PipelineStageReceipt
    @StateObject private var disclosure = CommandDisclosureModel()

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            HStack(spacing: 12) {
                Button {
                    disclosure.isExpanded.toggle()
                } label: {
                    Label(disclosure.isExpanded ? "Hide command" : "Show command", systemImage: disclosure.isExpanded ? "chevron.down" : "chevron.right")
                        .releaseFont(13, weight: .regular, relativeTo: .subheadline)
                        .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
                        .contentShape(Rectangle())
                }
                .buttonStyle(FocusStageButtonStyle())
                .accessibilityValue(disclosure.isExpanded ? "Expanded" : "Collapsed")
                Spacer(minLength: 0)
                GateCopyButton(receipt: receipt)
            }
            if disclosure.isExpanded {
                Text(receipt.command)
                    .releaseFont(12, weight: .regular, design: .monospaced, relativeTo: .caption)
                    .textSelection(.enabled)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(10)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.releaseSurface, in: RoundedRectangle(cornerRadius: 6))
            }
        }
    }
}

private extension PipelineEvidenceStatus {
    var symbol: String {
        switch self {
        case .passed: return "checkmark.circle.fill"
        case .reviewRequired: return "exclamationmark.triangle.fill"
        case .blocked: return "xmark.octagon.fill"
        case .held: return "pause.circle.fill"
        case .unproven: return "minus.circle.fill"
        case .stale: return "clock.badge.exclamationmark"
        }
    }

    func iconColor(in colorScheme: ColorScheme) -> Color {
        guard colorScheme == .light else { return tone.color }
        switch self {
        case .passed: return Color(red: 0.08, green: 0.46, blue: 0.20)
        case .reviewRequired: return .focusWarningInk
        case .blocked: return Color(red: 0.72, green: 0.12, blue: 0.10)
        case .held, .unproven, .stale: return .secondary
        }
    }
}

private struct FocusStageButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @StateObject private var interaction = SurfaceInteraction()

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.primary)
                    .opacity(configuration.isPressed ? 0.10 : (interaction.isHovered && isEnabled ? 0.04 : 0))
                    .animation(reduceMotion ? nil : SkillsBarMotion.feedback, value: interaction.isHovered)
                    .allowsHitTesting(false)
            }
            .opacity(configuration.isPressed ? 0.82 : 1)
            .onHover { interaction.isHovered = $0 }
    }
}

@MainActor
private final class SurfaceInteraction: ObservableObject {
    @Published var isHovered = false
}

private struct ReleaseHeader<Actions: View>: View {
    @Environment(\.colorScheme) private var colorScheme
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    let isFixture: Bool
    let actions: Actions

    init(
        dashboard: SkillDashboard,
        isRefreshing: Bool,
        isFixture: Bool,
        @ViewBuilder actions: () -> Actions
    ) {
        self.dashboard = dashboard
        self.isRefreshing = isRefreshing
        self.isFixture = isFixture
        self.actions = actions()
    }

    private var statusLabel: String {
        switch status {
        case .current: return "Up to date"
        case .attention: return "Needs attention"
        case .blocked: return "Blocked"
        case .refreshing: return "Refreshing"
        case .unavailable: return "Unavailable"
        }
    }
    private var status: MenuBarStatus { .resolve(dashboard: dashboard, isRefreshing: isRefreshing) }
    private var statusColor: Color {
        if colorScheme == .light {
            if status == .refreshing { return .focusInfoInk }
            if status == .attention { return .focusWarningInk }
        }
        return status.color
    }

    private var statusAccessibilityLabel: String {
        status.label
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ReleaseSkillLogo(size: 48)
            VStack(alignment: .leading, spacing: 4) {
                Text("SKILLS SDK")
                    .releaseFont(12, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
                Text(dashboard.displayName)
                    .releaseFont(16, weight: .medium, relativeTo: .headline)
                    .lineLimit(1).minimumScaleFactor(0.8)
                    .help(dashboard.displayName)
                HStack(spacing: 8) {
                    StatusBadge(text: isFixture ? "Demo" : "Local", tone: .advisory)
                    Text("v\(dashboard.version.trimmingCharacters(in: CharacterSet(charactersIn: "vV")))")
                        .releaseFont(13, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText).monospacedDigit().fixedSize()
                    HStack(spacing: 5) {
                        Circle().fill(statusColor).frame(width: 8, height: 8)
                        Text(statusLabel)
                            .releaseFont(13, weight: .medium, relativeTo: .caption)
                            .foregroundStyle(statusColor)
                    }
                    .accessibilityLabel(statusAccessibilityLabel)
                    .fixedSize()
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .layoutPriority(1)
            actions
        }
        .accessibilityElement(children: .contain)
    }
}

private struct SkillSelectionMenu: View {
    let dashboard: SkillDashboard
    let selectedSkillPath: String
    let availableSkillPaths: [String]
    let isPinned: Bool
    let onSelect: ((String) -> Void)?

    private var selectedName: String {
        Self.skillName(for: selectedSkillPath)
    }

    var body: some View {
            Menu {
            Menu("Select skill") {
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
            }
            Divider()
            ReleaseUtilityActions(dashboard: dashboard)
            Button("Close popover") { NSApp.keyWindow?.orderOut(nil) }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 12, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Rectangle())
        }
        .menuStyle(.borderlessButton)
        .menuIndicator(.hidden)
        .frame(width: 44, height: 44)
        .background { Circle().fill(Color.primary.opacity(0.035)).frame(width: 34, height: 34) }
        .overlay { Circle().strokeBorder(Color.primary.opacity(0.13), lineWidth: 1).frame(width: 34, height: 34).allowsHitTesting(false) }
        .help("More actions and skill selection")
        .accessibilityLabel("More SkillsBar actions; selected skill \(selectedName)")
    }

    private static func skillName(for path: String) -> String {
        let url = URL(fileURLWithPath: path)
        return url.deletingLastPathComponent().lastPathComponent.isEmpty
            ? path
            : url.deletingLastPathComponent().lastPathComponent
    }
}

private struct GateCopyButton: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    let receipt: PipelineStageReceipt
    @ObservedObject private var feedback = CopyFeedbackModel.shared
    private var copyError: String? { feedback.error(for: receipt.command) }

    var body: some View {
        Button {
            feedback.copy(receipt.command)
        } label: {
            HStack(spacing: 8) {
                Image(systemName: copyError != nil ? "exclamationmark.circle" : (feedback.copiedCommand == receipt.command ? "checkmark" : "doc.on.clipboard"))
                    .frame(width: 18)
                    .contentTransition(.opacity)
                    .animation(reduceMotion ? nil : SkillsBarMotion.feedback, value: feedback.copiedCommand)
                Text(copyError != nil ? "Retry copy" : (feedback.copiedCommand == receipt.command ? "Copied" : "Copy command"))
                    .frame(minWidth: 104, alignment: .leading)
            }
            .releaseFont(14, weight: .regular, relativeTo: .caption)
            .frame(minWidth: 132)
            .padding(.horizontal, 10)
            .frame(minHeight: 32)
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.roundedRectangle(radius: 8))
        .tint(.focusActionBlue)
        .help(copyError ?? "Copy the full \(receipt.stage.title.lowercased()) command")
        .accessibilityLabel("Copy the full \(receipt.stage.title.lowercased()) command")
        .accessibilityValue(copyError ?? (feedback.copiedCommand == receipt.command ? "Copied" : "Copies without executing"))
    }
}

private struct TesslRegistryPresentation {
    let isLive: Bool
    let hasRegistrySnapshot: Bool
    let isHistorical: Bool
    let hasCurrentCandidateDigest: Bool
    let statusLabel: String
    let statusTone: StatusTone
    let compactCaption: String
    let versionText: String
    let observedText: String

    init(dashboard: SkillDashboard, now: Date = Date()) {
        isLive = dashboard.tessl.dataOrigin == .liveCLI
        hasRegistrySnapshot = dashboard.tessl.registryScore != nil
            || dashboard.tessl.registryVersion != nil
            || dashboard.tessl.registryQualityScore != nil
            || dashboard.tessl.registryImpactScore != nil
            || dashboard.tessl.registrySecurityLabel != nil
        isHistorical = dashboard.tessl.dataOrigin == .cached
            || dashboard.tessl.dataOrigin == .fixture
            || (dashboard.tessl.dataOrigin == .unavailable && hasRegistrySnapshot)
        hasCurrentCandidateDigest = dashboard.pipeline.orderedReceipts
            .first(where: { $0.stage == .candidateBaseline })?.evidenceStatus == .passed

        if isLive {
            statusLabel = "LIVE"
            statusTone = .advisory
        } else if !dashboard.tessl.cliAvailable {
            statusLabel = "CLI UNAVAILABLE"
            statusTone = hasRegistrySnapshot ? .pending : .warning
        } else if isHistorical {
            statusLabel = "LAST KNOWN"
            statusTone = .pending
        } else {
            statusLabel = "UNAVAILABLE"
            statusTone = .warning
        }

        compactCaption = !dashboard.tessl.cliAvailable && !hasRegistrySnapshot
            ? "No cached evidence · separate from local proof."
            : dashboard.registryEvidenceCaption

        if let version = dashboard.tessl.registryVersion, !version.isEmpty {
            versionText = "v" + version.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        } else {
            versionText = "version unavailable"
        }

        if let observation = dashboard.tessl.observedAt ?? (isLive ? dashboard.refreshedAt : nil),
           observation.timeIntervalSince1970 > 0,
           now.timeIntervalSince(observation) >= 0 {
            let elapsed = now.timeIntervalSince(observation)
            if elapsed < 60 {
                observedText = "observed \(max(1, Int(elapsed.rounded())))s ago"
            } else if elapsed < 3_600 {
                observedText = "observed \(Int(elapsed / 60))m ago"
            } else {
                observedText = "observed \(Int(elapsed / 3_600))h ago"
            }
        } else {
            observedText = "last observation unavailable"
        }
    }
}

private struct TesslRegistrySummary: View {
    enum Style { case compact, expanded }

    let dashboard: SkillDashboard
    let presentation: TesslRegistryPresentation
    let style: Style

    var body: some View {
        HStack(alignment: .top, spacing: style == .compact ? 10 : 13) {
            ReleaseTesslLogo(size: 36)
                .accessibilityHidden(style == .compact)
            VStack(alignment: .leading, spacing: style == .compact ? 4 : 5) {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 8) { heading }
                    VStack(alignment: .leading, spacing: 5) { heading }
                }
                if style == .compact {
                    Text(presentation.compactCaption)
                        .releaseFont(12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .fixedSize(horizontal: false, vertical: true)
                } else {
                    if presentation.hasRegistrySnapshot {
                        Text("\(presentation.versionText) · \(presentation.observedText)")
                            .releaseFont(12.5, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                            .fixedSize(horizontal: false, vertical: true)
                            .monospacedDigit()
                    }
                    Text(dashboard.registryPath)
                        .releaseFont(11.5, weight: .regular, relativeTo: .caption2)
                        .foregroundStyle(.secondaryText)
                        .lineLimit(1)
                        .truncationMode(.middle)
                        .help("Tessl package identity: \(dashboard.registryPath)")
                }
            }
            if style == .expanded {
                Spacer(minLength: 4)
                VStack(alignment: .trailing, spacing: 5) {
                    if let score = dashboard.tessl.registryScore {
                        VStack(alignment: .trailing, spacing: 2) {
                            Text("\(score)")
                                .releaseFont(22, weight: .semibold, relativeTo: .title3)
                                .monospacedDigit()
                            Text("Registry score")
                                .releaseFont(11, weight: .regular, relativeTo: .caption)
                                .foregroundStyle(.secondary)
                        }
                        .accessibilityElement(children: .combine)
                    }
                    if let multiplier = dashboard.tessl.registryImprovementMultiplier {
                        StatusBadge(
                            text: String(format: "%.2fx lift", multiplier),
                            tone: dashboard.tessl.registryImpactTone
                        )
                    }
                }
            }
        }
    }

    @ViewBuilder private var heading: some View {
                    Text("Tessl Registry")
                        .releaseFont(style == .compact ? 14 : 17, weight: .medium, relativeTo: .subheadline)
                    StatusBadge(text: presentation.statusLabel == "CLI UNAVAILABLE" ? "CLI unavailable" : presentation.statusLabel.capitalized, tone: presentation.statusTone)
    }
}

private struct TesslEvidenceCard: View {
    let dashboard: SkillDashboard

    var body: some View {
        let presentation = TesslRegistryPresentation(dashboard: dashboard)
        VStack(alignment: .leading, spacing: 10) {
            TesslRegistrySummary(dashboard: dashboard, presentation: presentation,
                                 style: presentation.hasRegistrySnapshot ? .expanded : .compact)

            if presentation.hasRegistrySnapshot {
                EvidenceValueTransition(
                    key: dashboard.tessl.motionKey,
                    isEnabled: presentation.isLive,
                    animation: SkillsBarMotion.tesslRefresh
                ) {
                    HStack(spacing: 12) {
                        RegistryMetric(
                            label: "Quality",
                            value: dashboard.tessl.registryQualityScore.map { "\($0)%" } ?? "—",
                            progress: dashboard.tessl.registryQualityScore.map { Double($0) / 100 },
                            tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryQualityScore),
                            muted: !presentation.isLive,
                            animateChanges: presentation.isLive
                        )
                        RegistryVerticalDivider()
                        RegistryMetric(
                            label: "Impact",
                            value: dashboard.tessl.registryImpactScore.map { "\($0)%" } ?? "—",
                            progress: dashboard.tessl.registryImpactScore.map { Double($0) / 100 },
                            tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryImpactScore),
                            muted: !presentation.isLive,
                            animateChanges: presentation.isLive
                        )
                        RegistryVerticalDivider()
                        RegistryMetric(
                            label: "Security",
                            value: dashboard.tessl.registrySecurityDisplay,
                            progress: dashboard.tessl.registrySecurityTone == .positive ? 1 : nil,
                            tone: dashboard.tessl.registrySecurityTone,
                            muted: !presentation.isLive,
                            animateChanges: presentation.isLive
                        )
                    }
                }
            }

            if presentation.hasRegistrySnapshot, !dashboard.registryEvidenceCaption.isEmpty {
                Text(dashboard.registryEvidenceCaption)
                    .releaseFont(11, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
                    .fixedSize(horizontal: false, vertical: true)
            }
            if let url = dashboard.registryURL {
                HStack {
                    if presentation.hasRegistrySnapshot {
                        Text("Registry evidence · separate from local proof")
                            .releaseFont(11, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    Spacer(minLength: 8)
                    Button {
                        NSWorkspace.shared.open(url)
                    } label: {
                        Text("Tessl.io ↗")
                            .releaseFont(12, weight: .medium, relativeTo: .caption)
                            .foregroundStyle(Color.advisoryAccent)
                            .frame(minHeight: 40)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel("View in Tessl.io")
                }
            }
            if !presentation.isLive, !presentation.hasCurrentCandidateDigest {
                Text("Content comparison blocked until candidate digest exists.")
                    .releaseFont(10, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(
            "Tessl Registry. \(presentation.statusLabel). "
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

    private var refreshedText: String {
        guard dashboard.refreshedAt.timeIntervalSince1970 > 0 else { return "Checked time unavailable" }
        let elapsed = Date().timeIntervalSince(dashboard.refreshedAt)
        if elapsed < 60 { return "Checked \(max(1, Int(elapsed.rounded())))s ago" }
        if elapsed < 3_600 { return "Checked \(Int(elapsed / 60))m ago" }
        return "Checked \(Int(elapsed / 3_600))h ago"
    }

    var body: some View {
        Button { onRefresh?() } label: {
            HStack(spacing: 10) {
                Image(systemName: "arrow.clockwise")
                    .font(.system(size: 18, weight: .regular))
                Text(isRefreshing ? "Refreshing…" : refreshedText)
                    .releaseFont(12, weight: .regular, relativeTo: .caption)
                    .monospacedDigit()
                Spacer()
            }
            .foregroundStyle(.bodyText)
            .frame(maxWidth: .infinity, minHeight: 40, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(FocusStageButtonStyle())
        .disabled(onRefresh == nil || isRefreshing)
        .help("Refresh local evidence and registry metadata")
        .accessibilityLabel("Refresh evidence")
        .accessibilityValue(isRefreshing ? "Refreshing" : refreshedText)
    }
}

private struct ReleaseUtilityActions: View {
    let dashboard: SkillDashboard
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    var body: some View {
        Group {
            Button("Copy summary") { feedback.copy(diagnosticSummary, label: "Summary") }
            Button("Copy latest observation") { feedback.copy(historySummary, label: "Latest observation") }
            Button("Copy selected skill path") { feedback.copy(dashboard.fleet.selectedSkillPath, label: "Skill path") }
            Button("Copy model profile") { feedback.copy(profileSummary, label: "Model profile") }
            Divider()
            Button("Quit SkillsBar") { NSApp.terminate(nil) }
        }
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

private struct StatusBadge: View {
    @Environment(\.colorScheme) private var colorScheme
    enum Prominence { case standard, strong }

    let text: String
    let tone: StatusTone
    var prominence: Prominence = .standard

    private var ink: Color {
        guard colorScheme == .light else { return tone.color }
        switch tone {
        case .warning: return .focusWarningInk
        case .advisory: return .focusInfoInk
        case .positive: return Color(red: 0.08, green: 0.46, blue: 0.20)
        case .danger: return Color(red: 0.72, green: 0.12, blue: 0.10)
        case .pending: return .secondary
        }
    }

    var body: some View {
        Text(text)
            .releaseFont(
                prominence == .strong ? 13 : 11,
                weight: .medium,
                design: .default,
                relativeTo: prominence == .strong ? .caption : .caption2
            )
            .foregroundStyle(ink)
            .monospacedDigit()
            .padding(.horizontal, prominence == .strong ? 8 : 6)
            .padding(.vertical, prominence == .strong ? 4 : 2)
            .background(tone.color.opacity(prominence == .strong ? 0.12 : 0.08))
            .clipShape(prominence == .strong ? AnyShape(RoundedRectangle(cornerRadius: 6)) : AnyShape(Capsule()))
            .overlay {
                if prominence == .strong {
                    RoundedRectangle(cornerRadius: 6).stroke(tone.color.opacity(0.75), lineWidth: 1)
                } else {
                    Capsule().stroke(tone.color.opacity(0.46), lineWidth: 1)
                }
            }
            .fixedSize(horizontal: true, vertical: false)
    }
}

private struct ReleaseSkillLogo: View {
    @Environment(\.colorScheme) private var colorScheme
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
                .strokeBorder((colorScheme == .dark ? Color.white : .black).opacity(0.10), lineWidth: 1)
        )
    }
}

private struct ReleaseTesslLogo: View {
    @Environment(\.colorScheme) private var colorScheme
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
                .strokeBorder((colorScheme == .dark ? Color.white : .black).opacity(0.10), lineWidth: 1)
        )
    }
}

private struct ReleaseDivider: View {
    @Environment(\.displayScale) private var displayScale
    @Environment(\.colorSchemeContrast) private var contrast
    var body: some View {
        Rectangle().fill(Color.primary.opacity(contrast == .increased ? 0.4 : 0.11))
            .frame(height: contrast == .increased ? 1 : 1 / max(displayScale, 1))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
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
