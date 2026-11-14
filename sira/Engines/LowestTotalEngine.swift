import Foundation

/// Okey 101 accumulates deltas with no elimination or Round target. Only the
/// persisted ending declares the lowest total (or tied totals) final.
struct LowestTotalEngine: MatchEngine {
    func standings(for match: Match, rounds: [Round]) -> Standings {
        var totals: [Entrant.ID: Int] = [:]
        for entrant in match.entrants {
            totals[entrant.id] = 0
        }

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in rounds {
            lastRoundDeltas = [:]
            let multipliers = round.multipliers(in: match, winCondition: .lowestTotal)
            for entrant in match.entrants {
                guard let delta = round.deltas[entrant.id] else { continue }
                let appliedDelta = delta * (multipliers[entrant.id] ?? 1)
                totals[entrant.id] = (totals[entrant.id] ?? 0) + appliedDelta
                lastRoundDeltas[entrant.id] = appliedDelta
            }
        }

        let isOver = match.ended

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
