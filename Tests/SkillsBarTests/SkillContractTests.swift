import Foundation
import XCTest

final class SkillContractTests: XCTestCase {
    func testSignedAppResourceLookupPrecedesTheSwiftPMFallback() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let dashboardView = try String(
            contentsOf: repoRoot.appendingPathComponent("Sources/SkillsBar/Views/DashboardView.swift"),
            encoding: .utf8
        )
        let mainLookup = try XCTUnwrap(dashboardView.range(of: "Bundle.main.url(forResource:"))
        let moduleLookup = try XCTUnwrap(dashboardView.range(of: "Bundle.module.url(forResource:"))

        XCTAssertLessThan(mainLookup.lowerBound, moduleLookup.lowerBound)
    }

    deinit {}

    func testAnimationPlanCommandsShareTheResolvedDirectory() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let skillURL = repoRoot.appendingPathComponent(".codex/skills/improve-animations/SKILL.md")
        let templateURL = repoRoot.appendingPathComponent(".codex/skills/improve-animations/PLAN-TEMPLATE.md")
        let skill = try String(contentsOf: skillURL, encoding: .utf8)
        let template = try String(contentsOf: templateURL, encoding: .utf8)

        XCTAssertTrue(skill.contains("`.workflow-owner`"))
        XCTAssertTrue(skill.contains("`workflow: improve-animations`"))
        XCTAssertTrue(skill.contains("any other non-blank `workflow:` value"))
        XCTAssertTrue(skill.contains("use `animation-plans/` instead"))
        XCTAssertTrue(skill.contains("resolved directory for numbering, plan files, and its README"))
        XCTAssertTrue(skill.contains("`reconcile` | Resolve the plan directory with the Phase 4 rule"))
        XCTAssertFalse(skill.contains("`reconcile` | Re-check `plans/`"))
        XCTAssertTrue(template.contains("`<recon-verified-token-file-or-no-shared-token-file>`"))
        XCTAssertTrue(template.contains("`<resolved-plan-directory>/README.md`"))
        XCTAssertTrue(template.contains("must be reused for numbering, plan files, and README updates"))
    }
}
