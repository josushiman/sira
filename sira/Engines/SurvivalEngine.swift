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

        // Who is being scored, and from when. An Entrant seated at Setup is
        // joined from the Match's first Round; one who took a free seat partway
        // through is joined from the Round their JoinEvent sits on, and the
        // Rounds before it are not theirs to be scored — or ranked — for.
        //
        // Read from the Entrants rather than from the Rounds, and so not from
        // `rounds`, which is often a prefix: an Entrant whose join Round falls
        // outside the prefix must come out omitted, not seated at Setup on a
        // total of zero. That distinction is the whole point of the rule, and
        // the Scoresheet — which scores every prefix in turn — is what would
        // lose it. It is also what survives an Undo of the Round an arrival was
        // recorded against: the JoinEvent goes, the arrival does not, and the
        // seat is simply in no Round of the Match.
        let arrivals = Set(match.entrants.filter(\.arrivedMidMatch).map(\.id))
        var joined = Set(match.entrants.map(\.id)).subtracting(arrivals)

        var lastRoundDeltas: [Entrant.ID: Int] = [:]

        for round in rounds {
            lastRoundDeltas = [:]
            let multipliers = round.multipliers(in: match, winCondition: .survival)
            for entrant in match.entrants {
                guard joined.contains(entrant.id), isOut[entrant.id] == false,
                      let delta = round.deltas[entrant.id] else { continue }
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
            // Applied after the Round's deltas, like a Rejoin: a joiner arrives
            // at an agreed total for a Round already scored, rather than taking
            // score in it. Unlike a Rejoin, nothing here clears Out — an
            // Entrant who has not joined has taken no score to have gone Out
            // on, and a joining total above the limit is 05's to refuse rather
            // than this loop's to absolve.
            for join in round.joins {
                joined.insert(join.id)
                totals[join.id] = join.to
            }
        }

        // Only joined Entrants are in the Match to be decided over. One who is
        // seated but has not joined yet — every Round of this prefix predates
        // their arrival — must not keep a settled Match open by counting as
        // someone still in.
        let joinedEntrants = match.entrants.filter { joined.contains($0.id) }
        let stillIn = joinedEntrants.filter { isOut[$0.id] == false }
        let isOver = joinedEntrants.count > 1 && stillIn.count <= 1
        let result: String?
        if stillIn.count == 1 {
            result = "\(stillIn[0].name) wins!"
        } else if isOver {
            // Everyone still standing busted in the same Round: lowest total wins the tiebreak.
            let winner = joinedEntrants.min { (totals[$0.id] ?? 0) < (totals[$1.id] ?? 0) }
            result = winner.map { "\($0.name) wins!" }
        } else {
            result = nil
        }

        let ranked = joinedEntrants
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
