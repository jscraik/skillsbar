import XCTest
@testable import SkillsBar

final class PrototypeAdoptionTests: XCTestCase {
    func testTracebackHasActionableSummaryWithoutDiscardingOrdinaryBlocker() {
        let raw = "Automatic identity command failed: Traceback (most recent call last): File example.py"
        XCTAssertTrue(GateDiagnosticPresentation.containsTraceback(raw))
        XCTAssertFalse(GateDiagnosticPresentation.summary(raw).contains("example.py"))
        XCTAssertTrue(GateDiagnosticPresentation.summary(raw).contains("diagnostic details"))
        XCTAssertEqual(GateDiagnosticPresentation.summary("Package digest required"), "Package digest required")
    }

    @MainActor
    func testSequentialNavigationStopsAtEndpointsAndPreservesEvidence() {
        let candidate = SkillDashboard.reviewFixture.pipeline
        let navigation = FocusNavigatorModel(candidate: candidate)
        navigation.select(.candidateBaseline)
        navigation.step(-1)
        XCTAssertEqual(navigation.selectedStage, .candidateBaseline)
        for stage in PipelineStage.allCases.dropFirst() {
            navigation.step(1)
            XCTAssertEqual(navigation.receipt(in: candidate)?.stage, stage)
        }
        navigation.step(1)
        XCTAssertEqual(navigation.selectedStage, .liveScoreAndRuntime)
        XCTAssertEqual(candidate, SkillDashboard.reviewFixture.pipeline)
        navigation.reconcile(candidate)
        XCTAssertEqual(navigation.selectedStage, .liveScoreAndRuntime)
    }

    func testSearchMatchesPluginVersionAndOriginWithoutLosingIdentity() {
        let path = "/Users/test/.codex/plugins/cache/provider/skillsbar-internal/0.1.2/skills/verify-skillsbar-pipeline/SKILL.md"
        XCTAssertTrue(SkillSearch.matches(path, query: " INTERNAL 0.1.2 "))
        XCTAssertTrue(SkillSearch.matches(path, query: "verify pipeline"))
        XCTAssertFalse(SkillSearch.matches(path, query: "internal 0.1.1"))
        XCTAssertTrue(SkillSearch.matches(path, query: ""))
    }

    func testSummaryCountsAllEvidenceWithoutPromotingHeldStages() {
        let receipts = SkillDashboard.reviewFixture.pipeline.orderedReceipts
        XCTAssertEqual(receipts.count, 9)
        XCTAssertTrue(receipts.statusSummary.contains("awaiting proof"))
        XCTAssertFalse(receipts.statusSummary.contains("9 passed"))
    }
}
