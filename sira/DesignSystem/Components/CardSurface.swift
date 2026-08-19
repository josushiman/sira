import SwiftUI

/// The prototype's rounded, bordered surface container used for card rows
/// throughout the app: Home's Match list, the Variant picker, name-entry
/// rows, and standings rows.
struct CardSurface<Content: View>: View {
    var cornerRadius: CGFloat = 22
    var padding: CGFloat = 17
    @ViewBuilder var content: Content

    @Environment(\.theme) private var theme

    var body: some View {
        content
            .padding(padding)
            .background(theme.surface, in: RoundedRectangle(cornerRadius: cornerRadius, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(theme.line, lineWidth: 1)
            }
    }
}

/// A horizontal dashed rule — the divider between a Match card's header and
/// its leader/result line.
struct DashedDivider: View {
    var color: Color?

    @Environment(\.theme) private var theme

    var body: some View {
        GeometryReader { geo in
            Path { path in
                path.move(to: CGPoint(x: 0, y: geo.size.height / 2))
                path.addLine(to: CGPoint(x: geo.size.width, y: geo.size.height / 2))
            }
            .stroke(color ?? theme.line, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
        }
        .frame(height: 1)
    }
}

/// A small rounded status pill — "ROUND 3", "FINISHED", "ARCHIVED", "LEADS", "OUT".
struct StatusPill: View {
    let text: String
    var foreground: Color
    var background: Color
    /// Tighter tracking and padding, for rows that carry several pills at once
    /// (Home's Match cards) rather than a single one.
    var compact: Bool = false

    var body: some View {
        label
            .foregroundStyle(foreground)
            .padding(.horizontal, compact ? 4 : 6)
            .padding(.vertical, 3)
            .background(background, in: RoundedRectangle(cornerRadius: 5, style: .continuous))
    }

    /// `compact` overrides `monoTag`'s tracking, which is why the Text is built
    /// here rather than inline — `.tracking` has to come after `siraStyle`.
    private var label: Text {
        let text = Text(sira: .monoTag, text)
        return compact ? text.tracking(0.5) : text
    }
}

#Preview("CardSurface") {
    VStack(spacing: 24) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            VStack(alignment: .leading, spacing: 14) {
                CardSurface {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Gonga 151")
                            StatusPill(text: "Round 3", foreground: theme.onAccent, background: theme.accent)
                        }
                        DashedDivider()
                        Text("Leading: Ali on 34")
                    }
                }
            }
            .padding()
            .background(theme.background)
            .environment(\.theme, theme)
        }
    }
}
