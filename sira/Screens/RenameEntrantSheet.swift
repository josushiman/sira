import SwiftUI

/// Changing an Entrant's name mid-Match, opened by tapping their row in
/// Standings.
///
/// A relabel of a stable identity and nothing more: every screen reads a name
/// off the Entrant as it renders, so saving one moves it everywhere at once —
/// the Standings rows, Play's tiles, every Scoresheet column and the result
/// line — including on Rounds played before the rename. No total, delta, Out
/// state or Round modifier is keyed on a name, so none of them move. Nothing
/// records what the Entrant used to be called.
///
/// The name itself is judged by `EntrantName` rather than here, so that the
/// Add flow can be given the same judgement rather than its own.
struct RenameEntrantSheet: View {
    let entrant: Entrant
    /// The Match's Entrants, `entrant` included — the roster as it stands, not
    /// a pre-filtered one. Who is exempt from the duplicate check is
    /// `EntrantName`'s to decide, and it excludes the Entrant being renamed so
    /// that re-saving someone under their own name is a no-op.
    let entrants: [Entrant]
    /// Whether this Match is played by players or teams. Every "player" and
    /// "team" on this sheet comes from here rather than from the Game, because
    /// the mode is the thing that is actually true of the Entrants.
    let mode: EntrantMode
    let onSave: (String) -> Void

    /// What is in the field. Seeded from the Entrant's current name, so the
    /// common edit — a typo in an otherwise right name — starts from what is
    /// already there rather than from a blank.
    @State private var typed: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// `initialName` seeds the field mid-edit, so a snapshot can be taken of a
    /// refused name without a test having to type its way there — the same
    /// seam `SetupView` opens for the same reason.
    init(
        entrant: Entrant,
        entrants: [Entrant],
        mode: EntrantMode,
        initialName: String? = nil,
        onSave: @escaping (String) -> Void
    ) {
        self.entrant = entrant
        self.entrants = entrants
        self.mode = mode
        self.onSave = onSave
        _typed = State(initialValue: initialName ?? entrant.name)
    }

    /// The name in the field, as the Match will judge it. Seated where the
    /// Entrant already sits, so an emptied field falls back to that seat's
    /// name rather than to a row number.
    private var candidate: EntrantName {
        EntrantName(typed, seat: entrant.sequence, mode: mode, renaming: entrant.id)
    }

    private var resolution: EntrantName.Resolution {
        candidate.resolved(against: entrants)
    }

    var body: some View {
        DecisionSheet(
            title: "Rename \(entrant.name)",
            explanation: "The new name shows everywhere in this Match, including Rounds already played. Nothing this \(mode.entrantNoun) has scored changes.",
            prompt: { nameField },
            actions: {
                SheetButton(
                    title: "Save name",
                    emphasis: .filled(
                        background: theme.ink.opacity(resolution.name == nil ? 0.3 : 1),
                        foreground: theme.background
                    )
                ) {
                    save()
                }
                .disabled(resolution.name == nil)

                SheetButton(title: "Cancel", emphasis: .outlined) {
                    dismiss()
                }
            }
        )
    }

    /// The field, and — under it, where the tap that is about to fail is aimed
    /// — the reason it will not save. Said once, the way Setup says why it
    /// will not start.
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardSurface(cornerRadius: 16, padding: 12) {
                HStack(spacing: 12) {
                    // The initial of the name that would be saved, not of the
                    // characters in the field: clearing the field is not a
                    // nameless Entrant, it is `Player 3`, and the badge says
                    // `P` while the placeholder says the rest. A refused name
                    // has none to show, so the field's own initial stands in
                    // until it is fixed.
                    DotBadge(
                        text: (resolution.name ?? typed).dotBadgeInitial,
                        index: entrant.sequence,
                        size: 32
                    )
                    TextField(candidate.fallback, text: $typed)
                        .font(.sira(.subheadline))
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .onSubmit { save() }
                }
            }

            if let rejection = resolution.rejection {
                Text(rejection)
                    .siraStyle(.caption)
                    .foregroundStyle(theme.ink.opacity(0.6))
            }
        }
        .padding(.top, 6)
    }

    /// The button is disabled without a name to save, so this is the second
    /// lock rather than the first — Return in the field is the other way in,
    /// and it does not know the button is off.
    private func save() {
        guard let name = resolution.name else { return }
        onSave(name)
        dismiss()
    }
}

#Preview("Rename") {
    let entrants = [Entrant(name: "Ali").withSequence(0), Entrant(name: "Veli").withSequence(1)]

    return VStack(spacing: 0) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            RenameEntrantSheet(entrant: entrants[0], entrants: entrants, mode: .players) { _ in }
                .environment(\.theme, theme)
        }
    }
}
