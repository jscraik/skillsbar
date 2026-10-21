import XCTest
@testable import SkillsBar

final class PresentationPolishTests: XCTestCase {
    func testMissingVersionDoesNotRenderAsASoftwareVersion() {
        for raw in ["unknown", "", "  vunknown  "] {
            XCTAssertEqual(SkillVersionText(raw).label, "—")
            XCTAssertEqual(SkillVersionText(raw).accessibilityLabel, "Skill version not declared")
        }
        XCTAssertEqual(SkillVersionText("v0.1.1").label, "v0.1.1")
        XCTAssertEqual(SkillVersionText(" 0.2.0 ").label, "v0.2.0")
    }

    func testCheckedTimeAdvancesWithoutRequiringEvidenceRefresh() {
        let observed = Date(timeIntervalSince1970: 1_000)
        XCTAssertEqual(EvidenceAgeText.label(observedAt: observed, now: observed.addingTimeInterval(59)), "Checked 59s ago")
        XCTAssertEqual(EvidenceAgeText.label(observedAt: observed, now: observed.addingTimeInterval(60)), "Checked 1m ago")
        XCTAssertEqual(EvidenceAgeText.label(observedAt: observed, now: observed.addingTimeInterval(3_600)), "Checked 1h ago")
        XCTAssertEqual(EvidenceAgeText.label(observedAt: observed, now: observed.addingTimeInterval(-10)), "Checked 1s ago")
        XCTAssertEqual(EvidenceAgeText.label(observedAt: Date(timeIntervalSince1970: 0), now: observed), "Checked time unavailable")
    }
}
