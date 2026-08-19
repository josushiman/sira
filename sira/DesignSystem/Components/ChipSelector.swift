import SwiftUI

/// A row of tappable chips — used for entrant/round counts and, later,
/// round-entry quick-entry shortcuts. Selected chips invert to the ink color;
/// unselected chips sit on the surface with a hairline border.
///
/// Chips wrap onto further left-aligned rows once there are more than
/// `chipsPerRow` of them, so Gonga's 2–8 player counts stay on-screen at
/// every type size instead of being squeezed into one overflowing row.
struct ChipSelector<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @Environment(\.theme) private var theme

    private let chipsPerRow = 4

    private var rows: [[Option]] {
        stride(from: 0, to: options.count, by: chipsPerRow).map { start in
            Array(options[start..<min(start + chipsPerRow, options.count)])
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { option in
                        chip(for: option)
                    }
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func chip(for option: Option) -> some View {
        let isSelected = option == selection
        return Button {
            selection = option
        } label: {
            Text(label(option))
                .siraStyle(.monoValue)
                .frame(minWidth: 52)
                .padding(.horizontal, 16)
                .frame(height: 46)
                .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .foregroundStyle(isSelected ? theme.background : theme.ink)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(isSelected ? theme.ink : theme.surface)
                .overlay {
                    if !isSelected {
                        RoundedRectangle(cornerRadius: 14, style: .continuous)
                            .stroke(theme.line, lineWidth: 1)
                    }
                }
        }
    }
}

#Preview("ChipSelector") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            ChipSelectorPreview()
                .padding()
                .background(theme.background)
                .environment(\.theme, theme)
        }
    }
}

private struct ChipSelectorPreview: View {
    @State private var selection = 4

    var body: some View {
        ChipSelector(options: [2, 3, 4], label: { String($0) }, selection: $selection)
    }
}
