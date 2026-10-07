import AppKit
import XCTest
@testable import SkillsBar

final class FocusNavigatorTests: XCTestCase {
    @MainActor
    private final class Clipboard: PasteboardWriting {
        var value: String?
        var succeeds = true
        func clearContents() -> Int { value = nil; return 1 }
        func setString(_ string: String, forType _: NSPasteboard.PasteboardType) -> Bool {
            value = string
            return succeeds
        }
    }

    @MainActor
    func testRepeatedCopyKeepsLatestConfirmation() async throws {
        let feedback = CopyFeedbackModel(pasteboard: Clipboard())
        XCTAssertTrue(feedback.copy("command"))
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertTrue(feedback.copy("command"))
        try await Task.sleep(for: .milliseconds(600))
        XCTAssertEqual(feedback.copiedCommand, "command")
        try await Task.sleep(for: .milliseconds(800))
        XCTAssertNil(feedback.copiedCommand)
    }

    @MainActor
    func testUtilityCopyFailureDoesNotBelongToStageCommand() {
        let clipboard = Clipboard()
        clipboard.succeeds = false
        let feedback = CopyFeedbackModel(pasteboard: clipboard)
        XCTAssertFalse(feedback.copy("summary text", label: "Summary"))
        XCTAssertEqual(feedback.error(for: "summary text"), "Could not copy summary")
        XCTAssertNil(feedback.error(for: "stage command"))
        clipboard.succeeds = true
        XCTAssertTrue(feedback.copy("stage command"))
        XCTAssertNil(feedback.error(for: "summary text"))
    }

    @MainActor
    func testInspectingEveryStagePreservesEvidenceAndUsesItsCommand() throws {
        let candidate = SkillDashboard.reviewFixture.pipeline
        let navigator = FocusNavigatorModel(candidate: candidate)
        let pasteboard = Clipboard()
        let feedback = CopyFeedbackModel(pasteboard: pasteboard)
        let activeStage = candidate.activeReceipt?.stage
        XCTAssertEqual(navigator.selectedStage, candidate.activeReceipt?.stage)
        for receipt in candidate.orderedReceipts {
            navigator.select(receipt.stage)
            XCTAssertEqual(navigator.selectedStage, receipt.stage)
            navigator.reconcile(candidate)
            XCTAssertEqual(navigator.selectedStage, receipt.stage)
            XCTAssertEqual(candidate.activeReceipt?.stage, activeStage)
            let selected = try XCTUnwrap(navigator.receipt(in: candidate))
            XCTAssertEqual(selected.stage, receipt.stage)
            if !selected.command.isEmpty {
                XCTAssertTrue(feedback.copy(selected.command))
                XCTAssertEqual(pasteboard.value, receipt.command)
            }
        }
    }

    @MainActor
    func testNewCandidateResetsInspection() {
        let original = SkillDashboard.reviewFixture.pipeline
        let navigator = FocusNavigatorModel(candidate: original)
        navigator.select(.liveScoreAndRuntime)
        let updated = PipelineCandidate(
            fingerprint: "different-candidate",
            governedInputPaths: original.governedInputPaths,
            observedAt: original.observedAt,
            stageReceipts: original.stageReceipts
        )
        navigator.reconcile(updated)
        XCTAssertEqual(navigator.selectedStage, updated.activeReceipt?.stage)
    }

    func testPipelineStagesExposeStableCompactTitles() {
        XCTAssertEqual(
            PipelineStage.allCases.map(\.compactTitle),
            ["Identity", "Validation", "Security", "Eval prep", "Local eval", "Cloud eval", "Staging", "Publication", "Runtime"]
        )
    }

    @MainActor
    func testKeyboardMovesBetweenGridNeighborsAndStopsAtEdges() {
        let navigator = FocusNavigatorModel(candidate: SkillDashboard.reviewFixture.pipeline)
        XCTAssertEqual(navigator.moveFocus(from: .securityReview, direction: .down), .ossCloud)
        XCTAssertEqual(navigator.moveFocus(from: .ossCloud, direction: .left), .ossLocal)
        XCTAssertEqual(navigator.moveFocus(from: .ossLocal, direction: .up), .mechanicalValidation)
        XCTAssertNil(navigator.moveFocus(from: .securityReview, direction: .right))
        XCTAssertNil(navigator.moveFocus(from: .candidateBaseline, direction: .left))
        XCTAssertNil(navigator.moveFocus(from: .candidateBaseline, direction: .up))
        XCTAssertNil(navigator.moveFocus(from: .liveScoreAndRuntime, direction: .down))
        XCTAssertEqual(navigator.selectedStage, .mechanicalValidation)
    }
}
