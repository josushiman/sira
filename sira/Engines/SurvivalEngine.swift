import Foundation

/// Win Condition for Gonga 101/151: Entrants accumulate score; passing the
/// Variant's limit sends them Out; the last Entrant not Out wins.
struct SurvivalEngine: MatchEngine {
    func standings(for match: Match) -> Standings {
        let limit = match.variant.limit ?? .max

        var totals: [Entrant.ID: Int] = [:]
        var isOut: [Entrant.ID: Bool] = [:]
        for entrant in match.entrants {
            totals[entrant.id] = 0
            isOut[entrant.id] = false
        }

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in match.rounds {
            lastRoundDeltas = [:]
            for entrant in match.entrants {
                guard isOut[entrant.id] == false, let delta = round.deltas[entrant.id] else { continue }
                let newTotal = (totals[entrant.id] ?? 0) + delta
                totals[entrant.id] = newTotal
                lastRoundDeltas[entrant.id] = delta
                if newTotal > limit {
                    isOut[entrant.id] = true
                }
            }
        }

        let stillIn = match.entrants.filter { isOut[$0.id] == false }
        let isOver = match.entrants.count > 1 && stillIn.count <= 1
        let result: String?
        if stillIn.count == 1 {
            result = "\(stillIn[0].name) wins!"
        } else if isOver {
            // Everyone still standing busted in the same Round: lowest total wins the tiebreak.
            let winner = match.entrants.min { (totals[$0.id] ?? 0) < (totals[$1.id] ?? 0) }
            result = winner.map { "\($0.name) wins!" }
        } else {
            result = nil
        }

        let ranked = match.entrants
            .map { entrant in
                EntrantStanding(
                    entrantID: entrant.id,
                    name: entrant.name,
                    total: totals[entrant.id] ?? 0,
                    isOut: isOut[entrant.id] ?? false,
                    deltaFromLastRound: lastRoundDeltas[entrant.id] ?? 0
                )
            }
            .sorted { lhs, rhs in
                if lhs.isOut != rhs.isOut { return !lhs.isOut }
                return lhs.total < rhs.total
            }

        return Standings(ranked: ranked, isOver: isOver, result: result)
    }
}
