import AppKit
import Foundation
import SwiftUI

@MainActor
protocol PasteboardWriting: AnyObject {
    func clearContents() -> Int
    func setString(_ string: String, forType dataType: NSPasteboard.PasteboardType) -> Bool
}

extension NSPasteboard: PasteboardWriting {}

@MainActor
final class CopyFeedbackModel: ObservableObject {
    static let shared = CopyFeedbackModel()
    @Published var copiedCommand: String?
    @Published var copyError: String?
    private let pasteboard: any PasteboardWriting

    init(pasteboard: any PasteboardWriting = NSPasteboard.general) {
        self.pasteboard = pasteboard
    }

    @discardableResult
    func copy(_ command: String) -> Bool {
        _ = pasteboard.clearContents()
        guard pasteboard.setString(command, forType: .string) else {
            copiedCommand = nil
            let message = "Could not copy inspect command"
            copyError = message
            AccessibilityNotification.Announcement(message).post()
            return false
        }
        copyError = nil
        copiedCommand = command
        AccessibilityNotification.Announcement("Inspect command copied").post()
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) { [weak self] in
            guard self?.copiedCommand == command else { return }
            self?.copiedCommand = nil
        }
        return true
    }
}
