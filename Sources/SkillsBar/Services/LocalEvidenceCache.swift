import Foundation

final class LocalEvidenceCache: @unchecked Sendable {
    struct Entry {
        let packageDigest: String
        let checks: PipelineEvidenceLoader.LocalChecks
    }

    private let lock = NSLock()
    private var entries: [String: Entry] = [:]

    func entry(for key: String, packageDigest: String) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        guard let entry = entries[key], entry.packageDigest == packageDigest else { return nil }
        return entry
    }

    func store(_ checks: PipelineEvidenceLoader.LocalChecks, packageDigest: String, for key: String) {
        lock.lock()
        entries[key] = Entry(packageDigest: packageDigest, checks: checks)
        lock.unlock()
    }
}
