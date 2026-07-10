import Foundation
import SkillsBarCore

struct DashboardLoader {
    static let defaultRepoRoot = URL(fileURLWithPath: "/Users/jamiecraik/dev/agent-skills")
    static let defaultSkillPath = "Skills/agent-ops/improve-agent-native/SKILL.md"
    static let selectedSkillDefaultsKey = "selectedSkillPath"
    static let packageCommand = "./bin/ask skills package verify Skills/agent-ops/improve-agent-native --json --robot"
    static let impactCommand = "./bin/ask sdk eval scenario-quality Skills/agent-ops/improve-agent-native --preview --json --robot"
    static let securityCommand = "./bin/ask sdk security risk-modes Skills/agent-ops/improve-agent-native --preview --json --robot"
    static let allSkillsInventoryCommand = "find Skills -name SKILL.md -print | sort"
    static func packageCommand(for skillPath: String) -> String {
        "./bin/ask skills package verify \(shellQuoted(skillPath)) --json --robot"
    }

    static func impactCommand(for skillPath: String) -> String {
        "./bin/ask sdk eval scenario-quality \(shellQuoted(skillPath)) --preview --json --robot"
    }

    static func securityCommand(for skillPath: String) -> String {
        "./bin/ask sdk security risk-modes \(shellQuoted(skillPath)) --preview --json --robot"
    }

    static func localEvidenceCommand(root: URL, skillPath: String = defaultSkillPath) -> String {
        copyCommand(root: root, command: labelledCommand([
            ("quality package verify", packageCommand(for: skillPath)),
            ("impact scenario-quality", impactCommand(for: skillPath)),
            ("security risk-modes", securityCommand(for: skillPath))
        ]))
    }

    static func copyCommand(root: URL, command: String) -> String {
        "cd \(shellQuoted(root.path)) && \(command)"
    }

    static func tesslCommand(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        fileManager: FileManager = .default
    ) -> String {
        if let configured = environment["TESSL_BIN"], !configured.isEmpty {
            return shellQuoted(configured)
        }
        let localBinary = fileManager.homeDirectoryForCurrentUser
            .appendingPathComponent(".local/bin/tessl")
        if fileManager.isExecutableFile(atPath: localBinary.path) {
            return shellQuoted(localBinary.path)
        }
        return "tessl"
    }

    static func tesslVisibility(fromPluginInfo output: String) -> String? {
        guard let line = output.split(separator: "\n").first(where: {
            $0.trimmingCharacters(in: .whitespaces).lowercased().hasPrefix("visibility")
        }) else { return nil }
        let value = line.dropFirst("Visibility".count).trimmingCharacters(in: .whitespaces).lowercased()
        return value == "private" || value == "public" ? value : nil
    }

    static var selectionIsPinnedByEnvironment: Bool {
        let environment = ProcessInfo.processInfo.environment
        return !(environment["AGENT_SKILL_PATH"] ?? environment["SELECTED_SKILL_PATH"] ?? "").isEmpty
    }

    static func discoverSkillPaths(root: URL) -> [String] {
        guard let enumerator = FileManager.default.enumerator(
            at: root.appendingPathComponent("Skills"),
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else { return [] }
        return enumerator.compactMap { $0 as? URL }
            .filter { $0.lastPathComponent == "SKILL.md" }
            .compactMap { url in
                let components = url.pathComponents
                guard let skillsIndex = components.lastIndex(of: "Skills") else { return nil }
                return components[skillsIndex...].joined(separator: "/")
            }
            .sorted()
    }

    private static func shellQuoted(_ value: String) -> String {
        "'\(value.replacingOccurrences(of: "'", with: "'\\''"))'"
    }

    private static func labelledCommand(_ steps: [(String, String)]) -> String {
        steps.map { label, command in
            "printf '\\n== \(label) ==\\n'; \(command)"
        }.joined(separator: "; ")
    }

    func load() async throws -> SkillDashboard {
        let root = try findRepoRoot()
        let selectedSkillPath = try findSelectedSkillPath(root: root)
        let metadata = try SkillMetadata.load(from: root.appendingPathComponent(selectedSkillPath))
        let registryPath = "jscraik/\(metadata.name)"
        let packageCommand = Self.packageCommand(for: selectedSkillPath)
        let impactCommand = Self.impactCommand(for: selectedSkillPath)
        let securityCommand = Self.securityCommand(for: selectedSkillPath)

        async let packageResult = run(root: root, command: packageCommand)
        async let scenarioResult = run(root: root, command: impactCommand)
        async let securityResult = run(root: root, command: securityCommand)
        async let tesslResult = tesslSignal(root: root, registryPath: registryPath)

        let package = await packageResult
        let scenario = await scenarioResult
        let security = await securityResult
        let tessl = await tesslResult

        return SkillDashboard(
            displayName: metadata.name,
            version: metadata.version,
            description: metadata.description,
            registryPath: registryPath,
            repoPath: root.path,
            installCommand: "tessl install \(registryPath)",
            localEvidenceCommand: Self.localEvidenceCommand(root: root, skillPath: selectedSkillPath),
            reviewedText: "Local SDK evidence",
            deltaText: tessl.ok ? "Tessl" : "Local SDK",
            quality: qualitySignal(from: package, root: root, command: packageCommand),
            impact: impactSignal(from: scenario, root: root, command: impactCommand),
            security: securitySignal(from: security, root: root, command: securityCommand),
            tessl: tessl,
            fleet: fleetSignal(root: root, selectedSkillPath: selectedSkillPath),
            refreshedAt: Date(),
            error: nil
        )
    }

    func loadSync() throws -> SkillDashboard {
        let root = try findRepoRoot()
        let selectedSkillPath = try findSelectedSkillPath(root: root)
        let metadata = try SkillMetadata.load(from: root.appendingPathComponent(selectedSkillPath))
        let registryPath = "jscraik/\(metadata.name)"
        let packageCommand = Self.packageCommand(for: selectedSkillPath)
        let impactCommand = Self.impactCommand(for: selectedSkillPath)
        let securityCommand = Self.securityCommand(for: selectedSkillPath)
        let package = Shell.run(packageCommand, cwd: root, timeout: 45)
        let scenario = Shell.run(impactCommand, cwd: root, timeout: 45)
        let security = Shell.run(securityCommand, cwd: root, timeout: 45)
        return SkillDashboard(
            displayName: metadata.name,
            version: metadata.version,
            description: metadata.description,
            registryPath: registryPath,
            repoPath: root.path,
            installCommand: "tessl install \(registryPath)",
            localEvidenceCommand: Self.localEvidenceCommand(root: root, skillPath: selectedSkillPath),
            reviewedText: "Local SDK evidence",
            deltaText: "Local SDK",
            quality: qualitySignal(from: package, root: root, command: packageCommand),
            impact: impactSignal(from: scenario, root: root, command: impactCommand),
            security: securitySignal(from: security, root: root, command: securityCommand),
            tessl: tesslSignalSync(root: root, registryPath: registryPath),
            fleet: fleetSignal(root: root, selectedSkillPath: selectedSkillPath),
            refreshedAt: Date(),
            error: nil
        )
    }

    private func findRepoRoot() throws -> URL {
        if let explicit = ProcessInfo.processInfo.environment["AGENT_SKILLS_ROOT"], !explicit.isEmpty {
            return URL(fileURLWithPath: explicit)
        }
        var candidate = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
        for _ in 0..<8 {
            if FileManager.default.fileExists(atPath: candidate.appendingPathComponent("Skills/agent-ops/improve-agent-native/SKILL.md").path) {
                return candidate
            }
            candidate.deleteLastPathComponent()
        }
        let fallback = URL(fileURLWithPath: "/Users/jamiecraik/dev/agent-skills")
        if FileManager.default.fileExists(atPath: fallback.appendingPathComponent("Skills/agent-ops/improve-agent-native/SKILL.md").path) {
            return fallback
        }
        throw SkillsBarError.missingRepoRoot
    }

    private func findSelectedSkillPath(root: URL) throws -> String {
        let environment = ProcessInfo.processInfo.environment
        let rawPath = environment["AGENT_SKILL_PATH"]
            ?? environment["SELECTED_SKILL_PATH"]
            ?? UserDefaults.standard.string(forKey: Self.selectedSkillDefaultsKey)
            ?? Self.defaultSkillPath
        let relativePath = rawPath.hasPrefix(root.path + "/")
            ? String(rawPath.dropFirst(root.path.count + 1))
            : rawPath
        guard relativePath.hasPrefix("Skills/"),
              relativePath.hasSuffix("/SKILL.md"),
              FileManager.default.fileExists(atPath: root.appendingPathComponent(relativePath).path) else {
            return Self.defaultSkillPath
        }
        return relativePath
    }

    private func run(root: URL, command: String) async -> CommandResult {
        await Task.detached(priority: .utility) { Shell.run(command, cwd: root, timeout: 45) }.value
    }

    private func fleetSignal(root: URL, selectedSkillPath: String) -> FleetSignal {
        let skillsRoot = root.appendingPathComponent("Skills")
        let fileManager = FileManager.default
        guard let enumerator = fileManager.enumerator(
            at: skillsRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return FleetSignal(
                skillCount: 0,
                groupCount: 0,
                largestGroupName: "missing",
                largestGroupCount: 0,
                metadataCount: 0,
                referencesCount: 0,
                evalsCount: 0,
                selectedSkillPath: selectedSkillPath,
                inventoryCommand: Self.copyCommand(root: root, command: Self.allSkillsInventoryCommand)
            )
        }

        var groups: [String: Int] = [:]
        var skillCount = 0
        var metadataCount = 0
        var referencesCount = 0
        var evalsCount = 0
        for case let url as URL in enumerator where url.lastPathComponent == "SKILL.md" {
            skillCount += 1
            let text = (try? String(contentsOf: url, encoding: .utf8)) ?? ""
            if text.contains("\nmetadata:") || text.hasPrefix("metadata:") {
                metadataCount += 1
            }
            let referencesURL = url.deletingLastPathComponent().appendingPathComponent("references")
            var isDirectory: ObjCBool = false
            if fileManager.fileExists(atPath: referencesURL.path, isDirectory: &isDirectory), isDirectory.boolValue {
                referencesCount += 1
                if fileManager.fileExists(atPath: referencesURL.appendingPathComponent("evals.yaml").path) {
                    evalsCount += 1
                }
            }
            let relative = url.path.replacingOccurrences(of: root.path + "/", with: "")
            let parts = relative.split(separator: "/")
            let group = parts.dropFirst().first.map(String.init) ?? "unknown"
            groups[group, default: 0] += 1
        }
        let largest = groups.sorted { lhs, rhs in
            if lhs.value == rhs.value { return lhs.key < rhs.key }
            return lhs.value > rhs.value
        }.first

        return FleetSignal(
            skillCount: skillCount,
            groupCount: groups.count,
            largestGroupName: largest?.key ?? "none",
            largestGroupCount: largest?.value ?? 0,
            metadataCount: metadataCount,
            referencesCount: referencesCount,
            evalsCount: evalsCount,
            selectedSkillPath: selectedSkillPath,
            inventoryCommand: Self.copyCommand(root: root, command: Self.allSkillsInventoryCommand)
        )
    }

    private func tesslSignal(root: URL, registryPath: String) async -> TesslSignal {
        await Task.detached(priority: .utility) {
            tesslSignalSync(root: root, registryPath: registryPath)
        }.value
    }

    private func tesslSignalSync(root: URL, registryPath: String) -> TesslSignal {
        if let fixture = tesslFixtureSignal(registryPath: registryPath) {
            return fixture
        }

        let tessl = Self.tesslCommand()
        let versionResult = Shell.run("\(tessl) --version", cwd: root, timeout: 5)
        guard versionResult.exitCode == 0 else {
            return TesslSignal(
                ok: false,
                cliAvailable: false,
                authenticated: false,
                displayStatus: "CLI missing",
                detail: "Tessl CLI was not found on PATH.",
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
        }

        let version = versionResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        let whoami = Shell.run("\(tessl) whoami", cwd: root, timeout: 15)
        guard whoami.exitCode == 0 else {
            let authExpired = whoami.combinedOutput.localizedCaseInsensitiveContains("401")
                || whoami.combinedOutput.localizedCaseInsensitiveContains("login")
            return TesslSignal(
                ok: false,
                cliAvailable: true,
                authenticated: false,
                displayStatus: authExpired ? "Auth expired" : "Auth blocked",
                detail: whoami.shortFailure,
                cliVersion: version.isEmpty ? nil : version,
                registryScore: nil,
                registryVersion: nil,
                registryQualityScore: nil,
                registryImpactScore: nil,
                registrySecurityLabel: nil,
                registryEvalCount: nil,
                registryImprovementMultiplier: nil,
                registryVisibility: nil,
                recoveryCommand: "tessl login"
            )
        }

        let searchCommand = "\(tessl) search --json --type skills \(Self.shellQuoted(registryPath))"
        let search = Shell.run(searchCommand, cwd: root, timeout: 20)
        guard search.exitCode == 0 else {
            return TesslSignal(
                ok: false,
                cliAvailable: true,
                authenticated: true,
                displayStatus: "Search blocked",
                detail: search.shortFailure,
                cliVersion: version.isEmpty ? nil : version,
                registryScore: nil,
                registryVersion: nil,
                registryQualityScore: nil,
                registryImpactScore: nil,
                registrySecurityLabel: nil,
                registryEvalCount: nil,
                registryImprovementMultiplier: nil,
                registryVisibility: nil,
                recoveryCommand: "tessl search --type skills \(registryPath)"
            )
        }
        let metadata = TesslRegistryMetadata(payload: search.json, registryPath: registryPath)
        let detail = Shell.run("\(tessl) plugin info \(Self.shellQuoted(registryPath))", cwd: root, timeout: 20)
        let detailVisibility = detail.exitCode == 0 ? Self.tesslVisibility(fromPluginInfo: detail.stdout) : nil

        return TesslSignal(
            ok: true,
            cliAvailable: true,
            authenticated: true,
            displayStatus: metadata.score == nil ? "Connected" : "Scored",
            detail: metadata.score.map { "Registry returned score \($0); local evidence remains separate." } ?? "Registry search returned metadata for this authenticated Tessl session.",
            cliVersion: version.isEmpty ? nil : version,
            registryScore: metadata.score,
            registryVersion: metadata.version,
            registryQualityScore: metadata.qualityScore,
            registryImpactScore: metadata.impactScore,
            registrySecurityLabel: metadata.securityLabel,
            registryEvalCount: metadata.evalCount,
            registryImprovementMultiplier: metadata.improvementMultiplier,
            registryVisibility: detailVisibility ?? metadata.visibility,
            recoveryCommand: "tessl install \(registryPath)"
        )
    }

    private func tesslFixtureSignal(registryPath: String) -> TesslSignal? {
        let environment = ProcessInfo.processInfo.environment
        guard environment["TESSL_REGISTRY_FIXTURE"] == "1"
                || environment["TESSL_REGISTRY_FIXTURE_SCORE"] != nil else { return nil }
        let rawScore = environment["TESSL_REGISTRY_FIXTURE_SCORE"]
        let score = rawScore.flatMap(Int.init).flatMap { (0...100).contains($0) ? $0 : nil }
        return TesslSignal(
            ok: true,
            cliAvailable: true,
            authenticated: true,
            displayStatus: score == nil ? "Connected" : "Scored",
            detail: score.map { "Fixture registry score \($0); local evidence remains separate." } ?? "Fixture registry metadata connected; local evidence remains separate.",
            cliVersion: environment["TESSL_REGISTRY_FIXTURE_CLI_VERSION"] ?? "fixture",
            registryScore: score,
            registryVersion: environment["TESSL_REGISTRY_FIXTURE_VERSION"],
            registryQualityScore: environment["TESSL_REGISTRY_FIXTURE_QUALITY"].flatMap(Int.init),
            registryImpactScore: environment["TESSL_REGISTRY_FIXTURE_IMPACT"].flatMap(Int.init),
            registrySecurityLabel: environment["TESSL_REGISTRY_FIXTURE_SECURITY"],
            registryEvalCount: environment["TESSL_REGISTRY_FIXTURE_EVALS"].flatMap(Int.init),
            registryImprovementMultiplier: environment["TESSL_REGISTRY_FIXTURE_MULTIPLIER"].flatMap(Double.init),
            registryVisibility: environment["TESSL_REGISTRY_FIXTURE_VISIBILITY"] ?? "Private",
            recoveryCommand: "tessl install \(registryPath)"
        )
    }

    private func qualitySignal(from result: CommandResult, root: URL, command rawCommand: String) -> MetricSignal {
        let command = Self.copyCommand(root: root, command: rawCommand)
        guard result.exitCode == 0, let payload = result.json else {
            return MetricSignal(
                score: nil,
                detail: "Blocked: \(result.shortFailure)",
                source: "Local SDK package verify",
                command: command
            )
        }
        let status = payload.firstString(for: ["status"]) ?? "unknown"
        return MetricSignal(
            score: status == "success" ? 100 : 70,
            detail: "Package verify reported \(status).",
            source: "Local SDK package verify",
            command: command
        )
    }

    private func impactSignal(from result: CommandResult, root: URL, command rawCommand: String) -> MetricSignal {
        let command = Self.copyCommand(root: root, command: rawCommand)
        guard result.exitCode == 0, let payload = result.json else {
            return MetricSignal(
                score: nil,
                detail: "Blocked: \(result.shortFailure)",
                source: "Local SDK scenario-quality",
                command: command
            )
        }
        let total = payload.firstInt(for: ["scenario_count", "case_count", "total"])
        let ready = payload.firstInt(for: ["promotion_ready_count", "passed_count", "ready_count"])
        if let total, let ready, total > 0 {
            let score = Int((Double(ready) / Double(total) * 100.0).rounded())
            return MetricSignal(
                score: score,
                detail: "\(ready)/\(total) eval scenarios available.",
                source: "Local SDK scenario-quality",
                command: command,
                statusOverride: "\(ready)/\(total)"
            )
        }
        let status = payload.firstString(for: ["status"]) ?? "success"
        return MetricSignal(
            score: nil,
            detail: "Inspect: scenario-quality returned \(status), but count fields were unavailable.",
            source: "Local SDK scenario-quality",
            command: command
        )
    }

    private func securitySignal(from result: CommandResult, root: URL, command rawCommand: String) -> SecuritySignal {
        let inspectCommand = Self.copyCommand(root: root, command: rawCommand)
        guard result.exitCode == 0, let payload = result.json else {
            return SecuritySignal(
                score: nil,
                status: "Pending",
                detail: "Blocked: \(result.shortFailure)",
                sourceLabel: "Local SDK",
                segmentCount: 0,
                inspectCommand: inspectCommand
            )
        }
        let receiptPath = ["data", "skills_sdk_risk_mode_taxonomy", "receipt"]
        let status = payload.string(at: receiptPath + ["status"]) ?? payload.firstString(for: ["status"]) ?? "success"
        let detectedModes = Set(payload.stringArray(at: receiptPath + ["detected_modes"]))
        let detectedRows = payload.arrayOfDictionaries(at: receiptPath + ["mode_results"]).filter { row in
            guard (row["status"] as? String) == "detected" else { return false }
            guard !detectedModes.isEmpty, let mode = row["mode"] as? String else { return true }
            return detectedModes.contains(mode)
        }
        let severities = detectedRows.compactMap { $0["severity"] as? String }
        if !detectedRows.isEmpty {
            let score = securityScore(for: severities)
            let detail = "\(detectedRows.count) risk modes: \(severitySummary(for: severities))."
            return SecuritySignal(
                score: score,
                status: "Flagged",
                detail: detail,
                sourceLabel: "Local SDK risk-modes",
                segmentCount: min(max(detectedRows.count, 1), 5),
                inspectCommand: inspectCommand
            )
        }
        let detail = "No risk mode signals detected."
        return SecuritySignal(
            score: status == "success" ? 100 : 70,
            status: status == "success" ? "Passed" : status.capitalized,
            detail: detail,
            sourceLabel: "Local SDK risk-modes",
            segmentCount: status == "success" ? 4 : 2,
            inspectCommand: inspectCommand
        )
    }

    private func securityScore(for severities: [String]) -> Int {
        let penalty = severities.reduce(0) { total, severity in
            switch severity.lowercased() {
            case "critical": return total + 35
            case "high": return total + 15
            case "medium": return total + 8
            case "low": return total + 4
            default: return total + 10
            }
        }
        return max(0, 100 - penalty)
    }

    private func severitySummary(for severities: [String]) -> String {
        let grouped = Dictionary(grouping: severities.map { $0.lowercased() }, by: { $0 })
        let order = ["critical", "high", "medium", "low"]
        let parts = order.compactMap { severity -> String? in
            guard let count = grouped[severity]?.count, count > 0 else { return nil }
            return "\(count) \(severity)"
        }
        return parts.isEmpty ? "severity unavailable" : parts.joined(separator: ", ")
    }
}

struct SkillMetadata {
    var name: String
    var version: String
    var description: String

    static func load(from url: URL) throws -> SkillMetadata {
        let text = try String(contentsOf: url, encoding: .utf8)
        return SkillMetadata(
            name: value("name", in: text) ?? "improve-agent-native",
            version: metadataVersion(in: text) ?? "unknown",
            description: value("description", in: text) ?? "No description found."
        )
    }

    private static func value(_ key: String, in text: String) -> String? {
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let raw = String(line)
            if raw.hasPrefix("\(key):") {
                return clean(raw.replacingOccurrences(of: "\(key):", with: ""))
            }
        }
        return nil
    }

    private static func metadataVersion(in text: String) -> String? {
        var inMetadata = false
        for line in text.split(separator: "\n", omittingEmptySubsequences: false) {
            let raw = String(line)
            if raw == "metadata:" { inMetadata = true; continue }
            if inMetadata, raw.hasPrefix("  version:") {
                return clean(raw.replacingOccurrences(of: "  version:", with: ""))
            }
            if inMetadata, !raw.hasPrefix(" ") { inMetadata = false }
        }
        return nil
    }

    private static func clean(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).trimmingCharacters(in: CharacterSet(charactersIn: "\"'"))
    }
}

enum SkillsBarError: LocalizedError {
    case missingRepoRoot
    var errorDescription: String? {
        "Could not find agent-skills data repo. Set AGENT_SKILLS_ROOT."
    }
}
