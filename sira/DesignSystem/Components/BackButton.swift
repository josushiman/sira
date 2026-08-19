import SwiftUI

/// The screen-header back button shared by Setup, the Variant picker, and
/// Play. A 44×44 tap target (Apple's minimum) with an SF Symbol chevron —
/// larger and crisper than the old 34×34 circle with a literal "‹" glyph,
/// which read as small and hard to make out.
struct BackButton: View {
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: "chevron.left")
                .font(.system(size: 17, weight: .semibold))
        }
        .frame(width: 44, height: 44)
        .background(theme.surface, in: Circle())
        .overlay { Circle().stroke(theme.line, lineWidth: 1) }
        .foregroundStyle(theme.ink)
        .contentShape(Circle())
        .buttonStyle(.plain)
    }
}

#Preview("BackButton") {
    HStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            BackButton(action: {})
                .padding()
                .background(theme.background)
                .environment(\.theme, theme)
        }
    }
}
