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
        XCTAssertEqual(dashboard.tessl.registryVisibilityDisplay, "Private")
        XCTAssertEqual(dashboard.reviewInspectCommand, expectedCommand)
    }

    func testReviewPresentationExplainsLocalAndRegistryTruth() {
        let presentation = ReviewPresentation(dashboard: .reviewFixture)

        XCTAssertTrue(presentation.isReviewState)
        XCTAssertEqual(presentation.packageIdentity, "jscraik/improve-agent-native")
        XCTAssertEqual(presentation.bridgeTitle, "Registry clean. Local source has findings.")
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
        XCTAssertEqual(presentation.bridgeTitle, "Local and registry evidence are available.")
        XCTAssertEqual(presentation.bridgeSystemName, "checkmark.seal")
        XCTAssertFalse(presentation.showsBridgeWarningBadge)
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

    func testTesslMetadataPrefersCanonicalResultOverUnrelatedNestedKeys() throws {
        let metadata = try registryMetadata(fixture: "tessl-ambiguous-skill")

        XCTAssertEqual(metadata.version, "2.0.0")
        XCTAssertEqual(metadata.securityLabel, "Advisory")
        XCTAssertEqual(metadata.evalCount, 42)
        XCTAssertEqual(metadata.visibility, "public")
    }

    @MainActor
    func testReviewFixtureRenderMatchesRetainedBaseline() throws {
        let outputURL = FileManager.default.temporaryDirectory
            .appendingPathComponent("skillsbar-review-\(UUID().uuidString).png")
        defer { try? FileManager.default.removeItem(at: outputURL) }

        try SnapshotRenderer.render(dashboard: .reviewFixture, to: outputURL)

        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let baselineURL = repoRoot.appendingPathComponent(".harness/evidence/2026-07-09-skills-sdk-review-popover-implementation.png")
        let difference = try pixelDifference(baselineURL, outputURL)
        XCTAssertLessThanOrEqual(difference, 0.0005, "Rendered review fixture drifted from the retained baseline")
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

}

private func registryMetadata(fixture: String) throws -> TesslRegistryMetadata {
    let url = try XCTUnwrap(Bundle.module.url(forResource: fixture, withExtension: "json"))
    let object = try JSONSerialization.jsonObject(with: Data(contentsOf: url))
    return TesslRegistryMetadata(payload: JSONNode(object))
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
