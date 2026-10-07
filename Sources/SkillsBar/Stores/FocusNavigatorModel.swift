import SwiftUI

@MainActor
final class FocusNavigatorModel: ObservableObject {
    @Published private(set) var selectedStage: PipelineStage
    private var fingerprint: String
    private var hasManualSelection = false

    init(candidate: PipelineCandidate) {
        fingerprint = candidate.fingerprint
        selectedStage = candidate.activeReceipt?.stage ?? .candidateBaseline
    }

    func select(_ stage: PipelineStage) {
        selectedStage = stage
        hasManualSelection = true
    }

    func receipt(in candidate: PipelineCandidate) -> PipelineStageReceipt? {
        candidate.orderedReceipts.first { $0.stage == selectedStage }
    }

    func moveFocus(from stage: PipelineStage, direction: MoveCommandDirection) -> PipelineStage? {
        let offset: Int
        switch direction {
        case .left:
            guard (stage.number - 1) % 3 != 0 else { return nil }
            offset = -1
        case .right:
            guard stage.number % 3 != 0 else { return nil }
            offset = 1
        case .up: offset = -3
        case .down: offset = 3
        @unknown default: return nil
        }
        let index = stage.number - 1 + offset
        guard PipelineStage.allCases.indices.contains(index) else { return nil }
        let next = PipelineStage.allCases[index]
        select(next)
        return next
    }

    func reconcile(_ candidate: PipelineCandidate) {
        if candidate.fingerprint != fingerprint {
            fingerprint = candidate.fingerprint
            hasManualSelection = false
        }
        if !hasManualSelection {
            selectedStage = candidate.activeReceipt?.stage ?? .candidateBaseline
        }
    }
}
