import Foundation

protocol MatchEngine {
    func standings(for match: Match) -> Standings
}

extension WinCondition {
    /// The Engine that owns this Win Condition's scoring rules. Static and
    /// derived from the Win Condition alone, never user-selectable, so callers
    /// (e.g. the Home list) never need Win-Condition-specific branching of
    /// their own.
    var engine: MatchEngine {
        switch self {
        case .survival: return SurvivalEngine()
        case .elimination: return EliminationEngine()
        case .fixedRounds: fatalError("FixedRoundsEngine not implemented yet")
        }
    }
}
