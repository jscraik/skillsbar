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
        .frame(width: 23, height: 23)
        .frame(width: 23, height: 23, alignment: .center)
        .contentShape(Rectangle())
    }
}
