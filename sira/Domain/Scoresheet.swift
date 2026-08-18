import Foundation

struct ScoresheetRow: Identifiable {
    let id: Round.ID
    let roundNumber: Int
    let deltas: [Entrant.ID: Int]
}

/// A Round-by-Round history derived purely from `Match` → `Standings` diffs, so it
/// requires no Engine-specific logic: each row's delta is the change in an Entrant's
/// total between the Standings for the Rounds up to and including that Round, and the
/// Standings for the Rounds before it. This also means Rejoins are represented
/// correctly without special-casing them here.
struct Scoresheet {
    let rows: [ScoresheetRow]
    let totals: Standings

    init(match: Match, engine: MatchEngine) {
        var rows: [ScoresheetRow] = []
        var previousTotals: [Entrant.ID: Int] = Dictionary(uniqueKeysWithValues: match.entrants.map { ($0.id, 0) })

        var partial = match
        partial.rounds = []

        for (index, round) in match.rounds.enumerated() {
            partial.rounds.append(round)
            let standings = engine.standings(for: partial)

            var deltas: [Entrant.ID: Int] = [:]
            for standing in standings.ranked {
                let previous = previousTotals[standing.entrantID] ?? 0
                deltas[standing.entrantID] = standing.total - previous
                previousTotals[standing.entrantID] = standing.total
            }

            rows.append(ScoresheetRow(id: round.id, roundNumber: index + 1, deltas: deltas))
        }

        self.rows = rows
        self.totals = engine.standings(for: partial)
    }
}
