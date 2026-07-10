import SwiftUI

struct SkillsMenuBarIconView: View {
    var body: some View {
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
        .frame(width: 18, height: 18, alignment: .center)
        .contentShape(Rectangle())
    }
}
