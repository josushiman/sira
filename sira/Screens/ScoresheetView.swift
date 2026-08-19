import SwiftUI

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
                Text(deltaText(row.deltas[entrant.id]))
                    .siraStyle(.monoLabel)
                    .foregroundStyle(row.deltas[entrant.id] == 0 ? theme.ink.opacity(0.35) : theme.ink)
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(.horizontal, 15)
        .padding(.vertical, 11)
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
        variant: .gonga101,
        mode: .players,
        entrants: [a, b],
        rounds: [
            Round(deltas: [a.id: 20, b.id: 5]),
            Round(deltas: [a.id: 10, b.id: 15], cifteCallers: [a.id]),
        ]
    )
    return ScoresheetView(match: match, engine: SurvivalEngine())
        .padding()
        .themed()
}
