import Foundation

struct TesslRegistrySnapshot: Codable, Equatable {
    let registryPath: String
    let observedAt: Date
    let score: Int?
    let version: String?
    let qualityScore: Int?
    let impactScore: Int?
    let securityLabel: String?
    let evalCount: Int?
    let improvementMultiplier: Double?
    let visibility: String?

    init?(registryPath: String, observedAt: Date, signal: TesslSignal) {
        guard signal.dataOrigin == .liveCLI,
              signal.registryScore != nil
                || signal.registryVersion != nil
                || signal.registryQualityScore != nil
                || signal.registryImpactScore != nil
                || signal.registrySecurityLabel != nil else {
            return nil
        }
        self.registryPath = registryPath
        self.observedAt = observedAt
        score = signal.registryScore
        version = signal.registryVersion
        qualityScore = signal.registryQualityScore
        impactScore = signal.registryImpactScore
        securityLabel = signal.registrySecurityLabel
        evalCount = signal.registryEvalCount
        improvementMultiplier = signal.registryImprovementMultiplier
        visibility = signal.registryVisibility
    }

    var cachedSignal: TesslSignal {
        TesslSignal(
            ok: false,
            cliAvailable: false,
            authenticated: false,
            displayStatus: "CLI unavailable",
            detail: "The Tessl CLI is unavailable; showing the last known registry snapshot.",
            cliVersion: nil,
            registryScore: score,
            registryVersion: version,
            registryQualityScore: qualityScore,
            registryImpactScore: impactScore,
            registrySecurityLabel: securityLabel,
            registryEvalCount: evalCount,
            registryImprovementMultiplier: improvementMultiplier,
            registryVisibility: visibility,
            dataOrigin: .cached,
            recoveryCommand: "tessl doctor"
        )
    }
}

struct TesslRegistryCache {
    private let defaults: UserDefaults
    private let keyPrefix: String

    init(defaults: UserDefaults = .standard, keyPrefix: String = "skillsbar.tessl-registry.v1") {
        self.defaults = defaults
        self.keyPrefix = keyPrefix
    }

    func save(registryPath: String, signal: TesslSignal, observedAt: Date = Date()) {
        guard let snapshot = TesslRegistrySnapshot(
            registryPath: registryPath,
            observedAt: observedAt,
            signal: signal
        ), let data = try? JSONEncoder().encode(snapshot) else { return }
        defaults.set(data, forKey: key(for: registryPath))
    }

    func load(registryPath: String) -> TesslRegistrySnapshot? {
        guard let data = defaults.data(forKey: key(for: registryPath)),
              let snapshot = try? JSONDecoder().decode(TesslRegistrySnapshot.self, from: data),
              snapshot.registryPath == registryPath else { return nil }
        return snapshot
    }

    private func key(for registryPath: String) -> String {
        let safePath = registryPath.unicodeScalars.map { scalar -> Character in
            CharacterSet.alphanumerics.contains(scalar) ? Character(String(scalar)) : "_"
        }
        return keyPrefix + "." + String(safePath)
    }
}
