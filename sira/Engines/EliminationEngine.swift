import Foundation

/// Win Condition for Okey standard: two Entrants (Teams of 2) count down from
/// the Variant's starting score. Each Round the losing team takes a −2
/// penalty, scaled by that Round's modifiers, and the Gösterge find — one per
/// Round at most — deducts 1 from the *other* team, never scaled. The Match
/// ends the moment any Entrant's total reaches 0 or below.
///
/// With a single loser, Çifte's two branches land on the same team — "everyone
/// else doubles" and "the caller doubles themselves" both reach the loser — so
/// the totals here don't turn on which team called, or on how many did. The
/// callers are still recorded per Entrant, because the scoresheet shows who
/// called.
struct EliminationEngine: MatchEngine {
    func standings(for match: Match) -> Standings {
        let startingScore = match.variant.startingScore ?? 0

        var totals: [Entrant.ID: Int] = [:]
        for entrant in match.entrants {
            totals[entrant.id] = startingScore
        }

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in match.rounds {
            lastRoundDeltas = [:]
            let multipliers = round.multipliers(in: match)

            if let losingID = round.losingEntrantID, totals[losingID] != nil {
                let penalty = -2 * (multipliers[losingID] ?? 1)
                totals[losingID] = (totals[losingID] ?? 0) + penalty
                lastRoundDeltas[losingID, default: 0] += penalty
            }

            if let finderID = round.gostergeFinderID,
               match.entrants.contains(where: { $0.id == finderID }) {
                for other in match.entrants where other.id != finderID {
                    totals[other.id] = (totals[other.id] ?? 0) - 1
                    lastRoundDeltas[other.id, default: 0] -= 1
                }
            }
        }

        let isOver = totals.values.contains { $0 <= 0 }
        let result: String?
        if isOver {
            if let winner = match.entrants.first(where: { (totals[$0.id] ?? 0) > 0 }) {
                result = "\(winner.name) wins!"
            } else {
                // Every Entrant reached 0 in the same Round: the one with the
                // higher (least negative) total lost by less and wins the tiebreak.
                let winner = match.entrants.max { (totals[$0.id] ?? 0) < (totals[$1.id] ?? 0) }
                result = winner.map { "\($0.name) wins!" }
            }
        } else {
            result = nil
        }

        let ranked = match.entrants
            .map { entrant in
                EntrantStanding(
                    entrantID: entrant.id,
                    name: entrant.name,
                    total: totals[entrant.id] ?? 0,
                    isOut: (totals[entrant.id] ?? 0) <= 0,
                    deltaFromLastRound: lastRoundDeltas[entrant.id] ?? 0
                )
            }
            .sorted { lhs, rhs in
                if lhs.isOut != rhs.isOut { return !lhs.isOut }
                return lhs.total > rhs.total
            }

        return Standings(ranked: ranked, isOver: isOver, result: result)
    }
}
