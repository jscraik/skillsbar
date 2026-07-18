import Foundation

final class TesslSessionCache: @unchecked Sendable {
    static let shared = TesslSessionCache()

    private let lock = NSLock()
    private var versions: [String: String] = [:]

    func version(for executable: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return versions[executable]
    }

    func store(version: String, for executable: String) {
        guard !version.isEmpty else { return }
        lock.lock()
        versions[executable] = version
        lock.unlock()
    }
}
