import SwiftUI

/// A row of tappable chips — used for entrant/round counts and, later,
/// round-entry quick-entry shortcuts. Selected chips invert to the ink color;
/// unselected chips sit on the surface with a hairline border.
struct ChipSelector<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .siraStyle(.monoValue)
                        .frame(minWidth: 52)
                        .padding(.horizontal, 16)
                        .frame(height: 46)
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
        .buttonStyle(.plain)
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
