import AppKit
import SwiftUI

struct ReleaseEvidenceView: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    var isInitialLoad = false
    var isDemoFixture = false
    var onRefresh: () -> Void = {}

    var body: some View {
        VStack(spacing: 0) {
            ReleaseHeader(
                dashboard: dashboard,
                isRefreshing: isRefreshing,
                isInitialLoad: isInitialLoad,
                isDemoFixture: isDemoFixture
            )
            ReleaseDivider().padding(.vertical, 8)

            if isInitialLoad {
                AutomaticIdentityLoadingCard()
                    .padding(.bottom, 8)
            } else if let active = dashboard.pipeline.activeReceipt {
                NextRequiredCard(
                    receipt: active,
                    isRefreshing: isRefreshing,
                    onRefresh: onRefresh
                )
                .padding(.bottom, 8)
            }

            ScrollViewReader { proxy in
                ScrollView {
                    CompactDownstreamGateList(
                        dashboard: dashboard,
                        activeStageID: dashboard.pipeline.activeReceipt?.id,
                        isDemoFixture: isDemoFixture
                    )
                    .id(CompactDownstreamGateList.topAnchorID)
                }
                .onAppear {
                    proxy.scrollTo(CompactDownstreamGateList.topAnchorID, anchor: .top)
                }
            }
            .frame(minHeight: 132, maxHeight: .infinity)
            .scrollIndicators(.visible)
            .scrollBounceBehavior(.basedOnSize)
            .overlay(alignment: .top) {
                ReleaseScrollEdge(direction: .top)
            }
            .overlay(alignment: .bottom) {
                ReleaseScrollEdge(direction: .bottom)
            }
            .accessibilityLabel("Skills SDK downstream gate evidence")
            CompactCanonicalIdentityAction(
                receipt: dashboard.pipeline.activeReceipt,
                isRefreshing: isRefreshing,
                isInitialLoad: isInitialLoad,
                onRefresh: onRefresh
            )
                .padding(.top, 8)
            CompactTesslRegistryStrip(
                dashboard: dashboard,
                isDemoFixture: isDemoFixture
            )
                .padding(.top, 8)
        }
    }
}

private struct ReleaseHeader: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    let isInitialLoad: Bool
    let isDemoFixture: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    private var candidate: PipelineCandidate { dashboard.pipeline }
    private var active: PipelineStageReceipt? { candidate.activeReceipt }
    private var versionLabel: String {
        dashboard.version.lowercased().hasPrefix("v") ? dashboard.version : "v\(dashboard.version)"
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            ReleaseSkillLogo(size: 42)

            VStack(alignment: .leading, spacing: 5) {
                HStack(spacing: 6) {
                    Text("SKILLS SDK")
                        .releaseFont(12, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(.secondaryText)
                    if isDemoFixture {
                        ReleasePill(text: "DEMO FIXTURE", tone: .warning)
                            .accessibilityLabel("Deterministic demo fixture")
                    }
                    if isRefreshing {
                        if reduceMotion {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 10, weight: .medium))
                        } else {
                            ProgressView()
                                .controlSize(.mini)
                        }
                        Color.clear
                            .accessibilityLabel("Refreshing evidence")
                    }
                }
                HStack(spacing: 6) {
                    Text(dashboard.registryPath)
                        .releaseFont(12, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                        .lineLimit(1)
                    ReleasePill(text: "LOCAL", tone: .pending)
                    ReleasePill(text: versionLabel, tone: .pending)
                }
            }

            Spacer(minLength: 32)
        }
        .padding(.trailing, 30)
        .overlay(alignment: .bottomLeading) {
            VStack(alignment: .leading, spacing: 5) {
                Text(
                    isInitialLoad
                        ? "Checking local candidate automatically"
                        : active.map { "Local candidate needs \($0.stage.title.lowercased())" }
                            ?? "Local candidate is current"
                )
                    .releaseFont(18, weight: .medium, relativeTo: .title3)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.82)
                HStack(spacing: 6) {
                    Circle()
                        .fill(isInitialLoad ? Color.secondaryText : active?.evidenceStatus.tone.color ?? Color.successAccent)
                        .frame(width: 6, height: 6)
                    Text(
                        isInitialLoad
                            ? "Reading local SDK evidence"
                            : active.map { "Gate \($0.stage.number) of \(PipelineStage.allCases.count)" }
                                ?? "All gates current"
                    )
                        .releaseFont(11, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(isInitialLoad ? Color.secondaryText : active?.evidenceStatus.tone.color ?? Color.successAccent)
                    Text("·")
                        .foregroundStyle(.secondaryText)
                    Text(isInitialLoad ? "Automatic check" : active?.stage.title ?? "Current candidate")
                        .releaseFont(11, weight: .regular, relativeTo: .caption)
                        .foregroundStyle(.bodyText)
                }
                Text(
                    isInitialLoad
                        ? "Generating candidate identity before evaluating downstream proof"
                        : "\(candidate.evidencedStageCount) receipt current · downstream proof \(active == nil ? "available" : "held")"
                )
                    .releaseFont(10.5, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
            }
            .offset(y: 66)
        }
        .padding(.bottom, 66)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Skills SDK. \(isInitialLoad ? "Checking local candidate automatically" : active.map { "Local candidate needs \($0.stage.title.lowercased())" } ?? "Local candidate is current"). "
                + "\(candidate.evidencedStageCount) receipt current. "
                + (active.map { "Current gate \($0.stage.number), \($0.stage.title)." } ?? "All gates current.")
        )
    }
}

private struct ReleaseGateList: View {
    let dashboard: SkillDashboard
    let isRefreshing: Bool
    let isInitialLoad: Bool
    let onRefresh: () -> Void

    private var candidate: PipelineCandidate { dashboard.pipeline }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(isInitialLoad ? "AUTOMATIC CHECK" : "NEXT REQUIRED")
                .releaseFont(10, weight: .medium, relativeTo: .caption)
                .foregroundStyle(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.bottom, 5)

            if isInitialLoad {
                AutomaticIdentityLoadingCard()
                    .padding(.bottom, 9)
            } else if let active = candidate.activeReceipt {
                NextRequiredCard(
                    receipt: active,
                    isRefreshing: isRefreshing,
                    onRefresh: onRefresh
                )
                    .padding(.bottom, 9)
            }

            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    Text("LOCAL PROOF")
                        .releaseFont(11, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(.secondaryText)
                }
                .padding(.horizontal, 8)
                .padding(.bottom, 6)

            ZStack(alignment: .topLeading) {
                GateConnector()
                    .padding(.leading, 31)
                    .padding(.vertical, 24)

                VStack(spacing: 0) {
                    ForEach(Array(candidate.orderedReceipts.prefix(6).enumerated()), id: \.element.id) { index, receipt in
                        ReleaseGateRow(
                            receipt: receipt,
                            isActive: false,
                            securityBadge: receipt.stage == .securityReview ? dashboard.security.severityLine : nil
                        )
                        if index < 5 {
                            ReleaseDivider().padding(.leading, 64)
                        }
                    }
                }
            }

            Text("TESSL DELIVERY")
                .releaseFont(11, weight: .medium, relativeTo: .caption)
                .foregroundStyle(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.top, 9)
                .padding(.bottom, 6)

            ZStack(alignment: .topLeading) {
                GateConnector()
                    .padding(.leading, 31)
                    .padding(.vertical, 20)

                VStack(spacing: 0) {
                    ForEach(Array(candidate.orderedReceipts.suffix(3).enumerated()), id: \.element.id) { index, receipt in
                        ReleaseGateRow(receipt: receipt, isActive: false, securityBadge: nil)
                        if index < 2 {
                            ReleaseDivider().padding(.leading, 64)
                        }
                    }
                }
            }

                Text("A held observation cannot promote a downstream gate.")
                    .releaseFont(10.5, weight: .regular, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
                    .padding(.horizontal, 8)
                    .padding(.top, 6)
            }
            .opacity(isInitialLoad ? 0 : 1)
            .frame(height: isInitialLoad ? 0 : nil)
            .clipped()
            .accessibilityHidden(isInitialLoad)
        }
        .accessibilityElement(children: .contain)
    }
}

private struct AutomaticIdentityLoadingCard: View {
    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            ProgressView()
                .controlSize(.small)
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text("Candidate identity")
                    .releaseFont(14, weight: .medium, relativeTo: .subheadline)
                Text("Computing canonical package digest")
                    .releaseFont(10.5, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(.bodyText)
                Text("This read-only check runs automatically and does not modify or publish the skill.")
                    .releaseFont(10, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
            }
            Spacer(minLength: 4)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Checking candidate identity automatically with a read-only package digest command")
    }
}

private struct CompactDownstreamGateList: View {
    static let topAnchorID = "pipeline-top"

    let dashboard: SkillDashboard
    let activeStageID: PipelineStage?
    let isDemoFixture: Bool
    @State private var expandedStageID: PipelineStage?

    private var receipts: [PipelineStageReceipt] {
        dashboard.pipeline.orderedReceipts.filter { $0.id != activeStageID }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("PIPELINE · SCROLL FOR GATES 2–9")
                .releaseFont(10, weight: .medium, relativeTo: .caption)
                .foregroundStyle(.secondaryText)
                .padding(.horizontal, 8)
                .padding(.bottom, 5)

            ForEach(receipts) { receipt in
                if receipt.stage == .tesslStaging {
                    Text("TESSL DELIVERY")
                        .releaseFont(10, weight: .medium, relativeTo: .caption)
                        .foregroundStyle(.secondaryText)
                        .padding(.horizontal, 8)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                }

                Button {
                    expandedStageID = expandedStageID == receipt.id ? nil : receipt.id
                } label: {
                    CompactGateRow(receipt: receipt)
                }
                .buttonStyle(.plain)
                .accessibilityHint("Shows or hides detail for \(receipt.stage.title)")

                if expandedStageID == receipt.id {
                    CompactGateDetail(
                        receipt: receipt,
                        dashboard: dashboard,
                        isDemoFixture: isDemoFixture
                    )
                        .transition(.opacity)
                }

                if receipt.id != receipts.last?.id {
                    ReleaseDivider().padding(.leading, 43)
                }
            }
        }
        .padding(.trailing, 11)
        .accessibilityElement(children: .contain)
    }
}

private struct CompactGateRow: View {
    let receipt: PipelineStageReceipt

    private var trailingLabel: String {
        if receipt.stage == .mechanicalValidation,
           let completedChecks = receipt.completedChecks,
           let requiredChecks = receipt.requiredChecks {
            return "\(completedChecks) / \(requiredChecks)"
        }
        if receipt.evidenceStatus == .passed { return "PASS" }
        if receipt.evidenceStatus == .held { return "HELD" }
        if receipt.evidenceStatus == .unproven { return "LOCKED" }
        return receipt.evidenceStatus.label.uppercased()
    }

    var body: some View {
        HStack(spacing: 8) {
            GateSymbol(receipt: receipt, isActive: false)
                .frame(width: 27)
            VStack(alignment: .leading, spacing: 2) {
                Text("\(receipt.stage.number). \(receipt.stage.title)")
                    .releaseFont(12.5, weight: .medium, relativeTo: .subheadline)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                Text(receipt.nextAction)
                    .releaseFont(9.5, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            Text(trailingLabel)
                .releaseFont(9.5, weight: .medium, design: .rounded, relativeTo: .caption2)
                .foregroundStyle(receipt.evidenceStatus.tone.color)
                .lineLimit(1)
            Image(systemName: "chevron.down")
                .font(.system(size: 9, weight: .semibold))
                .foregroundStyle(.secondaryText)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .contentShape(Rectangle())
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Gate \(receipt.stage.number), \(receipt.stage.title). \(receipt.evidenceStatus.label).")
    }
}

private struct CompactGateDetail: View {
    let receipt: PipelineStageReceipt
    let dashboard: SkillDashboard
    let isDemoFixture: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(receipt.stage.supportingText)
                .releaseFont(10, weight: .regular, relativeTo: .caption2)
                .foregroundStyle(.bodyText)
            if receipt.stage == .tesslLiveRegistry {
                Text(RegistryEvidencePresentation(
                    dashboard: dashboard,
                    isDemoFixture: isDemoFixture
                ).caption)
                    .releaseFont(10, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(Color.teal.opacity(0.88))
            }
        }
        .padding(.leading, 43)
        .padding(.trailing, 10)
        .padding(.bottom, 7)
        .accessibilityElement(children: .combine)
    }
}

private struct CompactTesslRegistryStrip: View {
    let dashboard: SkillDashboard
    let isDemoFixture: Bool

    private var presentation: RegistryEvidencePresentation {
        RegistryEvidencePresentation(dashboard: dashboard, isDemoFixture: isDemoFixture)
    }
    private var versionText: String {
        guard let version = dashboard.tessl.registryVersion, !version.isEmpty else { return "version unavailable" }
        return "v\(version.trimmingCharacters(in: CharacterSet(charactersIn: "vV")))"
    }

    var body: some View {
        HStack(alignment: .center, spacing: 8) {
            ReleaseTesslLogo(size: 38)
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text("Tessl")
                        .releaseFont(11.5, weight: .semibold, relativeTo: .subheadline)
                        .foregroundStyle(.primaryText)
                    Text("tessl.io registry")
                        .releaseFont(8.5, weight: .medium, relativeTo: .caption2)
                        .foregroundStyle(.secondaryText)
                    ReleasePill(
                        text: presentation.statusLabel,
                        tone: presentation.usesRegistryAccent ? .advisory : .pending
                    )
                    Text(versionText)
                        .releaseFont(9.5, weight: .regular, relativeTo: .caption2)
                        .foregroundStyle(.bodyText)
                }
                HStack(spacing: 7) {
                    CompactRegistryMetric(
                        label: "Quality",
                        value: dashboard.tessl.registryQualityScore.map { "\($0)%" } ?? "—",
                        tone: .positive
                    )
                    CompactRegistryMetric(
                        label: "Impact",
                        value: dashboard.tessl.registryImpactScore.map { "\($0)%" } ?? "—",
                        tone: .warning
                    )
                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 3) {
                            Text("Security")
                            Text("by Snyk")
                                .releaseFont(6.5, weight: .semibold, relativeTo: .caption2)
                                .padding(.horizontal, 3)
                                .padding(.vertical, 1)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                        }
                        .releaseFont(7.5, weight: .regular, relativeTo: .caption2)
                        .foregroundStyle(.bodyText)
                        Text(dashboard.tessl.registrySecurityDisplay)
                            .releaseFont(10.5, weight: .medium, design: .rounded, relativeTo: .caption)
                            .foregroundStyle(dashboard.tessl.registrySecurityTone.color)
                    }
                }
                Text(presentation.caption)
                    .releaseFont(9, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
                    .lineLimit(1)
            }
            Spacer(minLength: 2)
            VStack(spacing: 0) {
                Text("TESSL")
                    .releaseFont(7.5, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
                Text(dashboard.tessl.registryResultLabel)
                    .releaseFont(18, weight: .semibold, design: .rounded, relativeTo: .title3)
                    .foregroundStyle(Color.warningAccent)
                    .monospacedDigit()
            }
            .frame(width: 38)
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.teal.opacity(presentation.usesRegistryAccent ? 0.075 : 0.035))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.teal.opacity(presentation.usesRegistryAccent ? 0.42 : 0.22), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Tessl Registry. \(presentation.statusLabel). \(presentation.caption)")
    }
}

struct RegistryEvidencePresentation: Equatable {
    let statusLabel: String
    let caption: String
    let usesRegistryAccent: Bool

    init(dashboard: SkillDashboard, isDemoFixture: Bool) {
        if isDemoFixture {
            statusLabel = "BASELINE"
            caption = "Published baseline · not candidate proof."
            usesRegistryAccent = true
            return
        }

        switch dashboard.tessl.dataOrigin {
        case .liveCLI:
            statusLabel = "LIVE"
            caption = dashboard.registryEvidenceCaption
            usesRegistryAccent = true
        case .cached, .fixture:
            statusLabel = "CLI UNAVAILABLE"
            caption = dashboard.registryEvidenceCaption
            usesRegistryAccent = false
        case .unavailable:
            statusLabel = "UNAVAILABLE"
            caption = dashboard.registryEvidenceCaption
            usesRegistryAccent = false
        }
    }
}

private struct CompactRegistryMetric: View {
    let label: String
    let value: String
    let tone: StatusTone

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text(label)
                .releaseFont(7.5, weight: .regular, relativeTo: .caption2)
                .foregroundStyle(.bodyText)
            Text(value)
                .releaseFont(10.5, weight: .medium, design: .rounded, relativeTo: .caption)
                .foregroundStyle(tone.color)
        }
    }
}

private struct CompactCanonicalIdentityAction: View {
    let receipt: PipelineStageReceipt?
    let isRefreshing: Bool
    let isInitialLoad: Bool
    let onRefresh: () -> Void
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    private var command: String { receipt?.command ?? "" }
    private var retriesAutomaticIdentity: Bool {
        receipt?.stage == .candidateBaseline && receipt?.evidenceStatus == .blocked
    }

    var body: some View {
        HStack(spacing: 9) {
            Image(systemName: isInitialLoad ? "arrow.triangle.2.circlepath" : "terminal")
                .font(.system(size: 16, weight: .medium))
                .frame(width: 31, height: 31)
                .background(Color.white.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 7, style: .continuous))
            VStack(alignment: .leading, spacing: 2) {
                Text(isInitialLoad ? "Checking candidate identity" : "Copy inspection command")
                    .releaseFont(12, weight: .medium, relativeTo: .subheadline)
                Text(isInitialLoad ? "Generating the local candidate fingerprint" : receipt?.nextAction ?? "No held downstream gates")
                    .releaseFont(9.5, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
                    .lineLimit(1)
            }
            Spacer(minLength: 4)
            if isInitialLoad {
                ProgressView().controlSize(.small)
            } else if retriesAutomaticIdentity {
                Button(action: onRefresh) {
                    Image(systemName: "arrow.clockwise")
                        .frame(width: 31, height: 31)
                }
                .buttonStyle(ReleasePressButtonStyle())
                .disabled(isRefreshing)
                .accessibilityLabel("Retry automatic identity check")
            } else if !command.isEmpty {
                Button { feedback.copy(command) } label: {
                    Image(systemName: feedback.copiedCommand == command ? "checkmark" : "doc.on.doc")
                        .frame(width: 31, height: 31)
                }
                .buttonStyle(ReleasePressButtonStyle())
                .foregroundStyle(feedback.copiedCommand == command ? Color.successAccent : Color.primaryText)
                .accessibilityLabel("Copy the active gate command")
            }
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 7)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(Color.white.opacity(0.14), lineWidth: 1))
    }
}

private struct NextRequiredCard: View {
    let receipt: PipelineStageReceipt
    let isRefreshing: Bool
    let onRefresh: () -> Void
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    private var retriesAutomaticIdentity: Bool {
        receipt.stage == .candidateBaseline && receipt.evidenceStatus == .blocked
    }

    var body: some View {
        HStack(alignment: .center, spacing: 10) {
            GateSymbol(receipt: receipt, isActive: true)
                .frame(width: 46)
            VStack(alignment: .leading, spacing: 3) {
                Text(receipt.stage.title)
                    .releaseFont(14, weight: .medium, relativeTo: .subheadline)
                Text(receipt.nextAction)
                    .releaseFont(10.5, weight: .medium, relativeTo: .caption)
                    .foregroundStyle(receipt.evidenceStatus.tone.color)
                Text(receipt.stage.supportingText)
                    .releaseFont(10, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
            }
            Spacer(minLength: 4)
            Button {
                if retriesAutomaticIdentity {
                    onRefresh()
                } else {
                    feedback.copy(receipt.command)
                }
            } label: {
                Text(
                    retriesAutomaticIdentity
                        ? "RETRY CHECK"
                        : feedback.copiedCommand == receipt.command ? "COPIED" : "COPY COMMAND"
                )
                    .releaseFont(10, weight: .medium, design: .rounded, relativeTo: .caption)
                    .padding(.horizontal, 9)
                    .frame(height: 30)
            }
            .buttonStyle(ReleasePressButtonStyle(tint: receipt.evidenceStatus.tone.color))
            .foregroundStyle(receipt.evidenceStatus.tone.color)
            .disabled(retriesAutomaticIdentity ? isRefreshing : receipt.command.isEmpty)
            .help(retriesAutomaticIdentity ? "Retry automatic identity check" : "Copy the \(receipt.stage.title.lowercased()) command")
            .accessibilityLabel(retriesAutomaticIdentity ? "Retry automatic identity check" : "Copy the \(receipt.stage.title.lowercased()) command")
        }
        .padding(.horizontal, 9)
        .padding(.vertical, 8)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(RoundedRectangle(cornerRadius: 9, style: .continuous).stroke(receipt.evidenceStatus.tone.color, lineWidth: 1))
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
    let securityBadge: String?

    private var trailingLabel: String {
        if receipt.stage == .mechanicalValidation,
           let completedChecks = receipt.completedChecks,
           let requiredChecks = receipt.requiredChecks {
            return "\(completedChecks) of \(requiredChecks) receipts"
        }
        if receipt.evidenceStatus == .held { return "HELD" }
        if receipt.evidenceStatus == .passed { return "PASS" }
        if receipt.evidenceStatus == .unproven { return "UNPROVEN" }
        return receipt.evidenceStatus.label.uppercased()
    }

    private var rowOpacity: Double {
        switch receipt.evidenceStatus {
        case .held: return 0.78
        case .unproven: return 0.88
        default: return 1
        }
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            GateSymbol(receipt: receipt, isActive: isActive)
                .frame(width: 46)

            VStack(alignment: .leading, spacing: 3) {
                Text("\(receipt.stage.number). \(receipt.stage.title)")
                    .releaseFont(13.5, weight: isActive ? .medium : .regular, relativeTo: .subheadline)
                    .foregroundStyle(.primaryText)
                    .lineLimit(1)
                Text(receipt.nextAction)
                    .releaseFont(10.5, weight: isActive ? .medium : .regular, relativeTo: .caption)
                    .foregroundStyle(isActive ? receipt.evidenceStatus.tone.color : .bodyText)
                    .fixedSize(horizontal: false, vertical: true)
                if isActive {
                    Text(receipt.stage.supportingText)
                        .releaseFont(10, weight: .regular, relativeTo: .caption2)
                        .foregroundStyle(.bodyText)
                }
                if let securityBadge, !securityBadge.isEmpty {
                    Text(securityBadge)
                        .releaseFont(10, weight: .medium, relativeTo: .caption2)
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

            Spacer(minLength: 5)
            Text(trailingLabel)
                .releaseFont(10.5, weight: isActive ? .medium : .regular, design: .rounded, relativeTo: .caption)
                .foregroundStyle(isActive ? receipt.evidenceStatus.tone.color : .bodyText)
                .monospacedDigit()
                .padding(.top, 2)
        }
        .padding(.horizontal, isActive ? 10 : 8)
        .padding(.vertical, isActive ? 9 : 7)
        .background {
            if isActive {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .fill(Color.white.opacity(0.035))
            }
        }
        .overlay {
            if isActive {
                RoundedRectangle(cornerRadius: 9, style: .continuous)
                    .stroke(receipt.evidenceStatus.tone.color.opacity(0.72), lineWidth: 1)
            }
        }
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
        .opacity(rowOpacity)
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Gate \(receipt.stage.number), \(receipt.stage.title). \(receipt.evidenceStatus.label). \(receipt.nextAction)."
        )
    }
}

private struct GateSymbol: View {
    let receipt: PipelineStageReceipt
    let isActive: Bool

    var body: some View {
        Group {
            if receipt.evidenceStatus == .unproven {
                Image(systemName: "lock.fill")
                    .font(.system(size: 12, weight: .medium))
                    .frame(width: 27, height: 27)
                    .background(Color.black.opacity(0.18))
                    .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .stroke(Color.secondaryText.opacity(0.6), lineWidth: 1.5)
                    )
            } else {
                ZStack {
                    Circle()
                        .fill(Color.black.opacity(0.18))
                    Circle()
                        .stroke(
                            isActive ? receipt.evidenceStatus.tone.color.opacity(0.72) : Color.secondaryText.opacity(0.65),
                            lineWidth: 1.5
                        )
                    Text(String(receipt.stage.number))
                        .releaseFont(13, weight: .medium, design: .rounded, relativeTo: .caption)
                        .monospacedDigit()
                }
                .frame(width: isActive ? 35 : 27, height: isActive ? 35 : 27)
            }
        }
        .foregroundStyle(isActive ? receipt.evidenceStatus.tone.color : .bodyText)
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
        if isLive { return "● LIVE" }
        if isHistorical { return "☁︎ CLI UNAVAILABLE" }
        return "⚠ REGISTRY UNAVAILABLE"
    }
    private var statusTone: StatusTone {
        if isLive { return .advisory }
        if isHistorical { return .pending }
        return .warning
    }
    private var versionText: String {
        guard let version = dashboard.tessl.registryVersion, !version.isEmpty else { return "version unavailable" }
        return (isHistorical ? "last known v" : "v") + version.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text(hasRegistrySnapshot ? "PUBLISHED BASELINE" : "REGISTRY STATUS")
                .releaseFont(9.5, weight: .medium, relativeTo: .caption2)
                .foregroundStyle(.secondaryText)
            HStack(alignment: .top, spacing: 10) {
                ReleaseTesslLogo(size: 44)
                VStack(alignment: .leading, spacing: 3) {
                    HStack(alignment: .firstTextBaseline, spacing: 5) {
                        Text("Tessl")
                            .releaseFont(13, weight: .semibold, relativeTo: .headline)
                            .foregroundStyle(.primaryText)
                        Text("tessl.io registry")
                            .releaseFont(8.5, weight: .medium, relativeTo: .caption2)
                            .foregroundStyle(.secondaryText)
                            .lineLimit(1)
                    }
                    HStack(spacing: 6) {
                        ReleasePill(
                            text: statusLabel,
                            tone: statusTone
                        )
                        Text(versionText)
                            .releaseFont(10.5, weight: .regular, relativeTo: .caption)
                            .foregroundStyle(.bodyText)
                            .lineLimit(1)
                    }
                    if dashboard.registryVersionMatchesCandidate {
                        ReleasePill(text: "DECLARED VERSION MATCH", tone: .pending)
                    }
                }
                Spacer(minLength: 4)
                VStack(alignment: .center, spacing: 1) {
                    Text("TESSL SCORE")
                        .releaseFont(7.5, weight: .medium, relativeTo: .caption2)
                        .tracking(0.5)
                        .foregroundStyle(Color.secondaryText.opacity(isLive ? 0.9 : 0.62))
                    RegistryScoreHex(
                        score: dashboard.tessl.registryResultLabel,
                        muted: !isLive
                    )
                }
                .accessibilityElement(children: .combine)
            }

            if isHistorical {
                Text("LAST KNOWN REGISTRY DATA")
                    .releaseFont(9.5, weight: .medium, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
            }

            HStack(spacing: 9) {
                RegistryMetric(
                    label: "Quality",
                    value: dashboard.tessl.registryQualityScore.map { "\($0)%" } ?? "—",
                    progress: dashboard.tessl.registryQualityScore.map { Double($0) / 100 },
                    tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryQualityScore),
                    muted: !isLive
                )
                RegistryVerticalDivider()
                RegistryMetric(
                    label: "Impact",
                    value: dashboard.tessl.registryImpactScore.map { "\($0)%" } ?? "—",
                    progress: dashboard.tessl.registryImpactScore.map { Double($0) / 100 },
                    tone: RegistryMetricPresentation.percentTone(dashboard.tessl.registryImpactScore),
                    muted: !isLive
                )
                RegistryVerticalDivider()
                RegistryMetric(
                    label: "Security",
                    source: "Snyk",
                    value: dashboard.tessl.registrySecurityDisplay,
                    progress: dashboard.tessl.registrySecurityTone == .positive ? 1 : nil,
                    tone: dashboard.tessl.registrySecurityTone,
                    muted: !isLive
                )
            }

            Text(dashboard.registryEvidenceCaption)
                .releaseFont(10.5, weight: .regular, relativeTo: .caption)
                .foregroundStyle(Color.teal.opacity(isLive ? 0.84 : 0.58))
                .fixedSize(horizontal: false, vertical: true)
            if !hasCurrentCandidateDigest {
                Text("Content comparison blocked until candidate digest exists.")
                    .releaseFont(10, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.secondaryText)
            }
        }
        .padding(11)
        .background(
            LinearGradient(
                colors: [Color.white.opacity(0.038), Color.teal.opacity(isLive ? 0.045 : 0.025), Color.black.opacity(0.07)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 10, style: .continuous)
                .stroke(Color.teal.opacity(isLive ? 0.42 : 0.28), lineWidth: 1)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "Tessl Registry. \(isLive ? "Live registry data" : (isHistorical ? "CLI unavailable, last known registry data" : "Registry comparison unavailable")). "
                + "Security by Snyk: \(dashboard.tessl.registrySecurityDisplay). "
                + dashboard.registryEvidenceCaption
        )
    }
}

private struct RegistryMetric: View {
    let label: String
    var source: String? = nil
    let value: String
    let progress: Double?
    let tone: StatusTone
    let muted: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 4) {
                Text(label)
                    .releaseFont(10, weight: .regular, relativeTo: .caption2)
                    .foregroundStyle(.bodyText)
                if let source {
                    RegistrySourceBadge(source: source)
                }
            }
            Text(value)
                .releaseFont(14, weight: .medium, design: .rounded, relativeTo: .subheadline)
                .foregroundStyle(tone.color.opacity(muted ? 0.68 : 1))
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Capsule().fill(Color.white.opacity(0.1))
                    if let progress {
                        Capsule()
                            .fill(tone.color.opacity(muted ? 0.62 : 1))
                            .frame(width: geometry.size.width * min(max(progress, 0), 1))
                    }
                }
            }
            .frame(height: 5)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct RegistrySourceBadge: View {
    let source: String

    var body: some View {
        Text("by \(source)")
            .releaseFont(7.5, weight: .semibold, relativeTo: .caption2)
            .foregroundStyle(Color.primaryText.opacity(0.92))
            .padding(.horizontal, 4)
            .frame(height: 14)
            .background(Color.white.opacity(0.07))
            .clipShape(Capsule())
            .overlay(Capsule().stroke(Color.white.opacity(0.10), lineWidth: 0.5))
            .accessibilityLabel("Security assessment by \(source)")
    }
}

private struct RegistryVerticalDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.12))
            .frame(width: 1, height: 40)
    }
}

private struct CanonicalIdentityAction: View {
    let receipt: PipelineStageReceipt?
    let isRefreshing: Bool
    let isInitialLoad: Bool
    let onRefresh: () -> Void
    @ObservedObject private var feedback = CopyFeedbackModel.shared

    private var command: String { receipt?.command ?? "" }
    private var isCandidateIdentityFailure: Bool {
        receipt?.stage == .candidateBaseline && receipt?.evidenceStatus == .blocked
    }
    private var title: String {
        if isInitialLoad { return "Checking candidate identity" }
        if isCandidateIdentityFailure { return "Automatic identity check failed" }
        return receipt.map { "\($0.stage.title) command" } ?? "All gates current"
    }
    private var subtitle: String {
        if isInitialLoad {
            return "SkillsBar is generating a read-only fingerprint of the local candidate."
        }
        return receipt?.nextAction ?? "No held downstream gates"
    }
    private var commandLabel: String {
        if isCandidateIdentityFailure { return "Copy diagnostic identity command" }
        return receipt.map { "Copy the \($0.stage.title.lowercased()) command" } ?? "Copy pipeline command"
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
            Image(systemName: isInitialLoad ? "arrow.triangle.2.circlepath" : "terminal")
                .font(.system(size: 19, weight: .medium))
                .frame(width: 38, height: 38)
                .background(Color.white.opacity(0.05))
                .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 8, style: .continuous)
                        .stroke(Color.white.opacity(0.17), lineWidth: 1)
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
                        .foregroundStyle(Color.white.opacity(0.78))
                        .lineLimit(2)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 5)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.black.opacity(0.27))
                        .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
                }
            }

            Spacer(minLength: 4)
            if isInitialLoad {
                ProgressView()
                    .controlSize(.small)
                    .frame(width: 36, height: 36)
                    .accessibilityLabel("Checking candidate identity automatically")
            } else {
                if isCandidateIdentityFailure {
                    Button(action: onRefresh) {
                        Image(systemName: "arrow.clockwise")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(ReleasePressButtonStyle())
                    .disabled(isRefreshing)
                    .help("Retry automatic identity check")
                    .accessibilityLabel("Retry automatic identity check")
                }
                if !command.isEmpty {
                    Button { feedback.copy(command) } label: {
                        Image(systemName: feedback.copiedCommand == command ? "checkmark" : "doc.on.doc")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 36, height: 36)
                    }
                    .buttonStyle(ReleasePressButtonStyle())
                    .foregroundStyle(feedback.copiedCommand == command ? Color.successAccent : Color.primaryText)
                    .help(commandLabel)
                    .accessibilityLabel(commandLabel)
                    .accessibilityValue(command)
                }
            }
        }
        .padding(10)
        .background(Color.white.opacity(0.035))
        .clipShape(RoundedRectangle(cornerRadius: 9, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 9, style: .continuous)
                .stroke(Color.white.opacity(0.14), lineWidth: 1)
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
                            Color.black.opacity(0.24),
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            ReleaseHexagon()
                .stroke(Color.white.opacity(muted ? 0.035 : 0.075), lineWidth: 0.75)
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
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    }
}

private struct ReleaseTesslLogo: View {
    let size: CGFloat

    var body: some View {
        Group {
            if let image = TesslLogoLoader.image {
                Image(nsImage: image)
                    .resizable()
                    .interpolation(.high)
                    .scaledToFit()
                    .scaleEffect(1.28)
            } else {
                Image(systemName: "shippingbox")
                    .font(.system(size: size * 0.48, weight: .medium))
            }
        }
        .frame(width: size, height: size)
        .background(Color.black.opacity(0.78))
        .clipShape(RoundedRectangle(cornerRadius: max(7, size * 0.2), style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: max(7, size * 0.2), style: .continuous)
                .stroke(
                    LinearGradient(
                        colors: [Color.white.opacity(0.22), Color.white.opacity(0.07)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    lineWidth: 1
                )
        )
        .shadow(color: Color.black.opacity(0.22), radius: 5, y: 2)
        .accessibilityHidden(true)
    }
}

private struct ReleaseDivider: View {
    var body: some View {
        Rectangle().fill(Color.white.opacity(0.11)).frame(height: 1)
    }
}

private struct ReleasePressButtonStyle: ButtonStyle {
    var tint: Color = .white
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(Color.white.opacity(configuration.isPressed ? 0.11 : 0.045))
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .stroke(tint.opacity(configuration.isPressed ? 0.72 : 0.42), lineWidth: 1)
            )
            .opacity(configuration.isPressed ? 0.82 : 1)
            .scaleEffect(configuration.isPressed && !reduceMotion ? 0.98 : 1)
            .animation(.easeOut(duration: reduceMotion ? 0 : 0.11), value: configuration.isPressed)
    }
}

private struct ReleaseScrollEdge: View {
    enum Direction {
        case top
        case bottom
    }

    let direction: Direction

    var body: some View {
        LinearGradient(
            colors: direction == .top
                ? [Color(red: 0.02, green: 0.035, blue: 0.043).opacity(0.94), .clear]
                : [.clear, Color(red: 0.02, green: 0.035, blue: 0.043).opacity(0.94)],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 15)
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
