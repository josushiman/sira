import SwiftUI

/// The Okey Round-entry screen. Everything this Round records is a
/// question about *who*, so all three choices take the same shape — the
/// losing-team choice as two full-width team cards (checkmark on the winner),
/// then who found the Gösterge and who called Çifte as rows of team chips.
/// Pushed full-screen from Play with the prototype's Cancel/Save top bar,
/// matching the keypad Round entry screen's chrome (`docs/adr/0003`).
///
/// There is one Gösterge per Round, so finding it is a single pick — tapping
/// the picked team again clears it back to nobody. Çifte is a multi-pick,
/// because both teams can call it in the same Round; it doubles the loss only
/// once however many called, so the chips record who did it rather than change
/// the arithmetic. Okey atmak stays Round-level: doing it *is* winning the
/// Round, so the winning team is the Okey atan by construction. Either
/// modifier alone doubles the loss to −4, both together take it to −8, and
/// neither ever touches the Gösterge deduction.
struct OkeyStandardRoundEntryView: View {
    let entrants: [Entrant]
    /// This round's number, shown in the top bar ("Round 3").
    let roundNumber: Int
    let onSave: (_ losingEntrantID: Entrant.ID?, _ gostergeFinderID: Entrant.ID?, _ cifteCallers: Set<Entrant.ID>, _ okeyAtti: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var losingEntrantID: Entrant.ID?
    @State private var gostergeFinderID: Entrant.ID?
    @State private var cifteCallers: Set<Entrant.ID>
    @State private var okeyAttiOn: Bool

    /// - Parameters:
    ///   - losingEntrantID, gostergeFinderID, cifteCallers, okeyAttiOn: Seed the
    ///     screen's interactive state directly — used by snapshot tests to
    ///     capture a specific in-progress state without driving the view
    ///     through taps. Production callers omit them and get nothing selected.
    init(
        entrants: [Entrant],
        roundNumber: Int,
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinderID: Entrant.ID? = nil,
        cifteCallers: Set<Entrant.ID> = [],
        okeyAttiOn: Bool = false,
        onSave: @escaping (_ losingEntrantID: Entrant.ID?, _ gostergeFinderID: Entrant.ID?, _ cifteCallers: Set<Entrant.ID>, _ okeyAtti: Bool) -> Void
    ) {
        self.entrants = entrants
        self.roundNumber = roundNumber
        self.onSave = onSave
        _losingEntrantID = State(initialValue: losingEntrantID)
        _gostergeFinderID = State(initialValue: gostergeFinderID)
        _cifteCallers = State(initialValue: cifteCallers)
        _okeyAttiOn = State(initialValue: okeyAttiOn)
    }

    private var isReadyToSave: Bool { losingEntrantID != nil }

    var body: some View {
        VStack(spacing: 0) {
            EntryTopBar(
                roundNumber: roundNumber,
                isReadyToSave: isReadyToSave,
                onCancel: { dismiss() },
                onSave: save
            )

            ScrollView {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Who won the round?")
                        .siraStyle(.displayTitle)
                    Text("First team to 0 loses.")
                        .siraStyle(.body)
                        .foregroundStyle(theme.ink.opacity(0.55))
                }
                .padding(.top, 16)
                .frame(maxWidth: .infinity, alignment: .leading)

                VStack(spacing: 10) {
                    ForEach(entrants) { entrant in
                        TeamPickCard(
                            entrant: entrant,
                            badgeIndex: badgeIndex(for: entrant.id),
                            otherName: otherEntrant(for: entrant)?.name,
                            isWinner: isWinner(entrant),
                            penalty: penalty
                        ) {
                            pickWinner(entrant)
                        }
                    }
                }
                .padding(.top, 18)

                TeamPickSection(
                    title: "Who found the G\u{f6}sterge?",
                    note: "One per round \u{2014} takes 1 off the other team.",
                    entrants: entrants,
                    isPicked: { $0 == gostergeFinderID },
                    onPick: pickGostergeFinder
                )
                .padding(.top, 24)

                TeamPickSection(
                    title: "Who called \u{c7}ifte?",
                    note: "Either team, or both \u{2014} it doubles the round once.",
                    entrants: entrants,
                    isPicked: cifteCallers.contains,
                    onPick: toggleCifteCaller
                )
                .padding(.top, 14)

                modifierChips
                    .padding(.top, 18)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 34)
        }
        .background(theme.background)
        .foregroundStyle(theme.ink)
        // EntryTopBar already offers the only two ways out of Round entry —
        // Cancel and Save — so the system chevron above it was a third,
        // unlabelled one. Every other screen hides the bar the same way.
        .toolbar(.hidden, for: .navigationBar)
    }

    /// Okey atmak — the one modifier that isn't a question about who, since
    /// the winning team is the Okey atan by construction — with the number the
    /// Round now produces spelled out underneath. Çifte and Okey atmak each
    /// double the loss on their own, so neither can be read back off the score
    /// and the player shouldn't have to work out whether they're looking at −4
    /// or −8.
    private var modifierChips: some View {
        VStack(alignment: .leading, spacing: 9) {
            // This is an Okey Variant, so the label is always Okey's.
            EntryChip(label: Game.okey.okeyAtmakLabel, isOn: okeyAttiOn) {
                okeyAttiOn.toggle()
            }
            Text(consequence)
                .siraStyle(.body)
                .foregroundStyle(theme.ink.opacity(0.55))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    /// What the losing team actually drops this Round, modifiers included —
    /// the same 2 the Engine starts from, scaled the same way. Gösterge finds
    /// are absent because the doubling never reaches them.
    private var penalty: Int {
        2 * (cifteCallers.isEmpty ? 1 : 2) * (okeyAttiOn ? 2 : 1)
    }

    /// Why the number on the cards is what it is. Neither modifier can be read
    /// back off the score — each alone produces the same −4 — so the line names
    /// the event rather than only its size.
    private var consequence: String {
        let drop = "the losing team drops \(penalty)"
        switch (!cifteCallers.isEmpty, okeyAttiOn) {
        case (false, false):
            return "Either one doubles the round."
        case (true, false):
            return "\u{c7}ifte doubles it \u{2014} \(drop)."
        case (false, true):
            return "Okey att\u{131} doubles it \u{2014} \(drop)."
        case (true, true):
            return "Both double it \u{2014} \(drop)."
        }
    }

    private func badgeIndex(for id: Entrant.ID) -> Int {
        entrants.firstIndex { $0.id == id } ?? 0
    }

    /// The other team in this two-team Elimination Match — Okey is
    /// always exactly two Entrants (Teams of 2), so "the other one" is
    /// unambiguous, matching the prototype's team-pick model.
    private func otherEntrant(for entrant: Entrant) -> Entrant? {
        entrants.first { $0.id != entrant.id }
    }

    /// A card reads as the winner when the *other* Entrant is the recorded
    /// loser — tapping a card picks that Entrant as the winner by setting
    /// `losingEntrantID` to the other team, mirroring the prototype's
    /// "{team} won" framing.
    private func isWinner(_ entrant: Entrant) -> Bool {
        guard let losingEntrantID else { return false }
        return losingEntrantID == otherEntrant(for: entrant)?.id
    }

    private func pickWinner(_ winner: Entrant) {
        losingEntrantID = otherEntrant(for: winner)?.id ?? winner.id
    }

    /// One Gösterge per Round means picking a team replaces whoever was there;
    /// tapping the picked team again is how "nobody found it" is expressed,
    /// since that is also where the Round starts.
    private func pickGostergeFinder(_ id: Entrant.ID) {
        gostergeFinderID = gostergeFinderID == id ? nil : id
    }

    private func toggleCifteCaller(_ id: Entrant.ID) {
        if cifteCallers.contains(id) {
            cifteCallers.remove(id)
        } else {
            cifteCallers.insert(id)
        }
    }

    private func save() {
        guard isReadyToSave else { return }
        onSave(losingEntrantID, gostergeFinderID, cifteCallers, okeyAttiOn)
    }
}

/// One team-pick card: dot badge, "{team} won", a sub-line naming the
/// consequence, and a checkmark on the selected (winning) card. Selecting a
/// card inverts it to the ink/background pairing, matching the prototype.
private struct TeamPickCard: View {
    let entrant: Entrant
    let badgeIndex: Int
    let otherName: String?
    let isWinner: Bool
    /// What the losing team drops this Round, already scaled by whichever
    /// modifiers are on, so the card never disagrees with the chips below it.
    let penalty: Int
    let onTap: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 13) {
                DotBadge(text: entrant.initial, index: badgeIndex, size: 38)

                VStack(alignment: .leading, spacing: 4) {
                    Text("\(entrant.name) won")
                        .siraStyle(.headline)
                        .lineLimit(1)
                    Text(subtitle)
                        .siraStyle(.body)
                        .opacity(0.6)
                }

                Spacer(minLength: 0)

                checkmark
            }
            .padding(.horizontal, 19)
            .padding(.vertical, 17)
            .background {
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(isWinner ? theme.ink : theme.surface)
            }
            .overlay {
                if !isWinner {
                    RoundedRectangle(cornerRadius: 22, style: .continuous)
                        .stroke(theme.line, lineWidth: 1)
                }
            }
        }
        .foregroundStyle(isWinner ? theme.background : theme.ink)
        .buttonStyle(.plain)
    }

    private var subtitle: String {
        guard let otherName, isWinner else { return "the other side drops \(penalty)" }
        return "\(otherName) drops \(penalty)"
    }

    private var checkmark: some View {
        ZStack {
            Circle()
                .fill(isWinner ? theme.accent : Color.clear)
                .overlay {
                    if !isWinner {
                        Circle().stroke(theme.line, lineWidth: 1)
                    }
                }
            if isWinner {
                Text("\u{2713}")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(theme.onAccent)
            }
        }
        .frame(width: 24, height: 24)
    }
}

/// A carded "which team did this?" question: a heading, a note naming what
/// the answer costs, and one chip per team. Single- or multi-pick is the
/// caller's business — the section only reports taps and draws whatever
/// `isPicked` says, so the Gösterge (one team at most) and Çifte (both teams
/// allowed) questions read identically to the player.
private struct TeamPickSection: View {
    let title: String
    let note: String
    let entrants: [Entrant]
    let isPicked: (Entrant.ID) -> Bool
    let onPick: (Entrant.ID) -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        CardSurface(cornerRadius: 22, padding: 19) {
            VStack(alignment: .leading, spacing: 15) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .siraStyle(.headline)
                    Text(note)
                        .siraStyle(.body)
                        .foregroundStyle(theme.ink.opacity(0.55))
                }

                HStack(spacing: 7) {
                    ForEach(entrants) { entrant in
                        EntryChip(label: entrant.name, isOn: isPicked(entrant.id)) {
                            onPick(entrant.id)
                        }
                    }
                    Spacer(minLength: 0)
                }
            }
        }
    }
}

#Preview("No team selected") {
    let a = Entrant(name: "Ekrem & Su")
    let b = Entrant(name: "Ada & Barış")
    return OkeyStandardRoundEntryView(entrants: [a, b], roundNumber: 3) { _, _, _, _ in }
        .themed()
}

#Preview("Team selected, Gösterge, both modifiers") {
    let a = Entrant(name: "Ekrem & Su")
    let b = Entrant(name: "Ada & Barış")
    return OkeyStandardRoundEntryView(
        entrants: [a, b],
        roundNumber: 3,
        losingEntrantID: b.id,
        gostergeFinderID: a.id,
        cifteCallers: [a.id, b.id],
        okeyAttiOn: true
    ) { _, _, _, _ in }
    .themed()
}
