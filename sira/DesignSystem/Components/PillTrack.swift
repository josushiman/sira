import SwiftUI

/// A two-option sliding-highlight tab track (Players/Teams, Standings/Scoresheet).
/// The selected option sits on the surface color with a soft shadow; the rest
/// sit directly on the track background.
struct PillTrack<Option: Hashable>: View {
    let options: [Option]
    let label: (Option) -> String
    @Binding var selection: Option

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 6) {
            ForEach(options, id: \.self) { option in
                let isSelected = option == selection
                Button {
                    selection = option
                } label: {
                    Text(label(option))
                        .siraStyle(.subheadline)
                        .fontWeight(isSelected ? .semibold : .medium)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .foregroundStyle(isSelected ? theme.ink : theme.ink.opacity(0.5))
                .background {
                    if isSelected {
                        RoundedRectangle(cornerRadius: 10, style: .continuous)
                            .fill(theme.surface)
                            .shadow(color: .black.opacity(0.08), radius: 1, y: 1)
                    }
                }
                .contentShape(Rectangle())
            }
        }
        .padding(4)
        .background(theme.track, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
        .buttonStyle(.plain)
        .animation(.easeOut(duration: 0.15), value: selection)
    }
}

#Preview("PillTrack") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            PillTrackPreview()
                .padding()
                .background(theme.background)
                .environment(\.theme, theme)
        }
    }
}

private struct PillTrackPreview: View {
    @State private var selection = "Players"

    var body: some View {
        PillTrack(options: ["Players", "Teams of 2"], label: { $0 }, selection: $selection)
    }
}
