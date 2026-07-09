import AppKit
import Foundation

@MainActor
final class CopyFeedbackModel: ObservableObject {
    static let shared = CopyFeedbackModel()
    @Published var copiedCommand: String?

    func copy(_ command: String) {
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(command, forType: .string)
        copiedCommand = command
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard self?.copiedCommand == command else { return }
            self?.copiedCommand = nil
        }
    }
}
