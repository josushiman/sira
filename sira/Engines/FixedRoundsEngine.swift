import Foundation

/// Win Condition for Okey 101: Entrants accumulate deltas each Round, scaled
/// by that Round's modifiers, with no elimination. The Match ends once the
/// Variant's configured Round count is reached; the lowest total wins. This is
/// the only Win Condition where Çifte's asymmetry is observable, having more
/// than one loser for a winning caller to double.
struct FixedRoundsEngine: MatchEngine {
    func standings(for match: Match) -> Standings {
        let roundCount = match.variant.roundCount ?? .max

        var totals: [Entrant.ID: Int] = [:]
        for entrant in match.entrants {
            totals[entrant.id] = 0
        }

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in match.rounds {
            lastRoundDeltas = [:]
            let multipliers = round.multipliers(in: match)
            for entrant in match.entrants {
                guard let delta = round.deltas[entrant.id] else { continue }
                let appliedDelta = delta * (multipliers[entrant.id] ?? 1)
                totals[entrant.id] = (totals[entrant.id] ?? 0) + appliedDelta
                lastRoundDeltas[entrant.id] = appliedDelta
            }
        }

        let isOver = match.rounds.count >= roundCount

        let ranked = match.entrants
            .map { entrant in
                EntrantStanding(
                    entrantID: entrant.id,
                    name: entrant.name,
                    total: totals[entrant.id] ?? 0,
                    isOut: false,
                    deltaFromLastRound: lastRoundDeltas[entrant.id] ?? 0
                )
            }
            .sorted { $0.total < $1.total }

        let result: String?
        if isOver, let lowest = ranked.first?.total {
            let winners = ranked.filter { $0.total == lowest }
            if winners.count == 1 {
                result = "\(winners[0].name) wins!"
            } else {
                result = "Tie between \(winners.map(\.name).joined(separator: " and "))!"
            }
        } else {
            result = nil
        }

        return Standings(ranked: ranked, isOver: isOver, result: result)
    }
}
