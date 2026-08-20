import SwiftUI

/// The Round-entry screen's shared top bar — Cancel, "Round N", and a Save
/// button that dims until the screen's own ready-to-save check passes. Used
/// by both the keypad (Survival/Fixed Rounds) and Okey 21 entry
/// screens so neither re-implements the same chrome (`docs/adr/0003`).
struct EntryTopBar: View {
    let roundNumber: Int
    let isReadyToSave: Bool
    let onCancel: () -> Void
    let onSave: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack {
            Button("Cancel", action: onCancel)
                .foregroundStyle(theme.ink.opacity(0.55))
                .font(.sira(.subheadline))

            Spacer()

            Text(sira: .monoEyebrow, "Round \(roundNumber)")
                .foregroundStyle(theme.ink.opacity(0.5))

            Spacer()

            Button("Save", action: onSave)
                .foregroundStyle(isReadyToSave ? theme.accent : theme.ink.opacity(0.35))
                .font(.sira(.subheadline))
                .fontWeight(.semibold)
                .disabled(!isReadyToSave)
        }
        .buttonStyle(.plain)
        .padding(.horizontal, 22)
        .padding(.top, 6)
    }
}

#Preview("EntryTopBar") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            VStack(spacing: 16) {
                EntryTopBar(roundNumber: 3, isReadyToSave: false, onCancel: {}, onSave: {})
                EntryTopBar(roundNumber: 3, isReadyToSave: true, onCancel: {}, onSave: {})
            }
            .padding(.vertical)
            .background(theme.background)
            .environment(\.theme, theme)
        }
    }
}
