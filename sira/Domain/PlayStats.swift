import Foundation

/// The Play screen's two stat tiles, derived purely from a Match's Engine
/// Standings — Leader/Result plus a second tile whose label and value depend
/// on the Variant's Win Condition (Survival: Closest to out, Fixed Rounds:
/// Rounds left, Elimination: Gap between the best and worst Standing).
struct PlayStats {
    let leadLabel: String
    let leadValue: String
    let secondaryLabel: String
    let secondaryValue: String

    init(match: Match, engine: MatchEngine) {
        self.init(match: match, standings: engine.standings(for: match))
    }

    init(match: Match, standings: Standings) {
        let leader = standings.ranked.first

        leadLabel = standings.isOver ? "Result" : "Leader"
        leadValue = leader.map { "\($0.name) · \($0.total)" } ?? "—"

        switch match.variant.winCondition {
        case .survival:
            // The Entrant with the least Room left is the one the Match is
            // about to lose — more telling than the leader's own headroom,
            // which the rows now spell out for every Entrant anyway.
            let limit = match.variant.limit ?? 0
            let atRisk = standings.ranked.filter { !$0.isOut }.max { $0.total < $1.total }
            if standings.isOver {
                // Over means one Entrant is left in, so nobody is close to
                // anything — report the survivor's headroom instead.
                secondaryLabel = "Room left"
                secondaryValue = atRisk.map { "\(max(0, limit - $0.total))" } ?? "—"
            } else {
                secondaryLabel = "Closest to out"
                secondaryValue = atRisk.map { "\($0.name) · \(max(0, limit - $0.total)) left" } ?? "—"
            }
        case .fixedRounds:
            secondaryLabel = "Rounds left"
            let roundCount = match.variant.roundCount ?? 0
            secondaryValue = "\(max(0, roundCount - match.rounds.count))"
        case .elimination:
            secondaryLabel = "Gap"
            let best = standings.ranked.first?.total ?? 0
            let worst = standings.ranked.last?.total ?? 0
            secondaryValue = "\(abs(best - worst))"
        }
    }
}
