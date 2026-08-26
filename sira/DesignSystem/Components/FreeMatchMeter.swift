import SwiftUI

/// The free-game meter beside Home's "Your games" heading: three marks that
/// fill as Free Matches are consumed, and a label naming what they mean.
///
/// The label is not decoration. Three marks alone are a shape the player has
/// to guess at the first time they see them, and a panel big enough to explain
/// itself would dominate a heading row — so the marks carry the count at a
/// glance and the label says what is being counted. The treatment is the one
/// resolved in the Claude Design project ("Paywall", turn 2), not one invented
/// here.
///
/// Marks, never "pips" or "dots": `Theme.pip` is the playing-card pip colour
/// and `Theme.dots` is the Entrant badge palette. This is neither, and naming
/// it after either would send the next reader to the wrong place.
struct FreeMatchMeter: View {
    let freeMatches: FreeMatches

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 7) {
            HStack(spacing: 4) {
                ForEach(0..<FreeMatches.allowance, id: \.self) { index in
                    mark(filled: index < freeMatches.used)
                }
            }
            Text(sira: .monoTag, label)
                .foregroundStyle(labelColor)
                .fixedSize()
        }
        // One element rather than four: read out, the marks are silence and
        // the label is a fragment, and "one of three free games left" is the
        // whole of what this row says. "Games", not "Matches" — Home's own
        // word for them.
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(freeMatches.remaining) of \(FreeMatches.allowance) free games left")
    }

    private var label: String { "\(freeMatches.remaining) free left" }

    /// Muted while there is something left, and the accent colour once there
    /// is not — the one change the meter makes on reaching the limit. Nothing
    /// else about it moves and no panel appears: the player has watched this
    /// fill for three games, and the wall in ticket 03 is what has something
    /// to say about it.
    private var labelColor: Color {
        freeMatches.isExhausted ? theme.accent : theme.ink.opacity(0.45)
    }

    @ViewBuilder
    private func mark(filled: Bool) -> some View {
        let shape = RoundedRectangle(cornerRadius: 2.5, style: .continuous)
        if filled {
            shape.fill(theme.accent).frame(width: 8, height: 8)
        } else {
            shape.stroke(theme.ink.opacity(0.34), lineWidth: 1).frame(width: 8, height: 8)
        }
    }
}

#Preview("FreeMatchMeter") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            VStack(alignment: .leading, spacing: 12) {
                ForEach(0...FreeMatches.allowance, id: \.self) { used in
                    FreeMatchMeter(freeMatches: FreeMatches(startedMatches: used))
                }
            }
            .padding()
            .background(theme.background)
            .environment(\.theme, theme)
        }
    }
    .padding()
}
