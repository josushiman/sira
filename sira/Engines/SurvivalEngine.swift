import Foundation

/// Win Condition for Gonga 101/151: Entrants accumulate score; passing the
/// Variant's limit sends them Out; the last Entrant not Out wins.
struct SurvivalEngine: MatchEngine {
    func standings(for match: Match) -> Standings {
        let limit = match.variant?.limit ?? .max

        var totals: [Entrant.ID: Int] = [:]
        var isOut: [Entrant.ID: Bool] = [:]
        for entrant in match.entrants {
            totals[entrant.id] = 0
            isOut[entrant.id] = false
        }

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in match.rounds {
            lastRoundDeltas = [:]
            let multipliers = round.multipliers(in: match)
            for entrant in match.entrants {
                guard isOut[entrant.id] == false, let delta = round.deltas[entrant.id] else { continue }
                let appliedDelta = delta * (multipliers[entrant.id] ?? 1)
                let newTotal = (totals[entrant.id] ?? 0) + appliedDelta
                totals[entrant.id] = newTotal
                lastRoundDeltas[entrant.id] = appliedDelta
                if newTotal > limit {
                    isOut[entrant.id] = true
                }
            }
            for rejoin in round.rejoins {
                totals[rejoin.id] = rejoin.to
                isOut[rejoin.id] = false
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

    /// The total a rejoining Entrant should be set to: the highest total currently
    /// held by any Entrant still in. If everyone busted in the same Round (nobody
    /// is still in), falls back to the highest total among all Entrants, capped at
    /// the Variant's limit so a Rejoin can never resume an Entrant already Out by
    /// the game's own rule.
    func rejoinTarget(for match: Match) -> Int {
        let limit = match.variant?.limit ?? .max
        let ranked = standings(for: match).ranked
        let stillIn = ranked.filter { !$0.isOut }.map(\.total).max()
        let target = stillIn ?? ranked.map(\.total).max() ?? 0
        return min(target, limit)
    }

    /// IDs of Entrants who are Out after the last Round but were not Out before it,
    /// i.e. entrants a Rejoin sheet should be offered to right now.
    func newlyOutEntrantIDs(for match: Match) -> [Entrant.ID] {
        guard !match.rounds.isEmpty else { return [] }

        var priorMatch = match
        priorMatch.rounds.removeLast()

        let before = standings(for: priorMatch)
        let after = standings(for: match)

        let outBefore = Set(before.ranked.filter(\.isOut).map(\.entrantID))
        return after.ranked
            .filter { $0.isOut && !outBefore.contains($0.entrantID) }
            .map(\.entrantID)
    }
}
