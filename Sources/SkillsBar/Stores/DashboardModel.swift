import Foundation

@MainActor
final class DashboardModel: ObservableObject {
    @Published var dashboard = SkillDashboard.placeholder
    @Published var isRefreshing = false
    private let refreshIntervalNanoseconds: UInt64 = 5 * 60 * 1_000_000_000
    private var refreshLoopTask: Task<Void, Never>?

    init(dashboard: SkillDashboard = .placeholder, autorefresh: Bool = true) {
        self.dashboard = dashboard
        if autorefresh {
            Task { await refresh() }
            startRefreshLoop()
        }
    }

    deinit {
        refreshLoopTask?.cancel()
    }

    var menuTitle: String {
        return "Skills SDK"
    }

    func refresh() async {
        guard !isRefreshing else { return }
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            dashboard = try await DashboardLoader().load()
        } catch {
            dashboard = SkillDashboard.placeholder.withError(error.localizedDescription)
        }
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
}
