import Foundation

@MainActor
final class DashboardModel: ObservableObject {
    @Published var dashboard: SkillDashboard
    @Published var isRefreshing = false
    @Published private(set) var availableSkillPaths: [String] = []
    private let refreshIntervalNanoseconds: UInt64 = 5 * 60 * 1_000_000_000
    private let sourceChangePollNanoseconds: UInt64 = 3 * 1_000_000_000
    private var refreshLoopTask: Task<Void, Never>?
    private var sourceChangeTask: Task<Void, Never>?
    private var observedSkillDirectory: String?
    private var observedSkillSourceModificationDate: Date?
    private let source: DashboardDataSource

    init(
        dashboard: SkillDashboard? = nil,
        autorefresh: Bool = true,
        source: DashboardDataSource = DashboardDataSource()
    ) {
        self.source = source
        self.dashboard = dashboard ?? source.initialDashboard
        if autorefresh && !source.usesReviewFixture {
            Task { await refresh() }
            startRefreshLoop()
            startSourceChangeObserver()
        }
    }

    deinit {
        refreshLoopTask?.cancel()
        sourceChangeTask?.cancel()
    }

    var menuTitle: String {
        return "Skills SDK"
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            dashboard = try await source.load()
            availableSkillPaths = DashboardLoader.discoverSkillPaths(root: URL(fileURLWithPath: dashboard.repoPath))
            recordSelectedSkillDirectory()
        } catch {
            dashboard = SkillDashboard.placeholder.withError(error.localizedDescription)
        }
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
                try? await Task.sleep(nanoseconds: self?.sourceChangePollNanoseconds ?? 3_000_000_000)
                guard !Task.isCancelled else { return }
                await self?.refreshIfSelectedSkillChanged()
            }
        }
    }

    private func refreshIfSelectedSkillChanged() async {
        guard let directory = selectedSkillDirectory(),
              let currentDate = selectedSkillSourceModificationDate(in: directory) else { return }
        guard observedSkillDirectory == directory.path,
              let previousDate = observedSkillSourceModificationDate else {
            observedSkillDirectory = directory.path
            observedSkillSourceModificationDate = currentDate
            return
        }
        guard currentDate > previousDate else { return }
        observedSkillSourceModificationDate = currentDate
        await refresh()
    }

    private func recordSelectedSkillDirectory() {
        guard let directory = selectedSkillDirectory() else { return }
        observedSkillDirectory = directory.path
        observedSkillSourceModificationDate = selectedSkillSourceModificationDate(in: directory)
    }

    private func selectedSkillDirectory() -> URL? {
        let skill = URL(fileURLWithPath: dashboard.repoPath)
            .appendingPathComponent(dashboard.fleet.selectedSkillPath)
        return skill.deletingLastPathComponent()
    }

    private func selectedSkillSourceModificationDate(in directory: URL) -> Date? {
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

    private func modificationDate(for url: URL) -> Date? {
        let values = try? url.resourceValues(forKeys: [.contentModificationDateKey])
        return values?.contentModificationDate
    }
}
