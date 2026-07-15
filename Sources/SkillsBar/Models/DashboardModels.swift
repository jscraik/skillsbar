import Foundation
import SkillsBarCore
import SwiftUI
import CryptoKit

enum StatusTone: Equatable {
    case positive
    case advisory
    case pending
    case warning
    case danger

    var color: Color {
        switch self {
        case .positive: return .successAccent
        case .advisory: return .advisoryAccent
        case .pending: return .pendingAccent
        case .warning: return .warningAccent
        case .danger: return .dangerAccent
        }
    }

    var panelColor: Color {
        switch self {
        case .positive: return Color.successAccent.opacity(0.16)
        case .advisory: return Color.advisoryAccent.opacity(0.16)
        case .pending: return Color.pendingAccent.opacity(0.12)
        case .warning: return Color.warningAccent.opacity(0.16)
        case .danger: return Color.dangerAccent.opacity(0.16)
        }
    }
}

enum SecurityDisposition: Equatable {
    case pending
    case passed
    case advisory
    case flagged
    case failed

    init(label: String?) {
        guard let label else {
            self = .pending
            return
        }
        let normalized = label.lowercased()
        if normalized.contains("not passed")
            || normalized.contains("not_passed")
            || normalized.contains("fail")
            || normalized.contains("critical")
            || normalized.contains("unsafe")
            || normalized.contains("error") {
            self = .failed
        } else if normalized.contains("flag")
            || normalized.contains("warning")
            || normalized.contains("high") {
            self = .flagged
        } else if normalized.contains("advisory")
            || normalized.contains("moderate") {
            self = .advisory
        } else if normalized.contains("pass")
            || normalized.contains("clean")
            || normalized.contains("safe")
            || normalized == "low" {
            self = .passed
        } else {
            self = .pending
        }
    }

    var tone: StatusTone {
        switch self {
        case .pending: return .pending
        case .passed: return .positive
        case .advisory: return .advisory
        case .flagged: return .warning
        case .failed: return .danger
        }
    }

    var requiresReview: Bool {
        self == .advisory || self == .flagged || self == .failed
    }
}

enum PipelineStage: String, CaseIterable, Identifiable {
    case candidateBaseline
    case mechanicalValidation
    case securityReview
    case evalPreparation
    case ossLocal
    case ossCloud
    case tesslStaging
    case tesslLiveRegistry
    case liveScoreAndRuntime

    var id: String { rawValue }

    var title: String {
        switch self {
        case .candidateBaseline: return "Candidate identity"
        case .mechanicalValidation: return "Mechanical validation"
        case .securityReview: return "Security & guardrails"
        case .evalPreparation: return "Eval preparation"
        case .ossLocal: return "Eval local proof"
        case .ossCloud: return "Eval cloud proof"
        case .tesslStaging: return "Tessl staging"
        case .tesslLiveRegistry: return "Tessl publication & registry"
        case .liveScoreAndRuntime: return "Runtime truth"
        }
    }

    var number: Int {
        Self.allCases.firstIndex(of: self).map { $0 + 1 } ?? 0
    }

    var weight: Int {
        switch self {
        case .candidateBaseline, .mechanicalValidation, .evalPreparation, .tesslStaging, .tesslLiveRegistry:
            return 10
        case .securityReview, .ossLocal, .ossCloud:
            return 15
        case .liveScoreAndRuntime:
            return 5
        }
    }
}

enum PipelineEvidenceStatus: Equatable {
    case passed
    case reviewRequired
    case blocked
    case held
    case unproven
    case stale

    var isCurrentEvidence: Bool {
        self == .passed || self == .reviewRequired || self == .blocked
    }

    var label: String {
        switch self {
        case .passed: return "Passed"
        case .reviewRequired: return "Review required"
        case .blocked: return "Blocked"
        case .held: return "Held"
        case .unproven: return "Unproven"
        case .stale: return "Stale"
        }
    }

    var tone: StatusTone {
        switch self {
        case .passed: return .positive
        case .reviewRequired: return .warning
        case .blocked: return .danger
        case .held, .unproven, .stale: return .pending
        }
    }
}

struct PipelineStageReceipt: Equatable, Identifiable {
    let stage: PipelineStage
    let candidateFingerprint: String
    let evidenceStatus: PipelineEvidenceStatus
    let stageScore: Int?
    let command: String
    let receiptPath: String?
    let modelProfile: String?
    let observedAt: Date?
    let nextAction: String

    var id: PipelineStage { stage }
}

struct PipelineCandidate: Equatable {
    let fingerprint: String
    let governedInputPaths: [String]
    let observedAt: Date
    let stageReceipts: [PipelineStageReceipt]

    init(
        fingerprint: String,
        governedInputPaths: [String],
        observedAt: Date,
        stageReceipts: [PipelineStageReceipt]
    ) {
        self.fingerprint = fingerprint
        self.governedInputPaths = governedInputPaths.sorted()
        self.observedAt = observedAt
        self.stageReceipts = Self.gatedReceipts(
            fingerprint: fingerprint,
            receipts: stageReceipts
        )
    }

    var postureScore: Int {
        orderedReceipts.reduce(0) { total, receipt in
            total + contribution(for: receipt)
        }
    }

    var evidencedStageCount: Int {
        orderedReceipts.filter(isCurrent).count
    }

    var activeReceipt: PipelineStageReceipt? {
        orderedReceipts.first { $0.evidenceStatus != .passed }
    }

    var orderedReceipts: [PipelineStageReceipt] {
        PipelineStage.allCases.compactMap { stage in
            stageReceipts.first(where: { $0.stage == stage })
        }
    }

    func isCurrent(_ receipt: PipelineStageReceipt) -> Bool {
        receipt.candidateFingerprint == fingerprint && receipt.evidenceStatus.isCurrentEvidence
    }

    func contribution(for receipt: PipelineStageReceipt) -> Int {
        guard isCurrent(receipt), let score = receipt.stageScore else { return 0 }
        return Int((Double(receipt.stage.weight * min(max(score, 0), 100)) / 100.0).rounded())
    }

    private static func gatedReceipts(
        fingerprint: String,
        receipts: [PipelineStageReceipt]
    ) -> [PipelineStageReceipt] {
        var receiptByStage = Dictionary(uniqueKeysWithValues: receipts.map { ($0.stage, $0) })
        var earlierStagePassed = true

        for stage in PipelineStage.allCases {
            guard var receipt = receiptByStage[stage] else { continue }
            let receiptMatchesCandidate = receipt.candidateFingerprint == fingerprint
            if !receiptMatchesCandidate {
                receipt = PipelineStageReceipt(
                    stage: stage,
                    candidateFingerprint: receipt.candidateFingerprint,
                    evidenceStatus: .stale,
                    stageScore: receipt.stageScore,
                    command: receipt.command,
                    receiptPath: receipt.receiptPath,
                    modelProfile: receipt.modelProfile,
                    observedAt: receipt.observedAt,
                    nextAction: receipt.nextAction
                )
            } else if !earlierStagePassed,
                      receipt.evidenceStatus == .passed
                        || receipt.evidenceStatus == .reviewRequired
                        || receipt.evidenceStatus == .blocked {
                receipt = PipelineStageReceipt(
                    stage: stage,
                    candidateFingerprint: receipt.candidateFingerprint,
                    evidenceStatus: .held,
                    stageScore: receipt.stageScore,
                    command: receipt.command,
                    receiptPath: receipt.receiptPath,
                    modelProfile: receipt.modelProfile,
                    observedAt: receipt.observedAt,
                    nextAction: receipt.nextAction
                )
            }
            receiptByStage[stage] = receipt
            earlierStagePassed = earlierStagePassed && receipt.evidenceStatus == .passed
        }
        return PipelineStage.allCases.compactMap { receiptByStage[$0] }
    }

    static func fingerprint(for paths: [URL], root: URL) -> String {
        let records = paths.sorted { $0.path < $1.path }.map { path -> String in
            let relative = path.path.replacingOccurrences(of: root.path + "/", with: "")
            let contents = (try? Data(contentsOf: path)) ?? Data()
            return relative + "\u{0}" + SHA256.hash(data: contents).map { String(format: "%02x", $0) }.joined()
        }
        return SHA256.hash(data: Data(records.joined(separator: "\n").utf8))
            .map { String(format: "%02x", $0) }
            .joined()
    }

    static func unproven(
        fingerprint: String = "pending-candidate",
        governedInputPaths: [String] = [],
        observedAt: Date = Date(),
        commands: [PipelineStage: String] = [:]
    ) -> PipelineCandidate {
        PipelineCandidate(
            fingerprint: fingerprint,
            governedInputPaths: governedInputPaths,
            observedAt: observedAt,
            stageReceipts: PipelineStage.allCases.map { stage in
                PipelineStageReceipt(
                    stage: stage,
                    candidateFingerprint: fingerprint,
                    evidenceStatus: .unproven,
                    stageScore: nil,
                    command: commands[stage] ?? "",
                    receiptPath: nil,
                    modelProfile: nil,
                    observedAt: nil,
                    nextAction: "Establish \(stage.title.lowercased())."
                )
            }
        )
    }
}

struct SkillDashboard {
    var displayName: String
    var version: String
    var description: String
    var registryPath: String
    var repoPath: String
    var installCommand: String
    var localEvidenceCommand: String
    var reviewedText: String
    var deltaText: String
    var quality: MetricSignal
    var impact: MetricSignal
    var security: SecuritySignal
    var tessl: TesslSignal
    var fleet: FleetSignal
    var pipeline: PipelineCandidate
    var refreshedAt: Date
    var error: String?

    var score: Int? {
        guard let qualityScore = quality.score,
              let impactScore = impact.score,
              let securityScore = security.score else { return nil }
        return Int((Double(qualityScore + impactScore + securityScore) / 3.0).rounded())
    }

    var scoreText: String { score.map(String.init) ?? "--" }
    var summaryLine: String { description }
    var scoreTone: StatusTone {
        guard let score else { return .pending }
        if score >= 80 { return .positive }
        if score >= 60 { return .warning }
        return .danger
    }
    var scoreCaption: String {
        "Local"
    }
    var scoreSourceLine: String {
        score == nil ? "Q/I/S pending" : "Q\(quality.formulaValue) I\(impact.formulaValue) S\(security.formulaValue)"
    }
    var localImpactDisplay: String {
        impact.ratioLabel ?? (impact.score == nil ? "Not run" : impact.statusLabel)
    }
    var registryURL: URL? {
        let escaped = registryPath
            .split(separator: "/")
            .map { String($0).addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? String($0) }
            .joined(separator: "/")
        return URL(string: "https://tessl.io/registry/\(escaped)")
    }
    var registrySearchCommand: String {
        "tessl search --json --type skills \(registryPath)"
    }
    var registryEvidenceCaption: String {
        switch tessl.dataOrigin {
        case .liveCLI:
            guard let registryVersion = tessl.registryVersion?.trimmingCharacters(in: .whitespacesAndNewlines),
                  !registryVersion.isEmpty else {
                return "Live Tessl registry data · candidate identity not verified."
            }
            if normalizedVersion(registryVersion) == normalizedVersion(version) {
                return "Version matches local declaration · package identity unverified."
            }
            return "Live Tessl registry · v\(normalizedVersion(registryVersion)) differs from local v\(normalizedVersion(version))."
        case .cached, .fixture:
            return "Historical external baseline · not proof for this candidate."
        case .unavailable:
            if !tessl.cliAvailable {
                return "Historical external baseline · not proof for this candidate."
            }
            return "Registry comparison unavailable · not proof for this candidate."
        }
    }
    var registryVersionMatchesCandidate: Bool {
        guard tessl.dataOrigin == .liveCLI, let registryVersion = tessl.registryVersion else { return false }
        return normalizedVersion(registryVersion) == normalizedVersion(version)
    }
    var reviewInspectCommand: String {
        security.inspectCommand
    }
    var selectedSkillInspectCommand: String {
        "cd \(globalShellQuoted(repoPath)) && sed -n '1,120p' \(globalShellQuoted(fleet.selectedSkillPath))"
    }
    var emblemBadgeLabel: String {
        if security.disposition.requiresReview {
            return security.statusDisplay
        }
        if score == nil {
            return "Local pending"
        }
        return "Local score"
    }
    var emblemBadgeSystemName: String {
        if security.disposition.requiresReview || scoreTone != .positive {
            return "exclamationmark.shield.fill"
        }
        if score == nil {
            return "clock"
        }
        return "checkmark.seal.fill"
    }
    var emblemBadgeTone: StatusTone {
        if security.disposition.requiresReview {
            return security.tone
        }
        if score == nil {
            return .pending
        }
        return scoreTone
    }
    var verdictTitle: String {
        switch security.disposition {
        case .failed, .flagged: return "Needs review"
        case .advisory: return "Advisory review"
        case .pending, .passed: break
        }
        if score == nil { return "Local pending" }
        if scoreTone != .positive { return "Needs review" }
        return "Skills SDK"
    }
    var verdictDetail: String {
        if security.disposition.requiresReview && !tessl.ok {
            return "Security review required · \(tessl.blockerSummary)"
        }
        if security.disposition == .advisory {
            return "Security advisory needs inspection"
        }
        if security.disposition == .flagged || security.disposition == .failed {
            return "\(security.statusDisplay) need inspection"
        }
        if scoreTone != .positive {
            return "Local score needs review"
        }
        if !tessl.ok {
            return "Current improve-agent-native run · \(tessl.blockerSummary)"
        }
        return "Local SDK evidence and Tessl registry checks available"
    }
    var provenanceLine: String {
        let tesslState = tessl.ok ? "loaded" : tessl.compactBlockerSummary
        return "SDK \(compactScoreBreakdownLine) · \(tessl.compactVersionBadge) · 5m · \(tesslState)"
    }
    var scoreBreakdownLine: String {
        "Q \(quality.formulaValue) · I \(impact.formulaValue) · S \(security.formulaValue)"
    }
    var compactScoreBreakdownLine: String {
        "Q\(quality.formulaValue) I\(impact.formulaValue) S\(security.formulaValue)"
    }
    var localComparisonDetail: String {
        let impactValue = impact.score == nil ? "--" : impact.formulaValue
        return "Q\(quality.formulaValue) I\(impactValue) S\(security.formulaValue)"
    }
    var refreshedTimeText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss"
        return formatter.string(from: refreshedAt)
    }

    func withError(_ message: String) -> SkillDashboard {
        var copy = self
        copy.error = message
        copy.tessl = TesslSignal(
            ok: false,
            cliAvailable: false,
            authenticated: false,
            displayStatus: "Blocked",
            detail: message,
            cliVersion: nil,
            registryScore: nil,
            registryVersion: nil,
            registryQualityScore: nil,
            registryImpactScore: nil,
            registrySecurityLabel: nil,
            registryEvalCount: nil,
            registryImprovementMultiplier: nil,
            registryVisibility: nil,
            recoveryCommand: "tessl doctor"
        )
        return copy
    }

    static let placeholder = SkillDashboard(
        displayName: "improve-agent-native",
        version: "0.2.0",
        description: "Audit agent-native readiness for this skill.",
        registryPath: "jscraik/improve-agent-native",
        repoPath: "/Users/jamiecraik/dev/agent-skills",
        installCommand: "tessl install jscraik/improve-agent-native",
        localEvidenceCommand: DashboardLoader.localEvidenceCommand(root: DashboardLoader.defaultRepoRoot),
        reviewedText: "Local SDK evidence",
        deltaText: "Local SDK",
        quality: MetricSignal(
            score: nil,
            detail: "Run package verify to populate quality.",
            source: "Local SDK package verify",
            command: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.packageCommand)
        ),
        impact: MetricSignal(
            score: nil,
            detail: "Run scenario-quality to populate impact.",
            source: "Local SDK scenario-quality",
            command: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.impactCommand)
        ),
        security: SecuritySignal(
            score: nil,
            status: "Pending",
            detail: "Run risk-modes to populate security.",
            sourceLabel: "Local SDK",
            segmentCount: 0,
            inspectCommand: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.securityCommand)
        ),
        tessl: TesslSignal(
            ok: false,
            cliAvailable: false,
            authenticated: false,
            displayStatus: "Not fetched",
            detail: "Tessl has not been probed yet.",
            cliVersion: nil,
            registryScore: nil,
            registryVersion: nil,
            registryQualityScore: nil,
            registryImpactScore: nil,
            registrySecurityLabel: nil,
            registryEvalCount: nil,
            registryImprovementMultiplier: nil,
            registryVisibility: nil,
            recoveryCommand: "tessl doctor"
        ),
        fleet: FleetSignal.placeholder,
        pipeline: .unproven(),
        refreshedAt: Date(),
        error: nil
    )

    static let reviewFixture = makeReviewFixture(
        tessl: TesslSignal(
            ok: true,
            cliAvailable: true,
            authenticated: true,
            displayStatus: "Scored",
            detail: "Registry metadata loaded from the Tessl CLI; local evidence remains separate.",
            cliVersion: "fixture",
            registryScore: 66,
            registryVersion: "0.2.0",
            registryQualityScore: 100,
            registryImpactScore: 63,
            registrySecurityLabel: "Passed",
            registryEvalCount: 68,
            registryImprovementMultiplier: 1.28,
            registryVisibility: "Private",
            dataOrigin: .liveCLI,
            recoveryCommand: "tessl install jscraik/improve-agent-native"
        )
    )

    static let reviewNoCLIFixture = makeReviewFixture(
        tessl: TesslSignal(
            ok: false,
            cliAvailable: false,
            authenticated: false,
            displayStatus: "CLI unavailable",
            detail: "The Tessl CLI is unavailable; showing the last known registry snapshot.",
            cliVersion: nil,
            registryScore: 66,
            registryVersion: "0.2.0",
            registryQualityScore: 100,
            registryImpactScore: 63,
            registrySecurityLabel: "Passed",
            registryEvalCount: 68,
            registryImprovementMultiplier: 1.28,
            registryVisibility: "Private",
            dataOrigin: .cached,
            recoveryCommand: "tessl doctor"
        )
    )

    private static func makeReviewFixture(tessl: TesslSignal) -> SkillDashboard {
        SkillDashboard(
        displayName: "improve-agent-native",
        version: "0.2.0",
        description: "Live eval plugin for improve-agent-native.",
        registryPath: "jscraik/improve-agent-native",
        repoPath: "/Users/jamiecraik/dev/agent-skills",
        installCommand: "tessl install jscraik/improve-agent-native",
        localEvidenceCommand: DashboardLoader.localEvidenceCommand(root: DashboardLoader.defaultRepoRoot),
        reviewedText: "Local SDK evidence",
        deltaText: "Local SDK",
        quality: MetricSignal(
            score: 100,
            detail: "Package verify reported success.",
            source: "Local SDK package verify",
            command: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.packageCommand)
        ),
        impact: MetricSignal(
            score: 100,
            detail: "71/71 eval scenarios available.",
            source: "Local SDK scenario-quality",
            command: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.impactCommand),
            statusOverride: "71/71"
        ),
        security: SecuritySignal(
            score: 35,
            status: "Flagged",
            detail: "3 risk modes: 1 critical, 2 high.",
            sourceLabel: "Local SDK risk-modes",
            segmentCount: 3,
            inspectCommand: DashboardLoader.copyCommand(
                root: DashboardLoader.defaultRepoRoot,
                command: DashboardLoader.securityCommand(for: DashboardLoader.defaultSkillPath)
            )
        ),
        tessl: tessl,
        fleet: FleetSignal(
            skillCount: 1,
            groupCount: 1,
            largestGroupName: "agent-ops",
            largestGroupCount: 1,
            metadataCount: 1,
            referencesCount: 1,
            evalsCount: 1,
            selectedSkillPath: DashboardLoader.defaultSkillPath,
            inventoryCommand: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.allSkillsInventoryCommand)
        ),
        pipeline: PipelineCandidate(
            fingerprint: "review-fixture-v1",
            governedInputPaths: [
                "Skills/agent-ops/improve-agent-native/SKILL.md",
                "Skills/agent-ops/improve-agent-native/references/risk-modes.md",
                "Skills/agent-ops/improve-agent-native/evals/scenarios.json"
            ],
            observedAt: Date(timeIntervalSince1970: 0),
            stageReceipts: [
                PipelineStageReceipt(
                    stage: .candidateBaseline,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .reviewRequired,
                    stageScore: nil,
                    command: DashboardLoader.copyCommand(
                        root: DashboardLoader.defaultRepoRoot,
                        command: DashboardLoader.sdkStartCommand(for: DashboardLoader.defaultSkillPath)
                    ),
                    receiptPath: nil,
                    modelProfile: "local-identity",
                    observedAt: Date(timeIntervalSince1970: 0),
                    nextAction: "Canonical package digest missing"
                ),
                PipelineStageReceipt(
                    stage: .mechanicalValidation,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .passed,
                    stageScore: 50,
                    command: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.packageCommand),
                    receiptPath: "fixture:package-verify",
                    modelProfile: "local-package",
                    observedAt: Date(timeIntervalSince1970: 0),
                    nextAction: "Package verify passed · Strict audit missing"
                ),
                PipelineStageReceipt(
                    stage: .securityReview,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .reviewRequired,
                    stageScore: 35,
                    command: DashboardLoader.copyCommand(
                        root: DashboardLoader.defaultRepoRoot,
                        command: DashboardLoader.securityCommand(for: DashboardLoader.defaultSkillPath)
                    ),
                    receiptPath: "fixture:risk-modes",
                    modelProfile: "local-security",
                    observedAt: Date(timeIntervalSince1970: 0),
                    nextAction: "Risk taxonomy observed early · full receipt missing"
                ),
                PipelineStageReceipt(
                    stage: .evalPreparation,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .passed,
                    stageScore: 50,
                    command: DashboardLoader.copyCommand(
                        root: DashboardLoader.defaultRepoRoot,
                        command: DashboardLoader.impactCommand(for: DashboardLoader.defaultSkillPath)
                    ),
                    receiptPath: "fixture:scenario-quality",
                    modelProfile: "eval-preparation",
                    observedAt: Date(timeIntervalSince1970: 0),
                    nextAction: "Scenario readiness 71 / 71 · scorer & calibration missing"
                ),
                PipelineStageReceipt(
                    stage: .ossLocal,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .unproven,
                    stageScore: nil,
                    command: "",
                    receiptPath: nil,
                    modelProfile: "oss-local",
                    observedAt: nil,
                    nextAction: "Eval local profile · Unproven"
                ),
                PipelineStageReceipt(
                    stage: .ossCloud,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .unproven,
                    stageScore: nil,
                    command: "",
                    receiptPath: nil,
                    modelProfile: "oss-cloud",
                    observedAt: nil,
                    nextAction: "Eval cloud profile · Same scenario IDs required"
                ),
                PipelineStageReceipt(
                    stage: .tesslStaging,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .unproven,
                    stageScore: nil,
                    command: "",
                    receiptPath: nil,
                    modelProfile: "tessl-staging",
                    observedAt: nil,
                    nextAction: "Local proof · dry run · handoff"
                ),
                PipelineStageReceipt(
                    stage: .tesslLiveRegistry,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .unproven,
                    stageScore: nil,
                    command: "",
                    receiptPath: nil,
                    modelProfile: "tessl-live",
                    observedAt: nil,
                    nextAction: "Publish receipt · registry visibility"
                ),
                PipelineStageReceipt(
                    stage: .liveScoreAndRuntime,
                    candidateFingerprint: "review-fixture-v1",
                    evidenceStatus: .unproven,
                    stageScore: nil,
                    command: "",
                    receiptPath: nil,
                    modelProfile: "live-runtime",
                    observedAt: nil,
                    nextAction: "Installed digest · doctor · observed behavior"
                )
            ]
        ),
        refreshedAt: Date(timeIntervalSince1970: 0),
        error: nil
        )
    }
}

private func normalizedVersion(_ value: String) -> String {
    let trimmed = value.trimmingCharacters(in: .whitespacesAndNewlines)
    guard trimmed.lowercased().hasPrefix("v") else { return trimmed }
    return String(trimmed.dropFirst())
}

struct ReviewPresentation {
    let dashboard: SkillDashboard

    enum State: Equatable {
        case loading
        case reviewRequired
        case advisory
        case degradedLocalEvidence
        case healthy
        case registryUnavailable
    }

    var isReviewState: Bool {
        dashboard.security.disposition.requiresReview || state == .degradedLocalEvidence
    }

    var state: State {
        if dashboard.security.disposition == .failed || dashboard.security.disposition == .flagged {
            return .reviewRequired
        }
        if dashboard.security.disposition == .advisory { return .advisory }
        if dashboard.score == nil { return .loading }
        if !dashboard.tessl.ok { return .registryUnavailable }
        if dashboard.scoreTone != .positive { return .degradedLocalEvidence }
        return .healthy
    }

    var emphasisTone: StatusTone {
        switch state {
        case .loading: return .pending
        case .reviewRequired: return dashboard.security.tone
        case .advisory: return .advisory
        case .degradedLocalEvidence: return dashboard.scoreTone
        case .healthy: return .positive
        case .registryUnavailable: return .pending
        }
    }

    var triggerTitle: String {
        switch state {
        case .loading: return "Evidence pending"
        case .reviewRequired: return "Review trigger"
        case .advisory: return "Advisory review"
        case .degradedLocalEvidence: return "Local score needs review"
        case .healthy: return "Local evidence"
        case .registryUnavailable: return "Registry unavailable"
        }
    }

    var triggerSystemName: String {
        switch state {
        case .loading: return "clock"
        case .reviewRequired: return "exclamationmark.triangle"
        case .advisory: return "info.circle"
        case .degradedLocalEvidence: return "exclamationmark.triangle"
        case .healthy: return "checkmark.seal"
        case .registryUnavailable: return "network.slash"
        }
    }

    var qualityDetail: String {
        dashboard.quality.score == 100 ? "Follows best\npractices" : dashboard.quality.compactDetail
    }

    var impactDetail: String {
        guard let ratio = dashboard.impact.ratioLabel else {
            return dashboard.impact.compactDetail
        }
        let values = ratio.split(separator: "/")
        if values.count == 2, values[0] == values[1] {
            return "All \(ratio) local\nscenarios passed"
        }
        return dashboard.impact.compactDetail
    }

    var bridgeSystemName: String {
        if !dashboard.tessl.ok { return "network.slash" }
        if dashboard.tessl.evidenceRequiresReview { return "exclamationmark.triangle" }
        return isReviewState ? "checkmark" : "checkmark.seal"
    }

    var bridgeTone: StatusTone {
        guard dashboard.tessl.ok else { return .pending }
        return dashboard.tessl.evidenceRequiresReview ? .warning : .positive
    }

    var showsBridgeWarningBadge: Bool {
        dashboard.tessl.ok && (isReviewState || dashboard.tessl.evidenceRequiresReview)
    }

    var packageIdentity: String {
        dashboard.registryPath
    }

    var bridgeTitle: String {
        if !dashboard.tessl.ok { return "Registry evidence unavailable." }
        if isReviewState && dashboard.tessl.evidenceRequiresReview {
            return "Local and registry evidence need review."
        }
        if isReviewState { return "Registry evidence healthy. Local source has findings." }
        if dashboard.tessl.evidenceRequiresReview { return "Registry evidence needs review." }
        return "Local and registry evidence are available."
    }

    var bridgeDetail: String {
        dashboard.tessl.registryEvalCount.map { "\($0) registry eval scenarios" }
            ?? "Registry eval count unavailable"
    }

    var actionTitle: String {
        "Copy inspect command"
    }

    var actionDetail: String {
        isReviewState
            ? "Inspect \(dashboard.security.severityLine) in SKILL.md"
            : "Inspect local security evidence in SKILL.md"
    }

    var actionCommand: String {
        dashboard.reviewInspectCommand
    }
}

struct RegistryMetricPresentation {
    static func percentTone(_ value: Int?) -> StatusTone {
        guard let value else { return .pending }
        if value >= 80 { return .positive }
        if value >= 60 { return .warning }
        return .danger
    }
}

struct TesslRegistryMetadata {
    let score: Int?
    let version: String?
    let qualityScore: Int?
    let impactScore: Int?
    let securityLabel: String?
    let evalCount: Int?
    let improvementMultiplier: Double?
    let visibility: String?

    init(payload: JSONNode?, registryPath: String? = nil) {
        let containers = Self.canonicalContainers(from: payload?.value, registryPath: registryPath)
        score = Self.score(from: containers)
        version = Self.string(in: containers, keys: ["latestVersion", "version", "latest_version", "published_version", "package_version"])
        qualityScore = Self.percent(from: containers, key: "quality")
        impactScore = Self.percent(from: containers, key: "impact")
        securityLabel = Self.string(in: containers, keys: ["security"])
        evalCount = Self.number(in: containers, keys: ["count"]).map { Int($0) }
        improvementMultiplier = Self.number(in: containers, keys: ["improvementMultiplier"])
        let rawVisibility = Self.string(in: containers, keys: ["visibility", "accessLevel", "access_level", "access"])?.lowercased()
        visibility = rawVisibility == "private" || rawVisibility == "public" ? rawVisibility : nil
    }

    private static func score(from containers: [[String: Any]]) -> Int? {
        for key in ["aggregate", "validated_score", "validation_score", "quality_score", "score", "rating"] {
            guard let rawScore = number(in: containers, keys: [key]) else { continue }
            let normalizedScore = rawScore <= 1.0 ? rawScore * 100.0 : rawScore
            let score = Int(normalizedScore.rounded())
            if (0...100).contains(score) { return score }
        }
        return nil
    }

    private static func percent(from containers: [[String: Any]], key: String) -> Int? {
        guard let rawValue = number(in: containers, keys: [key]) else { return nil }
        let normalizedValue = rawValue <= 1.0 ? rawValue * 100.0 : rawValue
        let value = Int(normalizedValue.rounded())
        return (0...100).contains(value) ? value : nil
    }

    private static func canonicalContainers(from value: Any?, registryPath: String?) -> [[String: Any]] {
        guard let root = value as? [String: Any] else { return [] }
        var containers: [[String: Any]] = []

        func appendResult(_ result: [String: Any]) {
            containers.append(result)
            if let scores = result["scores"] as? [String: Any] {
                containers.append(scores)
                if let evaluations = scores["evals"] as? [String: Any] {
                    containers.append(evaluations)
                }
            }
        }

        if let data = root["data"] as? [String: Any], let result = data["result"] as? [String: Any] {
            appendResult(result)
        }
        if let result = root["result"] as? [String: Any] { appendResult(result) }
        if let data = root["data"] as? [String: Any] { containers.append(data) }
        if let results = root["results"] as? [[String: Any]] {
            let selected = registryPath.flatMap { requested in
                results.first { ($0["fullName"] as? String)?.caseInsensitiveCompare(requested) == .orderedSame }
            } ?? results.first
            if let selected { appendResult(selected) }
        }
        containers.append(root)
        return containers
    }

    private static func string(in containers: [[String: Any]], keys: [String]) -> String? {
        for container in containers {
            for key in keys {
                if let value = container[key] as? String { return value }
            }
        }
        return nil
    }

    private static func number(in containers: [[String: Any]], keys: [String]) -> Double? {
        for container in containers {
            for key in keys {
                if let value = container[key] as? NSNumber { return value.doubleValue }
                if let value = container[key] as? Double { return value }
                if let value = container[key] as? Int { return Double(value) }
            }
        }
        return nil
    }
}

private func globalShellQuoted(_ value: String) -> String {
    "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
}

struct FleetSignal {
    var skillCount: Int
    var groupCount: Int
    var largestGroupName: String
    var largestGroupCount: Int
    var metadataCount: Int
    var referencesCount: Int
    var evalsCount: Int
    var selectedSkillPath: String
    var inventoryCommand: String

    static let placeholder = FleetSignal(
        skillCount: 0,
        groupCount: 0,
        largestGroupName: "unknown",
        largestGroupCount: 0,
        metadataCount: 0,
        referencesCount: 0,
        evalsCount: 0,
        selectedSkillPath: "Skills/agent-ops/improve-agent-native/SKILL.md",
        inventoryCommand: DashboardLoader.copyCommand(root: DashboardLoader.defaultRepoRoot, command: DashboardLoader.allSkillsInventoryCommand)
    )

    var title: String {
        skillCount > 0 ? "\(skillCount) local skills" : "Skill inventory pending"
    }

    var scanMode: String {
        "inventory"
    }

    var detail: String {
        guard skillCount > 0 else { return "Discovering Skills/**/SKILL.md before deeper checks." }
        return "\(groupCount) groups · meta \(coverage(metadataCount)) · refs \(coverage(referencesCount)) · evals \(coverage(evalsCount))"
    }
    var compactLine: String {
        guard skillCount > 0 else { return "Discovering local skills inventory" }
        return "\(skillCount) skills · \(groupCount) groups · \(largestGroupName) \(largestGroupCount)"
    }

    var tone: StatusTone {
        guard skillCount > 0 else { return .pending }
        if evalsCount < skillCount || referencesCount < skillCount || metadataCount < skillCount { return .warning }
        return .positive
    }

    private func coverage(_ count: Int) -> String {
        guard skillCount > 0 else { return "--" }
        return "\(count)/\(skillCount)"
    }
}

struct MetricSignal {
    var score: Int?
    var detail: String
    var source: String
    var command: String
    var statusOverride: String? = nil
    var displayScore: String { score.map { "\($0)%" } ?? "--" }
    var statusLabel: String { statusOverride ?? score.map { "\($0)%" } ?? "Pending" }
    var formulaValue: String { score.map { "\($0)" } ?? "--" }
    var sourceShort: String {
        if source.localizedCaseInsensitiveContains("package") { return "package verify" }
        if source.localizedCaseInsensitiveContains("scenario") { return "scenario-quality" }
        return source
    }
    var scoreFraction: Double { min(max(Double(score ?? 0) / 100.0, 0), 1) }
    var ratioLabel: String? {
        guard let first = detail.split(separator: " ").first.map(String.init),
              first.contains("/") else { return nil }
        return first
    }
    var tone: StatusTone {
        guard let score else { return .pending }
        if score >= 80 { return .positive }
        if score >= 60 { return .warning }
        return .danger
    }
    var compactDetail: String {
        if score != nil {
            if source.localizedCaseInsensitiveContains("package") {
                return "Package verified"
            }
            if source.localizedCaseInsensitiveContains("scenario") {
                return detail
                    .replacingOccurrences(of: " eval scenarios available.", with: " scenarios")
                    .replacingOccurrences(of: "Average across ", with: "")
            }
            return detail
        }
        if source.localizedCaseInsensitiveContains("package") {
            return "No package score yet"
        }
        if source.localizedCaseInsensitiveContains("scenario") {
            return "Scenario check not run"
        }
        return "Waiting for verification"
    }
    var shortDetail: String {
        compactDetail
            .replacingOccurrences(of: " scenarios", with: " scen.")
            .replacingOccurrences(of: "Package verified", with: "package")
            .replacingOccurrences(of: "Scenario check not run", with: "not run")
            .replacingOccurrences(of: "No package score yet", with: "no score")
    }
}

struct SecuritySignal {
    var score: Int?
    var status: String
    var detail: String
    var sourceLabel: String
    var segmentCount: Int
    var inspectCommand: String
    var disposition: SecurityDisposition { SecurityDisposition(label: status) }
    var tone: StatusTone {
        if score == nil { return .pending }
        return disposition.tone
    }
    var compactDetail: String {
        if detail.hasPrefix("Run ") { return "Security scan pending" }
        return detail
            .replacingOccurrences(of: "; no mutation performed.", with: "")
            .replacingOccurrences(of: " signal(s)", with: "")
            .replacingOccurrences(of: "mode detected", with: "modes detected")
    }
    var riskLabel: String {
        if let score, score > 0, status.localizedCaseInsensitiveContains("flag") {
            return compactDetail.replacingOccurrences(of: " detected", with: "")
        }
        return status
    }
    var statusDisplay: String {
        if status.localizedCaseInsensitiveContains("flag") {
            if let count = Int(riskLabel.prefix { $0.isNumber }) {
                return "\(count) risks"
            }
            return riskLabel.replacingOccurrences(of: " risk modes", with: " risks")
        }
        return status
    }
    var detailLine: String {
        if status.localizedCaseInsensitiveContains("flag") {
            return "\(riskLabel) from \(sourceLabel) evidence"
        }
        return compactDetail
    }
    var formulaValue: String { score.map { "\($0)" } ?? "--" }
    var scoreMathLine: String {
        guard let score else { return "pending" }
        return "100 - \(max(0, 100 - score)) = \(score)"
    }
    var penaltyLine: String {
        guard let score else { return "pending" }
        let penalty = max(0, 100 - score)
        return penalty > 0 ? "-\(penalty)" : "no penalty"
    }
    var severityLine: String {
        if status.localizedCaseInsensitiveContains("flag") {
            let withoutModes = riskLabel
                .replacingOccurrences(of: " risk modes", with: "")
                .replacingOccurrences(of: ".", with: "")
            if let colonIndex = withoutModes.firstIndex(of: ":") {
                return String(withoutModes[withoutModes.index(after: colonIndex)...]).trimmingCharacters(in: .whitespaces)
            }
            return withoutModes
        }
        return compactDetail
    }
    var sourceBadge: String {
        status.localizedCaseInsensitiveContains("flag") ? "from \(sourceLabel) receipt" : sourceLabel
    }
    var accessibilityText: String {
        if status.localizedCaseInsensitiveContains("flag") {
            return "Security flagged. \(riskLabel) from \(sourceLabel) evidence."
        }
        return "Security \(status). \(compactDetail)."
    }
}

enum TesslDataOrigin: Equatable {
    case unavailable
    case liveCLI
    case cached
    case fixture
}

struct TesslSignal {
    var ok: Bool
    var cliAvailable: Bool
    var authenticated: Bool
    var displayStatus: String
    var detail: String
    var cliVersion: String?
    var registryScore: Int?
    var registryVersion: String?
    var registryQualityScore: Int?
    var registryImpactScore: Int?
    var registrySecurityLabel: String?
    var registryEvalCount: Int?
    var registryImprovementMultiplier: Double?
    var registryVisibility: String?
    var dataOrigin: TesslDataOrigin = .unavailable
    var recoveryCommand: String

    var registryVisibilityDisplay: String? {
        guard let registryVisibility else { return nil }
        let value = registryVisibility.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty else { return nil }
        return value.prefix(1).uppercased() + value.dropFirst().lowercased()
    }
    var compactDetail: String {
        if ok, let registryVersion { return "Registry metadata v\(registryVersion); local evidence remains separate." }
        if ok { return "Registry metadata connected; local evidence remains separate." }
        if !cliAvailable { return "Tessl CLI is not available on PATH." }
        if !authenticated { return "\(cliVersionLabel) · login unlocks registry search." }
        return detail
    }
    var registryDetailLine: String {
        if ok {
            var parts: [String] = []
            if let registryVersion { parts.append("v\(registryVersion)") }
            if let registryScore { parts.append("score \(registryScore)") }
            parts.append("separate proof")
            return parts.joined(separator: " · ")
        }
        return compactDetail
    }
    var cliVersionLabel: String {
        cliVersion.map { "tessl \($0)" } ?? "tessl CLI detected"
    }
    var versionBadge: String {
        cliVersion.map { "tessl \($0)" } ?? (cliAvailable ? "tessl CLI" : "no tessl")
    }
    var compactVersionBadge: String {
        cliVersion.map { "tessl \($0)" } ?? (cliAvailable ? "tessl" : "no tessl")
    }
    var tone: StatusTone {
        if ok { return .positive }
        if cliAvailable { return .warning }
        return .pending
    }
    var registryStatusLabel: String {
        if ok, registryScore != nil { return "Loaded" }
        return displayStatus
    }
    var registryStatusTone: StatusTone {
        if ok { return .pending }
        return tone
    }
    var actionTitle: String {
        if ok { return "Open Tessl registry" }
        if cliAvailable { return "Log in to Tessl" }
        return "Copy install help"
    }
    var copiedActionTitle: String {
        if ok { return "Open Tessl registry" }
        return "Copied \(recoveryCommand)"
    }
    var actionHelp: String {
        if ok { return "Open Tessl registry" }
        if cliAvailable { return "Open Terminal and run \(recoveryCommand)" }
        return "Copy \(recoveryCommand) to the clipboard"
    }
    var installLabel: String {
        ok ? "Install" : "Login"
    }
    var blockerSummary: String {
        if ok { return "registry ok" }
        if !cliAvailable { return "CLI missing" }
        if !authenticated { return "auth expired" }
        return displayStatus.lowercased()
    }
    var compactBlockerSummary: String {
        if ok { return "registry ok" }
        if !cliAvailable { return "no CLI" }
        if !authenticated { return "auth exp" }
        return displayStatus.lowercased()
    }
    var nextStepSentence: String {
        if ok { return "Registry metadata is available." }
        return "Run \(recoveryCommand); local Q/I/S stays current."
    }
    var registryResultLabel: String {
        if let registryScore { return "\(registryScore)" }
        if ok { return "Registry OK" }
        if !cliAvailable { return "No CLI" }
        if !authenticated { return "Locked" }
        return "Blocked"
    }
    var registryVersionDisplay: String {
        registryVersion.map { "v\($0)" } ?? "version --"
    }
    var registryScoreTone: StatusTone {
        guard let registryScore else { return ok ? .pending : tone }
        if registryScore >= 80 { return .positive }
        if registryScore >= 60 { return .warning }
        return .danger
    }
    var registryImpactDisplay: String {
        if let registryImprovementMultiplier {
            return "\(String(format: "%.2f", registryImprovementMultiplier))x"
        }
        if let registryImpactScore {
            return "\(registryImpactScore)%"
        }
        return "--"
    }
    var registryImpactTone: StatusTone {
        if let registryImprovementMultiplier {
            return registryImprovementMultiplier >= 1 ? .positive : .danger
        }
        guard let registryImpactScore else { return .pending }
        if registryImpactScore >= 80 { return .positive }
        if registryImpactScore >= 60 { return .warning }
        return .danger
    }
    var registrySecurityDisplay: String {
        guard let registrySecurityLabel else { return ok ? "Loaded" : displayStatus }
        if registrySecurityLabel.localizedCaseInsensitiveContains("pass") {
            return "Passed"
        }
        if registrySecurityLabel.localizedCaseInsensitiveContains("low") {
            return "Passed"
        }
        return registrySecurityLabel.capitalized
    }
    var registrySecurityTone: StatusTone {
        guard registrySecurityLabel != nil else { return tone }
        return SecurityDisposition(label: registrySecurityLabel).tone
    }
    var evidenceRequiresReview: Bool {
        guard ok else { return false }
        if SecurityDisposition(label: registrySecurityLabel).requiresReview { return true }
        return [registryScore, registryQualityScore, registryImpactScore]
            .compactMap { $0 }
            .contains { $0 < 80 }
    }
    func driftLabel(localScore: Int?) -> String {
        guard let localScore else { return "--" }
        if let registryScore {
            let delta = registryScore - localScore
            if delta > 0 { return "+\(delta)" }
            return "\(delta)"
        }
        if ok { return "No score" }
        return "--"
    }
    func registryRelationLabel(localScore: Int?) -> String {
        guard localScore != nil else { return "local score pending" }
        guard let localScore, let registryScore else { return "No registry score" }
        let delta = registryScore - localScore
        if delta == 0 { return "Matches local" }
        if delta > 0 { return "\(delta) above local" }
        return "\(abs(delta)) below local"
    }
    func registryComparisonDetail(localScore: Int?) -> String {
        if ok, let breakdown = registryBreakdownLine {
            if localScore == nil {
                return breakdown
            }
            return "\(breakdown) · \(registryRelationLabel(localScore: localScore))"
        }
        if ok {
            return "Registry metadata · \(registryRelationLabel(localScore: localScore))"
        }
        return nextStepSentence
    }
    func headerBadgeLabel(localScore: Int?) -> String? {
        guard ok, let registryScore else { return nil }
        return "Tessl \(registryScore) \(driftLabel(localScore: localScore))"
    }
    func headerBadgeTone(localScore: Int?) -> StatusTone {
        guard ok else { return .pending }
        guard let localScore, let registryScore else { return .positive }
        if registryScore < localScore { return .warning }
        return .positive
    }
    var registryBreakdownLine: String? {
        guard ok else { return nil }
        var parts: [String] = []
        if let registryQualityScore { parts.append("Q\(registryQualityScore)") }
        if let registryImpactScore { parts.append("I\(registryImpactScore)") }
        if let registrySecurityLabel { parts.append("S:\(registrySecurityLabel.uppercased())") }
        if let registryEvalCount { parts.append("E\(registryEvalCount)") }
        if let registryImprovementMultiplier {
            parts.append("x\(String(format: "%.2f", registryImprovementMultiplier))")
        }
        return parts.isEmpty ? nil : parts.joined(separator: " ")
    }
}
