import SwiftUI

struct SkillsMenuBarIconView: View {
    let status: MenuBarStatus

    init(status: MenuBarStatus = .current) {
        self.status = status
    }

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            Group {
                if let image = SkillsSDKIconLoader.menuBarImage {
                    Image(nsImage: image)
                        .resizable()
                        .interpolation(.high)
                        .scaledToFit()
                } else {
                    Image(systemName: "doc.text.magnifyingglass")
                        .resizable()
                        .scaledToFit()
                        .foregroundStyle(.primary)
                }
            }
            .frame(width: 18, height: 18)

            Circle()
                .fill(status.color)
                .frame(width: 5, height: 5)
                .overlay(Circle().stroke(Color.primary.opacity(0.85), lineWidth: 1))
        }
        .frame(width: 18, height: 18)
        .frame(width: 18, height: 18, alignment: .center)
        .contentShape(Rectangle())
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skills SDK, \(status.label)")
    }
}
