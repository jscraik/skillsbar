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
        fixtureValue != nil
    }

    private var fixtureValue: String? {
        guard let value = environment["SKILLSBAR_REVIEW_FIXTURE"]?.lowercased(),
              ["1", "live", "no-cli", "offline"].contains(value) else { return nil }
        return value
    }

    private var fixtureDashboard: SkillDashboard {
        fixtureValue == "no-cli" || fixtureValue == "offline"
            ? .reviewNoCLIFixture
            : .reviewFixture
    }

    var initialDashboard: SkillDashboard {
        usesReviewFixture ? fixtureDashboard : .placeholder
    }

    func loadSync() throws -> SkillDashboard {
        if usesReviewFixture {
            return fixtureDashboard
        }
        return try liveLoad()
    }

    @MainActor
    func load() async throws -> SkillDashboard {
        if usesReviewFixture {
            return fixtureDashboard
        }
        return try await liveLoadAsync()
    }
}
