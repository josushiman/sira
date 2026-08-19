import SwiftUI

/// The screen-header button that returns to Home, taking the Back button's
/// slot and geometry on Play once a Match is under way. Back would step into
/// the Setup screen that created the Match, which is not where anyone wants
/// to be after playing a Round.
struct HomeButton: View {
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Image(systemName: "house.fill")
                .font(.system(size: 16, weight: .semibold))
                .frame(width: 44, height: 44)
                .contentShape(Circle())
        }
        .background(theme.surface, in: Circle())
        .overlay { Circle().stroke(theme.line, lineWidth: 1) }
        .foregroundStyle(theme.ink)
        .buttonStyle(.plain)
        .accessibilityLabel("Home")
    }
}

#Preview("HomeButton") {
    HStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            HomeButton(action: {})
                .padding()
                .background(theme.background)
                .environment(\.theme, theme)
        }
    }
}
