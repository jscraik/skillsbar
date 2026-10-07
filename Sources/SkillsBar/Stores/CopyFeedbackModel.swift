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
    private(set) var failedValue: String?
    private var resetTask: Task<Void, Never>?
    private let pasteboard: any PasteboardWriting

    init(pasteboard: any PasteboardWriting = NSPasteboard.general) {
        self.pasteboard = pasteboard
    }

    @discardableResult
    func copy(_ command: String, label: String = "Command") -> Bool {
        resetTask?.cancel()
        _ = pasteboard.clearContents()
        guard pasteboard.setString(command, forType: .string) else {
            copiedCommand = nil
            failedValue = command
            let message = "Could not copy \(label.lowercased())"
            copyError = message
            AccessibilityNotification.Announcement(message).post()
            return false
        }
        copyError = nil
        failedValue = nil
        copiedCommand = command
        AccessibilityNotification.Announcement("\(label) copied").post()
        resetTask = Task { [weak self] in
            do { try await Task.sleep(for: .milliseconds(1200)) }
            catch { return }
            self?.copiedCommand = nil
        }
        return true
    }

    func error(for value: String) -> String? {
        failedValue == value ? copyError : nil
    }
}
