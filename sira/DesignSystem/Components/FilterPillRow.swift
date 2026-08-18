import SwiftUI

/// A row of standalone capsule pills, one per option — Home's Active/All/Archived
/// filter. Unlike `PillTrack`, each pill is independently shaped rather than
/// sliding within a shared track.
struct FilterPillRow<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 5) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .siraStyle(.monoLabel)
                        .tracking(0.5)
                        .fixedSize()
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                }
                .foregroundStyle(isSelected ? theme.background : theme.ink.opacity(0.65))
                .background(isSelected ? theme.ink : theme.track, in: Capsule())
            }
        }
        .buttonStyle(.plain)
    }
}

#Preview("FilterPillRow") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            FilterPillRowPreview()
                .padding()
                .background(theme.background)
                .environment(\.theme, theme)
        }
    }
}

private struct FilterPillRowPreview: View {
    @State private var selection = "Active"

    var body: some View {
        FilterPillRow(options: ["Active", "All", "Archived"], label: { $0 }, selection: $selection)
    }
}
