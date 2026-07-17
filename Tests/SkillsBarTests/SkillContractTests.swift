import Foundation
import XCTest

final class SkillContractTests: XCTestCase {
    func testAnimationPlanCommandsShareTheResolvedDirectory() throws {
        let repoRoot = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
        let skillURL = repoRoot.appendingPathComponent(".codex/skills/improve-animations/SKILL.md")
        let skill = try String(contentsOf: skillURL, encoding: .utf8)

        XCTAssertTrue(skill.contains("otherwise use `animation-plans/`"))
        XCTAssertTrue(skill.contains("`reconcile` | Resolve the plan directory with the Phase 4 rule"))
        XCTAssertFalse(skill.contains("`reconcile` | Re-check `plans/`"))
    }
}
