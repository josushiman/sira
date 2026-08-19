import SwiftUI

/// The Okey-standard Round-entry screen: the losing-team choice renders as
/// two full-width team cards (checkmark on the winner), and Gösterge finds
/// render as a per-team `–`/count/`+` stepper row. Pushed full-screen from
/// Play with the prototype's Cancel/Save top bar, matching the keypad Round
/// entry screen's chrome (`docs/adr/0003`).
///
/// Both Round modifiers are Round-level here rather than per-Entrant: with a
/// single loser, Çifte's two branches collapse onto the same team, and Okey
/// atmak is winning the Round, so the winning team is the Okey atan by
/// construction. Either modifier alone doubles the loss to −4; both together
/// take it to −8, and neither ever touches a Gösterge find.
struct OkeyStandardRoundEntryView: View {
    let entrants: [Entrant]
    /// This round's number, shown in the top bar ("Round 3").
    let roundNumber: Int
    let onSave: (_ losingEntrantID: Entrant.ID?, _ gostergeFinds: [Entrant.ID: Int], _ cifte: Bool, _ okeyAtti: Bool) -> Void

    @Environment(\.dismiss) private var dismiss
    @Environment(\.theme) private var theme
    @State private var losingEntrantID: Entrant.ID?
    @State private var gostergeFinds: [Entrant.ID: Int]
    @State private var cifteOn: Bool
    @State private var okeyAttiOn: Bool

    /// - Parameters:
    ///   - losingEntrantID, gostergeFinds, cifteOn, okeyAttiOn: Seed the screen's interactive
    ///     state directly — used by snapshot tests to capture a specific
    ///     in-progress state without driving the view through taps.
    ///     Production callers omit them and get nothing selected.
    init(
        entrants: [Entrant],
        roundNumber: Int,
        losingEntrantID: Entrant.ID? = nil,
        gostergeFinds: [Entrant.ID: Int] = [:],
        cifteOn: Bool = false,
        okeyAttiOn: Bool = false,
        onSave: @escaping (_ losingEntrantID: Entrant.ID?, _ gostergeFinds: [Entrant.ID: Int], _ cifte: Bool, _ okeyAtti: Bool) -> Void
    ) {
        self.entrants = entrants
        self.roundNumber = roundNumber
        self.onSave = onSave
        _losingEntrantID = State(initialValue: losingEntrantID)
        _gostergeFinds = State(initialValue: gostergeFinds)
        _cifteOn = State(initialValue: cifteOn)
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

                CardSurface(cornerRadius: 22, padding: 19) {
                    VStack(alignment: .leading, spacing: 15) {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("Gösterge found")
                                .siraStyle(.headline)
                            Text("Each find takes 1 off the other team.")
                                .siraStyle(.body)
                                .foregroundStyle(theme.ink.opacity(0.55))
                        }

                        VStack(spacing: 10) {
                            ForEach(entrants) { entrant in
                                GostergeStepperRow(
                                    name: entrant.name,
                                    count: gostergeFinds[entrant.id] ?? 0,
                                    onDecrement: { adjustGosterge(entrant.id, by: -1) },
                                    onIncrement: { adjustGosterge(entrant.id, by: 1) }
                                )
                            }
                        }
                    }
                }
                .padding(.top, 24)

                modifierChips
                    .padding(.top, 18)
            }
            .padding(.horizontal, 22)
            .padding(.bottom, 34)
        }
        .background(theme.background)
        .foregroundStyle(theme.ink)
    }

    /// The two Round modifiers, with the number they produce spelled out
    /// underneath — either one alone doubles the loss, so the chips can't be
    /// told apart by their effect and the player shouldn't have to work out
    /// whether they're looking at −4 or −8.
    private var modifierChips: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack(spacing: 7) {
                EntryChip(label: "\u{c7}ifte", isOn: cifteOn) {
                    cifteOn.toggle()
                }
                // Okey 21 is an Okey Variant, so the label is always Okey's.
                EntryChip(label: Game.okey.okeyAtmakLabel, isOn: okeyAttiOn) {
                    okeyAttiOn.toggle()
                }
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
        2 * (cifteOn ? 2 : 1) * (okeyAttiOn ? 2 : 1)
    }

    /// Why the number on the cards is what it is. Neither chip can be read off
    /// the score — each alone produces the same −4 — so the line names the
    /// event rather than only its size.
    private var consequence: String {
        let drop = "the losing team drops \(penalty)"
        switch (cifteOn, okeyAttiOn) {
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

    /// The other team in this two-team Elimination Match — Okey standard is
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

    private func adjustGosterge(_ id: Entrant.ID, by delta: Int) {
        let current = gostergeFinds[id] ?? 0
        gostergeFinds[id] = max(0, min(1, current + delta))
    }

    private func save() {
        guard isReadyToSave else { return }
        onSave(losingEntrantID, gostergeFinds, cifteOn, okeyAttiOn)
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

/// A per-team Gösterge count: name, then a `–`/count/`+` stepper on a track
/// pill — the prototype's stepper row in place of a native `Stepper`.
private struct GostergeStepperRow: View {
    let name: String
    let count: Int
    let onDecrement: () -> Void
    let onIncrement: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        HStack(spacing: 12) {
            Text(name)
                .siraStyle(.subheadline)
                .lineLimit(1)

            Spacer(minLength: 0)

            HStack(spacing: 12) {
                StepButton(label: "\u{2013}", action: onDecrement)
                Text("\(count)")
                    .siraStyle(.monoValue)
                    .frame(minWidth: 16)
                    .multilineTextAlignment(.center)
                StepButton(label: "+", action: onIncrement)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 5)
            .background(theme.track, in: Capsule())
        }
    }
}

private struct StepButton: View {
    let label: String
    let action: () -> Void

    @Environment(\.theme) private var theme

    var body: some View {
        Button(action: action) {
            Text(label)
                .siraStyle(.subheadline)
                .frame(width: 30, height: 30)
                .contentShape(Circle())
        }
        .foregroundStyle(theme.ink)
        .background(theme.surface, in: Circle())
        .overlay { Circle().stroke(theme.line, lineWidth: 1) }
        .buttonStyle(.plain)
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
        gostergeFinds: [a.id: 1],
        cifteOn: true,
        okeyAttiOn: true
    ) { _, _, _, _ in }
    .themed()
}
