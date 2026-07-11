import AppKit
@testable import SkillsBar
import SkillsBarCore
import SwiftUI
import XCTest

final class ReviewPopoverTests: XCTestCase {
    @MainActor
    private final class TestPasteboard: PasteboardWriting {
        var string: String?
        var acceptsWrites = true

        func clearContents() -> Int {
            string = nil
            return 1
        }

        func setString(_ string: String, forType _: NSPasteboard.PasteboardType) -> Bool {
            guard acceptsWrites else { return false }
            self.string = string
            return true
        }
    }

    private let expectedCommand = "cd '/Users/jamiecraik/dev/agent-skills' && ./bin/ask sdk security risk-modes 'Skills/agent-ops/improve-agent-native/SKILL.md' --preview --json --robot"

    func testReviewFixtureMatchesImplementationHandoffContract() {
        let dashboard = SkillDashboard.reviewFixture

        XCTAssertEqual(dashboard.verdictTitle, "Needs review")
        XCTAssertEqual(dashboard.verdictDetail, "3 risks need inspection")
        XCTAssertEqual(dashboard.description, "Live eval plugin for improve-agent-native.")
        XCTAssertEqual(dashboard.score, 78)
        XCTAssertEqual(dashboard.pipeline.postureScore, 24)
        XCTAssertEqual(dashboard.pipeline.evidencedStageCount, 2)
        XCTAssertEqual(dashboard.pipeline.activeReceipt?.stage, .securityReview)
        XCTAssertEqual(dashboard.pipeline.activeReceipt?.nextAction, "Inspect 1 critical, 2 high in SKILL.md.")
        XCTAssertEqual(dashboard.pipeline.activeReceipt?.command, expectedCommand)
        XCTAssertEqual(dashboard.quality.statusLabel, "100%")
        XCTAssertEqual(dashboard.impact.statusLabel, "71/71")
        XCTAssertEqual(dashboard.security.statusDisplay, "3 risks")
        XCTAssertEqual(dashboard.security.severityLine, "1 critical, 2 high")
        XCTAssertEqual(dashboard.tessl.registryScore, 66)
        XCTAssertEqual(dashboard.tessl.registryVersion, "0.2.0")
        XCTAssertEqual(dashboard.tessl.registryQualityScore, 100)
        XCTAssertEqual(dashboard.tessl.registryImpactScore, 63)
        XCTAssertEqual(dashboard.tessl.registrySecurityDisplay, "Passed")
        XCTAssertEqual(dashboard.tessl.registryEvalCount, 68)
        XCTAssertEqual(dashboard.tessl.registryImprovementMultiplier, 1.28)
        XCTAssertEqual(dashboard.tessl.registryVisibilityDisplay, "Private")
        XCTAssertEqual(dashboard.reviewInspectCommand, expectedCommand)
    }

    func testReviewPresentationExplainsLocalAndRegistryTruth() {
        let presentation = ReviewPresentation(dashboard: .reviewFixture)

        XCTAssertTrue(presentation.isReviewState)
        XCTAssertEqual(presentation.packageIdentity, "jscraik/improve-agent-native")
        XCTAssertEqual(presentation.bridgeTitle, "Local and registry evidence need review.")
        XCTAssertEqual(presentation.bridgeDetail, "68 registry eval scenarios")
        XCTAssertEqual(presentation.actionTitle, "Copy inspect command")
        XCTAssertEqual(presentation.actionDetail, "Inspect 1 critical, 2 high in SKILL.md")
        XCTAssertEqual(presentation.actionCommand, expectedCommand)
    }

    func testPendingPresentationDoesNotClaimReviewOrSuccess() {
        let presentation = ReviewPresentation(dashboard: .placeholder)

        XCTAssertEqual(presentation.state, .loading)
        XCTAssertEqual(presentation.triggerTitle, "Evidence pending")
        XCTAssertEqual(presentation.emphasisTone, .pending)
        XCTAssertEqual(presentation.qualityDetail, "No package score yet")
        XCTAssertEqual(presentation.impactDetail, "Scenario check not run")
        XCTAssertEqual(presentation.bridgeTitle, "Registry evidence unavailable.")
        XCTAssertEqual(presentation.bridgeSystemName, "network.slash")
        XCTAssertFalse(presentation.showsBridgeWarningBadge)
    }

    func testHealthyPresentationUsesPositiveSemantics() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.security = SecuritySignal(
            score: 100,
            status: "Passed",
            detail: "No known issues.",
            sourceLabel: "Local SDK risk-modes",
            segmentCount: 3,
            inspectCommand: expectedCommand
        )
        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertEqual(presentation.state, .healthy)
        XCTAssertEqual(presentation.triggerTitle, "Local evidence")
        XCTAssertEqual(presentation.emphasisTone, .positive)
        XCTAssertEqual(presentation.bridgeTitle, "Registry evidence needs review.")
        XCTAssertEqual(presentation.bridgeSystemName, "exclamationmark.triangle")
        XCTAssertTrue(presentation.showsBridgeWarningBadge)
    }

    func testUnavailableRegistryDoesNotRenderSuccessBridge() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.tessl.ok = false
        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertEqual(presentation.state, .reviewRequired)
        XCTAssertEqual(presentation.triggerTitle, "Review trigger")
        XCTAssertEqual(presentation.bridgeTone, .pending)
        XCTAssertEqual(presentation.bridgeSystemName, "network.slash")
        XCTAssertFalse(presentation.showsBridgeWarningBadge)
    }

    func testRegistryVisibilityIsNormalizedAndCanBeAbsent() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.tessl.registryVisibility = "PUBLIC"
        XCTAssertEqual(dashboard.tessl.registryVisibilityDisplay, "Public")

        dashboard.tessl.registryVisibility = nil
        XCTAssertNil(dashboard.tessl.registryVisibilityDisplay)
    }

    func testRegistryMetricTonesFollowActualValues() {
        XCTAssertEqual(RegistryMetricPresentation.percentTone(nil), .pending)
        XCTAssertEqual(RegistryMetricPresentation.percentTone(100), .positive)
        XCTAssertEqual(RegistryMetricPresentation.percentTone(72), .warning)
        XCTAssertEqual(RegistryMetricPresentation.percentTone(35), .danger)
        XCTAssertEqual(SecurityDisposition(label: nil).tone, .pending)
        XCTAssertEqual(SecurityDisposition(label: "Passed").tone, .positive)
        XCTAssertEqual(SecurityDisposition(label: "Advisory").tone, .advisory)
        XCTAssertEqual(SecurityDisposition(label: "Advisory review").tone, .advisory)
        XCTAssertEqual(SecurityDisposition(label: "Flagged").tone, .warning)
        XCTAssertEqual(SecurityDisposition(label: "Failed").tone, .danger)
    }

    func testSecurityDispositionUsesSeverityFirstPrecedence() {
        XCTAssertEqual(SecurityDisposition(label: nil), .pending)
        XCTAssertEqual(SecurityDisposition(label: "Passed"), .passed)
        XCTAssertEqual(SecurityDisposition(label: "Advisory"), .advisory)
        XCTAssertEqual(SecurityDisposition(label: "Flagged"), .flagged)
        XCTAssertEqual(SecurityDisposition(label: "Failed"), .failed)
        XCTAssertEqual(SecurityDisposition(label: "Not passed"), .failed)
        XCTAssertEqual(SecurityDisposition(label: "Critical advisory"), .failed)
        XCTAssertEqual(SecurityDisposition(label: "Flagged but passed baseline"), .flagged)
        XCTAssertEqual(SecurityDisposition(label: "Failed after advisory review"), .failed)
    }

    func testLocalAdvisoryPresentationIsBlueAndNotHealthy() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.security = SecuritySignal(
            score: 70,
            status: "Advisory",
            detail: "Manual review advised.",
            sourceLabel: "Local SDK risk-modes",
            segmentCount: 2,
            inspectCommand: expectedCommand
        )
        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertEqual(dashboard.security.disposition, .advisory)
        XCTAssertEqual(dashboard.security.tone, .advisory)
        XCTAssertEqual(presentation.state, .advisory)
        XCTAssertEqual(presentation.emphasisTone, .advisory)
        XCTAssertEqual(presentation.triggerTitle, "Advisory review")
        XCTAssertTrue(presentation.isReviewState)
    }

    func testSecurityFindingOutranksMissingQualityAndImpactScores() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.quality.score = nil
        dashboard.impact.score = nil

        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertNil(dashboard.score)
        XCTAssertEqual(presentation.state, .reviewRequired)
        XCTAssertEqual(presentation.triggerTitle, "Review trigger")
        XCTAssertEqual(presentation.emphasisTone, .warning)
    }

    func testFailedSecurityUsesDangerTone() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.security.status = "Failed"

        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertEqual(presentation.state, .reviewRequired)
        XCTAssertEqual(presentation.emphasisTone, .danger)
    }

    func testLowLocalScoreIsNotPresentedAsHealthy() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.quality.score = 50
        dashboard.impact.score = 50
        dashboard.security = SecuritySignal(
            score: 100,
            status: "Passed",
            detail: "No known issues.",
            sourceLabel: "Local SDK risk-modes",
            segmentCount: 3,
            inspectCommand: expectedCommand
        )

        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertNotEqual(presentation.state, .healthy)
        XCTAssertEqual(presentation.emphasisTone, .warning)
        XCTAssertEqual(presentation.triggerSystemName, "exclamationmark.triangle")
    }

    func testRegistryFindingIsNotDescribedAsClean() {
        var dashboard = SkillDashboard.reviewFixture
        dashboard.tessl.registrySecurityLabel = "Flagged"
        dashboard.tessl.registryScore = 35

        let presentation = ReviewPresentation(dashboard: dashboard)

        XCTAssertTrue(dashboard.tessl.evidenceRequiresReview)
        XCTAssertEqual(presentation.bridgeTitle, "Local and registry evidence need review.")
        XCTAssertEqual(presentation.bridgeTone, .warning)
        XCTAssertEqual(presentation.bridgeSystemName, "exclamationmark.triangle")
    }

    func testRegistryVersionDoesNotFallBackToLocalSkillVersion() {
        var tessl = SkillDashboard.reviewFixture.tessl
        tessl.registryVersion = nil

        XCTAssertEqual(tessl.registryVersionDisplay, "version --")
    }

    func testSanitizedTesslPayloadMapsRegistryContract() throws {
        let url = try XCTUnwrap(Bundle.module.url(forResource: "tessl-private-skill", withExtension: "json"))
        let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
        let metadata = TesslRegistryMetadata(payload: JSONNode(object))

        XCTAssertEqual(metadata.score, 66)
        XCTAssertEqual(metadata.version, "0.2.0")
        XCTAssertEqual(metadata.qualityScore, 100)
        XCTAssertEqual(metadata.impactScore, 63)
        XCTAssertEqual(metadata.securityLabel, "Passed")
        XCTAssertEqual(metadata.evalCount, 68)
        XCTAssertEqual(metadata.visibility, "private")
    }

    func testSanitizedTesslPayloadSupportsPublicAndMissingVisibility() throws {
        let publicMetadata = try registryMetadata(fixture: "tessl-public-skill")
        let missingMetadata = try registryMetadata(fixture: "tessl-visibility-missing")

        XCTAssertEqual(publicMetadata.visibility, "public")
        XCTAssertNil(missingMetadata.visibility)
    }

    func testRegistryVisibilityDisplayNormalizesPluginMetadataForThePill() {
        var privateSignal = SkillDashboard.reviewFixture.tessl
        privateSignal.registryVisibility = "private"
        XCTAssertEqual(privateSignal.registryVisibilityDisplay, "Private")

        privateSignal.registryVisibility = "PUBLIC"
        XCTAssertEqual(privateSignal.registryVisibilityDisplay, "Public")
    }

    func testTesslMetadataPrefersCanonicalResultOverUnrelatedNestedKeys() throws {
        let metadata = try registryMetadata(fixture: "tessl-ambiguous-skill")

        XCTAssertEqual(metadata.version, "2.0.0")
        XCTAssertEqual(metadata.securityLabel, "Advisory")
        XCTAssertEqual(metadata.evalCount, 42)
        XCTAssertEqual(metadata.visibility, "public")
    }

    func testLiveTesslSearchSchemaUsesTheRequestedRegistryResult() throws {
        let metadata = try registryMetadata(
            fixture: "tessl-live-search-result",
            registryPath: "jscraik/improve-agent-native"
        )

        XCTAssertEqual(metadata.score, 67)
        XCTAssertEqual(metadata.version, "0.2.0")
        XCTAssertEqual(metadata.qualityScore, 100)
        XCTAssertEqual(metadata.impactScore, 63)
        XCTAssertEqual(metadata.securityLabel, "LOW")
        XCTAssertEqual(metadata.evalCount, 68)
        XCTAssertEqual(metadata.improvementMultiplier, 1.28)
        XCTAssertNil(metadata.visibility)
    }

    @MainActor
    func testReviewFixtureRendersPipelinePostureDeterministically() throws {
        let firstURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-review-first-\(UUID().uuidString).png")
        let secondURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-review-second-\(UUID().uuidString).png")
        defer {
            try? FileManager.default.removeItem(at: firstURL)
            try? FileManager.default.removeItem(at: secondURL)
        }

        try SnapshotRenderer.render(dashboard: .reviewFixture, to: firstURL)
        try SnapshotRenderer.render(dashboard: .reviewFixture, to: secondURL)

        let bitmap = try XCTUnwrap(NSBitmapImageRep(data: Data(contentsOf: firstURL)))
        XCTAssertEqual(bitmap.pixelsWide, 404)
        XCTAssertEqual(bitmap.pixelsHigh, 720)
        XCTAssertLessThanOrEqual(
            try pixelDifference(firstURL, secondURL),
            0.0005,
            "Repeated production renders must not capture partially materialized layers"
        )
    }

    @MainActor
    func testAdaptiveAndSemanticVariantsRenderAtStableCanvasSize() throws {
        var advisory = SkillDashboard.reviewFixture
        advisory.security.status = "Advisory"
        advisory.security.score = 70

        var publicRegistry = SkillDashboard.reviewFixture
        publicRegistry.tessl.registryVisibility = "public"

        var missingVisibility = SkillDashboard.reviewFixture
        missingVisibility.tessl.registryVisibility = nil

        let variants: [(SkillDashboard, SnapshotConfiguration)] = [
            (advisory, .default),
            (publicRegistry, .default),
            (missingVisibility, .default),
            (.reviewFixture, SnapshotConfiguration(dynamicTypeSize: .accessibility2, reduceTransparency: true, increasedContrast: true))
        ]

        for (dashboard, configuration) in variants {
            let outputURL = FileManager.default.temporaryDirectory
                .appendingPathComponent("skillsbar-variant-\(UUID().uuidString).png")
            defer { try? FileManager.default.removeItem(at: outputURL) }
            try SnapshotRenderer.render(dashboard: dashboard, configuration: configuration, to: outputURL)
            let bitmap = try XCTUnwrap(NSBitmapImageRep(data: Data(contentsOf: outputURL)))
            XCTAssertEqual(bitmap.pixelsWide, 404)
            XCTAssertEqual(bitmap.pixelsHigh, 720)
        }
    }

    func testReviewFixtureBypassesLiveLoader() throws {
        var liveLoadCount = 0
        let source = DashboardDataSource(
            environment: ["SKILLSBAR_REVIEW_FIXTURE": "1"],
            liveLoad: {
                liveLoadCount += 1
                return .placeholder
            }
        )

        let dashboard = try source.loadSync()

        XCTAssertEqual(liveLoadCount, 0)
        XCTAssertEqual(dashboard.reviewInspectCommand, expectedCommand)
    }

    func testPipelinePostureReconcilesVisibleFixtureContributions() {
        let candidate = SkillDashboard.reviewFixture.pipeline

        XCTAssertEqual(candidate.orderedReceipts.map(\.stage), PipelineStage.allCases)
        XCTAssertEqual(candidate.orderedReceipts.map { candidate.contribution(for: $0) }, [15, 9, 0, 0, 0, 0])
        XCTAssertEqual(candidate.postureScore, 24)
        XCTAssertEqual(
            candidate.postureScore,
            candidate.orderedReceipts.reduce(0) { $0 + candidate.contribution(for: $1) }
        )
    }

    func testPipelineGatesLaterReceiptsAfterReviewStage() {
        let fingerprint = "candidate-a"
        let candidate = PipelineCandidate(
            fingerprint: fingerprint,
            governedInputPaths: ["Skills/example/SKILL.md"],
            observedAt: Date(timeIntervalSince1970: 0),
            stageReceipts: PipelineStage.allCases.map { stage in
                PipelineStageReceipt(
                    stage: stage,
                    candidateFingerprint: fingerprint,
                    evidenceStatus: stage == .securityReview ? .reviewRequired : .passed,
                    stageScore: 100,
                    command: "inspect \(stage.title)",
                    receiptPath: "receipt:\(stage.rawValue)",
                    modelProfile: "test",
                    observedAt: Date(timeIntervalSince1970: 0),
                    nextAction: "Inspect \(stage.title)"
                )
            }
        )

        XCTAssertEqual(candidate.orderedReceipts[0].evidenceStatus, .passed)
        XCTAssertEqual(candidate.orderedReceipts[1].evidenceStatus, .reviewRequired)
        XCTAssertTrue(candidate.orderedReceipts.dropFirst(2).allSatisfy { $0.evidenceStatus == .unproven })
        XCTAssertEqual(candidate.postureScore, 40)
    }

    func testFingerprintChangeMakesOldReceiptsStale() {
        let oldFingerprint = "old"
        let candidate = PipelineCandidate(
            fingerprint: "new",
            governedInputPaths: ["Skills/example/SKILL.md", "Skills/example/references/core.md"],
            observedAt: Date(timeIntervalSince1970: 1),
            stageReceipts: PipelineStage.allCases.map { stage in
                PipelineStageReceipt(
                    stage: stage,
                    candidateFingerprint: oldFingerprint,
                    evidenceStatus: .passed,
                    stageScore: 100,
                    command: "inspect",
                    receiptPath: "old-receipt",
                    modelProfile: "test",
                    observedAt: Date(timeIntervalSince1970: 0),
                    nextAction: "Re-establish evidence"
                )
            }
        )

        XCTAssertTrue(candidate.orderedReceipts.allSatisfy { $0.evidenceStatus == .stale })
        XCTAssertEqual(candidate.evidencedStageCount, 0)
        XCTAssertEqual(candidate.postureScore, 0)
    }

    func testLoaderRejectsEvidenceWhenGovernedInputChangesDuringCollection() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-candidate-binding-\(UUID().uuidString)")
        let selectedSkillPath = "Skills/example/SKILL.md"
        let skillURL = root.appendingPathComponent(selectedSkillPath)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(
            at: skillURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "# Candidate before collection".write(to: skillURL, atomically: true, encoding: .utf8)

        let boundEvidence = try DashboardLoader.collectEvidence(
            root: root,
            selectedSkillPath: selectedSkillPath
        ) {
            try "# Candidate changed during collection".write(
                to: skillURL,
                atomically: true,
                encoding: .utf8
            )
            return (
                quality: MetricSignal(
                    score: 100,
                    detail: "Package verified.",
                    source: "Local SDK package verify",
                    command: "verify"
                ),
                security: SecuritySignal(
                    score: 100,
                    status: "Passed",
                    detail: "No known issues.",
                    sourceLabel: "Local SDK risk-modes",
                    segmentCount: 0,
                    inspectCommand: "inspect"
                )
            )
        }
        let candidate = DashboardLoader.pipelineCandidate(
            root: root,
            selectedSkillPath: selectedSkillPath,
            evidenceFingerprint: boundEvidence.candidateFingerprint,
            quality: boundEvidence.evidence.quality,
            security: boundEvidence.evidence.security,
            observedAt: Date(timeIntervalSince1970: 1)
        )

        XCTAssertNotEqual(candidate.fingerprint, boundEvidence.candidateFingerprint)
        XCTAssertEqual(candidate.orderedReceipts[0].evidenceStatus, .stale)
        XCTAssertEqual(candidate.orderedReceipts[1].evidenceStatus, .stale)
        XCTAssertTrue(candidate.orderedReceipts.dropFirst(2).allSatisfy { $0.evidenceStatus == .unproven })
        XCTAssertEqual(candidate.evidencedStageCount, 0)
        XCTAssertEqual(candidate.postureScore, 0)
    }

    func testFirstActiveStageAfterSecurityPassesHasInterpolatedGuidance() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-active-stage-\(UUID().uuidString)")
        let selectedSkillPath = "Skills/example/SKILL.md"
        let skillURL = root.appendingPathComponent(selectedSkillPath)
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(
            at: skillURL.deletingLastPathComponent(),
            withIntermediateDirectories: true
        )
        try "# Stable candidate".write(to: skillURL, atomically: true, encoding: .utf8)
        let fingerprint = DashboardLoader.collectEvidence(
            root: root,
            selectedSkillPath: selectedSkillPath
        ) {}
        let candidate = DashboardLoader.pipelineCandidate(
            root: root,
            selectedSkillPath: selectedSkillPath,
            evidenceFingerprint: fingerprint.candidateFingerprint,
            quality: MetricSignal(
                score: 100,
                detail: "Package verified.",
                source: "Local SDK package verify",
                command: "verify"
            ),
            security: SecuritySignal(
                score: 100,
                status: "Passed",
                detail: "No known issues.",
                sourceLabel: "Local SDK risk-modes",
                segmentCount: 0,
                inspectCommand: "inspect"
            ),
            observedAt: Date(timeIntervalSince1970: 1)
        )

        XCTAssertEqual(PipelineStage.ossLocal.title, "Local eval proof")
        XCTAssertEqual(PipelineStage.ossCloud.title, "Cloud eval proof")
        XCTAssertEqual(candidate.activeReceipt?.stage, .ossLocal)
        XCTAssertEqual(candidate.activeReceipt?.modelProfile, "oss-local")
        XCTAssertEqual(
            candidate.activeReceipt?.nextAction,
            "Establish local eval proof after earlier stages pass."
        )
        XCTAssertFalse(candidate.activeReceipt?.nextAction.contains("(stage.title.lowercased())") ?? true)
    }

    func testHistoricalTesslDataDoesNotChangeLocalPipelinePosture() {
        var dashboard = SkillDashboard.reviewFixture
        let before = dashboard.pipeline.postureScore
        dashboard.tessl.registryScore = 100
        dashboard.tessl.registryQualityScore = 100
        dashboard.tessl.registryImpactScore = 100
        dashboard.tessl.registrySecurityLabel = "Passed"
        dashboard.tessl.registryImprovementMultiplier = 1.28

        XCTAssertEqual(dashboard.pipeline.postureScore, before)
        XCTAssertEqual(dashboard.pipeline.postureScore, 24)
    }

    func testLiveSourceUsesLoaderWhenFixtureIsDisabled() throws {
        var liveLoadCount = 0
        let source = DashboardDataSource(
            environment: [:],
            liveLoad: {
                liveLoadCount += 1
                return .placeholder
            }
        )

        _ = try source.loadSync()

        XCTAssertEqual(liveLoadCount, 1)
    }

    func testTesslCommandPrefersAnExplicitConfiguredBinary() {
        let command = DashboardLoader.tesslCommand(
            environment: ["TESSL_BIN": "/Applications/Tessl/bin/tessl"]
        )

        XCTAssertEqual(command, "'/Applications/Tessl/bin/tessl'")
    }

    func testTesslVisibilityUsesTheRegistryDetailField() {
        let output = """
        Name            jscraik/improve-agent-native
        Latest Version  0.2.0
        Visibility      Private
        Security        Passed
        """

        XCTAssertEqual(DashboardLoader.tesslVisibility(fromPluginInfo: output), "private")
        XCTAssertNil(DashboardLoader.tesslVisibility(fromPluginInfo: "Registry lookup unavailable"))
    }

    func testSkillDiscoveryListsOnlyLocalSkillMarkdownFiles() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-skill-discovery-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("Skills/agent-ops/alpha"),
            withIntermediateDirectories: true
        )
        try FileManager.default.createDirectory(
            at: root.appendingPathComponent("Skills/frontend/beta"),
            withIntermediateDirectories: true
        )
        try "# Alpha".write(
            to: root.appendingPathComponent("Skills/agent-ops/alpha/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )
        try "# Beta".write(
            to: root.appendingPathComponent("Skills/frontend/beta/SKILL.md"),
            atomically: true,
            encoding: .utf8
        )
        try "Ignore me".write(
            to: root.appendingPathComponent("Skills/frontend/beta/README.md"),
            atomically: true,
            encoding: .utf8
        )

        XCTAssertEqual(
            DashboardLoader.discoverSkillPaths(root: root),
            ["Skills/agent-ops/alpha/SKILL.md", "Skills/frontend/beta/SKILL.md"]
        )
    }

    func testMenuBarTemplateUsesApprovedPointMetrics() {
        XCTAssertEqual(MenuBarTemplateMetrics.width, 404)
        XCTAssertEqual(MenuBarTemplateMetrics.height, 720)
        XCTAssertEqual(SkillsSDKIconLoader.menuBarImage?.size, NSSize(width: 18, height: 18))
        XCTAssertEqual(SkillsSDKIconLoader.menuBarImage?.isTemplate, true)
    }

    @MainActor
    func testCopyWritesExactReviewCommandToInjectedPasteboard() {
        let pasteboard = TestPasteboard()
        let model = CopyFeedbackModel(pasteboard: pasteboard)

        model.copy(SkillDashboard.reviewFixture.reviewInspectCommand)

        XCTAssertEqual(pasteboard.string, expectedCommand)
        XCTAssertEqual(model.copiedCommand, expectedCommand)
    }

    @MainActor
    func testCopyFailureDoesNotReportSuccess() {
        let pasteboard = TestPasteboard()
        pasteboard.acceptsWrites = false
        let model = CopyFeedbackModel(pasteboard: pasteboard)

        XCTAssertFalse(model.copy(expectedCommand))
        XCTAssertNil(model.copiedCommand)
        XCTAssertEqual(model.copyError, "Could not copy inspect command")
    }

    @MainActor
    func testSelectingSkillDuringAnActiveLoadQueuesAnotherRefresh() async {
        let gate = RefreshLoadGate()
        let source = DashboardDataSource(
            environment: [:],
            liveLoadAsync: { await gate.load() }
        )
        let model = DashboardModel(autorefresh: false, source: source)
        let previousSelection = UserDefaults.standard.object(forKey: DashboardLoader.selectedSkillDefaultsKey)
        defer {
            if let previousSelection {
                UserDefaults.standard.set(previousSelection, forKey: DashboardLoader.selectedSkillDefaultsKey)
            } else {
                UserDefaults.standard.removeObject(forKey: DashboardLoader.selectedSkillDefaultsKey)
            }
        }

        let initialRefresh = Task { @MainActor in await model.refresh() }
        await gate.waitForBlockedLoad()
        model.selectSkill(path: "Skills/testing/alternate/SKILL.md")
        await Task.yield()
        await gate.releaseBlockedLoad()
        await initialRefresh.value
        try? await Task.sleep(for: .milliseconds(50))

        let loadCount = await gate.loadCount
        XCTAssertEqual(loadCount, 2)
    }

    @MainActor
    func testSourceChangeDuringAnActiveLoadIsReloadedAfterThatLoad() async throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-source-change-\(UUID().uuidString)")
        defer { try? FileManager.default.removeItem(at: root) }
        let skillPath = "Skills/testing/alternate/SKILL.md"
        let skillURL = root.appendingPathComponent(skillPath)
        try FileManager.default.createDirectory(at: skillURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "# Alternate".write(to: skillURL, atomically: true, encoding: .utf8)

        var dashboard = SkillDashboard.reviewFixture
        dashboard.repoPath = root.path
        dashboard.fleet.selectedSkillPath = skillPath
        let gate = RefreshLoadGate(dashboard: dashboard, blockOnCall: 2)
        let source = DashboardDataSource(environment: [:], liveLoadAsync: { await gate.load() })
        let model = DashboardModel(dashboard: dashboard, autorefresh: false, source: source)

        await model.refresh()
        try FileManager.default.setAttributes(
            [.modificationDate: Date(timeIntervalSinceNow: 2)],
            ofItemAtPath: skillURL.path
        )

        let activeRefresh = Task { @MainActor in await model.refresh() }
        await gate.waitForBlockedLoad()
        await model.refreshIfSelectedSkillChanged()
        await gate.releaseBlockedLoad()
        await activeRefresh.value
        try? await Task.sleep(for: .milliseconds(50))

        let loadCount = await gate.loadCount
        XCTAssertEqual(loadCount, 3)
    }

}

private actor RefreshLoadGate {
    private let dashboard: SkillDashboard
    private let blockOnCall: Int
    private var calls = 0
    private var blockedLoadStarted = false
    private var startWaiter: CheckedContinuation<Void, Never>?
    private var releaseWaiter: CheckedContinuation<Void, Never>?

    init(dashboard: SkillDashboard = .reviewFixture, blockOnCall: Int = 1) {
        self.dashboard = dashboard
        self.blockOnCall = blockOnCall
    }

    var loadCount: Int { calls }

    func load() async -> SkillDashboard {
        calls += 1
        if calls == blockOnCall {
            blockedLoadStarted = true
            startWaiter?.resume()
            startWaiter = nil
            await withCheckedContinuation { releaseWaiter = $0 }
        }
        return dashboard
    }

    func waitForBlockedLoad() async {
        guard !blockedLoadStarted else { return }
        await withCheckedContinuation { startWaiter = $0 }
    }

    func releaseBlockedLoad() {
        releaseWaiter?.resume()
        releaseWaiter = nil
    }

}

private func registryMetadata(fixture: String, registryPath: String? = nil) throws -> TesslRegistryMetadata {
    let url = try XCTUnwrap(Bundle.module.url(forResource: fixture, withExtension: "json"))
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    return TesslRegistryMetadata(payload: JSONNode(object), registryPath: registryPath)
}

private func pixelDifference(_ lhsURL: URL, _ rhsURL: URL) throws -> Double {
    let lhs = try XCTUnwrap(NSBitmapImageRep(data: Data(contentsOf: lhsURL)))
    let rhs = try XCTUnwrap(NSBitmapImageRep(data: Data(contentsOf: rhsURL)))
    XCTAssertEqual(lhs.pixelsWide, rhs.pixelsWide)
    XCTAssertEqual(lhs.pixelsHigh, rhs.pixelsHigh)
    let lhsData = try XCTUnwrap(lhs.bitmapData)
    let rhsData = try XCTUnwrap(rhs.bitmapData)
    let count = min(lhs.bytesPerRow * lhs.pixelsHigh, rhs.bytesPerRow * rhs.pixelsHigh)
    guard count > 0 else { return 1 }
    var total = 0
    for index in 0..<count {
        total += abs(Int(lhsData[index]) - Int(rhsData[index]))
    }
    return Double(total) / Double(count * 255)
}
