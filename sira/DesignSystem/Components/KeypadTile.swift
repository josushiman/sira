import SwiftUI

/// A single round-entry keypad key. Digits render as filled mono tiles;
/// `C`/`⌫` render as plain display-weight text over no fill, matching the
/// prototype's distinction between numeric and control keys.
struct KeypadTile: View {
    let label: String
    var isControl: Bool = false
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(label)
                .font(isControl ? .sira(.subheadline) : .sira(.monoValue))
                .frame(maxWidth: .infinity)
                .frame(height: 52)
                .contentShape(RoundedRectangle(cornerRadius: 15, style: .continuous))
        }
        .foregroundStyle(isControl ? theme.ink.opacity(0.55) : theme.ink)
        .background {
            if !isControl {
                RoundedRectangle(cornerRadius: 15, style: .continuous)
                    .fill(theme.surface)
                    .shadow(color: .black.opacity(0.1), radius: 0, y: 1)
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("KeypadTile") {
    let keys = ["1", "2", "3", "4", "5", "6", "7", "8", "9", "C", "0", "⌫"]
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 7), count: 3), spacing: 7) {
                ForEach(keys, id: \.self) { key in
                    KeypadTile(label: key, isControl: key == "C" || key == "⌫") {}
                }
            }
            .padding()
            .background(theme.track)
            .environment(\.theme, theme)
        }
    }
    .padding()
}
