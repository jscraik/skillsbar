import Foundation
import SkillsBarCore

/// Reconciles read-only live SDK checks with durable, candidate-bound receipts.
///
/// The loader deliberately does not execute provider evals, Tessl publication, or
/// runtime installation/proof commands. Those lanes are admitted only from
/// durable receipts that carry the current canonical package digest.
struct PipelineEvidenceLoader {
    struct LocalChecks {
        let packageBuild: CommandResult
        let strictAudit: CommandResult
        let packageVerify: CommandResult
        let securityRiskModes: CommandResult
        let scenarioQuality: CommandResult
        let scorerQuality: CommandResult
        let scorerCalibration: CommandResult
    }

    private enum ReceiptState {
        case passed(path: String, scenarioIDs: [String])
        case blocked(path: String, reason: String)
        case stale(path: String)
        case unproven(reason: String)
    }

    private let root: URL
    private let selectedSkillPath: String
    private let evidenceFingerprint: String
    private let checks: LocalChecks
    private let tessl: TesslSignal
    private let observedAt: Date
    private let fileManager: FileManager

    init(
        root: URL,
        selectedSkillPath: String,
        evidenceFingerprint: String,
        checks: LocalChecks,
        tessl: TesslSignal,
        observedAt: Date = Date(),
        fileManager: FileManager = .default
    ) {
        self.root = root.standardizedFileURL
        self.selectedSkillPath = selectedSkillPath
        self.evidenceFingerprint = evidenceFingerprint
        self.checks = checks
        self.tessl = tessl
        self.observedAt = observedAt
        self.fileManager = fileManager
    }

    var packageDigest: String? {
        guard commandSucceeded(checks.packageBuild),
              let payload = checks.packageBuild.json,
              payload.string(at: ["data", "skills_sdk_package_build", "status"]) == "built",
              payload.string(at: ["data", "skills_sdk_package_build", "canonical_source_path"]) == selectedSkillPath,
              payload.bool(at: ["data", "skills_sdk_package_build", "mutation_performed"]) == false,
              let digest = payload.string(at: ["data", "skills_sdk_package_build", "package_digest"]),
              Self.isPackageDigest(digest) else { return nil }
        return digest
    }

    func stageReceipts() -> [PipelineStageReceipt] {
        let digest = packageDigest
        let identity = identityReceipt(digest: digest)
        let mechanical = mechanicalReceipt(digest: digest)
        let security = securityReceipt(digest: digest)
        let preparation = preparationReceipt(digest: digest)

        guard let digest else {
            return [identity, mechanical, security, preparation] + [
                unproven(.ossLocal, profile: "oss-local", action: "Current package digest required before Eval local proof"),
                unproven(.ossCloud, profile: "oss-cloud", action: "Current package digest required before Eval cloud proof"),
                unproven(.tesslStaging, profile: "tessl-staging", action: "Current package digest required before Tessl staging"),
                unproven(.tesslLiveRegistry, profile: "tessl-live", action: "Current package digest required before publication proof"),
                unproven(.liveScoreAndRuntime, profile: "live-runtime", action: "Current package digest required before runtime proof")
            ]
        }

        let local = boundGate("oss_local", digest: digest)
        let cloud = boundGate("oss_cloud", digest: digest)
        let localIDs = scenarioIDs(from: local)
        let cloudState: ReceiptState
        if case let .passed(path, cloudIDs) = cloud,
           !localIDs.isEmpty,
           cloudIDs.sorted() == localIDs.sorted() {
            cloudState = .passed(path: path, scenarioIDs: cloudIDs)
        } else if case let .passed(path, _) = cloud {
            cloudState = .blocked(path: path, reason: "Eval cloud scenario IDs do not match Eval local proof")
        } else {
            cloudState = cloud
        }
        let staging = combinedGate(
            ["tessl_local_proof", "tessl_dry_run", "handoff_readiness"],
            digest: digest,
            expectedScenarioIDs: localIDs
        )
        let publication = publicationGate(digest: digest)
        let runtime = runtimeGate(digest: digest)

        return [
            identity,
            mechanical,
            security,
            preparation,
            receipt(
                stage: .ossLocal,
                state: local,
                profile: "oss-local",
                passedAction: "Candidate-bound Eval local proof is current"
            ),
            receipt(
                stage: .ossCloud,
                state: cloudState,
                profile: "oss-cloud",
                passedAction: "Candidate-bound Eval cloud proof uses the same scenarios"
            ),
            receipt(
                stage: .tesslStaging,
                state: staging,
                profile: "tessl-staging",
                passedAction: "Local proof, dry run, and handoff are candidate-bound"
            ),
            receipt(
                stage: .tesslLiveRegistry,
                state: publication,
                profile: "tessl-live",
                passedAction: "Publication receipt and live registry observation are current"
            ),
            receipt(
                stage: .liveScoreAndRuntime,
                state: runtime,
                profile: "live-runtime",
                passedAction: "Installed digest and observed runtime behavior are current"
            )
        ]
    }

    private func identityReceipt(digest: String?) -> PipelineStageReceipt {
        let command = DashboardLoader.copyCommand(
            root: root,
            command: DashboardLoader.packageBuildCommand(for: selectedSkillPath)
        )
        return PipelineStageReceipt(
            stage: .candidateBaseline,
            candidateFingerprint: evidenceFingerprint,
            evidenceStatus: digest == nil ? .blocked : .passed,
            stageScore: digest == nil ? nil : 100,
            command: command,
            receiptPath: nil,
            modelProfile: digest,
            observedAt: digest == nil ? nil : observedAt,
            nextAction: digest == nil
                ? "Canonical package digest unavailable"
                : "Canonical package digest established"
        )
    }

    private func mechanicalReceipt(digest: String?) -> PipelineStageReceipt {
        let packagePassed = packageVerifyPassed
        let auditPassed = strictAuditPassed
        let status: PipelineEvidenceStatus
        if digest == nil {
            status = .unproven
        } else if packagePassed && auditPassed {
            status = .passed
        } else if packagePassed || auditPassed {
            status = .reviewRequired
        } else {
            status = .blocked
        }
        return PipelineStageReceipt(
            stage: .mechanicalValidation,
            candidateFingerprint: evidenceFingerprint,
            evidenceStatus: status,
            stageScore: status == .passed ? 100 : (packagePassed || auditPassed ? 50 : nil),
            command: DashboardLoader.copyCommand(
                root: root,
                command: DashboardLoader.mechanicalEvidenceCommand(for: selectedSkillPath)
            ),
            receiptPath: nil,
            modelProfile: "local-package",
            observedAt: packagePassed || auditPassed ? observedAt : nil,
            nextAction: "Package verify \(packagePassed ? "passed" : "missing") · strict audit \(auditPassed ? "passed" : "missing")",
            completedChecks: [packagePassed, auditPassed].filter { $0 }.count,
            requiredChecks: 2
        )
    }

    private func securityReceipt(digest: String?) -> PipelineStageReceipt {
        let resultDigest = checks.securityRiskModes.json?.string(
            at: ["data", "skills_sdk_risk_mode_taxonomy", "package_digest"]
        )
        let command = DashboardLoader.copyCommand(
            root: root,
            command: DashboardLoader.securityCommand(for: selectedSkillPath)
        )
        guard let digest else {
            return PipelineStageReceipt(
                stage: .securityReview,
                candidateFingerprint: evidenceFingerprint,
                evidenceStatus: .unproven,
                stageScore: nil,
                command: command,
                receiptPath: nil,
                modelProfile: "local-security",
                observedAt: nil,
                nextAction: "Canonical digest required before security evidence"
            )
        }
        guard commandSucceeded(checks.securityRiskModes), resultDigest == digest else {
            return PipelineStageReceipt(
                stage: .securityReview,
                candidateFingerprint: evidenceFingerprint,
                evidenceStatus: resultDigest == nil ? .blocked : .stale,
                stageScore: nil,
                command: command,
                receiptPath: nil,
                modelProfile: "local-security",
                observedAt: nil,
                nextAction: resultDigest == nil
                    ? "Candidate-bound security receipt unavailable"
                    : "Security receipt belongs to a different package digest"
            )
        }

        let rows = checks.securityRiskModes.json?.arrayOfDictionaries(
            at: ["data", "skills_sdk_risk_mode_taxonomy", "receipt", "mode_results"]
        ) ?? []
        let detected = rows.filter { ($0["status"] as? String) == "detected" }
        let severe = detected.filter {
            let severity = ($0["severity"] as? String)?.lowercased()
            return severity == "critical" || severity == "high"
        }
        let governedLane = securityLaneReceipt(digest: digest)
        let governedPath = path(from: governedLane)
        let governedAction: String
        let cleanStatus: PipelineEvidenceStatus
        switch governedLane {
        case .passed:
            cleanStatus = .passed
            governedAction = "Full governed security receipt is current"
        case .stale:
            cleanStatus = .stale
            governedAction = "Full governed security receipt belongs to a different package digest"
        case let .blocked(_, reason):
            cleanStatus = .blocked
            governedAction = reason
        case let .unproven(reason):
            cleanStatus = .unproven
            governedAction = reason
        }
        let evidenceStatus: PipelineEvidenceStatus = severe.isEmpty ? cleanStatus : .reviewRequired
        return PipelineStageReceipt(
            stage: .securityReview,
            candidateFingerprint: evidenceFingerprint,
            evidenceStatus: evidenceStatus,
            stageScore: evidenceStatus == .passed ? 100 : (severe.isEmpty ? nil : max(0, 100 - severe.count * 20)),
            command: command,
            receiptPath: governedPath,
            modelProfile: "local-security",
            observedAt: evidenceStatus.isCurrentEvidence ? observedAt : nil,
            nextAction: severe.isEmpty
                ? governedAction
                : "Review \(severe.count) critical/high security finding\(severe.count == 1 ? "" : "s") · \(governedAction.lowercased())"
        )
    }

    private func securityLaneReceipt(digest: String) -> ReceiptState {
        let skillName = URL(fileURLWithPath: selectedSkillPath).deletingLastPathComponent().lastPathComponent
        let url = root
            .appendingPathComponent(".harness/evidence/skills-sdk/oss-security")
            .appendingPathComponent("\(skillName)-security-lane-receipt.json")
        let relative = relativePath(url)
        guard let wrapper = loadObject(url),
              wrapper["status"] as? String == "success",
              let data = wrapper["data"] as? [String: Any],
              let lane = data["skills_sdk_security_lane"] as? [String: Any],
              let receipt = lane["receipt"] as? [String: Any],
              receipt["schema_version"] as? String == "skills-sdk.security-lane-receipt.v0",
              receipt["status"] as? String == "pass",
              let receiptDigest = receipt["package_digest"] as? String,
              let laneDigest = receipt["security_lane_digest"] as? String,
              Self.isPackageDigest(receiptDigest),
              Self.isPackageDigest(laneDigest),
              receipt["execution_performed"] as? Bool == false,
              receipt["network_accessed"] as? Bool == false,
              receipt["credentials_accessed"] as? Bool == false,
              receipt["mutation_performed"] as? Bool == false else {
            return .unproven(reason: "Full governed security receipt is missing or malformed")
        }
        guard receiptDigest == digest else {
            return .stale(path: relative)
        }
        return .passed(path: relative, scenarioIDs: [])
    }

    private func preparationReceipt(digest: String?) -> PipelineStageReceipt {
        let scenario = scenarioQualityPassed
        let scorer = scorerQualityPassed
        let calibration = scorerCalibrationPassed
        let passedCount = [scenario, scorer, calibration].filter { $0 }.count
        let status: PipelineEvidenceStatus
        if digest == nil { status = .unproven }
        else if passedCount == 3 { status = .passed }
        else if passedCount > 0 { status = .reviewRequired }
        else { status = .blocked }
        return PipelineStageReceipt(
            stage: .evalPreparation,
            candidateFingerprint: evidenceFingerprint,
            evidenceStatus: status,
            stageScore: passedCount == 0 ? nil : Int((Double(passedCount) / 3.0 * 100).rounded()),
            command: DashboardLoader.copyCommand(
                root: root,
                command: DashboardLoader.evalPreparationCommand(for: selectedSkillPath)
            ),
            receiptPath: nil,
            modelProfile: "eval-preparation",
            observedAt: passedCount == 0 ? nil : observedAt,
            nextAction: "Scenario \(scenario ? "passed" : "missing") · scorer \(scorer ? "passed" : "missing") · calibration \(calibration ? "passed" : "missing")",
            completedChecks: passedCount,
            requiredChecks: 3
        )
    }

    private var packageVerifyPassed: Bool {
        guard commandSucceeded(checks.packageVerify), let payload = checks.packageVerify.json else { return false }
        let checks = payload.arrayOfDictionaries(at: ["data", "skill_package_verification", "checks"])
        return payload.string(at: ["data", "skill_package_verification", "status"]) == "pass"
            && !checks.isEmpty
            && checks.allSatisfy { ($0["status"] as? String) == "pass" }
    }

    private var strictAuditPassed: Bool {
        guard commandSucceeded(checks.strictAudit), let payload = checks.strictAudit.json else { return false }
        let paths = [
            ["data", "diagnostics", "exit_code"],
            ["data", "security_gate", "exit_code"],
            ["data", "family_benchmarks", "exit_code"],
            ["data", "openclaw_guard", "exit_code"]
        ]
        return paths.allSatisfy { payload.int(at: $0) == 0 }
    }

    private var scenarioQualityPassed: Bool {
        guard commandSucceeded(checks.scenarioQuality), let payload = checks.scenarioQuality.json else { return false }
        let base = ["data", "skills_sdk_eval_scenario_quality"]
        guard payload.string(at: base + ["status"]) == "preview",
              payload.int(at: base + ["blocked_count"]) == 0,
              let count = payload.int(at: base + ["scenario_count"]),
              let ready = payload.int(at: base + ["promotion_ready_count"]),
              count > 0 else { return false }
        return count == ready
    }

    private var scorerQualityPassed: Bool {
        previewPassed(checks.scorerQuality, key: "skills_sdk_eval_scorer_quality")
    }

    private var scorerCalibrationPassed: Bool {
        previewPassed(checks.scorerCalibration, key: "skills_sdk_eval_scorer_calibration")
    }

    private func previewPassed(_ result: CommandResult, key: String) -> Bool {
        guard commandSucceeded(result), let payload = result.json else { return false }
        let base = ["data", key]
        return payload.string(at: base + ["status"]) == "preview"
            && payload.bool(at: base + ["ready"]) == true
            && payload.int(at: base + ["blocked_count"]) == 0
    }

    private func commandSucceeded(_ result: CommandResult) -> Bool {
        result.exitCode == 0 && result.json?.string(at: ["status"]) == "success"
    }

    private func boundGate(_ gateID: String, digest: String) -> ReceiptState {
        let chainPath = handoffDirectory.appendingPathComponent("gate-chain.json")
        guard let chain = loadObject(chainPath),
              chain["schema_version"] as? String == "skills-sdk.gate-chain.v1",
              let gates = chain["gates"] as? [[String: Any]],
              gateChainIsCanonical(gates, through: gateID),
              let gate = gates.first(where: { ($0["id"] as? String) == gateID }),
              (gate["status"] as? String) == "pass",
              let rawReceiptPath = gate["receipt_path"] as? String,
              let receiptURL = safeURL(rawReceiptPath) else {
            return .unproven(reason: "Missing governed \(gateID) gate-chain entry")
        }
        return validateReleaseReceipt(receiptURL, expectedGate: gateID, digest: digest)
    }

    private func combinedGate(
        _ gateIDs: [String],
        digest: String,
        expectedScenarioIDs: [String]
    ) -> ReceiptState {
        guard !expectedScenarioIDs.isEmpty else {
            return .unproven(reason: "Candidate-bound scenario identities are required before Tessl staging")
        }
        var paths: [String] = []
        let expected = expectedScenarioIDs.sorted()
        for gateID in gateIDs {
            let state = boundGate(gateID, digest: digest)
            switch state {
            case let .passed(path, scenarioIDs):
                guard scenarioIDs.sorted() == expected else {
                    return .blocked(path: path, reason: "\(gateID) scenario IDs do not match Eval local proof")
                }
                paths.append(path)
            case .stale:
                return state
            case .blocked:
                return state
            case .unproven:
                return state
            }
        }
        return .passed(path: paths.joined(separator: ", "), scenarioIDs: expected)
    }

    private func publicationGate(digest: String) -> ReceiptState {
        let combined = releaseReceipt(named: "tessl_live_registry", digest: digest)
        if case .passed = combined {
            guard registryReceiptBindsCandidate(digest: digest) else {
                return .blocked(
                    path: path(from: combined) ?? "",
                    reason: "Live Tessl registry receipt lacks an explicit candidate package digest"
                )
            }
            return registryObservationBlocker().map {
                .blocked(path: path(from: combined) ?? "", reason: $0)
            } ?? combined
        }
        let publication = releaseReceipt(named: "tessl_publication", digest: digest)
        let score = releaseReceipt(named: "tessl_score", digest: digest)
        guard case let .passed(publicationPath, publicationIDs) = publication,
              case let .passed(scorePath, scoreIDs) = score else {
            if case .stale = publication { return publication }
            if case .stale = score { return score }
            return .unproven(reason: "Candidate-bound Tessl publication and score receipts are required")
        }
        if let blocker = registryObservationBlocker() {
            return .blocked(
                path: [publicationPath, scorePath].joined(separator: ", "),
                reason: blocker
            )
        }
        return .passed(
            path: [publicationPath, scorePath].joined(separator: ", "),
            scenarioIDs: Array(Set(publicationIDs + scoreIDs)).sorted()
        )
    }

    private func registryReceiptBindsCandidate(digest: String) -> Bool {
        let receiptURL = handoffDirectory.appendingPathComponent("release-gate-tessl_live_registry.json")
        guard let receipt = loadObject(receiptURL),
              let refs = receipt["evidence_refs"] as? [String] else { return false }
        var documents: [Any] = [receipt]
        for ref in refs {
            guard let url = safeURL(ref), let object = loadObject(url) else { return false }
            documents.append(object)
        }
        let registryDigests = Set(documents.flatMap { collectStrings(named: "registry_package_digest", in: $0) })
        return registryDigests == [digest]
    }

    private func releaseReceipt(named gateID: String, digest: String) -> ReceiptState {
        let url = handoffDirectory.appendingPathComponent("release-gate-\(gateID).json")
        guard fileManager.fileExists(atPath: url.path) else {
            return .unproven(reason: "Missing \(gateID) receipt")
        }
        return validateReleaseReceipt(url, expectedGate: gateID, digest: digest)
    }

    private func validateReleaseReceipt(
        _ receiptURL: URL,
        expectedGate: String,
        digest: String
    ) -> ReceiptState {
        let relativeReceipt = relativePath(receiptURL)
        guard let receipt = loadObject(receiptURL),
              receipt["schema_version"] as? String == "skills-sdk.release-gate-receipt.v1",
              receipt["gate"] as? String == expectedGate,
              receipt["status"] as? String == "pass",
              nonblank(receipt["what_this_proves"]),
              nonblank(receipt["what_this_does_not_prove"]),
              let refs = receipt["evidence_refs"] as? [String],
              !refs.isEmpty else {
            return .unproven(reason: "Malformed \(expectedGate) release receipt")
        }

        var documents: [Any] = [receipt]
        for ref in refs {
            guard let url = safeURL(ref), let object = loadObject(url) else {
                return .blocked(path: relativeReceipt, reason: "Missing or unsafe evidence reference for \(expectedGate)")
            }
            documents.append(object)
        }
        let digests = Set(documents.flatMap { collectStrings(named: "package_digest", in: $0) })
        guard !digests.isEmpty else {
            return .unproven(reason: "\(expectedGate) receipt is not bound to a package digest")
        }
        guard digests == Set([digest]) else {
            return .stale(path: relativeReceipt)
        }
        let receiptScenarioIDs = Array(Set(documents.flatMap { scenarioIDs(in: $0) })).sorted()
        let scenarioBoundGates = [
            "oss_local", "oss_cloud", "tessl_local_proof", "tessl_dry_run",
            "handoff_readiness", "tessl_score"
        ]
        if scenarioBoundGates.contains(expectedGate), receiptScenarioIDs.isEmpty {
            return .unproven(reason: "\(expectedGate) receipt does not identify its scenarios")
        }
        return .passed(path: relativeReceipt, scenarioIDs: receiptScenarioIDs)
    }

    private func runtimeGate(digest: String) -> ReceiptState {
        let skillName = URL(fileURLWithPath: selectedSkillPath).deletingLastPathComponent().lastPathComponent
        let runtimeRoot = root
            .appendingPathComponent(".harness/evidence/runtime-proof")
            .appendingPathComponent(skillName)
        guard let enumerator = fileManager.enumerator(
            at: runtimeRoot,
            includingPropertiesForKeys: [.isRegularFileKey],
            options: [.skipsHiddenFiles]
        ) else {
            return .unproven(reason: "Runtime proof directory is missing")
        }
        let cards = enumerator.compactMap { $0 as? URL }
            .filter { $0.lastPathComponent == "runtime-card.json" }
            .sorted { $0.path < $1.path }
        var sawMismatch: URL?
        var sawCurrentBlocked: (URL, String)?
        for cardURL in cards {
            guard let card = loadObject(cardURL),
                  String(describing: card["schema_version"] ?? "") == "1",
                  card["skill_handle"] as? String == skillName else { continue }
            let digests = collectStrings(named: "package_digest", in: card)
            if !digests.isEmpty, !digests.contains(digest) {
                sawMismatch = cardURL
                continue
            }
            guard digests.contains(digest) else { continue }
            let status = (card["runtime_status"] as? String ?? "").lowercased()
            let installedDigests = collectStrings(named: "installed_digest", in: card)
            let doctorStatuses = collectStrings(named: "doctor_status", in: card)
            let behaviorStatuses = collectStrings(named: "observed_behavior_status", in: card)
            let runtimeComplete = installedDigests == [digest]
                && doctorStatuses.contains(where: Self.isPassStatus)
                && behaviorStatuses.contains(where: Self.isPassStatus)
            if (status == "pass" || status == "passed" || status == "success"), runtimeComplete {
                return .passed(path: relativePath(cardURL), scenarioIDs: [])
            }
            sawCurrentBlocked = (
                cardURL,
                runtimeComplete
                    ? "Runtime receipt is \(status.isEmpty ? "not passed" : status)"
                    : "Runtime receipt lacks matching installed digest, doctor pass, or observed behavior"
            )
        }
        if let sawCurrentBlocked {
            return .blocked(path: relativePath(sawCurrentBlocked.0), reason: sawCurrentBlocked.1)
        }
        if let sawMismatch {
            return .stale(path: relativePath(sawMismatch))
        }
        return .unproven(reason: "No runtime card is bound to the current package digest")
    }

    private func receipt(
        stage: PipelineStage,
        state: ReceiptState,
        profile: String,
        passedAction: String
    ) -> PipelineStageReceipt {
        let status: PipelineEvidenceStatus
        let path: String?
        let action: String
        let date: Date?
        switch state {
        case let .passed(receiptPath, _):
            status = .passed
            path = receiptPath
            action = passedAction
            date = observedAt
        case let .blocked(receiptPath, reason):
            status = .blocked
            path = receiptPath.isEmpty ? nil : receiptPath
            action = reason
            date = observedAt
        case let .stale(receiptPath):
            status = .stale
            path = receiptPath
            action = "Receipt belongs to a different package digest"
            date = nil
        case let .unproven(reason):
            status = .unproven
            path = nil
            action = reason
            date = nil
        }
        return PipelineStageReceipt(
            stage: stage,
            candidateFingerprint: evidenceFingerprint,
            evidenceStatus: status,
            stageScore: status == .passed ? 100 : nil,
            command: "",
            receiptPath: path,
            modelProfile: profile,
            observedAt: date,
            nextAction: action
        )
    }

    private func unproven(_ stage: PipelineStage, profile: String, action: String) -> PipelineStageReceipt {
        PipelineStageReceipt(
            stage: stage,
            candidateFingerprint: evidenceFingerprint,
            evidenceStatus: .unproven,
            stageScore: nil,
            command: "",
            receiptPath: nil,
            modelProfile: profile,
            observedAt: nil,
            nextAction: action
        )
    }

    private var handoffDirectory: URL {
        let skillName = URL(fileURLWithPath: selectedSkillPath).deletingLastPathComponent().lastPathComponent
        return root.appendingPathComponent(".harness/evidence/handoff").appendingPathComponent(skillName)
    }

    private func safeURL(_ rawPath: String) -> URL? {
        guard !rawPath.isEmpty else { return nil }
        let candidate = (rawPath.hasPrefix("/")
            ? URL(fileURLWithPath: rawPath)
            : root.appendingPathComponent(rawPath)).standardizedFileURL.resolvingSymlinksInPath()
        let resolvedRoot = root.resolvingSymlinksInPath()
        let rootPath = resolvedRoot.path.hasSuffix("/") ? resolvedRoot.path : resolvedRoot.path + "/"
        guard candidate.path.hasPrefix(rootPath) else { return nil }
        return candidate
    }

    private func loadObject(_ url: URL) -> [String: Any]? {
        guard let data = try? Data(contentsOf: url),
              let object = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        return object
    }

    private func relativePath(_ url: URL) -> String {
        url.standardizedFileURL.path.replacingOccurrences(of: root.path + "/", with: "")
    }

    private func nonblank(_ value: Any?) -> Bool {
        guard let string = value as? String else { return false }
        return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private func collectStrings(named key: String, in value: Any) -> [String] {
        if let dictionary = value as? [String: Any] {
            return dictionary.flatMap { name, child -> [String] in
                var values = name == key ? strings(from: child) : []
                values.append(contentsOf: collectStrings(named: key, in: child))
                return values
            }
        }
        if let array = value as? [Any] {
            return array.flatMap { collectStrings(named: key, in: $0) }
        }
        return []
    }

    private func scenarioIDs(in value: Any) -> [String] {
        collectStrings(named: "scenario_ids", in: value)
            + collectStrings(named: "case_ids", in: value)
    }

    private func strings(from value: Any) -> [String] {
        if let string = value as? String { return [string] }
        if let strings = value as? [String] { return strings }
        return []
    }

    private func scenarioIDs(from state: ReceiptState) -> [String] {
        if case let .passed(_, ids) = state { return ids }
        return []
    }

    private func path(from state: ReceiptState) -> String? {
        switch state {
        case let .passed(path, _), let .blocked(path, _), let .stale(path): return path
        case .unproven: return nil
        }
    }

    private func gateChainIsCanonical(_ gates: [[String: Any]], through gateID: String) -> Bool {
        let canonical = [
            "sdk_start", "strict_audit", "package_verify", "security_risk_modes",
            "scenario_quality", "scorer_quality", "scorer_calibration", "oss_local",
            "oss_cloud", "tessl_local_proof", "tessl_dry_run", "handoff_readiness"
        ]
        guard let targetIndex = canonical.firstIndex(of: gateID) else { return false }
        let required = Array(gates.prefix(targetIndex + 1))
        let ids = required.compactMap { $0["id"] as? String }
        return ids == Array(canonical.prefix(targetIndex + 1))
            && required.allSatisfy { ($0["status"] as? String)?.lowercased() == "pass" }
    }

    private func registryObservationBlocker() -> String? {
        guard tessl.ok, tessl.dataOrigin == .liveCLI else {
            return "Candidate receipt exists, but live Tessl registry confirmation is unavailable"
        }
        guard tessl.registryScore != nil else {
            return "Live Tessl registry confirmation has no score"
        }
        guard let visibility = tessl.registryVisibility?.lowercased(),
              visibility == "private" || visibility == "public" else {
            return "Live Tessl registry confirmation has no governed visibility"
        }
        guard let packageVersion = checks.packageBuild.json?.string(
            at: ["data", "skills_sdk_package_build", "version"]
        ),
              let registryVersion = tessl.registryVersion,
              normalizeSemanticVersion(packageVersion) == normalizeSemanticVersion(registryVersion) else {
            return "Live Tessl registry version does not match the current package version"
        }
        return nil
    }

    private static func isPassStatus(_ value: String) -> Bool {
        ["pass", "passed", "success"].contains(value.lowercased())
    }

    static func isPackageDigest(_ value: String) -> Bool {
        value.range(of: #"^sha256:[0-9a-f]{64}$"#, options: .regularExpression) != nil
    }
}
