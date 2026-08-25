import SwiftUI

/// Bringing someone into a Match already being played, opened by tapping the
/// Add row at the foot of Standings.
///
/// Deliberately the rename sheet's twin: the same field, the same badge over
/// the name that would be saved, the same rejection read back under it. The
/// two are the same act on the same list — one relabels a seat, one fills a
/// free one — and a player who has met either should recognise the other.
///
/// The name is judged by `EntrantName`, exactly as Rename's is, so the two
/// paths cannot drift on what counts as a duplicate or on what a blank field
/// becomes. What differs is only what is being named: an Entrant not in the
/// Match yet, so nobody is exempt from the duplicate check, and the seat the
/// fallback is numbered from is the free one rather than one already sat in.
struct AddEntrantSheet: View {
    /// The free seat and the total whoever takes it enters on, derived by the
    /// screen at render time and handed over — this sheet states the offer, it
    /// does not decide it.
    let addition: RosterAddition
    /// The Match's Entrants as they stand. Nobody is being renamed, so nobody
    /// is exempt: a name already on the table is a clash however it got there.
    let entrants: [Entrant]
    /// Whether this Match is played by players or teams. Every "player" and
    /// "team" here comes from the mode rather than the Game, because the mode
    /// is what is actually true of the Entrants.
    let mode: EntrantMode
    let onAdd: (String) -> Void

    /// What is in the field. Starts empty: nobody has a name yet to correct,
    /// and an empty field is a legal answer — it materialises the seat's own
    /// fallback.
    @State private var typed: String

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme

    /// `initialName` seeds the field mid-edit, so a snapshot can be taken of a
    /// refused name without a test having to type its way there — the same
    /// seam `RenameEntrantSheet` and `SetupView` open for the same reason.
    init(
        addition: RosterAddition,
        entrants: [Entrant],
        mode: EntrantMode,
        initialName: String = "",
        onAdd: @escaping (String) -> Void
    ) {
        self.addition = addition
        self.entrants = entrants
        self.mode = mode
        self.onAdd = onAdd
        _typed = State(initialValue: initialName)
    }

    /// The name in the field, as the Match will judge it. Seated at the free
    /// seat, so an empty field falls back to that seat's name rather than to a
    /// row number — and `renaming` is `nil`, because there is no incumbent to
    /// excuse from the duplicate check.
    private var candidate: EntrantName {
        EntrantName(typed, seat: addition.seat, mode: mode)
    }

    private var resolution: EntrantName.Resolution {
        candidate.resolved(against: entrants)
    }

    var body: some View {
        DecisionSheet(
            title: "Add a \(mode.entrantNoun)",
            explanation: "They start on \(addition.total) — the highest score still on the table — and are scored from this Round on. Rounds already played show a dash for them.",
            prompt: { nameField },
            actions: {
                SheetButton(
                    title: "Add on \(addition.total)",
                    emphasis: .filled(
                        background: theme.ink.opacity(resolution.name == nil ? 0.3 : 1),
                        foreground: theme.background
                    )
                ) {
                    add()
                }
                .disabled(resolution.name == nil)

                SheetButton(title: "Cancel", emphasis: .outlined) {
                    dismiss()
                }
            }
        )
    }

    /// The field, and under it the reason the tap that is about to fail will
    /// fail — said once, where the rename sheet says it.
    private var nameField: some View {
        VStack(alignment: .leading, spacing: 8) {
            CardSurface(cornerRadius: 16, padding: 12) {
                HStack(spacing: 12) {
                    // The badge already wears the free seat's colour, so what
                    // the sheet shows is the dot that is about to appear in
                    // the list — and it carries the initial of the name that
                    // would be saved, which for an untouched field is the
                    // fallback's.
                    DotBadge(
                        text: (resolution.name ?? typed).dotBadgeInitial,
                        index: addition.seat,
                        size: 32
                    )
                    TextField(candidate.fallback, text: $typed)
                        .font(.sira(.subheadline))
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .onSubmit { add() }
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
    private func add() {
        guard let name = resolution.name else { return }
        onAdd(name)
        dismiss()
    }
}

#Preview("Add") {
    let entrants = [Entrant(name: "Ali").withSequence(0), Entrant(name: "Veli").withSequence(1)]
    let match = Match(
        game: .gonga,
        variant: .gongaStandard,
        number: 101,
        mode: .players,
        entrants: entrants,
        rounds: [Round(deltas: [entrants[0].id: 61, entrants[1].id: 40])]
    )
    let addition = RosterAddition(
        match: match,
        variant: .gongaStandard,
        standings: SurvivalEngine().standings(for: match)
    )

    return VStack(spacing: 0) {
        ForEach([Theme.paper, Theme.felt], id: \.name) { theme in
            if let addition {
                AddEntrantSheet(addition: addition, entrants: match.entrants, mode: .players) { _ in }
                    .environment(\.theme, theme)
            }
        }
    }
}
