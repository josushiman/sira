import SwiftUI

/// The prototype's slide-up sheet chrome — rounded top corners, a drag
/// handle, and the shell background — for content presented via a native
/// `.sheet(item:)` (the Rejoin offer). Presentation mechanics stay native;
/// only the visual shell is ported (`docs/adr/0003`).
struct BottomSheetContent<Content: View>: View {
    @ViewBuilder var content: Content

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Capsule()
                .fill(theme.ink.opacity(0.2))
                .frame(width: 38, height: 4)
                .padding(.top, 10)
                .padding(.bottom, 10)

            content
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 32)
        .frame(maxWidth: .infinity)
        .background(theme.background)
        .clipShape(.rect(topLeadingRadius: 28, bottomLeadingRadius: 0, bottomTrailingRadius: 0, topTrailingRadius: 28))
    }
}

#Preview("BottomSheetContent") {
    VStack(spacing: 0) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            BottomSheetContent {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Ali is out")
                        .siraStyle(.displayTitle)
                    Text("Ali passed 101 on 112. They can rejoin at the highest score still on the table.")
                        .siraStyle(.body)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .environment(\.theme, theme)
        }
    }
}
