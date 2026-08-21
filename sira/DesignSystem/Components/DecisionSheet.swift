import SwiftUI

/// A sheet that puts one decision to the player and waits: the Rejoin offer,
/// the delete confirmation. Title, a line saying what the decision means, and
/// the actions stacked beneath it, on the app's own slide-up surface.
///
/// Presentation stays native — this is the content of a `.sheet`, not a
/// mechanism of its own (`docs/adr/0003`). What it owns is the shape both
/// decisions share, so a second one cannot drift a detent or a spacing away
/// from the first.
struct DecisionSheet<Actions: View>: View {
    let title: String
    /// What saying yes means, in a sentence. The sheets that use this are
    /// asking about things that cannot be taken back, so this line is the one
    /// doing the real work.
    let explanation: String
    @ViewBuilder var actions: Actions

    @Environment(\.theme) private var theme

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 0)
            bottomSheet
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.clear)
    }

    private var bottomSheet: some View {
        BottomSheetContent {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .siraStyle(.displayTitle)
                Text(explanation)
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))

                VStack(spacing: 9) {
                    actions
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

/// One of a `DecisionSheet`'s stacked actions: full width, tall enough to hit
/// without looking, and filled or outlined according to whether it is the
/// thing the sheet is asking about or the way back out of it.
struct SheetButton: View {
    let title: String
    let emphasis: Emphasis
    let action: () -> Void

    @Environment(\.theme) private var theme

    enum Emphasis {
        /// The action the sheet exists to offer. Its colours are the caller's
        /// to give, because what "the action" means differs: accepting a
        /// Rejoin is ordinary and wears the theme's ink, deleting a Match is
        /// not and wears the palette's one warning colour.
        case filled(background: Color, foreground: Color)
        /// The way out — declining, cancelling, keeping things as they are.
        case outlined
    }

    var body: some View {
        Button(action: action) {
            label
        }
        .buttonStyle(.plain)
    }

    @ViewBuilder
    private var label: some View {
        switch emphasis {
        case let .filled(background, foreground):
            text
                .fontWeight(.semibold)
                .foregroundStyle(foreground)
                .background(background, in: RoundedRectangle(cornerRadius: 17, style: .continuous))
        case .outlined:
            text
                .foregroundStyle(theme.ink.opacity(0.75))
                .overlay {
                    RoundedRectangle(cornerRadius: 17, style: .continuous)
                        .stroke(theme.line, lineWidth: 1)
                }
        }
    }

    private var text: some View {
        Text(title)
            .siraStyle(.subheadline)
            .frame(maxWidth: .infinity)
            .frame(height: 52)
            .contentShape(RoundedRectangle(cornerRadius: 17, style: .continuous))
    }
}

#Preview("DecisionSheet") {
    VStack(spacing: 0) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            DecisionSheet(
                title: "Delete this Match?",
                explanation: "14th March 2026 · 9pm, its players and all 6 Rounds played will be deleted for good. There is no undo."
            ) {
                SheetButton(title: "Delete Match", emphasis: .filled(background: theme.pip, foreground: .white)) {}
                SheetButton(title: "Keep it", emphasis: .outlined) {}
            }
            .environment(\.theme, theme)
        }
    }
}
