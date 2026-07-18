import Foundation
import OSLog

private let refreshLogger = Logger(
    subsystem: Bundle.main.bundleIdentifier ?? "local.jscraik.skillsbar",
    category: "Refresh"
)

@MainActor
final class DashboardModel: ObservableObject {
    @Published var dashboard: SkillDashboard
    @Published var isRefreshing = false
    @Published private(set) var hasLoadedEvidence: Bool
    @Published private(set) var availableSkillPaths: [String] = []
    private let refreshIntervalNanoseconds: UInt64 = 5 * 60 * 1_000_000_000
    private let sourceChangePollNanoseconds: UInt64 = 500_000_000
    private let sourceChangeDebounceNanoseconds: UInt64 = 350_000_000
    private var refreshLoopTask: Task<Void, Never>?
    private var sourceChangeTask: Task<Void, Never>?
    private var sourceChangeDebounceTask: Task<Void, Never>?
    private var observedSkillDirectory: String?
    private var observedSkillSourceModificationDate: Date?
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
                dashboard = try await source.load { [weak self] localDashboard in
                    guard let self else { return }
                    dashboard = localDashboard
                    hasLoadedEvidence = true
                    let elapsedMilliseconds = Int(Date().timeIntervalSince(refreshStartedAt) * 1_000)
                    refreshLogger.info("Local evidence ready in \(elapsedMilliseconds, privacy: .public) ms")
                }
                availableSkillPaths = DashboardLoader.discoverSkillPaths(root: URL(fileURLWithPath: dashboard.repoPath))
                await recordSelectedSkillDirectory()
                let elapsedMilliseconds = Int(Date().timeIntervalSince(refreshStartedAt) * 1_000)
                refreshLogger.info("Evidence refresh completed in \(elapsedMilliseconds, privacy: .public) ms")
            } catch {
                dashboard = SkillDashboard.placeholder.withError(error.localizedDescription)
                let elapsedMilliseconds = Int(Date().timeIntervalSince(refreshStartedAt) * 1_000)
                refreshLogger.error("Evidence refresh failed after \(elapsedMilliseconds, privacy: .public) ms")
            }
            hasLoadedEvidence = true
        } while refreshQueued
    }

    var isSkillSelectionPinned: Bool {
        DashboardLoader.selectionIsPinnedByEnvironment
    }

    func selectSkill(path: String) {
        guard !isSkillSelectionPinned else { return }
        UserDefaults.standard.set(path, forKey: DashboardLoader.selectedSkillDefaultsKey)
        observedSkillDirectory = nil
        observedSkillSourceModificationDate = nil
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
                try? await Task.sleep(nanoseconds: self?.sourceChangePollNanoseconds ?? 500_000_000)
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
        guard let directory = selectedSkillDirectory(),
              let currentDate = await Self.selectedSkillSourceModificationDate(in: directory) else { return false }
        guard observedSkillDirectory == directory.path,
              let previousDate = observedSkillSourceModificationDate else {
            observedSkillDirectory = directory.path
            observedSkillSourceModificationDate = currentDate
            return false
        }
        guard currentDate > previousDate else { return false }
        observedSkillSourceModificationDate = currentDate
        return true
    }

    private func recordSelectedSkillDirectory() async {
        guard let directory = selectedSkillDirectory() else { return }
        observedSkillDirectory = directory.path
        observedSkillSourceModificationDate = await Self.selectedSkillSourceModificationDate(in: directory)
    }

    private func selectedSkillDirectory() -> URL? {
        let skill = URL(fileURLWithPath: dashboard.repoPath)
            .appendingPathComponent(dashboard.fleet.selectedSkillPath)
        return skill.deletingLastPathComponent()
    }

    private nonisolated static func selectedSkillSourceModificationDate(in directory: URL) async -> Date? {
        await Task.detached(priority: .utility) {
            selectedSkillSourceModificationDateSync(in: directory)
        }.value
    }

    private nonisolated static func selectedSkillSourceModificationDateSync(in directory: URL) -> Date? {
        let fileManager = FileManager.default
        var latest = modificationDate(for: directory)
        guard let enumerator = fileManager.enumerator(
            at: directory,
            includingPropertiesForKeys: [.contentModificationDateKey],
            options: [.skipsHiddenFiles]
        ) else { return latest }
        for case let url as URL in enumerator {
            guard let date = modificationDate(for: url) else { continue }
            if latest == nil || date > latest! {
                latest = date
            }
        }
        return latest
    }

    private nonisolated static func modificationDate(for url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }
}
