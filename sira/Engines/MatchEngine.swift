import Foundation

protocol MatchEngine {
    /// The Standings for `match` as if it held exactly `rounds`, in the order
    /// given.
    ///
    /// The Rounds come in separately rather than being read off the Match so
    /// that a caller can score a *prefix* of a Match — the Scoresheet derives
    /// each row from the Standings before and after a Round, and Survival has
    /// to know who was Out before the last Round to know who has just gone Out.
    /// Both used to do that by copying the Match and mutating the copy, which a
    /// model class cannot offer: a Match is one shared object, so a copy that
    /// scored a prefix would have emptied the real Match of its Rounds
    /// (`docs/adr/0006`).
    func standings(for match: Match, rounds: [Round]) -> Standings
}

extension MatchEngine {
    /// The Standings for every Round the Match holds — what almost every caller
    /// wants, and the only form the screens use.
    func standings(for match: Match) -> Standings {
        standings(for: match, rounds: match.rounds)
    }
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
        case .fixedRounds: return FixedRoundsEngine()
        }
    }
}
