import Foundation

/// Win Condition for Gonga: Entrants accumulate score; passing the
/// Variant's limit sends them Out; the last Entrant not Out wins.
struct SurvivalEngine: MatchEngine {
    func standings(for match: Match, rounds: [Round]) -> Standings {
        // A Survival Match with no limit is not a Match with a lenient limit,
        // which is what resolving it as `.max` used to make it: nobody could
        // ever go Out and the Match could never end. There is nothing to score
        // it by, so there is nothing to say about it. Such a Match does not
        // reach here — `scorable` gates it out before Play can open it.
        guard let limit = match.variantNumber else {
            return Standings(ranked: [], isOver: false, result: nil)
        }

        var totals: [Entrant.ID: Int] = [:]
        var isOut: [Entrant.ID: Bool] = [:]
        for entrant in match.entrants {
            totals[entrant.id] = 0
            isOut[entrant.id] = false
        }

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in rounds {
            lastRoundDeltas = [:]
            let multipliers = round.multipliers(in: match, winCondition: .survival)
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
    /// the Match's limit so a Rejoin can never resume an Entrant already Out by
    /// the game's own rule.
    func rejoinTarget(for match: Match) -> Int {
        let ranked = standings(for: match).ranked
        let stillIn = ranked.filter { !$0.isOut }.map(\.total).max()
        let target = stillIn ?? ranked.map(\.total).max() ?? 0
        // No limit means no Standings either, so there is no target to cap and
        // nothing here to cap it against.
        guard let limit = match.variantNumber else { return target }
        return min(target, limit)
    }

    /// IDs of Entrants who are Out after the last Round but were not Out before it,
    /// i.e. entrants a Rejoin sheet should be offered to right now.
    func newlyOutEntrantIDs(for match: Match) -> [Entrant.ID] {
        let played = match.rounds
        guard !played.isEmpty else { return [] }

        let before = standings(for: match, rounds: Array(played.dropLast()))
        let after = standings(for: match, rounds: played)

        let outBefore = Set(before.ranked.filter(\.isOut).map(\.entrantID))
        return after.ranked
            .filter { $0.isOut && !outBefore.contains($0.entrantID) }
            .map(\.entrantID)
    }
}
