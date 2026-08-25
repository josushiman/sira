import SwiftUI

/// A sheet that puts one decision to the player and waits: the Rejoin offer,
/// the delete confirmation, the rename. Title, a line saying what the decision
/// means, whatever the player has to fill in to make it, and the actions
/// stacked beneath, on the app's own slide-up surface.
///
/// Presentation stays native — this is the content of a `.sheet`, not a
/// mechanism of its own (`docs/adr/0003`). What it owns is the shape every one
/// of them shares, so a second cannot drift a detent or a spacing away from
/// the first.
struct DecisionSheet<Prompt: View, Actions: View>: View {
    let title: String
    /// What saying yes means, in a sentence. The sheets that use this are
    /// asking about things that cannot be taken back, or that show up
    /// everywhere at once, so this line is the one doing the real work.
    let explanation: String
    /// What the player has to supply before the decision can be made — the
    /// rename's name field. Empty on the sheets that only ask yes or no, and
    /// an empty one costs nothing: a `VStack` neither draws nor spaces around
    /// an `EmptyView`.
    @ViewBuilder var prompt: Prompt
    @ViewBuilder var actions: Actions

    @Environment(\.theme) private var theme
    /// How tall the sheet's own surface turned out to be, once its wording has
    /// been laid out — see `detents`.
    @State private var surfaceHeight: CGFloat?

    var body: some View {
        bottomSheet
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.size.height
            } action: { height in
                surfaceHeight = height
            }
            .frame(maxHeight: .infinity, alignment: .bottom)
            .presentationDetents(detents)
            .presentationDragIndicator(.hidden)
            // The app's own surface rather than a clear background. What sits
            // under a sheet's clear background is the system's translucency —
            // a blurred, frozen copy of the screen behind — and any part of
            // the sheet the surface does not cover shows it: the strip below
            // the buttons that the home indicator's safe area keeps the
            // surface out of. In the shell's own colour that strip is the
            // surface, and the sheet reads as one card.
            .presentationBackground(theme.background)
    }

    /// The sheet is exactly as tall as the surface it draws, rather than a
    /// fixed fraction of the screen.
    ///
    /// A `.medium` sheet is half the screen whatever it holds, and the surface
    /// is only the bottom of that. The rest is the presentation itself, which
    /// on a clear background is the system's own translucency: half a screen
    /// of blurred, frozen Home sitting above the question, which is what made
    /// deleting a Match look broken. Sized to its surface, there is no such
    /// gap to show anything through.
    ///
    /// Measured rather than declared, because the wording is what decides it:
    /// the delete confirmation runs to three lines for a Match with Rounds and
    /// two without, and a height written down here would be wrong for one of
    /// them. `.medium` stands in for the frame or two before the first
    /// measurement arrives.
    private var detents: Set<PresentationDetent> {
        guard let surfaceHeight, surfaceHeight > 0 else { return [.medium] }
        return [.height(surfaceHeight)]
    }

    private var bottomSheet: some View {
        BottomSheetContent {
            VStack(alignment: .leading, spacing: 10) {
                Text(title)
                    .siraStyle(.displayTitle)
                Text(explanation)
                    .siraStyle(.body)
                    .foregroundStyle(theme.ink.opacity(0.6))

                // No padding of its own: a modifier on an empty prompt is a
                // layout item where there should be none, and the sheets that
                // ask only yes or no must lay out exactly as they did before
                // this slot existed.
                prompt

                VStack(spacing: 9) {
                    actions
                }
                .padding(.top, 12)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

extension DecisionSheet where Prompt == EmptyView {
    /// A sheet that asks only yes or no, with nothing for the player to fill
    /// in — the Rejoin offer and the delete confirmation, which is how this
    /// sheet started out.
    init(title: String, explanation: String, @ViewBuilder actions: () -> Actions) {
        self.init(title: title, explanation: explanation, prompt: { EmptyView() }, actions: actions)
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
