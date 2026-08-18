import Foundation

/// A one-line Home-list summary derived purely from a Match's Engine Standings —
/// leader-and-score while in progress, or the Win Condition's result once over.
/// Contains no Win-Condition-specific logic, so it reads the same for any Engine.
struct MatchSummary {
    let text: String

    init(match: Match, engine: MatchEngine) {
        let standings = engine.standings(for: match)
        if standings.isOver, let result = standings.result {
            text = result
        } else if let leader = standings.ranked.first {
            text = "\(leader.name) leads with \(leader.total)"
        } else {
            text = "No Entrants"
        }
    }
}
