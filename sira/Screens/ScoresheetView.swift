import SwiftUI

struct ScoresheetView: View {
    let match: Match
    let engine: MatchEngine

    var body: some View {
        let scoresheet = Scoresheet(match: match, engine: engine)
        let totalsByEntrant = Dictionary(
            uniqueKeysWithValues: scoresheet.totals.ranked.map { ($0.entrantID, $0.total) }
        )

        ScrollView([.horizontal, .vertical]) {
            Grid(alignment: .leading, horizontalSpacing: 16, verticalSpacing: 10) {
                GridRow {
                    Text("Round")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)
                    ForEach(match.entrants) { entrant in
                        Text(entrant.name)
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }

                Divider().gridCellColumns(match.entrants.count + 1)

                ForEach(scoresheet.rows) { row in
                    GridRow {
                        Text("\(row.roundNumber)")
                            .foregroundStyle(.secondary)
                        ForEach(match.entrants) { entrant in
                            Text(deltaText(row.deltas[entrant.id]))
                                .monospacedDigit()
                        }
                    }
                }

                Divider().gridCellColumns(match.entrants.count + 1)

                GridRow {
                    Text("Total")
                        .font(.headline)
                    ForEach(match.entrants) { entrant in
                        Text("\(totalsByEntrant[entrant.id] ?? 0)")
                            .font(.headline.monospacedDigit())
                    }
                }
            }
            .padding()
        }
    }

    private func deltaText(_ delta: Int?) -> String {
        guard let delta else { return "–" }
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
            Round(deltas: [a.id: 10, b.id: 15], cifte: true),
        ]
    )
    return ScoresheetView(match: match, engine: SurvivalEngine())
}
