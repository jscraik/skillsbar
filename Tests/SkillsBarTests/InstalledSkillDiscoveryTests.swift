import Foundation
import SkillsBarCore
import XCTest
@testable import SkillsBar

final class InstalledSkillDiscoveryTests: XCTestCase {
    func testInstalledRegistryEvidenceLoadsThroughSyncAndAsyncWithoutClearingLifecycle() async throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let relative = ".agents/skills/simplify/SKILL.md"
        try writeSkill(relative, home: home)
        let selected = home.appendingPathComponent(relative)
        try "---\nname: simplify\ndescription: Simplify code.\n---\n".write(to: selected, atomically: true, encoding: .utf8)
        var signal = SkillDashboard.placeholder.tessl
        signal.ok = true
        signal.cliAvailable = true
        signal.authenticated = true
        signal.registryScore = 97
        signal.registryVersion = "0.2.18"
        signal.registryQualityScore = 94
        signal.registryImpactScore = 98
        signal.registryEvalCount = 8
        signal.registryImprovementMultiplier = 0.98
        signal.dataOrigin = .liveCLI
        let response = signal
        let loader = DashboardLoader(environment: ["AGENT_SKILLS_ROOT": home.appendingPathComponent("missing").path,
            "AGENT_SKILL_PATH": selected.path], homeDirectory: home, storedSkillPath: nil,
            installedRegistryLookup: { _, path in
                XCTAssertEqual(path, "jscraik/simplify")
                return response
            })
        let sync = try loader.loadSync()
        let asyncResult = try await loader.load()
        for dashboard in [sync, asyncResult] {
            XCTAssertEqual(dashboard.registryPath, "jscraik/simplify")
            XCTAssertEqual(dashboard.tessl.registryScore, 97)
            XCTAssertEqual(dashboard.tessl.registryQualityScore, 94)
            XCTAssertEqual(dashboard.tessl.registryImpactScore, 98)
            XCTAssertEqual(dashboard.tessl.registryEvalCount, 8)
            XCTAssertEqual(dashboard.tessl.dataOrigin, .liveCLI)
            XCTAssertNotNil(dashboard.registryURL)
            XCTAssertNil(dashboard.score)
            XCTAssertTrue(dashboard.pipeline.orderedReceipts.allSatisfy { $0.evidenceStatus == .unproven })
        }
    }

    func testRegistrySearchDoesNotBorrowAnUnrelatedResultWhenExactPackageIsAbsent() {
        let payload = JSONNode(["results": [["fullName": "another/simplify", "latestVersion": "9.0.0",
            "scores": ["aggregate": 1, "quality": 1, "impact": 1]]]])
        let metadata = TesslRegistryMetadata(payload: payload, registryPath: "jscraik/simplify")
        XCTAssertNil(metadata.score)
        XCTAssertNil(metadata.version)
        XCTAssertNil(metadata.qualityScore)
        XCTAssertNil(metadata.impactScore)
    }

    func testRegistryIdentityFilteringCoversWrappedAndMixedResponses() {
        let wrong: [String: Any] = ["fullName": "another/simplify", "latestVersion": "9.0.0", "scores": ["aggregate": 1]]
        let right: [String: Any] = ["fullName": "jscraik/simplify", "latestVersion": "0.2.18", "scores": ["aggregate": 0.968]]
        for payload in [["result": wrong], ["data": ["result": wrong]], ["data": wrong], wrong] {
            let metadata = TesslRegistryMetadata(payload: JSONNode(payload), registryPath: "jscraik/simplify")
            XCTAssertNil(metadata.score)
            XCTAssertNil(metadata.version)
        }
        let mixed: [String: Any] = ["result": wrong, "data": ["result": wrong], "results": [right], "score": 1]
        let metadata = TesslRegistryMetadata(payload: JSONNode(mixed), registryPath: "jscraik/simplify")
        XCTAssertEqual(metadata.score, 97)
        XCTAssertEqual(metadata.version, "0.2.18")
    }

    func testHomeRootsIncludeStandaloneSystemAndPluginSkillsWithoutScanningPluginResources() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let expected = [
            ".codex/skills/alpha/SKILL.md",
            ".codex/skills/.system/system-tool/SKILL.md",
            ".agents/skills/beta/SKILL.md",
            ".codex/plugins/cache/provider/internal/0.1.1/skills/verify/SKILL.md"
        ]
        for path in expected { try writeSkill(path, home: home) }
        try writeSkill(".codex/plugins/cache/provider/internal/0.1.1/resources/ignored/SKILL.md", home: home)
        XCTAssertEqual(Set(InstalledSkillDiscovery.paths(home: home)), Set(expected.map { home.appendingPathComponent($0).path }))
    }

    func testSymlinkedPackagesAreDiscoverableAndAliasesAndCyclesAreDeduplicated() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeSkill(".codex/skills/alpha/SKILL.md", home: home)
        let agents = home.appendingPathComponent(".agents/skills")
        try FileManager.default.createDirectory(at: agents, withIntermediateDirectories: true)
        try FileManager.default.createSymbolicLink(at: agents.appendingPathComponent("alias"), withDestinationURL: home.appendingPathComponent(".codex/skills/alpha"))
        try FileManager.default.createSymbolicLink(at: home.appendingPathComponent(".codex/skills/alpha/loop"), withDestinationURL: home.appendingPathComponent(".codex/skills"))
        XCTAssertEqual(InstalledSkillDiscovery.paths(home: home), [home.appendingPathComponent(".codex/skills/alpha/SKILL.md").path])
    }

    func testInstalledSelectionLoadsWithoutSDKCheckoutAndCannotBorrowPassedEvidence() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }
        let relative = ".codex/plugins/cache/provider/internal/0.1.1/skills/verify/SKILL.md"
        try writeSkill(relative, home: home)
        let selected = home.appendingPathComponent(relative).path
        let loader = DashboardLoader(environment: ["AGENT_SKILLS_ROOT": home.appendingPathComponent("missing-sdk").path, "AGENT_SKILL_PATH": selected], homeDirectory: home, storedSkillPath: nil, installedRegistryLookup: { _, _ in SkillDashboard.placeholder.tessl })
        let dashboard = try loader.loadSync()
        XCTAssertEqual(dashboard.displayName, "installed-example")
        XCTAssertEqual(dashboard.fleet.selectedSkillPath, selected)
        XCTAssertEqual(dashboard.fleet.skillCount, 1)
        XCTAssertEqual(dashboard.pipeline.orderedReceipts.count, 9)
        XCTAssertTrue(dashboard.pipeline.orderedReceipts.allSatisfy { $0.evidenceStatus == .unproven && $0.stageScore == nil && $0.receiptPath == nil })
        XCTAssertNil(dashboard.score)
        XCTAssertNil(dashboard.registryURL)
        XCTAssertEqual(dashboard.tessl.dataOrigin, .unavailable)
        XCTAssertFalse(dashboard.localEvidenceCommand.contains("./bin/ask"))
        XCTAssertTrue(dashboard.selectedSkillInspectCommand.hasPrefix("sed "))
    }

    func testInvalidPersistedSelectionFallsBackToAnExistingInstalledSkill() throws {
        let home = temporaryHome()
        defer { try? FileManager.default.removeItem(at: home) }
        try writeSkill(".agents/skills/actual/SKILL.md", home: home)
        let dashboard = try DashboardLoader(environment: ["AGENT_SKILLS_ROOT": home.appendingPathComponent("missing").path], homeDirectory: home, storedSkillPath: "/outside/arbitrary/SKILL.md", installedRegistryLookup: { _, _ in SkillDashboard.placeholder.tessl }).loadSync()
        XCTAssertEqual(dashboard.fleet.selectedSkillPath, home.appendingPathComponent(".agents/skills/actual/SKILL.md").path)
    }

    func testInstalledPathsStayAbsoluteAndChooserDistinguishesOrigins() {
        let root = URL(fileURLWithPath: "/sdk")
        let path = "/home/example/.codex/plugins/cache/provider/internal/0.1.1/skills/verify/SKILL.md"
        XCTAssertEqual(InstalledSkillDiscovery.skillURL(path: path, root: root).path, path)
        XCTAssertEqual(InstalledSkillDiscovery.skillURL(path: "Skills/local/SKILL.md", root: root).path, "/sdk/Skills/local/SKILL.md")
        XCTAssertEqual(InstalledSkillDiscovery.displayName(path: path), "verify · internal 0.1.1")
        XCTAssertEqual(InstalledSkillDiscovery.displayName(path: "/home/example/.agents/skills/tool/SKILL.md"), "tool · Agents")
    }

    private func temporaryHome() -> URL {
        FileManager.default.temporaryDirectory.appendingPathComponent("skillsbar-home-discovery-\(UUID().uuidString)")
    }

    private func writeSkill(_ path: String, home: URL) throws {
        let url = home.appendingPathComponent(path)
        try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
        try "---\nname: installed-example\ndescription: Installed test skill.\n---\n".write(to: url, atomically: true, encoding: .utf8)
    }
}
