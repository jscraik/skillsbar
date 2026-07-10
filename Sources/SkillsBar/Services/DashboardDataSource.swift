import Foundation

struct DashboardDataSource {
    private let environment: [String: String]
    private let liveLoad: () throws -> SkillDashboard
    private let liveLoadAsync: () async throws -> SkillDashboard

    init(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        liveLoad: @escaping () throws -> SkillDashboard = { try DashboardLoader().loadSync() },
        liveLoadAsync: @escaping () async throws -> SkillDashboard = { try await DashboardLoader().load() }
    ) {
        self.environment = environment
        self.liveLoad = liveLoad
        self.liveLoadAsync = liveLoadAsync
    }

    var usesReviewFixture: Bool {
        environment["SKILLSBAR_REVIEW_FIXTURE"] == "1"
    }

    var initialDashboard: SkillDashboard {
        usesReviewFixture ? .reviewFixture : .placeholder
    }

    func loadSync() throws -> SkillDashboard {
        if usesReviewFixture {
            return .reviewFixture
        }
        return try liveLoad()
    }

    @MainActor
    func load() async throws -> SkillDashboard {
        if usesReviewFixture {
            return .reviewFixture
        }
        return try await liveLoadAsync()
    }
}
