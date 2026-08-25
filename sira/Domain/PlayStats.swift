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

    init(variant: Variant, match: Match, engine: MatchEngine) {
        self.init(variant: variant, match: match, standings: engine.standings(for: match))
    }

    /// The Variant comes in already resolved: Play has one in hand before it
    /// renders, so the tiles never have to describe a Match without rules.
    init(variant: Variant, match: Match, standings: Standings) {
        let leader = standings.ranked.first

        leadLabel = standings.isOver ? "Result" : "Leader"
        leadValue = leader.map { "\($0.name) · \($0.total)" } ?? "—"

        switch variant.winCondition {
        case .survival:
            // The Entrant with the least Room left is the one the Match is
            // about to lose — more telling than the leader's own Room left,
            // which the rows now spell out for every Entrant anyway.
            //
            // Every Entrant on that total is named, not one of them: a Rejoin
            // — and a Join — puts an Entrant on the highest total still in, so
            // a tie at the top is the ordinary case. Picking one by ranking
            // order would state a fact that isn't true.
            let stillIn = standings.ranked.filter { !$0.isOut }
            let highest = stillIn.map(\.total).max()
            let atRiskEntrants = stillIn.filter { $0.total == highest }
            // Room left is measured against the Match's limit, so a Match with
            // no limit has none to report — the same em dash as a Match with
            // nobody left to report it for. Resolving the limit as zero used
            // to say instead that everyone had run out of room.
            let roomLeft = match.variantNumber.flatMap { limit in
                highest.map { max(0, limit - $0) }
            }
            if standings.isOver {
                // Over means one Entrant is left in, so nobody is close to
                // anything — report the survivor's own Room left instead.
                secondaryLabel = "Room left"
                secondaryValue = roomLeft.map { "\($0)" } ?? "—"
            } else {
                secondaryLabel = "Closest to out"
                secondaryValue = Self.names(atRiskEntrants).flatMap { names in
                    roomLeft.map { "\(names) · \($0) left" }
                } ?? "—"
            }
        case .fixedRounds:
            secondaryLabel = "Rounds left"
            secondaryValue = match.variantNumber.map { "\(max(0, $0 - match.rounds.count))" } ?? "—"
        case .elimination:
            secondaryLabel = "Gap"
            let best = standings.ranked.first?.total ?? 0
            let worst = standings.ranked.last?.total ?? 0
            secondaryValue = "\(abs(best - worst))"
        }
    }

    /// Names a set of tied Entrants for a stat tile: `Bob`, `Bob & Cem`,
    /// `Bob, Cem & Dila`. A comma list with an ampersand on the last pair
    /// still fits the tile's two lines at four names, where spelling out
    /// "and" between each would not. `nil` when there is nobody to name, so
    /// the caller reports an em dash rather than an empty string.
    private static func names(_ standings: [EntrantStanding]) -> String? {
        let names = standings.map(\.name)
        guard let last = names.last else { return nil }
        guard names.count > 1 else { return last }
        return "\(names.dropLast().joined(separator: ", ")) & \(last)"
    }
}
