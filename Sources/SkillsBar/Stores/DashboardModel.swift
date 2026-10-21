import Foundation
import OSLog
import Darwin

private let refreshLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "local.jscraik.skillsbar",
    category: "Refresh"
)

@MainActor
final class DashboardModel: ObservableObject {
    @Published var dashboard: SkillDashboard
    @Published var isRefreshing = false
    @Published private(set) var pendingSelectionPath: String?
    @Published private(set) var hasLoadedEvidence: Bool
    @Published private(set) var availableSkillPaths: [String] = []
    private let refreshIntervalNanoseconds: UInt64 = 5 * 60 * 1_000_000_000
    // Scans can traverse every supporting file beside SKILL.md. Poll at a
    // calm cadence and move that work off the main actor so an open menu stays
    // responsive while local evidence is changing.
    private let sourceChangePollNanoseconds: UInt64 = 750_000_000
    private let sourceChangeDebounceNanoseconds: UInt64 = 350_000_000
    private var refreshLoopTask: Task<Void, Never>?
    private var sourceChangeTask: Task<Void, Never>?
    private var sourceChangeDebounceTask: Task<Void, Never>?
    private var observedSkillDirectory: String?
    private var observedSkillSourceSignature: String?
    private var refreshQueued = false
    private let source: DashboardDataSource

    init(
        dashboard: SkillDashboard? = nil,
        autorefresh: Bool = true,
        source: DashboardDataSource = DashboardDataSource()
    ) {
        self.source = source
        self.dashboard = dashboard ?? source.initialDashboard
        self.hasLoadedEvidence = dashboard != nil || source.usesReviewFixture
        if autorefresh && !source.usesReviewFixture {
            Task { await refresh() }
            startRefreshLoop()
            startSourceChangeObserver()
        }
    }

    deinit {
        refreshLoopTask?.cancel()
        sourceChangeTask?.cancel()
        sourceChangeDebounceTask?.cancel()
    }

    var menuTitle: String {
        return "Skills SDK"
    }

    func refresh() async {
        guard !isRefreshing else {
            refreshQueued = true
            return
        }
        isRefreshing = true
        defer { isRefreshing = false }
        let refreshStartedAt = Date()
        refreshLogger.info("Evidence refresh started")
        repeat {
            refreshQueued = false
            do {
                let loadedDashboard = try await source.load { [weak self] localDashboard in
                    guard let self else { return }
                    guard pendingSelectionPath == nil || pendingSelectionPath == localDashboard.fleet.selectedSkillPath else { return }
                    dashboard = localDashboard
                    pendingSelectionPath = nil
                    hasLoadedEvidence = true
                    let elapsedMilliseconds = Int(Date().timeIntervalSince(refreshStartedAt) * 1_000)
                    refreshLogger.info("Local evidence ready in \(elapsedMilliseconds, privacy: .public) ms")
                }
                if pendingSelectionPath == nil || pendingSelectionPath == loadedDashboard.fleet.selectedSkillPath {
                    dashboard = loadedDashboard
                    pendingSelectionPath = nil
                }
                let root = URL(fileURLWithPath: dashboard.repoPath)
                availableSkillPaths = await Task.detached(priority: .utility) {
                    DashboardLoader.discoverSkillPaths(root: root)
                        + InstalledSkillDiscovery.paths(home: FileManager.default.homeDirectoryForCurrentUser)
                }.value
                await recordSelectedSkillDirectory()
                let elapsedMilliseconds = Int(Date().timeIntervalSince(refreshStartedAt) * 1_000)
                refreshLogger.info("Evidence refresh completed in \(elapsedMilliseconds, privacy: .public) ms")
            } catch {
                dashboard = SkillDashboard.placeholder.withError(error.localizedDescription)
                pendingSelectionPath = nil
                let elapsedMilliseconds = Int(Date().timeIntervalSince(refreshStartedAt) * 1_000)
                refreshLogger.error("Evidence refresh failed after \(elapsedMilliseconds, privacy: .public) ms")
            }
            hasLoadedEvidence = true
        } while refreshQueued
    }

    var isSkillSelectionPinned: Bool {
        DashboardLoader.selectionIsPinnedByEnvironment
    }

    var usesReviewFixture: Bool {
        source.usesReviewFixture
    }

    func selectSkill(path: String) {
        guard !isSkillSelectionPinned else { return }
        pendingSelectionPath = path
        UserDefaults.standard.set(path, forKey: DashboardLoader.selectedSkillDefaultsKey)
        observedSkillDirectory = nil
        observedSkillSourceSignature = nil
        Task { await refresh() }
    }

    private func startRefreshLoop() {
        refreshLoopTask?.cancel()
        refreshLoopTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: self?.refreshIntervalNanoseconds ?? 300_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refresh()
            }
        }
    }

    private func startSourceChangeObserver() {
        sourceChangeTask?.cancel()
        sourceChangeTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(nanoseconds: self?.sourceChangePollNanoseconds ?? 10 * 1_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.queueRefreshIfSelectedSkillChanged()
            }
        }
    }

    private func queueRefreshIfSelectedSkillChanged() async {
        guard await selectedSkillChanged() else { return }
        sourceChangeDebounceTask?.cancel()
        sourceChangeDebounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(nanoseconds: sourceChangeDebounceNanoseconds)
            guard !Task.isCancelled else { return }
            await refresh()
        }
    }

    func refreshIfSelectedSkillChanged() async {
        guard await selectedSkillChanged() else { return }
        await refresh()
    }

    private func selectedSkillChanged() async -> Bool {
        let directories = selectedSkillDirectories()
        let key = directories.map(\.path).joined(separator: "\n")
        let currentSignature = await Self.selectedSkillSourceSignature(in: directories)
        guard observedSkillDirectory == key,
              let previousSignature = observedSkillSourceSignature else {
            let changed = observedSkillDirectory != nil
            observedSkillDirectory = key
            observedSkillSourceSignature = currentSignature
            return changed
        }
        guard currentSignature != previousSignature else { return false }
        observedSkillSourceSignature = currentSignature
        return true
    }

    private func recordSelectedSkillDirectory() async {
        let directories = selectedSkillDirectories()
        observedSkillDirectory = directories.map(\.path).joined(separator: "\n")
        observedSkillSourceSignature = await Self.selectedSkillSourceSignature(in: directories)
    }

    private func selectedSkillDirectories() -> [URL] {
        let skill = InstalledSkillDiscovery.skillURL(
            path: dashboard.fleet.selectedSkillPath, root: URL(fileURLWithPath: dashboard.repoPath)
        )
        let linked = dashboard.fleet.selectedSkillPath.hasPrefix("/")
            ? InstalledSourceEvidence.watchDirectories(skill: skill, home: FileManager.default.homeDirectoryForCurrentUser) : []
        return [skill.deletingLastPathComponent()] + linked
    }

    private nonisolated static func selectedSkillSourceSignature(in directories: [URL]) async -> String {
        await Task.detached(priority: .utility) {
            directories.map { sourceChangeSignature(in: $0) }.joined(separator: "\n")
        }.value
    }

    /// Schedules SDK re-verification; this metadata observation never proves bytes.
    nonisolated static func sourceChangeSignature(in directory: URL) -> String {
        var paths = [directory]
        if let enumerator = FileManager.default.enumerator(at: directory, includingPropertiesForKeys: nil, options: []) {
            paths += enumerator.compactMap { $0 as? URL }
        }
        return paths.sorted { $0.path < $1.path }.map { url in
            var info = stat()
            guard lstat(url.path, &info) == 0 else { return "missing:\(url.path)" }
            return "\(url.path)|\(info.st_mode)|\(info.st_size)|\(info.st_ino)|\(info.st_mtimespec.tv_sec).\(info.st_mtimespec.tv_nsec)|\(info.st_ctimespec.tv_sec).\(info.st_ctimespec.tv_nsec)"
        }.joined(separator: "\n")
    }
}
