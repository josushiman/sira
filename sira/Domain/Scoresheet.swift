import Foundation

struct ScoresheetRow: Identifiable {
    let id: Round.ID
    let roundNumber: Int
    let deltas: [Entrant.ID: Int]
    /// The Round's modifiers, carried through unchanged so the history can say
    /// *why* a Round doubled and who did it — the deltas above already have
    /// the doubling in them, and a number alone can't be traced back to the
    /// event that caused it.
    let cifteCallers: Set<Entrant.ID>
    let okeyAtanID: Entrant.ID?

    init(
        id: Round.ID,
        roundNumber: Int,
        deltas: [Entrant.ID: Int],
        cifteCallers: Set<Entrant.ID> = [],
        okeyAtanID: Entrant.ID? = nil
    ) {
        self.id = id
        self.roundNumber = roundNumber
        self.deltas = deltas
        self.cifteCallers = cifteCallers
        self.okeyAtanID = okeyAtanID
    }
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

        // `match.rounds` is sequence-ordered, so a row's number is its position
        // in that order — never its position in however the Rounds were stored.
        let played = match.rounds
        for (index, round) in played.enumerated() {
            let standings = engine.standings(for: match, rounds: Array(played.prefix(index + 1)))

            var deltas: [Entrant.ID: Int] = [:]
            for standing in standings.ranked {
                let previous = previousTotals[standing.entrantID] ?? 0
                deltas[standing.entrantID] = standing.total - previous
                previousTotals[standing.entrantID] = standing.total
            }

            rows.append(ScoresheetRow(
                id: round.id,
                roundNumber: index + 1,
                deltas: deltas,
                cifteCallers: round.cifteCallers,
                okeyAtanID: round.okeyAtanID
            ))
        }

        self.rows = rows
        self.totals = engine.standings(for: match, rounds: played)
    }
}
