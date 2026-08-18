import SwiftUI

/// A colored initial badge — used for Entrant/Game rows and standings.
/// Colored by `index` from the current theme's rotating dot palette
/// (`docs/adr/0002-two-system-driven-themes.md`).
struct DotBadge: View {
    let text: String
    let index: Int
    var size: CGFloat = 34

    @Environment(\.theme) private var theme

    var body: some View {
        Text(text)
            .font(.custom(FontFamily.display, size: size * 0.4, relativeTo: .body).weight(.semibold))
            .foregroundStyle(theme.background)
            .frame(width: size, height: size)
            .background(theme.dot(index), in: RoundedRectangle(cornerRadius: size / 3, style: .continuous))
    }
}

#Preview("DotBadge") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            HStack(spacing: 10) {
                ForEach(0..<6) { i in
                    DotBadge(text: "AZ".map(String.init)[i % 2], index: i)
                }
            }
            .padding()
            .background(theme.background)
            .environment(\.theme, theme)
        }
    }
    .padding()
}
