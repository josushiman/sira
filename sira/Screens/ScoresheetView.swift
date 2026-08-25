import SwiftUI

/// A Round modifier as the scoresheet draws it: one icon, sitting in the
/// column of the Entrant it applied to. Okey atmak is the joker discarded to
/// finish; Çifte is the pair — two cards, and the doubling they stand for.
enum RoundModifierMark: String, Identifiable, CaseIterable {
    case okeyAtmak
    case cifte

    var id: String { rawValue }

    var symbol: String {
        switch self {
        case .okeyAtmak: return "theatermasks.fill"
        case .cifte: return "rectangle.on.rectangle.fill"
        }
    }

    /// Okey atmak's surface label is per-Game; Çifte is Okey-only and always
    /// itself.
    func label(for game: Game) -> String {
        switch self {
        case .okeyAtmak: return game.okeyAtmakLabel
        case .cifte: return "\u{c7}ifte"
        }
    }
}

struct ScoresheetView: View {
    let match: Match
    let engine: MatchEngine

    @Environment(\.theme) private var theme

    var body: some View {
        let scoresheet = Scoresheet(match: match, engine: engine)
        let totalsByEntrant = Dictionary(
            uniqueKeysWithValues: scoresheet.totals.ranked.map { ($0.entrantID, $0.total) }
        )

        VStack(alignment: .leading, spacing: 12) {
            CardSurface(cornerRadius: 22, padding: 0) {
                VStack(spacing: 0) {
                    columnHeader

                    Rectangle()
                        .fill(theme.line)
                        .frame(height: 1)

                    if scoresheet.rows.isEmpty {
                        Text("No rounds yet.")
                            .siraStyle(.body)
                            .foregroundStyle(theme.ink.opacity(0.45))
                            .frame(maxWidth: .infinity)
                            .padding(24)
                    } else {
                        ForEach(Array(scoresheet.rows.enumerated()), id: \.element.id) { index, row in
                            roundRow(row)
                            if index < scoresheet.rows.count - 1 {
                                Rectangle()
                                    .fill(theme.line)
                                    .frame(height: 1)
                            }
                        }
                    }

                    totalsRow(totalsByEntrant)
                }
                .clipShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
            }

            let marks = marksInUse(scoresheet.rows)
            if !marks.isEmpty {
                modifierKey(marks)
            }

            Text("Undo removes the last round — totals, eliminations and rejoins all recalculate.")
                .siraStyle(.caption)
                .foregroundStyle(theme.ink.opacity(0.5))
        }
    }

    private var columnHeader: some View {
        HStack(spacing: 8) {
            Text(sira: .monoEyebrow, "Rd")
                .foregroundStyle(theme.ink.opacity(0.5))
                .frame(width: 26, alignment: .leading)
            // Every column is an equal share of what is left beside the Rd
            // column, header and numbers alike, so a name long enough to fill
            // its own header truncates inside it rather than widening it and
            // sliding every other column along — the numbers below have to
            // stay under the name they belong to.
            ForEach(match.entrants) { entrant in
                Text(sira: .monoEyebrow, columnLabel(for: entrant))
                    .foregroundStyle(theme.ink.opacity(0.5))
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 12)
    }

    private func roundRow(_ row: ScoresheetRow) -> some View {
        HStack(spacing: 8) {
            Text(sira: .monoLabel, "\(row.roundNumber)")
                .foregroundStyle(theme.ink.opacity(0.4))
                .frame(width: 26, alignment: .leading)
            ForEach(match.entrants) { entrant in
                HStack(spacing: 5) {
                    ForEach(modifiers(for: entrant.id, in: row)) { modifier in
                        Image(systemName: modifier.symbol)
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(theme.accent2)
                    }
                    Text(deltaText(row.deltas[entrant.id]))
                        .siraStyle(.monoLabel)
                        .foregroundStyle(row.deltas[entrant.id] == 0 ? theme.ink.opacity(0.35) : theme.ink)
                }
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
    }

    /// Which modifiers reached this Entrant in this Round. They're drawn in
    /// the Entrant's own column rather than spelled out in a note underneath,
    /// so the mark sits on the number it explains and names who did it by
    /// position — a scoresheet stays a grid.
    private func modifiers(for id: Entrant.ID, in row: ScoresheetRow) -> [RoundModifierMark] {
        var marks: [RoundModifierMark] = []
        if row.okeyAtanID == id { marks.append(.okeyAtmak) }
        if row.cifteCallers.contains(id) { marks.append(.cifte) }
        return marks
    }

    /// The marks present anywhere in this scoresheet, in a fixed order, for
    /// the key below the card. Absent entirely from an unmodified Match, which
    /// is most of them.
    private func marksInUse(_ rows: [ScoresheetRow]) -> [RoundModifierMark] {
        var marks: [RoundModifierMark] = []
        if rows.contains(where: { $0.okeyAtanID != nil }) { marks.append(.okeyAtmak) }
        if rows.contains(where: { !$0.cifteCallers.isEmpty }) { marks.append(.cifte) }
        return marks
    }

    /// What the icons mean, shown only once a Round has actually used one — an
    /// icon is only minimal if it doesn't send the reader looking for what it
    /// stands for.
    private func modifierKey(_ marks: [RoundModifierMark]) -> some View {
        HStack(spacing: 14) {
            ForEach(marks) { mark in
                HStack(spacing: 5) {
                    Image(systemName: mark.symbol)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(theme.accent2)
                    Text(mark.label(for: match.game))
                        .siraStyle(.caption)
                        .foregroundStyle(theme.ink.opacity(0.5))
                }
            }
        }
    }

    private func totalsRow(_ totalsByEntrant: [Entrant.ID: Int]) -> some View {
        HStack(spacing: 8) {
            Text(sira: .monoEyebrow, "Tot")
                .foregroundStyle(theme.ink.opacity(0.5))
                .frame(width: 26, alignment: .leading)
            ForEach(match.entrants) { entrant in
                Text("\(totalsByEntrant[entrant.id] ?? 0)")
                    .siraStyle(.monoValue)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 13)
        .background(theme.track)
    }

    private func columnLabel(for entrant: Entrant) -> String {
        String(entrant.name.split(separator: " ").first.map(String.init) ?? entrant.name)
    }

    private func deltaText(_ delta: Int?) -> String {
        guard let delta else { return "·" }
        return delta > 0 ? "+\(delta)" : "\(delta)"
    }
}

#Preview {
    let a = Entrant(name: "Alice")
    let b = Entrant(name: "Bob")
    let match = Match(
        game: .gonga,
        variant: .gongaStandard,
        number: 101,
        mode: .players,
        entrants: [a, b],
        rounds: [
            Round(deltas: [a.id: 20, b.id: 5]),
            Round(deltas: [a.id: 10, b.id: 15], cifteCallers: [a.id]),
            Round(deltas: [a.id: 0, b.id: 12], okeyAtanID: a.id),
        ]
    )
    return ScoresheetView(match: match, engine: SurvivalEngine())
        .padding()
        .themed()
}
