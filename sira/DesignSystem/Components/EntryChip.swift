import SwiftUI

/// A Round-entry chip: either a momentary shortcut button (e.g. "Won the
/// round · 0") or, when `isOn` is driven from state, a toggle (Çifte) —
/// the prototype's filled/unfilled chip styling. Shared by the keypad and
/// Okey-standard entry screens (`docs/adr/0003`).
struct EntryChip: View {
    let label: String
    var isOn: Bool = false
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(label)
                .siraStyle(.caption)
                .padding(.horizontal, 14)
                .padding(.vertical, 11)
                .contentShape(RoundedRectangle(cornerRadius: 13, style: .continuous))
        }
        .foregroundStyle(isOn ? theme.background : theme.ink)
        .background {
            RoundedRectangle(cornerRadius: 13, style: .continuous)
                .fill(isOn ? theme.accent2 : theme.surface)
                .overlay {
                    if !isOn {
                        RoundedRectangle(cornerRadius: 13, style: .continuous)
                            .stroke(theme.line, lineWidth: 1)
                    }
                }
        }
        .buttonStyle(.plain)
    }
}

#Preview("EntryChip") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            HStack(spacing: 8) {
                EntryChip(label: "Won the round \u{b7} 0") {}
                EntryChip(label: "\u{c7}ifte \u{2014} double all \u{d7}2", isOn: true) {}
            }
            .padding()
            .background(theme.background)
            .environment(\.theme, theme)
        }
    }
}
