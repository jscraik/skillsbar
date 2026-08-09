import SwiftUI

enum MenuBarStatus: Equatable {
    case current
    case attention
    case blocked
    case refreshing
    case unavailable

    var color: Color {
        switch self {
        case .current: return .successAccent
        case .attention: return .warningAccent
        case .blocked: return .dangerAccent
        case .refreshing: return .advisoryAccent
        case .unavailable: return .pendingAccent
        }
    }

    var label: String {
        switch self {
        case .current: return "Up to date"
        case .attention: return "Evidence needs attention"
        case .blocked: return "Evidence blocked"
        case .refreshing: return "Refreshing evidence"
        case .unavailable: return "Evidence unavailable"
        }
    }

    static func resolve(dashboard: SkillDashboard, isRefreshing: Bool) -> MenuBarStatus {
        if isRefreshing { return .refreshing }
        if dashboard.error != nil { return .unavailable }
        guard let active = dashboard.pipeline.activeReceipt else { return .current }
        switch active.evidenceStatus {
        case .blocked:
            return .blocked
        case .reviewRequired, .held, .unproven, .stale:
            return .attention
        case .passed:
            return .current
        }
    }
}

extension DashboardModel {
    var menuBarStatus: MenuBarStatus {
        MenuBarStatus.resolve(dashboard: dashboard, isRefreshing: isRefreshing)
    }
}
