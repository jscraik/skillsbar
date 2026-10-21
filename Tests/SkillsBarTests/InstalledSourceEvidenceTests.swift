import CryptoKit
import Foundation
import XCTest
import SkillsBarCore
@testable import SkillsBar

final class InstalledSourceEvidenceTests: XCTestCase {
    func testStandaloneLookupUnderBothHomeSkillDirectories() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        let directory = InstalledSourceEvidence.directory(home: fixture.root)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        for parent in [".agents/skills", ".codex/skills"] {
            let path = fixture.root.appendingPathComponent(parent + "/simplify")
            try FileManager.default.createDirectory(at: path, withIntermediateDirectories: true)
            let installed = path.resolvingSymlinksInPath()
            var link = fixture.link
            link = .init(schema_version: link.schema_version, installed_root: installed.path,
                         source_root: link.source_root, source_revision: link.source_revision,
                         sdk_executable: link.sdk_executable, validation_path: link.validation_path,
                         validation_sha256: link.validation_sha256, package_kind: "skill")
            let key = SHA256.hash(data: Data(installed.path.utf8)).map { String(format: "%02x", $0) }.joined()
            try JSONEncoder().encode(link).write(to: directory.appendingPathComponent(key + ".json"))
            let selected = installed.appendingPathComponent("SKILL.md")
            XCTAssertEqual(InstalledSourceEvidence.link(skill: selected, home: fixture.root)?.installed_root, installed.path)
            XCTAssertTrue(InstalledSourceEvidence.watchDirectories(skill: selected, home: fixture.root).contains(installed))
            XCTAssertNil(InstalledSourceEvidence.link(skill: installed.appendingPathComponent("other/SKILL.md"), home: fixture.root))
        }
    }

    func testStandaloneComparisonRetainsDriftAndNeverClearsManagedGates() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        var link = fixture.link
        link.package_kind = "skill"
        let skill = URL(fileURLWithPath: link.installed_root).appendingPathComponent("SKILL.md")
        for status in ["drift", "pass", "blocked"] {
            let payload: [String: Any] = ["schema_version": "runtime-copy-comparison/v1", "status": status,
                                         "different_paths": status == "drift" ? ["agents/openai.yaml"] : []]
            let data = try JSONSerialization.data(withJSONObject: payload)
            try data.write(to: URL(fileURLWithPath: link.validation_path))
            link = .init(schema_version: link.schema_version, installed_root: link.installed_root,
                         source_root: link.source_root, source_revision: link.source_revision,
                         sdk_executable: link.sdk_executable, validation_path: link.validation_path,
                         validation_sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined(),
                         package_kind: "skill")
            let observation = InstalledSourceEvidence.observe(link: link, skill: skill) { command, _ in
                XCTAssertTrue(command.contains("compare-copy"))
                return CommandResult(exitCode: status == "pass" ? 0 : 2,
                                     stdout: String(decoding: data, as: UTF8.self), stderr: "")
            }
            XCTAssertNotEqual(observation.identityStatus, .passed)
            XCTAssertNotEqual(observation.validationStatus, .passed)
            XCTAssertEqual(observation.status, status == "drift" ? .stale : status == "pass" ? .reviewRequired : .blocked)
            let changed = InstalledSourceEvidence.observe(link: link, skill: skill) { _, _ in
                CommandResult(exitCode: 0, stdout: "{}", stderr: "")
            }
            XCTAssertEqual(changed.status, .stale)
        }
    }

    func testValidationNeedsPassingBoundPresentationAndEveryChildContentReview() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        let observation = InstalledSourceEvidence.observe(link: fixture.link, skill: fixture.skill) { _, _ in fixture.result() }
        let capture = try XCTUnwrap(observation.capture)
        let candidate = try JSONSerialization.jsonObject(with: JSONEncoder().encode(capture.candidate))
        let child = try XCTUnwrap(capture.skills.first?.validation?.candidate)
        let childCandidate = try JSONSerialization.jsonObject(with: JSONEncoder().encode(child))
        func write(_ name: String, _ value: [String: Any]) throws -> InstalledSourceEvidence.SourceReview.Evidence {
            let path = fixture.root.appendingPathComponent(name)
            let data = try JSONSerialization.data(withJSONObject: value)
            try data.write(to: path)
            return .init(path: path.path, sha256: SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined())
        }
        for variant in ["valid", "failed-presentation", "foreign-child", "missing-child"] {
            let presentation = try write("presentation.json", [
                "schema_version": "plugin-presentation-check/v1", "status": variant == "failed-presentation" ? "blocked" : "pass",
                "candidate": candidate, "mode_manifest_sha256": capture.mode_manifest_sha256,
                "mutation_performed": false, "execution_authorized": false, "release_ready": false])
            let content = try write("content.json", [
                "schema_version": "content-review/v1", "status": "pass",
                "candidate": variant == "foreign-child" ? candidate : childCandidate,
                "mutation_performed": false, "promotion_authorized": false])
            let review = InstalledSourceEvidence.SourceReview(
                schema_version: "skillsbar-source-review/v1", candidate: capture.candidate,
                mode_manifest_sha256: capture.mode_manifest_sha256, owner: "Owner", maintainer: "Owner",
                rights_basis: "Private authored", source_reference: "Recorded source", revision_boundary: "Dirty baseline",
                reviewer: "Reviewer", evidence: [presentation, content], validation_findings: [],
                validation_proof: .init(rationale: "Root docs reviewed", presentation: presentation,
                    content_reviews: variant == "missing-child" ? [] : [content]))
            let path = fixture.root.appendingPathComponent("review.json")
            let data = try JSONEncoder().encode(review)
            try data.write(to: path)
            var link = fixture.link
            link.source_review_path = path.path
            link.source_review_sha256 = SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
            let checked = InstalledSourceEvidence.observe(link: link, skill: fixture.skill) { command, _ in
                if command.contains("verify_validation_receipts.py") {
                    return CommandResult(exitCode: 0, stdout: "pass\n", stderr: "")
                }
                return fixture.result()
            }
            XCTAssertEqual(checked.validationStatus, variant == "valid" ? .passed : .stale, variant)
            if variant == "valid" {
                let rejected = InstalledSourceEvidence.observe(link: link, skill: fixture.skill) { command, _ in
                    command.contains("verify_validation_receipts.py")
                        ? CommandResult(exitCode: 2, stdout: "", stderr: "blocked: ValidationError") : fixture.result()
                }
                XCTAssertEqual(rejected.validationStatus, .stale)
            }
        }
    }

    func testCandidateBoundSourceReviewClearsOnlyIdentityAndRetainsValidationFinding() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        let source = InstalledSourceEvidence.observe(link: fixture.link, skill: fixture.skill) { _, _ in fixture.result() }
        let proof = fixture.root.appendingPathComponent("owner-evidence.json")
        try Data("Observed private author-owned release".utf8).write(to: proof)
        func digest(_ url: URL) throws -> String {
            SHA256.hash(data: try Data(contentsOf: url)).map { String(format: "%02x", $0) }.joined()
        }
        let review = InstalledSourceEvidence.SourceReview(
            schema_version: "skillsbar-source-review/v1", candidate: try XCTUnwrap(source.capture).candidate,
            mode_manifest_sha256: String(repeating: "b", count: 64), owner: "Owner", maintainer: "Owner",
            rights_basis: "Authored for private use", source_reference: "Local source and account readback",
            revision_boundary: "Dirty baseline; not a committed-source claim", reviewer: "Source reviewer",
            evidence: [.init(path: proof.path, sha256: try digest(proof))],
            validation_findings: ["Root README release claim is stale"])
        let path = fixture.root.appendingPathComponent("review.json")
        try JSONEncoder().encode(review).write(to: path)
        var link = fixture.link
        link.source_review_path = path.path
        link.source_review_sha256 = try digest(path)
        let current = InstalledSourceEvidence.observe(link: link, skill: fixture.skill) { _, _ in fixture.result() }
        XCTAssertEqual(current.identityStatus, .passed)
        XCTAssertEqual(current.validationStatus, .blocked)
        try Data("changed observation".utf8).write(to: proof)
        let changed = InstalledSourceEvidence.observe(link: link, skill: fixture.skill) { _, _ in fixture.result() }
        XCTAssertEqual(changed.identityStatus, .stale)
        XCTAssertEqual(changed.validationStatus, .stale)
        link.source_review_sha256 = nil
        let incomplete = InstalledSourceEvidence.observe(link: link, skill: fixture.skill) { _, _ in fixture.result() }
        XCTAssertEqual(incomplete.identityStatus, .stale)
    }

    func testMatchingSDKVerifiedCapturesAdmitOnlyStructuralObservation() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        var calls = 0
        let observation = InstalledSourceEvidence.observe(link: fixture.link, skill: fixture.skill) { command, _ in
            XCTAssertTrue(command.contains("--verify-evidence"))
            calls += 1
            return fixture.result()
        }
        XCTAssertEqual(calls, 2)
        XCTAssertEqual(observation.status, .passed)
        XCTAssertEqual(observation.lifecycleStatus, .reviewRequired)
        XCTAssertTrue(observation.detail.contains("Security and eval proof remain separate"))
    }

    func testFailedMalformedMismatchedAndOverclaimingSDKResultsNeverPass() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        let invalid: [CommandResult] = [
            fixture.result(exit: 2),
            CommandResult(exitCode: 0, stdout: "not JSON", stderr: ""),
            fixture.result(overrides: ["status": "blocked"]),
            fixture.result(overrides: ["release_ready": true]),
            fixture.result(overrides: ["mutation_performed": true]),
            fixture.result(overrides: ["mode_manifest_sha256": String(repeating: "c", count: 64)]),
            fixture.result(overrides: ["skills": [["path": "skills/other"]]])
        ]
        for response in invalid {
            var calls = 0
            let observation = InstalledSourceEvidence.observe(link: fixture.link, skill: fixture.skill) { _, _ in
                calls += 1
                return calls == 1 ? fixture.result() : response
            }
            XCTAssertEqual(observation.status, .stale)
            XCTAssertEqual(observation.lifecycleStatus, .stale)
            XCTAssertNil(observation.capture)
        }
    }

    func testChangedCaptureCannotExecuteOrClearAnything() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        try Data("changed".utf8).write(to: URL(fileURLWithPath: fixture.link.validation_path))
        let observation = InstalledSourceEvidence.observe(link: fixture.link, skill: fixture.skill) { _, _ in
            XCTFail("Changed stored capture must fail before SDK execution")
            return fixture.result()
        }
        XCTAssertEqual(observation.status, .stale)
    }

    func testLookupIsBoundToExactInstalledRootAndSourceWatchIncludesBothPackages() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        let directory = InstalledSourceEvidence.directory(home: fixture.root)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let key = SHA256.hash(data: Data(fixture.link.installed_root.utf8)).map { String(format: "%02x", $0) }.joined()
        try JSONEncoder().encode(fixture.link).write(to: directory.appendingPathComponent(key + ".json"))
        XCTAssertNotNil(InstalledSourceEvidence.link(skill: fixture.skill, home: fixture.root))
        XCTAssertNil(InstalledSourceEvidence.link(skill: fixture.root.appendingPathComponent("other/skills/check/SKILL.md"), home: fixture.root))
        let watched = InstalledSourceEvidence.watchDirectories(skill: fixture.skill, home: fixture.root).map(\.path)
        XCTAssertTrue(watched.contains(fixture.link.source_root))
        XCTAssertTrue(watched.contains(fixture.link.installed_root))
    }

    func testWatcherNoticesHiddenInputsPermissionsAndRemoval() throws {
        let fixture = try Fixture()
        defer { fixture.clean() }
        let overlay = fixture.root.appendingPathComponent(".codex-plugin/plugin.json")
        try FileManager.default.createDirectory(at: overlay.deletingLastPathComponent(), withIntermediateDirectories: true)
        try Data("one".utf8).write(to: overlay)
        let initial = DashboardModel.sourceChangeSignature(in: fixture.root)
        try Data("two".utf8).write(to: overlay)
        let changed = DashboardModel.sourceChangeSignature(in: fixture.root)
        XCTAssertNotEqual(initial, changed)
        try FileManager.default.setAttributes([.posixPermissions: 0o600], ofItemAtPath: overlay.path)
        let changedMode = DashboardModel.sourceChangeSignature(in: fixture.root)
        XCTAssertNotEqual(changed, changedMode)
        try FileManager.default.removeItem(at: overlay)
        XCTAssertNotEqual(changedMode, DashboardModel.sourceChangeSignature(in: fixture.root))
    }

    private struct Fixture {
        let root: URL
        let skill: URL
        let link: InstalledSourceEvidence.Link

        init() throws {
            root = FileManager.default.temporaryDirectory.appendingPathComponent("skillsbar-sdk-link-\(UUID().uuidString)").resolvingSymlinksInPath()
            let installed = root.appendingPathComponent("installed")
            skill = installed.appendingPathComponent("skills/check/SKILL.md")
            try FileManager.default.createDirectory(at: skill.deletingLastPathComponent(), withIntermediateDirectories: true)
            try Data("skill".utf8).write(to: skill)
            let capture = Data("SDK capture fixture".utf8)
            let receipt = root.appendingPathComponent("capture.json")
            try capture.write(to: receipt)
            link = InstalledSourceEvidence.Link(
                schema_version: "skillsbar-source-link/v1", installed_root: installed.path,
                source_root: root.appendingPathComponent("source").path,
                source_revision: String(repeating: "a", count: 40), sdk_executable: "/sdk/skills-sdk",
                validation_path: receipt.path,
                validation_sha256: SHA256.hash(data: capture).map { String(format: "%02x", $0) }.joined()
            )
        }

        func result(exit: Int32 = 0, overrides: [String: Any] = [:]) -> CommandResult {
            var payload: [String: Any] = [
                "schema_version": "plugin-package-validation/v1", "status": "pass",
                "candidate": ["schema_version": "package-candidate/v1", "package_id": "plugin-test", "source_revision": link.source_revision, "content_sha256": String(repeating: "a", count: 64)],
                "manifest": ["name": "test", "version": "0.1.1"],
                "mode_manifest_sha256": String(repeating: "b", count: 64),
                "mutation_performed": false, "execution_authorized": false, "release_ready": false,
                "skills": [["path": "skills/check", "validation": ["candidate": [
                    "schema_version": "package-candidate/v1", "package_id": "check",
                    "source_revision": link.source_revision, "content_sha256": String(repeating: "c", count: 64)]]]]
            ]
            payload.merge(overrides) { _, new in new }
            let data = try! JSONSerialization.data(withJSONObject: payload)
            return CommandResult(exitCode: exit, stdout: String(decoding: data, as: UTF8.self), stderr: "")
        }

        func clean() { try? FileManager.default.removeItem(at: root) }
    }
}
