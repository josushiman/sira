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

/// A Round-by-Round history of changes in total, supplied by the Engine so
/// additive scoring can avoid repeated prefix calculations while resets and
/// arrivals keep their Standings-derived meaning.
struct Scoresheet {
    let rows: [ScoresheetRow]
    let totals: Standings

    init(match: Match, engine: MatchEngine) {
        // `match.rounds` is sequence-ordered, so a row's number is its position
        // in that order — never its position in however the Rounds were stored.
        let played = match.rounds
        let deltas = engine.deltasByRound(for: match, rounds: played)
        self.rows = played.enumerated().map { index, round in
            ScoresheetRow(
                id: round.id,
                roundNumber: index + 1,
                deltas: deltas[index],
                cifteCallers: round.cifteCallers,
                okeyAtanID: round.okeyAtanID
            )
        }
        self.totals = engine.standings(for: match, rounds: played)
    }
}
